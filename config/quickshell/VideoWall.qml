import QtQuick
import QtMultimedia

// Looping, muted video wallpaper. Loaded through a Loader so a missing
// QtMultimedia (qt6-multimedia) only disables video instead of breaking the shell.
Item {
    id: root
    property string source
    property bool playing: true
    readonly property bool ready: player.mediaStatus === MediaPlayer.LoadedMedia
                                || player.mediaStatus === MediaPlayer.BufferedMedia
                                || player.mediaStatus === MediaPlayer.BufferingMedia
                                || player.mediaStatus === MediaPlayer.EndOfMedia

    MediaPlayer {
        id: player
        source: root.source ? "file://" + root.source : ""
        loops: MediaPlayer.Infinite
        videoOutput: output
        onMediaStatusChanged: if (root.ready) root.sync()
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
