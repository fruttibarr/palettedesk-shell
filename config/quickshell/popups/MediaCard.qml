import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Now-playing card: art, title, progress, controls.
Rectangle {
    id: card
    readonly property MprisPlayer player: Media.player

    implicitHeight: 116
    radius: 16
    color: Theme.alpha(Theme.surfaceContainerHigh, 0.55)

    // Position isn't pushed by MPRIS; ask for fresh values while playing.
    Timer {
        interval: 1000; repeat: true
        running: card.visible && (card.player?.isPlaying ?? false)
        onTriggered: card.player.positionChanged()
    }

    component CtrlButton: Rectangle {
        id: btn
        property string icon
        property bool primary: false
        signal clicked()
        implicitWidth: primary ? 40 : 32
        implicitHeight: implicitWidth
        radius: width / 2
        color: primary ? Theme.primary
             : btnMouse.containsMouse ? Theme.alpha(Theme.primary, 0.2) : "transparent"
        Text {
            anchors.centerIn: parent
            text: btn.icon
            color: btn.primary ? Theme.textOnPrimary : Theme.text
            font.family: Theme.font
            font.pixelSize: btn.primary ? 20 : 17
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        ClippingRectangle {
            implicitWidth: 92
            implicitHeight: 92
            radius: 12
            color: Theme.alpha(Theme.primaryContainer, 0.8)

            Image {
                id: art
                anchors.fill: parent
                source: card.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(184, 184)
            }
            Text {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "󰎆"
                color: Theme.textOnPrimaryContainer
                font.family: Theme.font
                font.pixelSize: 34
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: card.player?.trackTitle || card.player?.identity || ""
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: card.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                visible: card.player?.lengthSupported ?? false
                implicitHeight: 4
                radius: 2
                color: Theme.alpha(Theme.outlineVariant, 0.6)
                Rectangle {
                    height: parent.height
                    radius: 2
                    color: Theme.primary
                    width: {
                        const p = card.player;
                        return p && p.length > 0 ? parent.width * Math.min(1, p.position / p.length) : 0;
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                CtrlButton {
                    icon: "󰒮"
                    enabled: card.player?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: card.player.previous()
                }
                CtrlButton {
                    primary: true
                    icon: card.player?.isPlaying ? "󰏤" : "󰐊"
                    onClicked: card.player.togglePlaying()
                }
                CtrlButton {
                    icon: "󰒭"
                    enabled: card.player?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: card.player.next()
                }
            }
        }
    }
}
