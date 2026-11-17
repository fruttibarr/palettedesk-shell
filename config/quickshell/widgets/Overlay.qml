import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import QtQuick

// Full-screen transparent layer for popups: fades in/out, closes on
// click-outside or Esc, shows on the focused monitor. Put a GlassPanel in it.
PanelWindow {
    id: win
    property bool open: false
    property string name: "overlay"
    property bool grabKeyboard: true
    // point the content zooms from (default: screen center)
    property point origin: Qt.point(width / 2, height / 2)
    property bool zoom: true
    // content animates itself (e.g. slides off an edge): no fade-in, and stay
    // visible until the slide-out has finished
    property bool slideMode: false
    property int slideOutMs: 260
    // animation length multiplier (per-popup setting; launcher/control center override it)
    property real animScale: Theme.animPopups
    default property alias content: holder.data
    signal closeRequested()

    visible: open || holder.opacity > 0
    // Opens on the screen that asked for it (a bar click) or else the focused monitor, and STAYS there while
    // open (it used to follow the focused monitor live, so a popup jumped screens when focus moved).
    ScreenPin { id: pin; frozen: win.open || holder.opacity > 0 }
    screen: pin.screen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-" + name
    WlrLayershell.keyboardFocus: open && grabKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    MouseArea { anchors.fill: parent; onClicked: win.closeRequested() }

    FocusScope {
        id: holder
        anchors.fill: parent
        focus: true
        opacity: win.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: win.slideMode ? (win.open ? 60 : win.slideOutMs * win.animScale) : (win.open ? 200 : 140) * win.animScale
                easing.type: win.slideMode && !win.open ? Easing.InExpo : Easing.OutCubic
            }
        }

        // zoom: overshoots slightly when opening, quick shrink when closing
        transform: Scale {
            origin.x: win.origin.x
            origin.y: win.origin.y
            xScale: zoom.value
            yScale: zoom.value
        }
        QtObject {
            id: zoom
            property real value: win.open || !Settings.s.popupZoom || !win.zoom ? 1 : 0.92
            Behavior on value {
                NumberAnimation {
                    duration: (win.open ? 380 : 160) * win.animScale
                    easing.type: win.open ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.3
                }
            }
        }
        Keys.onEscapePressed: win.closeRequested()
    }
}
