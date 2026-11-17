import Quickshell
import Quickshell.Hyprland
import qs.services
import QtQuick

// Picks the screen for a popup window. While the popup is hidden it follows the focused monitor (or the screen a
// bar just asked for, see Globals.popupFrom); once it is shown (`frozen`) it stays where it opened, so moving
// focus to another monitor doesn't drag an open popup across.
//
//   ScreenPin { id: pin; frozen: win.visible }
//   PanelWindow { screen: pin.screen }
QtObject {
    id: pin
    property bool frozen: false
    property bool followBars: true     // honour Globals.popupScreen (bar clicks)
    property string name: ""
    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]

    property Binding follow: Binding {
        target: pin; property: "name"
        value: (pin.followBars ? Globals.popupScreen : "") || (Hyprland.focusedMonitor?.name ?? "")
        when: !pin.frozen
        // Qt 6 restores the property's old value when a Binding switches off; we want to KEEP the last one
        restoreMode: Binding.RestoreNone
    }
}
