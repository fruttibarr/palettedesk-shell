import qs.services
import QtQuick
import QtQuick.Layouts

// Slider with snapping and a value readout. Drag, click, or scroll.
RowLayout {
    id: s
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property real value: 0
    property int decimals: 0
    property real displayScale: 1      // e.g. 100 to show 0.35 as 35
    property string suffix: ""
    property string zeroText: ""       // shown instead of 0 (e.g. "Never")
    signal moved(real value)

    spacing: 12

    function snap(v) {
        const c = Math.max(from, Math.min(to, v));
        return Number((Math.round((c - from) / stepSize) * stepSize + from).toFixed(6));
    }
    readonly property real ratio: (Math.max(from, Math.min(to, value)) - from) / (to - from)

    Item {
        Layout.fillWidth: true
        Layout.preferredWidth: 220
        implicitHeight: 26

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Theme.alpha(Theme.outlineVariant, 0.6)

            Rectangle {
                width: Math.max(track.height, track.width * s.ratio)
                height: parent.height
                radius: 4
                color: Theme.primary
                Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
            }
        }

        Rectangle {   // knob
            width: drag.pressed || drag.containsMouse ? 18 : 16
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: track.width * s.ratio - width / 2
            color: Theme.primary
            border.width: 3
            border.color: Theme.surface
            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on x { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function update(x) { s.moved(s.snap(s.from + Math.max(0, Math.min(1, x / width)) * (s.to - s.from))); }
            onPressed: e => update(e.x)
            onPositionChanged: e => { if (pressed) update(e.x); }
            onWheel: e => s.moved(s.snap(s.value + (e.angleDelta.y > 0 ? s.stepSize : -s.stepSize)))
        }
    }

    Text {
        Layout.preferredWidth: 64
        horizontalAlignment: Text.AlignRight
        text: s.zeroText && s.value === 0 ? s.zeroText : (s.value * s.displayScale).toFixed(s.decimals) + s.suffix
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.features: { "tnum": 1 }
    }
}
