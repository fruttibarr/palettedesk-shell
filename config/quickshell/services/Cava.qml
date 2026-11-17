pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Audio levels for the album-cover wallpaper's visualizer, from `cava`
// (the system output's monitor). Only runs while the visualizer is on screen
// and music is playing.
//   levels   0..100 per bar, bass first
Singleton {
    id: root

    readonly property bool wanted: Settings.s.albumWallpaper && Settings.s.albumVisualizer && Theme.albumActive
        && !Globals.locked && (Media.player?.isPlaying ?? false)
    readonly property int bars: Settings.s.albumVizBars
    property var levels: []
    readonly property bool running: proc.running

    onWantedChanged: if (!wanted) levels = []

    Process {
        id: proc
        running: root.wanted
        // the config is written fresh each start so the bar count follows the setting
        command: ["sh", "-c", `
            d="$HOME/.cache/rice"; mkdir -p "$d"
            printf '%s\n' '[general]' 'bars = ${root.bars}' 'framerate = 40' \
              '[input]' 'method = pipewire' 'source = auto' \
              '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' \
              'ascii_max_range = 100' 'bar_delimiter = 59' 'frame_delimiter = 10' \
              '[smoothing]' 'noise_reduction = 55' > "$d/cava.conf"
            exec cava -p "$d/cava.conf"`]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (const p of parts) if (p !== "") out.push(Number(p));
                if (out.length) root.levels = out;
            }
        }
    }
}
