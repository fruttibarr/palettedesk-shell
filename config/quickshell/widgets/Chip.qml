import qs.services
import QtQuick

// Rounded capsule grouping bar items. Look follows Settings:
// chipStyle (filled / outlined / flat), chipShape (pill / rounded / square),
// chipEffect (glass / gradient / neon / underline / soft / bracket), chipGlow,
// chipAccent (primary / tertiary / rainbow / gradient across the bar),
// chipHover + chipEntrance animation presets, barDensity,
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
    property real accentPos: 0        // 0..1 position along the bar (set by the bar zone) for rainbow / gradient accents
    readonly property bool hovered: mouse.containsMouse
    readonly property string style: Settings.s.chipStyle
    readonly property string effect: Settings.s.chipEffect
    readonly property string hoverMode: Settings.s.chipHover
    signal clicked()

    readonly property real densityK: ({ compact: 0.7, spacious: 1.35 })[Settings.s.barDensity] ?? 1
    readonly property real heightAdj: ({ compact: -4, spacious: 4 })[Settings.s.barDensity] ?? 0

    // Accent colour used for borders / effects / glow. "none" = the theme primary (the classic look).
    readonly property color accent: {
        const m = Settings.s.chipAccent, p = Math.max(0, Math.min(1, accentPos));
        if (m === "tertiary") return Theme.tertiary;
        if (m === "rainbow") {
            const b = Theme.primary;
            return Qt.hsla((b.hslHue + p * 0.9) % 1, Math.max(0.5, b.hslSaturation), Math.max(0.6, Math.min(0.75, b.hslLightness)), 1);
        }
        if (m === "gradient") {
            const a = Theme.primary, c = Theme.tertiary;
            return Qt.rgba(a.r + (c.r - a.r) * p, a.g + (c.g - a.g) * p, a.b + (c.b - a.b) * p, 1);
        }
        return Theme.primary;
    }
    readonly property bool accented: Settings.s.chipAccent !== "none"

    implicitWidth: row.implicitWidth + padding * densityK * 2
    implicitHeight: Math.max(20, Theme.barHeight - 10 + heightAdj)
    radius: Settings.s.chipShape === "pill" ? height / 2 : Settings.s.chipShape === "rounded" ? 8 : 3

    readonly property real baseAlpha: alphaOverride >= 0 && (Theme.barIslands || style === "filled") ? alphaOverride
                                     : Theme.barIslands ? Math.max(0.55, Theme.barOpacity + 0.2)
                                     : style === "filled" ? tintOpacity : 0
    readonly property color baseColor: Theme.barIslands && tint === Theme.surfaceContainerHigh ? Theme.surface : tint
    readonly property real hoverAdd: clickable && hovered && hoverMode !== "none" ? 0.25 : 0
    // effect tweaks to the fill
    readonly property real fxAlpha: effect === "glass" ? Math.max(0.18, baseAlpha * 0.55)
                                  : effect === "neon" ? Math.min(baseAlpha, 0.25)
                                  : effect === "underline" || effect === "bracket" ? Math.min(baseAlpha, 0.3)
                                  : baseAlpha
    color: effect === "gradient" ? "transparent"
         : Theme.alpha(baseColor, Math.min(1, fxAlpha + hoverAdd) + (clickable && hovered && style !== "filled" && hoverMode !== "none" ? 0.15 : 0))
    border.width: effect === "neon" ? 1.5 : effect === "underline" ? 0 : style === "outlined" ? 1.5 : style === "flat" && !Theme.barIslands ? 0 : 1
    border.color: effect === "glass" ? Theme.alpha(Qt.rgba(1, 1, 1, 1), hovered && clickable ? 0.28 : 0.16)
                : effect === "neon" ? Theme.alpha(accent, hovered && clickable ? 1 : 0.85)
                : Theme.alpha(accent, style === "outlined" ? (hovered && clickable ? 0.7 : 0.4)
                                      : clickable && hovered ? 0.35 : Theme.barIslands ? 0.2 : (accented ? 0.3 : 0.08))

    Behavior on color { ColorAnimation { duration: 220 } }
    Behavior on border.color { ColorAnimation { duration: 220 } }
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // ---- hover / press ----
    readonly property real pressScale: mouse.pressed ? 0.95 : clickable && hovered && hoverMode === "lift" ? 1.04
                                      : clickable && hovered && hoverMode === "pulse" ? 1.07 : 1
    property real entScale: 1
    scale: pressScale * entScale
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }

    // ---- entrance (chipEntrance: rise / fade / pop / slide / none) ----
    readonly property string entrance: Settings.s.chipEntrance
    opacity: 0
    transform: [
        Translate { id: rise },
        Translate { id: hop; y: chip.clickable && chip.hovered && chip.hoverMode === "bounce" ? Theme.barTop ? -3 : 3 : 0
                    Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 4 } } }
    ]
    Component.onCompleted: {
        // set once (not bindings) so later bar moves don't re-offset it
        if (entrance === "none") { opacity = 1; return; }
        if (entrance === "rise") rise.y = Theme.barTop ? -8 : 8;
        else if (entrance === "slide") rise.x = -18;
        else if (entrance === "pop") entScale = 0.55;
        appear.start();
    }
    SequentialAnimation {
        id: appear
        PauseAnimation { duration: chip.appearDelay }
        ParallelAnimation {
            NumberAnimation { target: chip; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { target: rise; property: "x"; to: 0; duration: 520; easing.type: Easing.OutCubic }
            NumberAnimation { target: chip; property: "entScale"; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 2 }
        }
    }

    // ---- effect layers ----
    Rectangle {   // gradient fill
        visible: chip.effect === "gradient"
        anchors.fill: parent
        radius: chip.radius
        opacity: Math.max(0.35, chip.baseAlpha) * (chip.clickable && chip.hovered ? 1.3 : 1)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.alpha(chip.accent, 0.5) }
            GradientStop { position: 1; color: Theme.alpha(chip.accented && Settings.s.chipAccent !== "gradient" ? chip.accent : Theme.tertiary, 0.2) }
        }
    }
    Rectangle {   // glass: top-lit sheen
        visible: chip.effect === "glass"
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, chip.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.16) }
            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.02) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
    Rectangle {   // soft (neumorphic): lit top, shaded bottom
        visible: chip.effect === "soft"
        anchors.fill: parent
        radius: chip.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.10) }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.22) }
        }
    }
    Rectangle {   // underline accent
        visible: chip.effect === "underline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: parent.width * (chip.clickable && chip.hovered ? 0.8 : 0.5)
        height: 2; radius: 1
        color: chip.accent
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    }
    Repeater {   // bracketed: [ content ]
        model: chip.effect === "bracket" ? 2 : 0
        Rectangle {
            required property int index
            x: index === 0 ? 3 : chip.width - 5
            anchors.verticalCenter: parent.verticalCenter
            width: 2; height: parent.height * 0.5; radius: 1
            color: chip.accent
            opacity: chip.clickable && chip.hovered ? 1 : 0.7
        }
    }
    Repeater {   // accent glow: concentric outlines fading outwards (chipGlow)
        model: Settings.s.chipGlow > 0 || (chip.effect === "neon") ? 3 : 0
        Rectangle {
            required property int index
            readonly property real k: Math.max(Settings.s.chipGlow, chip.effect === "neon" ? 0.5 : 0) * (chip.hovered && chip.clickable ? 1.5 : 1)
            z: -1
            anchors.fill: parent
            anchors.margins: -(1 + index * 2.5)
            radius: chip.radius + 1 + index * 2.5
            color: "transparent"
            border.width: 2.5
            border.color: Theme.alpha(chip.accent, Math.min(0.9, k * (0.5 - index * 0.15)))
            Behavior on border.color { ColorAnimation { duration: 220 } }
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
