pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Screen recording state. The work is done by scripts/screenrec.sh (wf-recorder),
// which keeps running if the shell reloads; this just polls its status.
//   active   a recording is in progress
//   elapsed  seconds since it started
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/screenrec.sh"
    property bool active: false
    property real startedAt: 0
    property string file: ""
    property int elapsed: 0
    readonly property string clock: {
        const m = Math.floor(elapsed / 60), s = elapsed % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function start(mode: string): void { Quickshell.execDetached([script, "start", mode || Settings.s.recMode]); recheck.restart(); }
    function stop(): void { Quickshell.execDetached([script, "stop"]); recheck.restart(); }
    function toggle(mode: string): void { Quickshell.execDetached([script, "toggle", mode || Settings.s.recMode]); recheck.restart(); }
    function refresh(): void { probe.running = true; }

    Process {
        id: probe
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(" ");
                root.active = p[0] === "recording";
                if (root.active) { root.startedAt = Number(p[1]); root.file = p.slice(2).join(" "); }
                else root.elapsed = 0;
            }
        }
    }

    // quick follow-up polls after a start/stop (a region pick or countdown can take a while)
    Timer { id: recheck; interval: 700; repeat: true; running: false; property int n: 0
        onTriggered: { root.refresh(); if (++n > 40) { n = 0; stop(); } }
        onRunningChanged: if (!running) n = 0
    }
    Timer { interval: 1000; repeat: true; running: root.active; onTriggered: { root.elapsed = Math.max(0, Math.floor(Date.now() / 1000 - root.startedAt)); } }
    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
