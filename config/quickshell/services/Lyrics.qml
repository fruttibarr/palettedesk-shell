pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Time-synced lyrics for the current track, from LRCLIB (scripts/lyrics.py
// does the lookup + disk cache in ~/.cache/rice/lyrics).
//   status   "idle" | "loading" | "synced" | "plain" | "instrumental" | "notfound" | "error"
//   lines    [{ t: seconds, text }]  (synced only)
//   index    line being sung right now (-1 before the first one)
//   current  its text ("" during gaps)
Singleton {
    id: root

    readonly property MprisPlayer player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property real length: player?.length ?? 0
    readonly property string trackKey: title ? [title, artist, Math.round(length)].join("\u001f") : ""

    property string status: "idle"
    property var lines: []
    property string plain: ""
    property string loadedKey: ""
    property real position: 0
    property int index: -1
    readonly property bool synced: status === "synced"
    readonly property string current: index >= 0 && index < lines.length ? lines[index].text : ""
    // shift every line: positive = lyrics show earlier
    readonly property real offset: Settings.s.lyricsOffset / 1000

    // Metadata arrives a field at a time on track change; wait for it to settle.
    onTrackKeyChanged: {
        if (trackKey === loadedKey) return;
        lines = []; plain = ""; index = -1;
        status = trackKey ? "loading" : "idle";
        settle.restart();
    }
    Timer { id: settle; interval: 350; onTriggered: root.fetch() }

    function fetch() {
        fetcher.running = false;
        if (!trackKey) return;
        fetcher.key = trackKey;
        fetcher.command = ["python3", Quickshell.shellDir + "/scripts/lyrics.py",
                           trackKey, title, artist, album, String(length)];
        fetcher.running = true;
    }
    function retry() { loadedKey = ""; status = "loading"; fetch(); }

    Process {
        id: fetcher
        property string key
        stdout: StdioCollector {
            onStreamFinished: {
                let r;
                try { r = JSON.parse(text); } catch (e) { return; }
                if (r.key !== root.trackKey) return;   // track changed while we were asking
                root.loadedKey = r.key;
                root.lines = r.status === "synced" ? root.parseLrc(r.synced) : [];
                root.plain = r.plain || "";
                root.status = r.status === "synced" && root.lines.length === 0 ? "notfound" : r.status;
                root.index = -1;
                root.tick();
            }
        }
    }

    // "[01:23.45] words" → { t: 83.45, text: "words" }; a line can carry several stamps
    function parseLrc(src) {
        const out = [];
        const stamp = /\[(\d+):(\d+(?:[.:]\d+)?)\]/g;
        for (const raw of src.split("\n")) {
            stamp.lastIndex = 0;
            const times = [];
            let m, end = 0;
            while ((m = stamp.exec(raw)) !== null) {
                times.push(parseInt(m[1]) * 60 + parseFloat(m[2].replace(":", ".")));
                end = stamp.lastIndex;
            }
            if (!times.length) continue;
            const text = raw.slice(end).replace(/<\d+:\d+(?:\.\d+)?>/g, "").trim();
            for (const t of times) out.push({ t: t, text: text });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    // MPRIS doesn't push the position; read it while playing.
    function tick() {
        const p = player;
        if (!p) return;
        position = p.position;
        if (!lines.length) { index = -1; return; }
        const now = position + offset;
        let i = index;
        // usually the same line or the next one; otherwise (seek) binary search
        if (i < -1 || i >= lines.length || (i >= 0 && lines[i].t > now) || (i + 2 < lines.length && lines[i + 2].t <= now)) {
            let lo = 0, hi = lines.length - 1;
            i = -1;
            while (lo <= hi) {
                const mid = (lo + hi) >> 1;
                if (lines[mid].t <= now) { i = mid; lo = mid + 1; } else hi = mid - 1;
            }
        } else if (i + 1 < lines.length && lines[i + 1].t <= now) {
            i++;
        }
        if (i !== index) index = i;
    }
    Timer {
        interval: 80
        repeat: true
        running: root.playing && root.lines.length > 0
        onTriggered: root.tick()
    }
    onPlayingChanged: tick()
    onOffsetChanged: tick()

    function seekTo(t) {
        const p = player;
        if (!p || !p.canSeek) return;
        p.position = Math.max(0, t - offset);
        tick();
    }
}
