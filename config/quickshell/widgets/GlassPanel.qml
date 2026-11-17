import qs.services
import QtQuick

// Translucent wallpaper-tinted panel (Hyprland blurs behind it).
// Look comes from the panel* settings (Popups & Panels page).
Rectangle {
    id: gp
    readonly property var cfg: Settings.s
    readonly property string borderMode: cfg.panelBorderMode
    readonly property real tint: Math.max(0, Math.min(1, cfg.panelVibrancy)) * 0.7

    radius: Math.max(0, Theme.radius + cfg.panelRadiusExtra)
    color: {
        const a = Theme.surface, b = Theme.primaryContainer, t = tint;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, Theme.panelOpacity);
    }
    border.width: borderMode === "none" || borderMode === "gradient" ? 0 : cfg.panelBorderWidth
    border.color: borderMode === "soft" ? Theme.alpha(Theme.outline, 0.4)
                : borderMode === "tertiary" ? Theme.alpha(Theme.tertiary, 0.55)
                : Theme.alpha(Theme.primary, 0.35)
    Behavior on color { ColorAnimation { duration: 400 } }

    // drop shadow: hollow dark rings around the panel, shifted down
    Repeater {
        model: gp.cfg.panelShadow > 0.001 ? 5 : 0
        Rectangle {
            required property int index
            z: -2
            x: -(index + 1) * 4; y: -(index + 1) * 4 + 7
            width: gp.width + (index + 1) * 8; height: gp.height + (index + 1) * 8
            radius: gp.radius + (index + 1) * 4
            color: "transparent"
            border.width: 4
            border.color: Qt.rgba(0, 0, 0, gp.cfg.panelShadow * 0.30 / (1 + index * 0.8))
        }
    }
    // outer glow in the accent colour
    Repeater {
        model: gp.cfg.panelGlow > 0.001 ? 5 : 0
        Rectangle {
            required property int index
            z: -1
            x: -(index + 1) * 3; y: -(index + 1) * 3
            width: gp.width + (index + 1) * 6; height: gp.height + (index + 1) * 6
            radius: gp.radius + (index + 1) * 3
            color: "transparent"
            border.width: 3
            border.color: Theme.alpha(Theme.primary, gp.cfg.panelGlow * 0.32 / (1 + index * 0.9))
        }
    }

    // gradient border (accent -> tertiary)
    Rectangle {
        visible: gp.borderMode === "gradient"
        anchors.fill: parent
        radius: gp.radius
        color: "transparent"
        Canvas {
            id: gb
            anchors.fill: parent
            property color c1: Theme.primary
            property color c2: Theme.tertiary
            property real bw: Math.max(1, gp.cfg.panelBorderWidth)
            property real r: gp.radius
            onC1Changed: requestPaint(); onC2Changed: requestPaint(); onBwChanged: requestPaint()
            onRChanged: requestPaint(); onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (width < 4) return;
                const g = ctx.createLinearGradient(0, 0, width, height);
                g.addColorStop(0, c1); g.addColorStop(1, c2);
                ctx.strokeStyle = g;
                ctx.lineWidth = bw;
                const h = bw / 2, rr = Math.max(0, Math.min(r, (width - bw) / 2, (height - bw) / 2));
                ctx.beginPath();
                ctx.moveTo(h + rr, h);
                ctx.arcTo(width - h, h, width - h, height - h, rr);
                ctx.arcTo(width - h, height - h, h, height - h, rr);
                ctx.arcTo(h, height - h, h, h, rr);
                ctx.arcTo(h, h, width - h, h, rr);
                ctx.closePath();
                ctx.stroke();
            }
        }
    }

    // glossy highlight across the top
    Rectangle {
        visible: gp.cfg.panelGloss > 0.001
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        height: Math.min(parent.height * 0.45, 220)
        radius: gp.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.text, gp.cfg.panelGloss * 0.14) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // accent line on one edge
    Rectangle {
        readonly property string e: gp.cfg.panelAccentEdge
        visible: e !== "none"
        readonly property bool horiz: e === "top" || e === "bottom"
        width: horiz ? parent.width - gp.radius * 2 : 3
        height: horiz ? 3 : parent.height - gp.radius * 2
        x: e === "left" ? 0 : horiz ? gp.radius : parent.width - 3
        y: e === "top" ? 0 : e === "bottom" ? parent.height - 3 : gp.radius
        radius: 2
        gradient: Gradient {
            orientation: parent.horiz ? Gradient.Horizontal : Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Theme.tertiary }
        }
    }

    // inner glow: soft accent light just inside the edge (Appearance → Glass)
    Repeater {
        model: gp.cfg.glassInner > 0.001 ? 4 : 0
        Rectangle {
            required property int index
            anchors.fill: parent
            anchors.margins: 1 + index * 2
            radius: Math.max(0, gp.radius - 1 - index * 2)
            color: "transparent"
            border.width: 2
            border.color: Theme.alpha(Theme.primary, gp.cfg.glassInner * 0.30 / (1 + index * 0.9))
        }
    }
    // film grain over the glass (Appearance → Glass): a tiled noise texture at low opacity
    Image {
        visible: gp.cfg.glassGrain > 0.001
        anchors.fill: parent
        anchors.margins: Math.min(gp.radius * 0.3, 6)
        source: Qt.resolvedUrl("grain.png")
        fillMode: Image.Tile
        opacity: gp.cfg.glassGrain * 0.12
    }

    MouseArea { anchors.fill: parent; z: -3 }  // clicks inside don't close the overlay
}
