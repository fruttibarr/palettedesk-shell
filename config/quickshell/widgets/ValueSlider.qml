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
    readonly property string look: Settings.s.uiSliderStyle   // round | thin | thick | glow | dotted

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
            height: s.look === "thin" ? 3 : s.look === "thick" ? 14 : s.look === "dotted" ? 4 : 8
            radius: height / 2
            color: Theme.alpha(Theme.outlineVariant, 0.6)

            // dotted: tick marks at every step (capped)
            Repeater {
                model: s.look === "dotted" ? Math.min(40, Math.round((s.to - s.from) / s.stepSize) + 1) : 0
                Rectangle {
                    required property int index
                    readonly property int n: Math.min(40, Math.round((s.to - s.from) / s.stepSize) + 1)
                    x: n > 1 ? (track.width - 4) * index / (n - 1) : 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4; height: 4; radius: 2
                    color: (n > 1 ? index / (n - 1) : 0) <= s.ratio + 0.001 ? Theme.primary : Theme.alpha(Theme.outline, 0.6)
                }
            }

            Rectangle {
                width: Math.max(track.height, track.width * s.ratio)
                height: parent.height
                radius: height / 2
                visible: s.look !== "dotted"
                color: Theme.primary
                Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
            }
        }

        Rectangle {   // glow ring (glow style)
            visible: s.look === "glow"
            width: knob.width + (drag.pressed ? 18 : 12); height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: knob.x + knob.width / 2 - width / 2
            color: Theme.alpha(Theme.primary, drag.pressed ? 0.35 : 0.22)
            Behavior on width { NumberAnimation { duration: 140 } }
        }
        Rectangle {   // knob
            id: knob
            readonly property int base: s.look === "thin" ? 12 : s.look === "thick" ? 22 : 16
            width: base + (drag.pressed || drag.containsMouse ? 2 : 0)
            height: s.look === "thick" ? 22 : width
            radius: s.look === "thick" ? 6 : width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: track.width * s.ratio - width / 2
            color: s.look === "thick" ? Theme.text : Theme.primary
            border.width: s.look === "thin" ? 2 : s.look === "thick" ? 0 : 3
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
