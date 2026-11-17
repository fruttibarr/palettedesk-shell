import Quickshell
import qs.services
import QtQuick
import QtQuick.Window

// One wallpaper, whatever its type: still image, animated GIF, or video.
// `playing` pauses animation (e.g. on battery or under fullscreen windows).
Item {
    id: layer
    property string path: ""
    property string still: ""        // a frame of the video, used as fallback
    property bool playing: true

    // Real pixels per logical pixel (1.25 at 125% scale). Decode at full resolution,
    // otherwise images are loaded small and stretched back up (blurry).
    readonly property real dpr: Window.window?.devicePixelRatio ?? 1
    readonly property size pixelSize: Qt.size(Math.round(width * dpr), Math.round(height * dpr))
    // Upscaled 2x or more (pixel art, tiny GIFs): nearest-neighbour keeps it sharp
    function crisp(w, h) {
        return Settings.s.wallCrispPixels && w > 0 && h > 0
            && Math.max(pixelSize.width / w, pixelSize.height / h) >= 2;
    }

    readonly property string kind: /\.(mp4|webm|mkv|mov)$/i.test(path) ? "video"
                                 : /\.gif$/i.test(path) ? "gif" : "image"
    readonly property bool videoFailed: kind === "video" && video.status === Loader.Error
    readonly property bool ready: path === "" ? false
        : kind === "image" ? img.status === Image.Ready
        : kind === "gif" ? gif.status === AnimatedImage.Ready
        : videoFailed ? fallback.status === Image.Ready
        : (video.item?.ready ?? false)

    Image {
        id: img
        anchors.fill: parent
        visible: layer.kind === "image"
        source: layer.kind === "image" && layer.path ? "file://" + layer.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: layer.pixelSize
        smooth: !layer.crisp(implicitWidth, implicitHeight)
        mipmap: smooth
    }

    AnimatedImage {
        id: gif
        anchors.fill: parent
        visible: layer.kind === "gif"
        source: layer.kind === "gif" && layer.path ? "file://" + layer.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: !layer.crisp(implicitWidth, implicitHeight)
        playing: layer.playing
    }

    Loader {
        id: video
        anchors.fill: parent
        active: layer.kind === "video" && layer.path !== ""
        source: Qt.resolvedUrl("VideoWall.qml")
        onLoaded: {
            item.source = Qt.binding(() => layer.path);
            item.playing = Qt.binding(() => layer.playing);
        }
    }

    // Video support missing (qt6-multimedia not installed): show a still frame
    Image {
        id: fallback
        anchors.fill: parent
        visible: layer.videoFailed
        source: layer.videoFailed && layer.still ? "file://" + layer.still : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: layer.pixelSize
    }
}
