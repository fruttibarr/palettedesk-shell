import Quickshell
import qs.services
import qs.widgets
import QtQuick

// Now playing: dancing bars + scrolling title. Click opens the control center.
Chip {
    id: chip
    readonly property var player: Media.player
    readonly property bool playing: player?.isPlaying ?? false
    clickable: true
    spacing: 9

    // three bouncing bars
    Row {
        visible: Settings.s.mediaBars
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        height: 14
        Repeater {
            model: 3
            Rectangle {
                id: bar
                required property int index
                anchors.bottom: parent.bottom
                width: 3
                radius: 1.5
                height: 4
                color: Theme.tertiary
                Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutQuad } }
                Timer {
                    running: chip.playing && chip.visible
                    repeat: true
                    interval: 170 + bar.index * 40
                    onTriggered: bar.height = 4 + Math.random() * 10
                    onRunningChanged: if (!running) bar.height = 4
                }
            }
        }
    }

    // marquee title
    Item {
        id: marquee
        anchors.verticalCenter: parent.verticalCenter
        readonly property real maxW: Settings.s.mediaMaxWidth
        readonly property real overflow: Math.max(0, title.implicitWidth - maxW)
        width: Math.min(title.implicitWidth, maxW)
        height: title.implicitHeight
        clip: true

        Text {
            id: title
            text: {
                const p = chip.player;
                if (!p) return "";
                return p.trackArtist ? `${p.trackTitle} · ${p.trackArtist}` : (p.trackTitle || p.identity);
            }
            color: chip.playing ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            onTextChanged: { x = 0; scroll.restart(); }
        }

        SequentialAnimation {
            id: scroll
            running: marquee.overflow > 0 && chip.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 2200 }
            NumberAnimation { target: title; property: "x"; to: -marquee.overflow; duration: marquee.overflow * 28; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 1600 }
            NumberAnimation { target: title; property: "x"; to: 0; duration: 500; easing.type: Easing.OutCubic }
        }
    }
}
