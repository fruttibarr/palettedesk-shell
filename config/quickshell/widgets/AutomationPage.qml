import Quickshell
import Quickshell.Hyprland
import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Automation: rules that change settings while a condition holds (see services/Profiles.qml).
ColumnLayout {
    id: page
    spacing: 16

    readonly property var rules: Settings.s.autoRules ?? []
    function save(arr) { Settings.set("autoRules", arr); }
    function patch(id, change) { save(rules.map(r => r.id === id ? Object.assign({}, r, change) : r)); }
    function patchTrigger(id, change) { patch(id, { trigger: Object.assign({}, rules.find(r => r.id === id)?.trigger ?? {}, change) }); }
    function patchAction(id, change) {
        const a = Object.assign({}, rules.find(r => r.id === id)?.action ?? {}, change);
        for (const k in a) if (a[k] === "" || a[k] === null || a[k] === undefined) delete a[k];
        patch(id, { action: a });
    }
    function remove(id) { save(rules.filter(r => r.id !== id)); }
    function addRule() {
        save(rules.concat([{ id: "rule-" + Date.now().toString(36), name: "New rule", enabled: false, trigger: { type: "battery", below: 0 }, action: { settings: {} } }]));
    }
    function setKeys(id, entries) {   // entries: [[key, value], ...]
        const o = {};
        for (const [k, v] of entries) o[k] = v;
        patchAction(id, { settings: o });
    }
    function parseValue(t) { try { return JSON.parse(t); } catch (e) { return t; } }

    readonly property var quick: [
        { label: "Blur off", k: "blurEnabled", v: false }, { label: "Shadows off", k: "shadowEnabled", v: false },
        { label: "Animations ½", k: "animScale", v: 0.5 }, { label: "Animations off", k: "animScale", v: 0 },
        { label: "Night light", k: "nightLight", v: true }, { label: "Dim inactive", k: "dimInactive", v: true },
        { label: "Light mode", k: "colorMode", v: "light" }, { label: "No gaps", k: "gapsOut", v: 0 },
    ]
    readonly property var triggers: [
        { label: "On battery", value: "battery" }, { label: "Fullscreen window", value: "fullscreen" }, { label: "App focused", value: "app" },
        { label: "Time of day", value: "time" }, { label: "Extra monitor", value: "monitor" },
    ]

    component Btn: Rectangle {
        property string label: ""
        property bool danger: false
        property bool primary: false
        signal clicked()
        implicitHeight: 30; implicitWidth: bt.implicitWidth + 24; radius: 15
        color: primary ? (bm.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
             : bm.containsMouse ? (danger ? Theme.error : Theme.primary) : Theme.alpha(Theme.surfaceContainerHigh, 0.8)
        Text { id: bt; anchors.centerIn: parent; text: parent.label; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
               color: parent.primary || bm.containsMouse ? Theme.textOnPrimary : danger ? Theme.error : Theme.text }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
    component Cap: Text { color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }

    Text { text: "Automation"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 9; font.weight: Font.Bold }
    Text {
        Layout.fillWidth: true; wrapMode: Text.Wrap
        text: "Rules change settings while their condition holds and put everything back afterwards. If you change a setting yourself while a rule is active, your change is kept. Later rules win when two change the same setting."
        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
    }
    Text {
        Layout.fillWidth: true
        text: Profiles.activeIds.length ? "● Active now: " + Profiles.activeIds.map(id => page.rules.find(r => r.id === id)?.name ?? id).join(", ") : "○ No rule is active right now"
        color: Profiles.activeIds.length ? Theme.primary : Theme.outline
        font.family: Theme.font; font.pixelSize: Theme.fontSize
    }

    Repeater {
        model: page.rules
        SettingSection {
            id: card
            required property var modelData
            readonly property string rid: modelData.id
            readonly property var trig: modelData.trigger ?? ({})
            readonly property var act: modelData.action ?? ({})
            readonly property var entries: Object.entries(act.settings ?? {})
            readonly property bool live: Profiles.activeIds.includes(rid)
            title: modelData.name + (live ? "   ● active" : "")

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Toggle { checked: card.modelData.enabled === true; onToggled: v => page.patch(card.rid, { enabled: v }) }
                SettingText { Layout.fillWidth: true; placeholder: "Rule name"; text: card.modelData.name; onSubmitted: t => page.patch(card.rid, { name: t }) }
                Btn { label: "Delete"; danger: true; onClicked: page.remove(card.rid) }
            }

            Cap { text: "When" }
            Segmented {
                current: card.trig.type ?? "battery"
                onPicked: v => page.patch(card.rid, { trigger: v === "battery" ? { type: v, below: 0 } : v === "time" ? { type: v, from: "21:00", to: "06:00" } : v === "app" ? { type: v, match: "" } : { type: v } })
                options: page.triggers
            }
            SettingRow {
                visible: card.trig.type === "battery"
                label: "Only below"; description: "0 = whenever unplugged"
                ValueSlider { from: 0; to: 100; stepSize: 5; suffix: " %"; value: card.trig.below ?? 0; onMoved: v => page.patchTrigger(card.rid, { below: v }) }
            }
            RowLayout {
                visible: card.trig.type === "app"
                Layout.fillWidth: true; spacing: 8
                Cap { text: "App class (regex)" }
                SettingText { Layout.fillWidth: true; placeholder: "e.g. steam_app|mpv"; text: card.trig.match ?? ""; onSubmitted: t => page.patchTrigger(card.rid, { match: t }) }
            }
            Flow {
                visible: card.trig.type === "app"
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: { const seen = new Set(); for (const t of Hyprland.toplevels.values) { const c = t.lastIpcObject?.class; if (c) seen.add(c); } return Array.from(seen).sort(); }
                    Btn { required property string modelData; label: modelData; onClicked: page.patchTrigger(card.rid, { match: "^" + modelData + "$" }) }
                }
            }
            RowLayout {
                visible: card.trig.type === "time"
                Layout.fillWidth: true; spacing: 8
                Cap { text: "From" }
                SettingText { implicitWidth: 90; placeholder: "21:00"; text: card.trig.from ?? ""; onSubmitted: t => page.patchTrigger(card.rid, { from: t }) }
                Cap { text: "to" }
                SettingText { implicitWidth: 90; placeholder: "06:00"; text: card.trig.to ?? ""; onSubmitted: t => page.patchTrigger(card.rid, { to: t }) }
                Cap { text: "(24-hour, may cross midnight)" }
            }

            Cap { text: "Do" }
            Cap { text: "Power profile" }
            Segmented {
                current: card.act.power ?? ""
                onPicked: v => page.patchAction(card.rid, { power: v })
                options: [{ label: "Leave", value: "" }, { label: "Power saver", value: "power-saver" }, { label: "Balanced", value: "balanced" }, { label: "Performance", value: "performance" }]
            }
            Cap { text: "Do Not Disturb" }
            Segmented {
                current: card.act.dnd === true ? "on" : card.act.dnd === false ? "off" : ""
                onPicked: v => page.patchAction(card.rid, { dnd: v === "on" ? true : v === "off" ? false : "" })
                options: [{ label: "Leave", value: "" }, { label: "Turn on", value: "on" }, { label: "Turn off", value: "off" }]
            }
            Cap { text: "Theme (also changes the wallpaper)" }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Btn { label: "Keep current"; primary: !card.act.theme; onClicked: page.patchAction(card.rid, { theme: "" }) }
                Repeater { model: Presets.all.filter(p => !p.auto); Btn { required property var modelData; label: modelData.name; primary: card.act.theme === modelData.name; onClicked: page.patchAction(card.rid, { theme: modelData.name }) } }
            }

            Cap { text: "Settings to change" }
            Repeater {
                model: card.entries
                RowLayout {
                    id: er
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true; spacing: 8
                    SettingText {
                        Layout.preferredWidth: 190
                        placeholder: "setting key"
                        text: er.modelData[0]
                        onSubmitted: t => page.setKeys(card.rid, card.entries.map((e, i) => i === er.index ? [t, e[1]] : e).filter(e => e[0] !== ""))
                    }
                    Cap { text: "=" }
                    SettingText {
                        Layout.fillWidth: true
                        placeholder: "value (true, 0.5, \"text\")"
                        text: JSON.stringify(er.modelData[1])
                        onSubmitted: t => page.setKeys(card.rid, card.entries.map((e, i) => i === er.index ? [e[0], page.parseValue(t)] : e))
                    }
                    Cap { visible: !(er.modelData[0] in Settings.defaults); text: "unknown key"; color: Theme.error }
                    Btn { label: "✕"; danger: true; onClicked: page.setKeys(card.rid, card.entries.filter((e, i) => i !== er.index)) }
                }
            }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Cap { text: "Add:"; height: 30; verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: page.quick
                    Btn { required property var modelData; label: modelData.label; onClicked: page.setKeys(card.rid, card.entries.filter(e => e[0] !== modelData.k).concat([[modelData.k, modelData.v]])) }
                }
                Btn { label: "+ Other setting"; onClicked: page.setKeys(card.rid, card.entries.concat([["", ""]]).filter(e => true)) }
            }

            Cap { text: "Commands (optional)" }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Cap { Layout.preferredWidth: 90; text: "When it starts" }
                SettingText { Layout.fillWidth: true; placeholder: "shell command"; text: card.act.command ?? ""; onSubmitted: t => page.patchAction(card.rid, { command: t }) }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Cap { Layout.preferredWidth: 90; text: "When it ends" }
                SettingText { Layout.fillWidth: true; placeholder: "shell command"; text: card.act.commandOff ?? ""; onSubmitted: t => page.patchAction(card.rid, { commandOff: t }) }
            }
        }
    }

    Btn { primary: true; label: "󰐕  New rule"; onClicked: page.addRule() }
}
