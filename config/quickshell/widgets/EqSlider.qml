import qs.services
import QtQuick

// Horizontal slider for the equalizer footer: `frac` 0..1 in,
// moved(frac) / stepped(+1|-1) out.
Item {
    id: slider
    property real frac
    property color accent: Theme.tertiary
    property bool dim
    signal moved(real value)
    signal stepped(int direction)
    implicitHeight: 24
    opacity: dim ? 0.45 : 1
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: 4
        color: Theme.alpha(Theme.outlineVariant, 0.6)
        Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, slider.frac)))
            height: parent.height
            radius: 4
            color: slider.accent
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(x) { slider.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x); }
        onWheel: e => slider.stepped(e.angleDelta.y > 0 ? 1 : -1)
    }
}
