import qs.services
import QtQuick
import QtQuick.Layouts

// Quick-toggle tile for the control center.
// Click the tile to toggle; with `expandable`, the chevron on the right
// emits expandClicked() to open a detail list.
Rectangle {
    id: tile
    property string icon
    property string title
    property string subtitle
    property bool active
    property bool expandable: false
    property bool expanded: false
    signal clicked()
    signal expandClicked()

    implicitHeight: 62
    radius: 16
    opacity: enabled ? 1 : 0.5
    color: active ? Theme.alpha(Theme.primaryContainer, mouse.containsMouse ? 1 : 0.85)
                  : Theme.alpha(Theme.surfaceContainerHigh, mouse.containsMouse ? 0.85 : 0.55)
    border.width: expanded ? 2 : 0
    border.color: Theme.primary
    Behavior on color { ColorAnimation { duration: 200 } }

    // declared first so the chevron's MouseArea sits on top of it
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: tile.expandable ? 6 : 12
        spacing: tile.expandable ? 9 : 12

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 18
            color: tile.active ? Theme.primary : Theme.alpha(Theme.outline, 0.25)
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: tile.icon
                color: tile.active ? Theme.textOnPrimary : Theme.text
                font.family: Theme.font
                font.pixelSize: 17
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: tile.title
                color: tile.active ? Theme.textOnPrimaryContainer : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: tile.subtitle
                elide: Text.ElideRight
                color: tile.active ? Theme.alpha(Theme.textOnPrimaryContainer, 0.8) : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }

        // chevron: opens the detail list
        Rectangle {
            visible: tile.expandable
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            implicitWidth: 26
            radius: 10
            color: chevMouse.containsMouse
                   ? Theme.alpha(tile.active ? Theme.primary : Theme.outline, 0.3)
                   : Theme.alpha(tile.active ? Theme.primary : Theme.outline, 0.12)
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: "󰅀"
                rotation: tile.expanded ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                color: tile.active ? Theme.textOnPrimaryContainer : Theme.text
                font.family: Theme.font
                font.pixelSize: 15
            }
            MouseArea {
                id: chevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.expandClicked()
            }
        }
    }
}
