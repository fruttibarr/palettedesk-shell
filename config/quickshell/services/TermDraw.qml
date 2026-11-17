pragma Singleton
import Quickshell
import QtQuick

// State for "draw a terminal": SUPER+drag on the desktop (or SUPER+SHIFT+Enter
// then drag) sketches a rectangle; releasing opens a floating terminal there.
Singleton {
    id: root

    property bool armed: false        // keybind mode: next drag anywhere draws
    property bool active: false       // a drag is in progress
    property bool viaOverlay: false   // drag started on the overlay (keybind mode)
    property var screen: null
    property real x0: 0
    property real y0: 0
    property real x1: 0
    property real y1: 0

    readonly property real rx: Math.min(x0, x1)
    readonly property real ry: Math.min(y0, y1)
    readonly property real rw: Math.abs(x1 - x0)
    readonly property real rh: Math.abs(y1 - y0)
    readonly property bool bigEnough: rw >= 140 && rh >= 90

    function arm() { armed = true; }

    // ---- desktop SUPER+drag ----
    // Wayland doesn't give the desktop layer modifier state, so Hyprland's
    // SUPER+click bind calls superClick() over IPC. A press on the desktop and
    // that signal can arrive in either order; whichever is second starts the draw.
    property var pending: null       // { screen, x, y, t } of the last desktop press
    property real lastX: 0
    property real lastY: 0
    property double superTime: 0
    readonly property int pairWindowMs: 700

    function desktopPress(scr, x, y, metaHeld) {
        pending = { screen: scr, x: x, y: y, t: Date.now() };
        lastX = x; lastY = y;
        const recentSuper = Date.now() - superTime < pairWindowMs;
        console.info(`[termdraw] desktop press at ${x},${y} meta=${metaHeld} recentSuper=${recentSuper}`);
        if (metaHeld || recentSuper) startPending();
    }

    function desktopMove(x, y) {
        lastX = x; lastY = y;
        if (active) update(x, y);
    }

    function desktopRelease() {
        pending = null;
        if (active && !viaOverlay) finish();
    }

    function superClick() {
        superTime = Date.now();
        const recentPress = pending !== null && Date.now() - pending.t < pairWindowMs;
        console.info(`[termdraw] SUPER+click from Hyprland, pending press=${recentPress}`);
        if (recentPress && !active) startPending();
    }

    function startPending() {
        if (!pending || !Settings.s.drawTerminal) return;
        begin(pending.screen, pending.x, pending.y, false);
        update(lastX, lastY);
    }

    function begin(scr, x, y, fromOverlay) {
        screen = scr;
        x0 = x1 = x;
        y0 = y1 = y;
        viaOverlay = fromOverlay;
        active = true;
        armed = false;
    }

    function update(x, y) {
        if (!active) return;
        x1 = x;
        y1 = y;
    }

    function cancel() {
        active = false;
        armed = false;
        viaOverlay = false;
    }

    function finish() {
        if (!active) return;
        active = false;
        viaOverlay = false;
        if (!bigEnough || !screen) return;

        const gx = Math.round(screen.x + rx);
        const gy = Math.round(screen.y + ry);
        const cmd = (Settings.s.drawTerminalCommand || "kitty").replace(/[\\"]/g, "");
        Quickshell.execDetached(["hyprctl", "eval",
            `hl.exec_cmd("${cmd}", { float = true, size = "${Math.round(rw)} ${Math.round(rh)}", move = "${gx} ${gy}" })`]);
    }
}
