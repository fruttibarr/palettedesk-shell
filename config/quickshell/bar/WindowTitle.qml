import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.widgets
import QtQuick

// Focused window: app icon + title (Settings: titleMaxWidth).
Chip {
    id: chip
    // The monitor this bar belongs to (each Bar passes its own). Unset = the globally focused window.
    property var monitor: null
    readonly property var ws: monitor?.activeWorkspace ?? null
    readonly property var win: {
        if (!monitor) return Hyprland.activeToplevel;
        const list = ws?.toplevels?.values ?? [];
        const focused = list.find(t => t.activated);
        if (focused) return focused;
        // an unfocused monitor: the window Hyprland last focused on its workspace
        const last = String(ws?.lastIpcObject?.lastwindow ?? "").replace(/^0x/, "");
        return list.find(t => String(t.address).replace(/^0x/, "") === last) ?? list[0] ?? null;
    }
    readonly property string appClass: win?.lastIpcObject?.class ?? ""
    readonly property string iconSrc: {
        if (!appClass) return "";
        const entry = DesktopEntries.byId(appClass) ?? DesktopEntries.byId(appClass.toLowerCase());
        return Quickshell.iconPath(entry?.icon ?? appClass.toLowerCase(), true);
    }
    property bool active: (win?.title ?? "") !== "" && (win?.workspace?.id ?? -1) === ((monitor ?? Hyprland.focusedMonitor)?.activeWorkspace?.id ?? -2)
    spacing: 8

    Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.s.titleIcon
        width: 16; height: 16
        IconImage { anchors.fill: parent; source: chip.iconSrc; visible: chip.iconSrc !== "" }
        Text {
            anchors.centerIn: parent
            visible: chip.iconSrc === ""
            text: chip.active ? "󰖯" : "󰇄"
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Settings.s.titleMaxWidth)
        elide: Text.ElideRight
        text: chip.active ? chip.win.title : "Desktop"
        color: chip.active ? Theme.text : Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.weight: Settings.s.titleStyle === "bold" ? Font.Bold : Font.Normal
        font.italic: Settings.s.titleStyle === "italic"
        font.capitalization: Settings.s.titleStyle === "caps" ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: Settings.s.titleStyle === "caps" ? 1 : 0
    }
}
