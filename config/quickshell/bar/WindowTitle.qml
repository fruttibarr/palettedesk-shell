import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.widgets
import QtQuick

// Focused window: app icon + title (Settings: titleMaxWidth).
Chip {
    id: chip
    readonly property var win: Hyprland.activeToplevel
    readonly property string appClass: win?.lastIpcObject?.class ?? ""
    readonly property string iconSrc: {
        if (!appClass) return "";
        const entry = DesktopEntries.byId(appClass) ?? DesktopEntries.byId(appClass.toLowerCase());
        return Quickshell.iconPath(entry?.icon ?? appClass.toLowerCase(), true);
    }
    property bool active: (win?.title ?? "") !== "" && (win?.workspace?.id ?? -1) === (Hyprland.focusedMonitor?.activeWorkspace?.id ?? -2)
    spacing: 8

    Item {
        anchors.verticalCenter: parent.verticalCenter
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
    }
}
