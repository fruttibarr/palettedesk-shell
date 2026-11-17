import qs.services
import QtQuick

// Audio visualizer drawn over the album-cover wallpaper (Settings → Wallpaper & Colors).
// Styles: bars, mirror (bass in the middle), wave, dots.
Item {
    id: viz
    readonly property var levels: Cava.levels
    readonly property string style: Settings.s.albumVizStyle

    opacity: Cava.wanted ? Settings.s.albumVizOpacity : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    onLevelsChanged: canvas.requestPaint()
    Connections {
        target: Theme
        function onPrimaryChanged() { canvas.requestPaint(); }
        function onTertiaryChanged() { canvas.requestPaint(); }
    }
    Connections {
        target: Settings.s
        function onAlbumVizStyleChanged() { canvas.requestPaint(); }
        function onAlbumVizColorChanged() { canvas.requestPaint(); }
        function onAlbumVizHeightChanged() { canvas.requestPaint(); }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const L = viz.levels;
            if (!L || L.length < 2) return;

            const W = width, H = height;
            const maxH = H * Settings.s.albumVizHeight;
            const base = H - H * 0.035;                // baseline, a little above the screen edge
            const mode = Settings.s.albumVizColor;

            let fill;
            if (mode === "gradient") {
                fill = ctx.createLinearGradient(0, 0, W, 0);
                fill.addColorStop(0, String(Theme.primary));
                fill.addColorStop(0.5, String(Theme.secondary));
                fill.addColorStop(1, String(Theme.tertiary));
            } else if (mode === "light") {
                fill = String(Theme.text);
            } else {
                fill = String(Theme.primary);
            }
            ctx.fillStyle = fill;
            ctx.strokeStyle = fill;

            // bass first; "mirror" folds it around the middle
            let vals = L;
            if (viz.style === "mirror") {
                const half = Math.floor(L.length / 2);
                vals = [];
                for (let i = half - 1; i >= 0; i--) vals.push(L[i]);
                for (let i = 0; i < half; i++) vals.push(L[i]);
            }
            const n = vals.length;
            const slot = W / n;
            const hOf = i => Math.max(3, vals[i] / 100 * maxH);

            if (viz.style === "wave") {
                const pts = [];
                for (let i = 0; i < n; i++) pts.push({ x: (i + 0.5) * slot, y: base - hOf(i) });
                const trace = () => {
                    ctx.moveTo(0, pts[0].y);
                    ctx.lineTo(pts[0].x, pts[0].y);
                    for (let i = 1; i < n; i++) {
                        const mx = (pts[i - 1].x + pts[i].x) / 2, my = (pts[i - 1].y + pts[i].y) / 2;
                        ctx.quadraticCurveTo(pts[i - 1].x, pts[i - 1].y, mx, my);
                    }
                    ctx.lineTo(pts[n - 1].x, pts[n - 1].y);
                    ctx.lineTo(W, pts[n - 1].y);
                };
                ctx.beginPath();
                trace();
                ctx.lineTo(W, H); ctx.lineTo(0, H); ctx.closePath();
                ctx.globalAlpha = 0.35;
                ctx.fill();
                ctx.beginPath();
                trace();
                ctx.globalAlpha = 1;
                ctx.lineWidth = Math.max(2, H * 0.004);
                ctx.lineJoin = "round";
                ctx.stroke();
            } else if (viz.style === "dots") {
                const d = Math.max(3, slot * 0.55);
                const step = d * 1.5;
                for (let i = 0; i < n; i++) {
                    const rows = Math.max(1, Math.round(vals[i] / 100 * maxH / step));
                    for (let r = 0; r < rows; r++) {
                        ctx.globalAlpha = 1 - 0.55 * (r / Math.max(rows, 4));
                        ctx.beginPath();
                        ctx.arc((i + 0.5) * slot, base - d / 2 - r * step, d / 2, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            } else {
                const bw = Math.max(2, slot * 0.68);
                for (let i = 0; i < n; i++) {
                    const h = hOf(i);
                    ctx.beginPath();
                    ctx.roundedRect(i * slot + (slot - bw) / 2, base - h, bw, h, bw / 2, bw / 2);
                    ctx.fill();
                }
            }
        }
    }
}
