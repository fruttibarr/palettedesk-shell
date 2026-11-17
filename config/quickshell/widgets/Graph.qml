import QtQuick

// A small filled line graph. `values` is an array of numbers (oldest first), scaled to `maxValue`.
Canvas {
    id: g
    property var values: []
    property real maxValue: 100
    property color color: "#88aaff"
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.strokeStyle = Qt.rgba(1, 1, 1, 0.06); c.lineWidth = 1;
        for (let i = 1; i < 4; i++) { c.beginPath(); c.moveTo(0, height * i / 4); c.lineTo(width, height * i / 4); c.stroke(); }
        const v = values;
        if (!v || v.length < 2) return;
        const step = width / Math.max(1, 59);
        const x0 = width - (v.length - 1) * step;
        c.beginPath();
        for (let i = 0; i < v.length; i++) {
            const y = height - Math.max(0, Math.min(1, v[i] / maxValue)) * (height - 2) - 1;
            if (i === 0) c.moveTo(x0, y); else c.lineTo(x0 + i * step, y);
        }
        c.strokeStyle = color; c.lineWidth = 2; c.stroke();
        c.lineTo(width, height); c.lineTo(x0, height); c.closePath();
        c.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.18); c.fill();
    }
}
