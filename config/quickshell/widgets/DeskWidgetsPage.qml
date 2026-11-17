import Quickshell
import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Desktop widgets: add, arrange and style widgets that sit on the wallpaper (see system/DesktopWidgets.qml).
ColumnLayout {
    id: page
    spacing: 16

    readonly property var widgets: Settings.s.desktopWidgets ?? []
    readonly property var types: [
        { id: "clock", name: "Clock", icon: "󰥔" }, { id: "calendar", name: "Calendar", icon: "󰃭" }, { id: "media", name: "Now playing", icon: "󰎆" },
        { id: "system", name: "CPU & RAM", icon: "󰍛" }, { id: "weather", name: "Weather", icon: "󰖐" }, { id: "notes", name: "Note", icon: "󰎞" },
        { id: "lyrics", name: "Lyrics", icon: "󰎈" }, { id: "command", name: "Command output", icon: "󰆍" },
    ]
    function typeName(id) { return (types.find(t => t.id === id) ?? { name: id }).name; }
    function save(arr) { Settings.set("desktopWidgets", arr); }
    function patch(uid, change) { save(widgets.map(w => w.uid === uid ? Object.assign({}, w, change) : w)); }
    function patchOpts(uid, change) { patch(uid, { opts: Object.assign({}, widgets.find(w => w.uid === uid)?.opts ?? {}, change) }); }
    function remove(uid) { save(widgets.filter(w => w.uid !== uid)); }
    function add(type) {
        const n = widgets.length, plain = ["clock", "lyrics", "command"].includes(type);
        const opts = type === "clock" ? { h24: true, seconds: false, date: true, size: 72 } : type === "command" ? { command: "date", interval: 5, size: 18 } : {};
        save(widgets.concat([{ uid: "w" + Date.now().toString(36), type: type, monitor: Quickshell.screens[0]?.name ?? "", x: 0.06 + 0.07 * (n % 6), y: 0.14 + 0.09 * (n % 6),
                               scale: 1, opacity: 1, style: plain ? "plain" : "glass", opts: opts }]));
    }

    component Btn: Rectangle {
        property string label: ""
        property bool danger: false
        property bool primary: false
        signal clicked()
        implicitHeight: 32; implicitWidth: bt.implicitWidth + 26; radius: 16
        color: primary ? Theme.primary : bm.containsMouse ? (danger ? Theme.error : Theme.primary) : Theme.alpha(Theme.surfaceContainerHigh, 0.8)
        Text { id: bt; anchors.centerIn: parent; text: parent.label; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
               color: parent.primary || bm.containsMouse ? Theme.textOnPrimary : danger ? Theme.error : Theme.text }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Text { text: "Desktop widgets"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 9; font.weight: Font.Bold }
    Text {
        Layout.fillWidth: true; wrapMode: Text.Wrap
        text: "Clocks, calendars, now playing, stats and notes placed on your wallpaper. They sit under your windows, so they only show on a clear desktop."
        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
    }

    SettingSection {
        title: "Add & arrange"
        RowLayout {
            Layout.fillWidth: true
            Btn { primary: true; label: Globals.deskEdit ? "󰄬  Done arranging" : "󰇙  Arrange on desktop"; onClicked: Globals.deskEdit = !Globals.deskEdit }
            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Drag widgets around, resize from the corner handle. Also: qs ipc call desktop edit"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
        }
        Flow {
            Layout.fillWidth: true; spacing: 6
            Repeater { model: page.types; Btn { required property var modelData; label: "+ " + modelData.icon + "  " + modelData.name; onClicked: page.add(modelData.id) } }
        }
    }

    Text { visible: page.widgets.length === 0; text: "No widgets yet. Add one above."; color: Theme.outline; font.family: Theme.font }

    Repeater {
        model: page.widgets
        SettingSection {
            id: card
            required property var modelData
            readonly property string uid: modelData.uid
            readonly property var opts: modelData.opts ?? ({})
            title: page.typeName(modelData.type)

            Text { text: "Style"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            Segmented {
                current: card.modelData.style ?? "glass"
                onPicked: v => page.patch(card.uid, { style: v })
                options: [{ label: "Glass card", value: "glass" }, { label: "Outline", value: "outline" }, { label: "Plain (no card)", value: "plain" }]
            }
            SettingRow {
                label: "Opacity"
                ValueSlider { from: 0.1; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: card.modelData.opacity ?? 1; onMoved: v => page.patch(card.uid, { opacity: v }) }
            }
            SettingRow {
                label: "Size"
                ValueSlider { from: 0.5; to: 3; stepSize: 0.05; displayScale: 100; suffix: "%"; value: card.modelData.scale ?? 1; onMoved: v => page.patch(card.uid, { scale: v }) }
            }
            Text { visible: Quickshell.screens.length > 1; text: "Show on"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            Segmented {
                visible: Quickshell.screens.length > 1
                current: card.modelData.monitor ?? ""
                onPicked: v => page.patch(card.uid, { monitor: v })
                options: [{ label: "All screens", value: "" }].concat(Quickshell.screens.map(s => ({ label: s.name, value: s.name })))
            }

            // clock
            SettingRow { visible: card.modelData.type === "clock"; label: "24-hour time"; Toggle { checked: card.opts.h24 !== false; onToggled: v => page.patchOpts(card.uid, { h24: v }) } }
            SettingRow { visible: card.modelData.type === "clock"; label: "Show seconds"; Toggle { checked: card.opts.seconds === true; onToggled: v => page.patchOpts(card.uid, { seconds: v }) } }
            SettingRow { visible: card.modelData.type === "clock"; label: "Show date"; Toggle { checked: card.opts.date !== false; onToggled: v => page.patchOpts(card.uid, { date: v }) } }
            SettingRow {
                visible: card.modelData.type === "clock"; label: "Text size"
                ValueSlider { from: 24; to: 160; stepSize: 2; suffix: " px"; value: card.opts.size ?? 72; onMoved: v => page.patchOpts(card.uid, { size: v }) }
            }
            // command
            Text { visible: card.modelData.type === "command"; text: "Command (output is shown, last output wins)"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            SettingText { visible: card.modelData.type === "command"; Layout.fillWidth: true; placeholder: "e.g. uptime -p"; text: card.opts.command ?? ""; onSubmitted: t => page.patchOpts(card.uid, { command: t }) }
            SettingRow {
                visible: card.modelData.type === "command"; label: "Refresh every"
                ValueSlider { from: 1; to: 300; stepSize: 1; suffix: " s"; value: card.opts.interval ?? 5; onMoved: v => page.patchOpts(card.uid, { interval: v }) }
            }
            SettingRow {
                visible: card.modelData.type === "command"; label: "Text size"
                ValueSlider { from: 10; to: 80; stepSize: 1; suffix: " px"; value: card.opts.size ?? 18; onMoved: v => page.patchOpts(card.uid, { size: v }) }
            }
            Text {
                visible: card.modelData.type === "weather"
                Layout.fillWidth: true; wrapMode: Text.Wrap
                text: "Uses the weather location from Settings › Behavior › Weather."
                color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
            Btn { label: "Remove widget"; danger: true; onClicked: page.remove(card.uid) }
        }
    }
}
