import qs.services
import QtQuick

// Rounded capsule grouping bar items. Look follows Settings:
// chipStyle (filled / outlined / flat), chipShape (pill / rounded / square),
// and bar style "islands" (chips become standalone glass).
// clickable: hover lift + press squish + clicked() signal.
Rectangle {
    id: chip
    default property alias content: row.data
    property alias spacing: row.spacing
    property color tint: Theme.surfaceContainerHigh
    property real tintOpacity: 0.5
    property real padding: 12
    property real alphaOverride: -1   // >= 0: fixed background alpha (filled / islands looks)
    property bool clickable: false
    property int appearDelay: 0
    readonly property bool hovered: mouse.containsMouse
    readonly property string style: Settings.s.chipStyle
    signal clicked()

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Math.max(20, Theme.barHeight - 10)
    radius: Settings.s.chipShape === "pill" ? height / 2 : Settings.s.chipShape === "rounded" ? 8 : 3

    readonly property real baseAlpha: alphaOverride >= 0 && (Theme.barIslands || style === "filled") ? alphaOverride
                                     : Theme.barIslands ? Math.max(0.55, Theme.barOpacity + 0.2)
                                     : style === "filled" ? tintOpacity : 0
    readonly property color baseColor: Theme.barIslands && tint === Theme.surfaceContainerHigh ? Theme.surface : tint
    color: Theme.alpha(baseColor, clickable && hovered ? Math.min(1, baseAlpha + 0.25) + (style !== "filled" ? 0.15 : 0) : baseAlpha)
    border.width: style === "outlined" ? 1.5 : style === "flat" && !Theme.barIslands ? 0 : 1
    border.color: Theme.alpha(Theme.primary, style === "outlined" ? (hovered && clickable ? 0.7 : 0.4)
                                           : clickable && hovered ? 0.35 : Theme.barIslands ? 0.2 : 0.08)

    Behavior on color { ColorAnimation { duration: 220 } }
    Behavior on border.color { ColorAnimation { duration: 220 } }
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    scale: mouse.pressed ? 0.95 : clickable && hovered ? 1.04 : 1
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }

    // entrance
    opacity: 0
    transform: Translate { id: rise }
    Component.onCompleted: {
        rise.y = Theme.barTop ? -8 : 8;   // set once (not a binding) so later bar moves don't re-offset it
        appear.start();
    }
    SequentialAnimation {
        id: appear
        PauseAnimation { duration: chip.appearDelay }
        ParallelAnimation {
            NumberAnimation { target: chip; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: chip.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14
    }
}
