import qs.services
import QtQuick
import QtQuick.Layouts

// Icon button + draggable/scrollable slider + percentage.
RowLayout {
    id: root
    property string icon
    property real value
    property bool dim: false
    signal moved(real v)
    signal iconClicked()

    spacing: 12

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    Rectangle {
        implicitWidth: 38
        implicitHeight: 38
        radius: 19
        color: Theme.alpha(Theme.surfaceContainerHigh, iconMouse.containsMouse ? 0.9 : 0.6)
        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.dim ? Theme.outline : Theme.primary
            font.family: Theme.font
            font.pixelSize: 17
        }
        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 38

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 12
            radius: 6
            color: Theme.alpha(Theme.outlineVariant, 0.6)

            Rectangle {
                width: Math.max(track.height, track.width * root.clamp(root.value))
                height: parent.height
                radius: 6
                color: root.dim ? Theme.outline : Theme.primary
                Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function update(x) { root.moved(root.clamp(x / width)); }
            onPressed: e => update(e.x)
            onPositionChanged: e => { if (pressed) update(e.x); }
            onWheel: e => root.moved(root.clamp(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
        }
    }

    Text {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.clamp(root.value) * 100) + "%"
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
