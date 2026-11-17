pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU and RAM usage, sampled every 2 seconds.
Singleton {
    id: root
    property real cpu: 0
    property real ram: 0
    property var last: null

    Process {
        id: proc
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const f = lines[0].split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0);
                const total = f.reduce((a, b) => a + b, 0);
                if (root.last) {
                    const dt = total - root.last.total;
                    if (dt > 0) root.cpu = 1 - (idle - root.last.idle) / dt;
                }
                root.last = { idle, total };
                const kb = k => Number(lines.find(l => l.startsWith(k)).split(/\s+/)[1]);
                root.ram = 1 - kb("MemAvailable") / kb("MemTotal");
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
