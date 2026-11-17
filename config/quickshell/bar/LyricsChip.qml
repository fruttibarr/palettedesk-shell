import Quickshell
import qs.services
import qs.widgets
import QtQuick

// Live lyrics: the line being sung right now (LRCLIB, see services/Lyrics.qml).
// Click pulls down the full lyrics viewer (popups/LyricsViewer.qml).
Chip {
    id: chip
    clickable: true
    spacing: 8
    tint: Globals.lyricsOpen ? Theme.primaryContainer : Theme.surfaceContainerHigh
    tintOpacity: Globals.lyricsOpen ? 0.85 : 0.5

    // what the chip says when there is no line to show
    readonly property string idleText: Lyrics.status === "loading" ? "Finding lyrics…"
                                     : Lyrics.status === "instrumental" ? "Instrumental"
                                     : Lyrics.status === "plain" ? "Lyrics (not timed)"
                                     : Lyrics.status === "notfound" ? "No lyrics"
                                     : Lyrics.status === "error" ? "Lyrics offline"
                                     : ""
    readonly property bool live: Lyrics.synced && Lyrics.current !== ""
    readonly property string wanted: live ? Lyrics.current : Lyrics.synced ? "" : idleText

    onClicked: {
        // tell the viewer where to drop from (screen x of the chip's middle)
        Globals.lyricsAnchorX = chip.mapToItem(null, chip.width / 2, 0).x + Theme.barMarginPx;
        Globals.lyricsOpen = !Globals.lyricsOpen;
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰎈"
        color: chip.live ? Theme.tertiary : Theme.outline
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Item {
        id: view
        anchors.verticalCenter: parent.verticalCenter
        readonly property real maxW: Settings.s.lyricsMaxWidth
        readonly property real overflow: Math.max(0, line.implicitWidth - maxW)
        visible: line.text !== ""
        width: Math.min(line.implicitWidth, maxW)
        height: line.implicitHeight
        clip: true

        Text {
            id: line
            color: chip.live ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            transform: Translate { id: lift }
        }

        // long lines glide to their end while they're being sung
        NumberAnimation {
            id: glide
            target: line; property: "x"
            to: -view.overflow
            easing.type: Easing.InOutSine
        }
    }

    // line change: old one lifts out, new one rises in
    onWantedChanged: if (line.text === "") { swap.stop(); show(); rise.restart(); } else swap.restart()
    Component.onCompleted: show()
    function show() {
        glide.stop();
        line.x = 0;
        line.text = wanted;
        if (!chip.live) return;
        const next = Lyrics.lines[Lyrics.index + 1];
        const span = next ? (next.t - Lyrics.lines[Lyrics.index].t) * 1000 : 4000;
        if (view.overflow > 0) {
            glide.duration = Math.max(600, span - 900);
            glideDelay.restart();
        }
    }
    Timer { id: glideDelay; interval: 450; onTriggered: glide.restart() }

    SequentialAnimation {
        id: swap
        ParallelAnimation {
            NumberAnimation { target: line; property: "opacity"; to: 0; duration: 110 }
            NumberAnimation { target: lift; property: "y"; to: -6; duration: 110; easing.type: Easing.InQuad }
        }
        ScriptAction { script: chip.show() }
        ScriptAction { script: rise.restart() }
    }
    ParallelAnimation {
        id: rise
        NumberAnimation { target: line; property: "opacity"; from: 0; to: 1; duration: 220 }
        NumberAnimation { target: lift; property: "y"; from: 7; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
}
