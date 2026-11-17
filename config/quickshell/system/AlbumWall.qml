import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Album-cover wallpaper (Settings → Wallpaper & Colors): follows the current
// track's cover with scripts/album-wallpaper.sh, and puts the normal wallpaper
// back when there is no cover to show or the setting is off.
Scope {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/album-wallpaper.sh"
    readonly property var player: Media.player
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property bool playing: player?.isPlaying ?? false

    // what should be on screen: "<art url>\n<style>", or "" for the normal wallpaper
    readonly property string want: Settings.s.albumWallpaper && art !== "" && (playing || Settings.s.albumWallKeepPaused)
        ? art + "\n" + Settings.s.albumWallStyle : ""
    property string applied: "?"      // unknown until the first run
    property string lastError: ""

    // Metadata arrives a field at a time (and players show up a moment after login): let it settle.
    onWantChanged: settle.restart()
    Component.onCompleted: settle.restart()
    Timer { id: settle; interval: 2000; onTriggered: { interval = 500; root.sync(); } }

    function sync() {
        if (proc.running || want === applied) return;   // a running one re-checks when it exits
        proc.target = want;
        proc.command = want ? [script].concat(want.split("\n")) : [script, "--restore"];
        proc.running = true;
    }

    Process {
        id: proc
        property string target
        stderr: StdioCollector { id: err }
        onExited: code => {
            root.applied = target;
            root.lastError = code === 0 ? "" : err.text.trim();
            if (root.want !== target) settle.restart();
        }
    }

    IpcHandler {
        target: "albumwall"
        function status(): string {
            return JSON.stringify({ enabled: Settings.s.albumWallpaper, art: root.art, playing: root.playing,
                                    active: Theme.albumActive, busy: proc.running, error: root.lastError });
        }
        function toggle(): void { Settings.set("albumWallpaper", !Settings.s.albumWallpaper); }
    }
}
