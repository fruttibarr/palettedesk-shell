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

    // optional backdrop dimming (popupDim setting)
    Rectangle {
        anchors.fill: parent
        visible: Settings.s.popupDim > 0.001
        color: Theme.alpha(Theme.background, Settings.s.popupDim)
        opacity: holder.opacity
    }

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
        transform: [
            Scale {
                origin.x: win.origin.x
                origin.y: win.origin.y
                xScale: zoom.value
                yScale: zoom.value
            },
            Translate { y: zoom.shift }
        ]
        QtObject {
            id: zoom
            // popupEntrance: zoom (default, honours popupZoom) | bounce | slide | drop | fade
            readonly property string mode: win.slideMode ? "zoom" : Settings.s.popupEntrance
            readonly property bool scaled: mode === "bounce" || (mode === "zoom" && Settings.s.popupZoom && win.zoom)
            property real value: win.open || !scaled ? 1 : (mode === "bounce" ? 0.7 : 0.92)
            property real shift: win.open || (mode !== "slide" && mode !== "drop") ? 0 : (mode === "slide" ? 44 : -44)
            Behavior on value {
                NumberAnimation {
                    duration: (win.open ? (zoom.mode === "bounce" ? 520 : 380) : 160) * win.animScale
                    easing.type: win.open ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: zoom.mode === "bounce" ? 2.6 : 1.3
                }
            }
            Behavior on shift {
                NumberAnimation {
                    duration: (win.open ? 360 : 160) * win.animScale
                    easing.type: win.open ? Easing.OutCubic : Easing.InCubic
                }
            }
        }
        Keys.onEscapePressed: win.closeRequested()
    }
}
