import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Effects

// Left click = activate, right click = menu, middle = secondary, scroll = scroll.
Item {
    id: root
    required property SystemTrayItem modelData
    property var barWindow

    implicitWidth: Settings.s.trayIconSize
    implicitHeight: Settings.s.trayIconSize

    // trayTint: none / grey / mono (text colour) / accent
    readonly property string tint: Settings.s.trayTint
    IconImage {
        id: img
        anchors.fill: parent
        source: root.modelData.icon
        asynchronous: true
        visible: root.tint === "none"
    }
    MultiEffect {
        visible: root.tint !== "none"
        anchors.fill: parent
        source: img
        saturation: root.tint === "grey" ? -1 : 0
        colorization: root.tint === "mono" || root.tint === "accent" ? 1 : 0
        colorizationColor: root.tint === "accent" ? Theme.primary : Theme.text
        opacity: root.tint === "grey" ? 0.85 : 1
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            const item = root.modelData;
            if (e.button === Qt.LeftButton && !item.onlyMenu) item.activate();
            else if (e.button === Qt.MiddleButton) item.secondaryActivate();
            else if (item.hasMenu) {
                const p = root.mapToItem(null, 0, root.height + 12);
                item.display(root.barWindow, p.x, p.y);
            }
        }
        onWheel: e => root.modelData.scroll(e.angleDelta.y, false)
    }
}
