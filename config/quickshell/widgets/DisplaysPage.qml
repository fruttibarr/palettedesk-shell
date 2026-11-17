import Quickshell
import Quickshell.Hyprland
import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Displays: per-monitor resolution, refresh rate, position, scale, rotation and on/off.
// Changes apply live; if you don't confirm within 15 s they are reverted, so a bad mode can't leave you
// with a black screen. Stored as JSON in the `monitors` setting, keyed by "desc:<monitor description>".
ColumnLayout {
    id: page
    spacing: 16

    readonly property var mons: Hyprland.monitors.values
    readonly property int enabledCount: mons.length   // monitors Hyprland currently drives

    function parse(t) { try { return JSON.parse(t || "{}"); } catch (e) { return {}; } }
    function keyOf(m) { return m.description ? "desc:" + m.description : m.name; }
    function ipc(m) { return m.lastIpcObject ?? {}; }
    function baseOf(m) {
        const o = ipc(m);
        return { enabled: true, mode: o.width + "x" + o.height + "@" + Number(o.refreshRate ?? 60).toFixed(2),
                 x: m.x, y: m.y, scale: m.scale, transform: o.transform ?? 0 };
    }
    function cfgOf(m) { return Object.assign({}, baseOf(m), parse(Settings.s.monitors)[keyOf(m)] ?? {}); }
    function logicalSize(m, c) {   // size in layout units after scale and rotation
        const o = ipc(m);
        const swap = (c.transform & 1) === 1;
        const w = (swap ? o.height : o.width) / c.scale, h = (swap ? o.width : o.height) / c.scale;
        return { w: Math.round(w), h: Math.round(h) };
    }

    // ---- apply with a safety net ----
    property string previous: ""
    property int countdown: 0
    function change(m, patch) {
        const all = parse(Settings.s.monitors);
        const k = keyOf(m);
        all[k] = Object.assign({}, cfgOf(m), patch);
        if (countdown === 0) previous = Settings.s.monitors;
        Settings.set("monitors", JSON.stringify(all));
        countdown = 15;
        tick.restart();
    }
    function keep() { tick.stop(); countdown = 0; }
    function revert() { tick.stop(); countdown = 0; Settings.set("monitors", previous); }
    Timer {
        id: tick; interval: 1000; repeat: true
        onTriggered: { page.countdown--; if (page.countdown <= 0) page.revert(); }
    }

    Text {
        text: "Displays"
        color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 8; font.weight: Font.Bold
    }
    Text {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: "Resolution, position, scale and rotation for each monitor. Changes apply immediately and revert after 15 seconds unless you keep them."
        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
    }

    Rectangle {   // keep / revert banner
        visible: page.countdown > 0
        Layout.fillWidth: true
        implicitHeight: 52
        radius: 12
        color: Theme.alpha(Theme.primary, 0.25)
        border.width: 1; border.color: Theme.primary
        RowLayout {
            anchors.fill: parent; anchors.margins: 12; spacing: 12
            Text {
                Layout.fillWidth: true
                text: "Keep these display settings? Reverting in " + page.countdown + " s"
                color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize
            }
            Rectangle {
                width: 70; height: 30; radius: 15; color: Theme.primary
                Text { anchors.centerIn: parent; text: "Keep"; color: Theme.textOnPrimary; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.keep() }
            }
            Rectangle {
                width: 90; height: 30; radius: 15; color: Theme.surfaceContainerHigh
                Text { anchors.centerIn: parent; text: "Revert now"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.revert() }
            }
        }
    }

    Repeater {
        model: page.mons

        SettingSection {
            id: card
            required property var modelData
            required property int index
            readonly property var c: page.cfgOf(modelData)
            readonly property var modes: page.ipc(modelData).availableModes ?? []
            title: modelData.name + (modelData.description ? "  ·  " + modelData.description : "")

            SettingRow {
                label: "Resolution and refresh rate"
                description: "Now " + page.ipc(card.modelData).width + "x" + page.ipc(card.modelData).height
                             + " at " + Number(page.ipc(card.modelData).refreshRate ?? 0).toFixed(0) + " Hz"
                Item {
                    id: wrap
                    width: 420
                    height: flow.height
                    implicitWidth: 420
                    implicitHeight: flow.height
                    Flow {
                    id: flow
                    width: wrap.width; spacing: 6
                    Repeater {
                        model: card.modes.slice(0, 14)
                        Rectangle {
                            id: chip
                            required property string modelData
                            readonly property string mode: modelData.replace("Hz", "")
                            readonly property bool current: card.c.mode && Math.abs(parseFloat(card.c.mode.split("@")[1] ?? 0) - parseFloat(mode.split("@")[1])) < 0.5
                                                             && card.c.mode.split("@")[0] === mode.split("@")[0]
                            height: 26; width: label.implicitWidth + 18; radius: 13
                            color: current ? Theme.primary : Theme.surfaceContainerHigh
                            Text { id: label; anchors.centerIn: parent; text: chip.modelData; color: chip.current ? Theme.textOnPrimary : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.change(card.modelData, { mode: chip.mode }) }
                        }
                    }
                    }
                }
            }
            SettingRow {
                label: "Scale"
                Segmented {
                    current: card.c.scale
                    onPicked: v => page.change(card.modelData, { scale: v })
                    options: [{ label: "100%", value: 1 }, { label: "125%", value: 1.25 }, { label: "150%", value: 1.5 },
                              { label: "175%", value: 1.75 }, { label: "200%", value: 2 }]
                }
            }
            SettingRow {
                label: "Rotation"
                Segmented {
                    current: card.c.transform
                    onPicked: v => page.change(card.modelData, { transform: v })
                    options: [{ label: "0°", value: 0 }, { label: "90°", value: 1 }, { label: "180°", value: 2 }, { label: "270°", value: 3 }]
                }
            }
            SettingRow {
                visible: card.index > 0
                label: "Position"
                description: "Relative to " + (page.mons[0]?.name ?? "the first monitor")
                Segmented {
                    current: ""
                    onPicked: v => {
                        const ref = page.mons[0], rc = page.cfgOf(ref), rs = page.logicalSize(ref, rc);
                        const me = page.logicalSize(card.modelData, card.c);
                        const pos = { left: { x: rc.x - me.w, y: rc.y }, right: { x: rc.x + rs.w, y: rc.y },
                                      above: { x: rc.x, y: rc.y - me.h }, below: { x: rc.x, y: rc.y + rs.h } }[v];
                        page.change(card.modelData, pos);
                    }
                    options: [{ label: "Left of", value: "left" }, { label: "Right of", value: "right" },
                              { label: "Above", value: "above" }, { label: "Below", value: "below" }]
                }
            }
            SettingRow {
                label: "Enabled"
                description: page.mons.length < 2 ? "The only monitor can't be turned off" : "Turn this monitor off"
                Toggle {
                    checked: card.c.enabled !== false
                    enabled: page.mons.length > 1
                    onToggled: v => page.change(card.modelData, { enabled: v })
                }
            }
        }
    }
}
