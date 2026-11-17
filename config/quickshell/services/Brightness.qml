pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness. Reads sysfs, writes through systemd-logind (no root,
// no brightnessctl needed).
Singleton {
    id: root

    property string device: ""
    property int max: 1
    property int current: 0
    readonly property bool available: device !== ""
    readonly property real value: current / max

    function set(v) {
        current = Math.round(Math.max(0.01, Math.min(1, v)) * max);
        writer.restart();
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        stdout: StdioCollector { onStreamFinished: root.device = text.trim() }
    }

    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        id: cur
        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: if (!writer.running) root.current = parseInt(text()) || 0
    }

    // sysfs doesn't emit change events, so poll (catches brightness keys)
    Timer {
        interval: 1500; running: root.available; repeat: true
        onTriggered: cur.reload()
    }

    // Debounce writes while dragging the slider
    Timer {
        id: writer
        interval: 40
        onTriggered: Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1",
            "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session",
            "SetBrightness", "ssu", "backlight", root.device, String(root.current)])
    }
}
