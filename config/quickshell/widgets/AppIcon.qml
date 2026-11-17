import Quickshell
import Quickshell.Widgets
import qs.services
import QtQuick

// App icon with a lettered fallback tile
Item {
    id: ai
    property var entry: null
    property int size: 40
    readonly property string path: entry ? Quickshell.iconPath(entry.icon, true) : ""
    width: size
    height: size
    IconImage {
        anchors.fill: parent
        visible: ai.path !== ""
        source: ai.path
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        visible: ai.path === ""
        radius: ai.size * 0.3
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.primaryContainer }
            GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0.6) }
        }
        Text {
            anchors.centerIn: parent
            text: ai.entry ? ai.entry.name.charAt(0).toUpperCase() : "?"
            color: Theme.textOnPrimaryContainer
            font.family: Theme.font
            font.pixelSize: ai.size * 0.45
            font.bold: true
        }
    }
}
