import Quickshell
import qs.services
import QtQuick

// The line being sung, with the previous and next ones faded around it.
Item {
    id: w
    property var opts: ({})
    implicitWidth: 460
    implicitHeight: 110
    readonly property var all: Lyrics.lines
    function line(o) { const i = Lyrics.index + o; return Lyrics.synced && i >= 0 && i < all.length ? all[i].text : ""; }
    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 6
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: w.line(-1); color: Theme.subtext; opacity: 0.6; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        Text {
            width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
            text: Lyrics.synced ? (w.line(0) || "♪") : Lyrics.status === "loading" ? "Finding lyrics…" : Lyrics.status === "idle" ? "Nothing playing" : "No synced lyrics"
            color: Theme.primary; font.family: Theme.font; font.pixelSize: Theme.fontSize + 8; font.weight: Font.Bold
        }
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: w.line(1); color: Theme.subtext; opacity: 0.6; font.family: Theme.font; font.pixelSize: Theme.fontSize }
    }
}
