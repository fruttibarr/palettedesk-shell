pragma Singleton
import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Countdown timers and a pomodoro helper. Survive shell restarts (state in ~/.local/state/rice/timers.json).
//   qs ipc call timer start <minutes> [label] | list | cancel <id>
Singleton {
    id: root
    property var items: []            // [{ id, label, end (ms since epoch), total (ms) }]
    property real now: Date.now()
    readonly property string file: Quickshell.env("HOME") + "/.local/state/rice/timers.json"
    property int nextId: 1

    function start(minutes, label) {
        const ms = Math.round(Number(minutes) * 60000);
        if (!(ms > 0)) return -1;
        const id = nextId++;
        items = items.concat([{ id: id, label: label || (minutes + " min"), end: Date.now() + ms, total: ms }]);
        save();
        return id;
    }
    function cancel(id) { items = items.filter(t => t.id !== id); save(); }
    function remaining(t) { return Math.max(0, t.end - now); }
    function clock(ms) { const s = Math.ceil(ms / 1000); const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60;
                         return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(x).padStart(2, "0"); }

    function save() { store.setText(JSON.stringify({ nextId: nextId, items: items })); }
    FileView {
        id: store
        path: root.file
        onLoaded: { try { const d = JSON.parse(text()); root.items = d.items ?? []; root.nextId = d.nextId ?? 1; } catch (e) {} }
    }

    Timer {
        interval: 1000; repeat: true; running: root.items.length > 0
        onTriggered: {
            root.now = Date.now();
            const done = root.items.filter(t => t.end <= root.now);
            if (!done.length) return;
            for (const t of done)
                Quickshell.execDetached(["notify-send", "-a", "Timer", "-u", "critical", "Timer finished", t.label]);
            root.items = root.items.filter(t => t.end > root.now);
            root.save();
        }
    }

    IpcHandler {
        target: "timer"
        function start(minutes: real, label: string): string { const id = root.start(minutes, label); return id > 0 ? "started " + id : "invalid duration"; }
        function cancel(id: int): void { root.cancel(id); }
        function list(): string { return root.items.map(t => t.id + " " + t.label + " " + root.clock(root.remaining(t))).join("\n") || "no timers"; }
    }
}
