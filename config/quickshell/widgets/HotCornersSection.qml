import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Behavior > Hot corners: a little monitor, click a corner to choose what it does.
SettingSection {
    id: sec
    title: "Hot corners"
    property string editing: "tl"
    readonly property var corners: Settings.s.hotCorners ?? ({})
    readonly property var actions: [
        { label: "Nothing", value: "none" }, { label: "Overview", value: "overview" }, { label: "Launcher", value: "launcher" },
        { label: "Control center", value: "controlcenter" }, { label: "Dashboard", value: "dashboard" }, { label: "Settings", value: "settings" },
        { label: "Cheatsheet", value: "cheatsheet" }, { label: "Clipboard", value: "clipboard" }, { label: "Wallpapers", value: "wallpaper" },
        { label: "Scratchpad", value: "special" }, { label: "Power menu", value: "power" }, { label: "Lock", value: "lock" },
        { label: "Run command", value: "command" },
    ]
    readonly property var names: ({ tl: "top left", tr: "top right", bl: "bottom left", br: "bottom right" })
    function actionLabel(a) { return (actions.find(x => x.value === a) ?? actions[0]).label; }
    function patch(corner, key, v) {
        const all = Object.assign({}, corners);
        all[corner] = Object.assign({ action: "none", command: "" }, all[corner] ?? {});
        all[corner][key] = v;
        Settings.set("hotCorners", all);
    }

    SettingRow {
        label: "Enable hot corners"
        description: "Rest the pointer in a corner for a moment to trigger it"
        keywords: "screen corner edge mouse action overview"
        Toggle { checked: Settings.s.hotCornersEnabled; onToggled: v => Settings.set("hotCornersEnabled", v) }
    }
    SettingRow {
        label: "Delay"; description: "How long the pointer must stay in the corner"
        ValueSlider { from: 0; to: 1000; stepSize: 50; suffix: " ms"; value: Settings.s.hotCornerDelay; onMoved: v => Settings.set("hotCornerDelay", v) }
    }
    SettingRow {
        label: "Corner size"; description: "Bigger is easier to hit, but covers screen pixels"
        ValueSlider { from: 1; to: 40; stepSize: 1; suffix: " px"; value: Settings.s.hotCornerSize; onMoved: v => Settings.set("hotCornerSize", v) }
    }
    SettingRow {
        label: "Work over fullscreen windows"
        description: "Off = ignored while a window is fullscreen (so games don't trigger them)"
        Toggle { checked: Settings.s.hotCornersFullscreen; onToggled: v => Settings.set("hotCornersFullscreen", v) }
    }

    // the monitor
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 420
        Layout.preferredHeight: 236
        radius: 10
        color: Theme.alpha(Theme.surface, 0.6)
        border.width: 2
        border.color: Theme.alpha(Theme.outline, 0.6)
        Text { anchors.centerIn: parent; text: "Click a corner"; color: Theme.outline; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
        Repeater {
            model: ["tl", "tr", "bl", "br"]
            Rectangle {
                id: cbtn
                required property string modelData
                readonly property bool sel: sec.editing === modelData
                readonly property string act: sec.corners[modelData]?.action ?? "none"
                width: 120; height: 44; radius: 10
                x: modelData[1] === "l" ? 8 : parent.width - width - 8
                y: modelData[0] === "t" ? 8 : parent.height - height - 8
                color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, cm.containsMouse ? 0.95 : 0.7)
                border.width: act !== "none" && !sel ? 1 : 0
                border.color: Theme.primary
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: sec.actionLabel(cbtn.act)
                    color: cbtn.sel ? Theme.textOnPrimary : cbtn.act === "none" ? Theme.subtext : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sec.editing = cbtn.modelData }
            }
        }
    }

    Text {
        text: "Action for the " + sec.names[sec.editing] + " corner"
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
    Segmented {
        Layout.fillWidth: true
        current: sec.corners[sec.editing]?.action ?? "none"
        onPicked: v => sec.patch(sec.editing, "action", v)
        options: sec.actions
    }
    SettingText {
        visible: (sec.corners[sec.editing]?.action ?? "none") === "command"
        Layout.fillWidth: true
        placeholder: "shell command, e.g. kitty"
        text: sec.corners[sec.editing]?.command ?? ""
        onSubmitted: t => sec.patch(sec.editing, "command", t)
    }
}
