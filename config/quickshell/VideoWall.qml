import QtQuick
import QtMultimedia

// Looping, muted video wallpaper. Loaded through a Loader so a missing
// QtMultimedia (qt6-multimedia) only disables video instead of breaking the shell.
Item {
    id: root
    property string source
    property bool playing: true
    // Plain property, set from the status handler. (A binding on mediaStatus that also reacted to
    // its own change by calling play() was a binding loop: QML could abort it and leave `ready`
    // stale, so the new wallpaper was never revealed.)
    property bool ready: false

    MediaPlayer {
        id: player
        source: root.source ? "file://" + root.source : ""
        loops: MediaPlayer.Infinite
        videoOutput: output
        onMediaStatusChanged: {
            const s = mediaStatus;
            root.ready = s === MediaPlayer.LoadedMedia || s === MediaPlayer.BufferedMedia
                      || s === MediaPlayer.BufferingMedia || s === MediaPlayer.EndOfMedia;
            if (root.ready) root.sync();
        }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    function sync() {
        if (playing) player.play(); else player.pause();
    }
    onPlayingChanged: sync()
    Component.onDestruction: player.stop()
}
