import qs.services
import QtQuick
import QtQuick.Shapes

// Small circular gauge (0..1) with animated sweep.
Item {
    id: ring
    property real value: 0
    property color color: Theme.primary
    property real thickness: 2.5
    implicitWidth: 16
    implicitHeight: 16

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {   // track
            fillColor: "transparent"
            strokeColor: Theme.alpha(ring.color, 0.22)
            strokeWidth: ring.thickness
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: (ring.width - ring.thickness) / 2; radiusY: radiusX
                startAngle: 0; sweepAngle: 360
            }
        }
        ShapePath {   // value
            fillColor: "transparent"
            strokeColor: ring.color
            strokeWidth: ring.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: (ring.width - ring.thickness) / 2; radiusY: radiusX
                startAngle: -90; sweepAngle: 360 * ring.shown
            }
        }
    }
}
