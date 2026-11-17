import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Shows the output of a shell command, rerun every few seconds. opts: { command, interval, size }
Item {
    id: w
    property var opts: ({})
    property string out: ""
    implicitWidth: Math.min(600, Math.max(120, label.implicitWidth))
    implicitHeight: label.implicitHeight
    Process {
        id: proc
        command: ["sh", "-c", w.opts.command ?? "true"]
        running: (w.opts.command ?? "") !== ""
        stdout: StdioCollector { onStreamFinished: w.out = text.replace(/\s+$/, "") }
    }
    Timer { interval: Math.max(1, w.opts.interval ?? 5) * 1000; running: (w.opts.command ?? "") !== ""; repeat: true; onTriggered: if (!proc.running) proc.running = true }
    Text {
        id: label
        text: w.out !== "" ? w.out : (w.opts.command ? "…" : "Set a command in Settings › Desktop widgets")
        color: Theme.text
        font.family: Theme.font; font.pixelSize: w.opts.size ?? 18
    }
}
