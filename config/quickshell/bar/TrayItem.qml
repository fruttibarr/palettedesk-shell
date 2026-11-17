import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets
import QtQuick

// Left click = activate, right click = menu, middle = secondary, scroll = scroll.
Item {
    id: root
    required property SystemTrayItem modelData
    property var barWindow

    implicitWidth: 18
    implicitHeight: 18

    IconImage {
        anchors.fill: parent
        source: root.modelData.icon
        asynchronous: true
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
