import qs.services
import QtQuick
import QtQuick.Shapes

// Inverse-corner flare where an attached bar meets the screen side (Settings: barFlares).
Shape {
    id: fl
    property bool mirror: false
    required property var bar
    readonly property real rad: 14
    visible: Theme.barAttached && Settings.s.barFlares && !Theme.barIslands
    y: bar.top ? bar.stripY + bar.barHeight : bar.stripY - rad
    x: mirror ? parent.width - rad : 0
    width: rad; height: rad
    preferredRendererType: Shape.CurveRenderer
    transform: Scale {
        origin.x: fl.rad / 2; origin.y: fl.rad / 2
        xScale: fl.mirror ? -1 : 1
        yScale: fl.bar.top ? 1 : -1
    }
    ShapePath {
        fillColor: Theme.barColor
        strokeColor: "transparent"
        startX: 0; startY: 0
        PathLine { x: fl.rad; y: 0 }
        PathArc { x: 0; y: fl.rad; radiusX: fl.rad; radiusY: fl.rad; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: 0 }
    }
}
