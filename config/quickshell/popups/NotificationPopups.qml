import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets
import QtQuick

// Toast stack under the bar; side, width and count come from Settings.
PanelWindow {
    id: win
    visible: Notifs.popups.length > 0 && !Globals.controlCenterOpen
    ScreenPin { id: pin; frozen: win.visible; followBars: false }   // the focused monitor when a notification arrives
    screen: pin.screen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-notifications"
    exclusionMode: ExclusionMode.Ignore
    readonly property string side: Settings.s.notifPosition   // left | center | right
    readonly property int slideDir: side === "left" ? -1 : 1
    anchors { top: Theme.barTop; bottom: !Theme.barTop; right: side === "right"; left: side === "left" }
    margins { top: Theme.barReserved; bottom: Theme.barReserved; right: Math.max(10, Theme.barMarginPx); left: Math.max(10, Theme.barMarginPx) }
    implicitWidth: Settings.s.notifWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups

            NotifCard {
                id: toast
                required property var modelData
                notif: modelData
                popup: true
                width: stack.width
                onExpired: slideOut.start()

                // slide in from the right
                transform: Translate { id: shift; x: win.side === "center" ? 0 : 400 * win.slideDir; y: win.side === "center" ? (Theme.barTop ? -60 : 60) : 0 }
                Component.onCompleted: slideIn.start()
                NumberAnimation {
                    id: slideIn
                    target: shift; properties: "x,y"
                    to: 0; duration: 420 * Theme.animNotifs; easing.type: Easing.OutBack; easing.overshoot: 1.1
                }
                ParallelAnimation {
                    id: slideOut
                    NumberAnimation { target: shift; property: "x"; to: win.side === "center" ? 0 : 420 * win.slideDir; duration: 300 * Theme.animNotifs; easing.type: Easing.InCubic }
                    NumberAnimation { target: toast; property: "opacity"; to: 0; duration: 260 * Theme.animNotifs }
                    onFinished: Notifs.hidePopup(toast.modelData)
                }
            }
        }
    }
}
