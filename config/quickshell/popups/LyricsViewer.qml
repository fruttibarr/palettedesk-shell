import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Lyrics viewer: pulls down from the bar under the lyrics chip.
// Follows the song, click a line to jump there, scroll freely in between.
// Toggle: click the lyrics chip or `qs ipc call lyrics toggle`.
Scope {
    id: root
    readonly property bool open: Globals.lyricsOpen
    readonly property MprisPlayer player: Media.player

    IpcHandler {
        target: "lyrics"
        function toggle(): void { Globals.lyricsOpen = !Globals.lyricsOpen }
        function status(): string { return Lyrics.status + " " + Lyrics.index + "/" + Lyrics.lines.length + " " + Lyrics.current }
        function retry(): void { Lyrics.retry() }
    }

    Overlay {
        id: win
        name: "lyrics"
        zoom: false
        slideMode: true
        slideOutMs: 240
        open: root.open
        onCloseRequested: Globals.lyricsOpen = false

        // everything past the bar's inner edge; the panel slides out from behind this line
        Item {
            id: well
            anchors.fill: parent
            anchors.topMargin: Theme.barTop ? Theme.barMarginPx + Theme.barHeight : 0
            anchors.bottomMargin: Theme.barTop ? 0 : Theme.barMarginPx + Theme.barHeight
            clip: true

            GlassPanel {
                id: panel
                width: Math.min(440, well.width - 20)
                height: Math.min(600, well.height - 40)
                x: {
                    const ax = Globals.lyricsAnchorX >= 0 ? Globals.lyricsAnchorX : well.width / 2;
                    return Math.max(10, Math.min(well.width - width - 10, ax - width / 2));
                }
                readonly property real shownY: Theme.barTop ? 8 : well.height - height - 8
                readonly property real hiddenY: Theme.barTop ? -height - 4 : well.height + 4
                y: root.open ? shownY : hiddenY
                Behavior on y {
                    NumberAnimation {
                        duration: (root.open ? 380 : 240) * win.animScale
                        easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // ---- now playing ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ClippingRectangle {
                            implicitWidth: 52
                            implicitHeight: 52
                            radius: 10
                            color: Theme.alpha(Theme.primaryContainer, 0.8)
                            Image {
                                id: art
                                anchors.fill: parent
                                source: root.open || win.visible ? (root.player?.trackArtUrl ?? "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(128, 128)
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: art.status !== Image.Ready
                                text: "󰎆"
                                color: Theme.textOnPrimaryContainer
                                font.family: Theme.font
                                font.pixelSize: 22
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: Lyrics.title || root.player?.identity || "Nothing playing"
                                elide: Text.ElideRight
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.weight: Font.Bold
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: Lyrics.artist
                                elide: Text.ElideRight
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        component RoundButton: Rectangle {
                            id: rb
                            property string icon
                            property bool primary: false
                            property bool active: true
                            signal clicked()
                            implicitWidth: primary ? 36 : 30
                            implicitHeight: implicitWidth
                            radius: width / 2
                            opacity: active ? 1 : 0.35
                            color: primary ? Theme.primary
                                 : rbMouse.containsMouse && active ? Theme.alpha(Theme.primary, 0.2) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: rb.icon
                                color: rb.primary ? Theme.textOnPrimary : Theme.text
                                font.family: Theme.font
                                font.pixelSize: rb.primary ? 18 : 16
                            }
                            MouseArea {
                                id: rbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: rb.active
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rb.clicked()
                            }
                        }
                        RoundButton { icon: "󰒮"; active: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }
                        RoundButton { icon: root.player?.isPlaying ? "󰏤" : "󰐊"; primary: true; active: root.player !== null; onClicked: root.player.togglePlaying() }
                        RoundButton { icon: "󰒭"; active: root.player?.canGoNext ?? false; onClicked: root.player.next() }
                    }

                    // progress
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 3
                        radius: 1.5
                        color: Theme.alpha(Theme.outlineVariant, 0.6)
                        Rectangle {
                            height: parent.height
                            radius: 1.5
                            color: Theme.primary
                            width: Lyrics.length > 0 ? parent.width * Math.max(0, Math.min(1, Lyrics.position / Lyrics.length)) : 0
                        }
                    }

                    // ---- the lyrics ----
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // timed: follows the song
                        ListView {
                            id: list
                            anchors.fill: parent
                            visible: Lyrics.synced
                            clip: true
                            model: Lyrics.lines
                            spacing: 10
                            boundsBehavior: Flickable.StopAtBounds
                            currentIndex: Lyrics.index
                            // keep the current line around the upper third; the user can still scroll away
                            highlightRangeMode: ListView.ApplyRange
                            preferredHighlightBegin: height * 0.32
                            preferredHighlightEnd: height * 0.32 + 40
                            highlightMoveDuration: 450
                            highlightMoveVelocity: -1
                            highlightFollowsCurrentItem: true
                            header: Item { height: 6 }
                            footer: Item { height: list.height * 0.5 }

                            delegate: Item {
                                id: row
                                required property var modelData
                                required property int index
                                readonly property bool isCurrent: index === Lyrics.index
                                readonly property bool past: index < Lyrics.index
                                width: list.width
                                implicitHeight: words.implicitHeight

                                Text {
                                    id: words
                                    width: parent.width - 8
                                    text: row.modelData.text || "♪"
                                    wrapMode: Text.Wrap
                                    color: row.isCurrent ? Theme.text : rowMouse.containsMouse ? Theme.primary : Theme.subtext
                                    opacity: row.isCurrent ? 1 : row.past ? 0.4 : 0.7
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 3
                                    font.weight: row.isCurrent ? Font.Bold : Font.Medium
                                    transformOrigin: Item.Left
                                    scale: row.isCurrent ? 1.0 : 0.94
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 260 } }
                                    Behavior on color { ColorAnimation { duration: 260 } }
                                }
                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: root.player?.canSeek ?? false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Lyrics.seekTo(row.modelData.t)
                                }
                            }
                        }

                        // not timed: just the text
                        Flickable {
                            id: plainView
                            anchors.fill: parent
                            visible: Lyrics.status === "plain"
                            clip: true
                            contentHeight: plainText.implicitHeight + 20
                            boundsBehavior: Flickable.StopAtBounds
                            Text {
                                id: plainText
                                width: plainView.width - 8
                                text: Lyrics.plain
                                wrapMode: Text.Wrap
                                color: Theme.text
                                lineHeight: 1.35
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                            }
                        }

                        // nothing to show
                        Column {
                            anchors.centerIn: parent
                            visible: !Lyrics.synced && Lyrics.status !== "plain"
                            spacing: 10
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Lyrics.status === "loading" ? "󰔟" : Lyrics.status === "instrumental" ? "󰎈"
                                    : Lyrics.status === "error" ? "󰖪" : "󰎊"
                                color: Theme.primary
                                font.family: Theme.font
                                font.pixelSize: 40
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Lyrics.status === "loading" ? "Finding lyrics…"
                                    : Lyrics.status === "instrumental" ? "Instrumental"
                                    : Lyrics.status === "error" ? "Couldn't reach LRCLIB"
                                    : Lyrics.status === "notfound" ? "No lyrics found for this track"
                                    : "Play something to see its lyrics"
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: Lyrics.status === "error" || Lyrics.status === "notfound"
                                width: retryText.implicitWidth + 28
                                height: 30
                                radius: 15
                                color: Theme.alpha(Theme.primary, retryMouse.containsMouse ? 0.3 : 0.15)
                                Text {
                                    id: retryText
                                    anchors.centerIn: parent
                                    text: "Try again"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                MouseArea {
                                    id: retryMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Lyrics.retry()
                                }
                            }
                        }
                    }

                    // ---- footer: timing nudge + credit ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: "Lyrics from LRCLIB"
                            color: Theme.outline
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                        component Nudge: Rectangle {
                            id: nb
                            property string label
                            signal clicked()
                            implicitWidth: 26
                            implicitHeight: 22
                            radius: 6
                            color: Theme.alpha(Theme.primary, nbMouse.containsMouse ? 0.25 : 0.1)
                            Text {
                                anchors.centerIn: parent
                                text: nb.label
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                            }
                            MouseArea {
                                id: nbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: nb.clicked()
                            }
                        }
                        Nudge { visible: Lyrics.synced; label: "−"; onClicked: Settings.set("lyricsOffset", Math.max(-5000, Settings.s.lyricsOffset - 100)) }
                        Text {
                            visible: Lyrics.synced
                            text: "Timing " + (Settings.s.lyricsOffset > 0 ? "+" : "") + (Settings.s.lyricsOffset / 1000).toFixed(1) + "s"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.features: { "tnum": 1 }
                        }
                        Nudge { visible: Lyrics.synced; label: "+"; onClicked: Settings.set("lyricsOffset", Math.min(5000, Settings.s.lyricsOffset + 100)) }
                    }
                }
            }
        }

        // open already on the current line instead of scrolling there
        Connections {
            target: root
            function onOpenChanged() {
                if (root.open && Lyrics.index >= 0) list.positionViewAtIndex(Lyrics.index, ListView.Center);
            }
        }
    }
}
