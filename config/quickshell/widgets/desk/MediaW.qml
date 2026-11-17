import Quickshell
import Quickshell.Services.Mpris
import qs.services
import QtQuick

// Now playing: cover, title, artist and controls.
Item {
    id: w
    property var opts: ({})
    readonly property var p: Media.player
    implicitWidth: 320
    implicitHeight: 96
    Rectangle {
        id: art
        width: 96; height: 96; radius: 12
        color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
        clip: true
        Image { anchors.fill: parent; source: w.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
        Text { anchors.centerIn: parent; visible: !(w.p?.trackArtUrl); text: "󰎆"; color: Theme.outline; font.family: Theme.font; font.pixelSize: 34 }
    }
    Column {
        anchors { left: art.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 3
        Text { width: parent.width; elide: Text.ElideRight; text: w.p ? (w.p.trackTitle || w.p.identity) : "Nothing playing"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2; font.weight: Font.Bold }
        Text { width: parent.width; elide: Text.ElideRight; text: w.p?.trackArtist ?? ""; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
        Row {
            spacing: 14
            topPadding: 6
            Repeater {
                model: [{ i: "󰒮", f: "prev" }, { i: w.p?.isPlaying ? "󰏤" : "󰐊", f: "toggle" }, { i: "󰒭", f: "next" }]
                Text {
                    required property var modelData
                    text: modelData.i; color: Theme.primary; font.family: Theme.font; font.pixelSize: 22
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!w.p) return; if (modelData.f === "prev") w.p.previous(); else if (modelData.f === "next") w.p.next(); else w.p.togglePlaying(); }
                    }
                }
            }
        }
    }
}
