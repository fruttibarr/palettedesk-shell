pragma Singleton
import Quickshell
import Quickshell.Io
import qs.services
import QtQuick
import QtQml

// User-defined bar modules (Settings > Bar > Custom modules). Each one runs a shell command:
//   interval mode: rerun every N seconds, the last output line is shown
//   stream mode:   keep it running, every output line replaces the text (restarted 3 s after it exits)
// With "JSON" on, a line may be {"text","icon","tint"}; otherwise the line is the text.
// tint is primary | secondary | tertiary | error | none.
Singleton {
    id: root
    readonly property var modules: Settings.s.customModules ?? []
    property var values: ({})          // id -> { text, icon, tint }

    function config(id) { return modules.find(m => m.id === id) ?? null; }
    // Shown in the bar unless it is set to hide while empty and has nothing to say.
    function shown(id) {
        const c = config(id);
        if (!c) return false;
        const v = values[id];
        return !(c.hideWhenEmpty && (!v || (v.text ?? "") === "" && (v.icon ?? "") === ""));
    }
    function run(cmd) { if (cmd && cmd.trim() !== "") Quickshell.execDetached(["sh", "-c", cmd]); }
    function refresh(id) {
        for (let i = 0; i < inst.count; i++) {
            const o = inst.objectAt(i);
            if (o && o.mid === id) { o.rerun(); return true; }
        }
        return false;
    }
    function ingest(id, line, cfg) {
        line = line.trim();
        if (line === "") return;
        let v = { text: line };
        if (cfg.json) {
            try {
                const j = JSON.parse(line);
                v = { text: String(j.text ?? ""), icon: j.icon !== undefined ? String(j.icon) : undefined,
                      tint: j.tint !== undefined ? String(j.tint) : undefined };
            } catch (e) { v = { text: line }; }
        }
        const next = Object.assign({}, values);
        next[id] = v;
        values = next;
    }

    Instantiator {
        id: inst
        model: root.modules
        delegate: QtObject {
            id: m
            required property var modelData
            readonly property string mid: modelData.id
            readonly property bool stream: modelData.mode === "stream"
            function rerun() { proc.running = false; proc.running = true; }

            property Process proc: Process {
                command: ["sh", "-c", m.modelData.command ?? "true"]
                running: (m.modelData.command ?? "") !== ""
                stdout: SplitParser { onRead: line => root.ingest(m.mid, line, m.modelData) }
            }
            // interval mode: rerun on a timer; stream mode: just revive the process if it died
            property Timer tick: Timer {
                interval: m.stream ? 3000 : Math.max(1, m.modelData.interval ?? 5) * 1000
                running: (m.modelData.command ?? "") !== ""
                repeat: true
                onTriggered: if (!m.proc.running) m.proc.running = true
            }
        }
    }

    IpcHandler {
        target: "custommodule"
        function list(): string { return root.modules.map(c => c.id + "  " + (c.name ?? "") + "  = " + JSON.stringify(root.values[c.id]?.text ?? "")).join("\n"); }
        function refresh(id: string): string { return root.refresh(id) ? "ok" : "no such module"; }
    }
}
