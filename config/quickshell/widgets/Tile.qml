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

    // look: ccTileHeight, ccTileRadius, ccActiveStyle (container | accent | outline), ccIconShape (circle | rounded | square | none)
    readonly property string activeStyle: Settings.s.ccActiveStyle
    readonly property bool solid: active && activeStyle === "accent"
    readonly property color fg: solid ? Theme.textOnPrimary : active && activeStyle === "container" ? Theme.textOnPrimaryContainer : Theme.text
    implicitHeight: Settings.s.ccTileHeight
    radius: Math.min(Settings.s.ccTileRadius, implicitHeight / 2)
    opacity: enabled ? 1 : 0.5
    color: solid ? Theme.alpha(Theme.primary, mouse.containsMouse ? 1 : 0.9)
         : active && activeStyle === "outline" ? Theme.alpha(Theme.primary, mouse.containsMouse ? 0.16 : 0.08)
         : active ? Theme.alpha(Theme.primaryContainer, mouse.containsMouse ? 1 : 0.85)
                  : Theme.alpha(Theme.surfaceContainerHigh, mouse.containsMouse ? 0.85 : 0.55)
    border.width: expanded || (active && activeStyle === "outline") ? 2 : 0
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
            readonly property string shape: Settings.s.ccIconShape
            implicitWidth: shape === "none" ? 26 : 36
            implicitHeight: shape === "none" ? 26 : 36
            radius: shape === "square" ? 4 : shape === "rounded" ? 11 : width / 2
            color: shape === "none" ? "transparent" : tile.solid ? Theme.alpha(Theme.textOnPrimary, 0.2) : tile.active ? Theme.primary : Theme.alpha(Theme.outline, 0.25)
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: tile.icon
                color: tile.solid ? Theme.textOnPrimary : tile.active ? (parent.shape === "none" ? Theme.primary : Theme.textOnPrimary) : Theme.text
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
                color: tile.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: tile.subtitle
                elide: Text.ElideRight
                color: tile.active ? Theme.alpha(tile.fg, 0.8) : Theme.subtext
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
                color: tile.fg
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
