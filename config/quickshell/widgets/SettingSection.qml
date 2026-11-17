import qs.services
import QtQuick
import QtQuick.Layouts

// Card grouping related settings under a small heading.
Rectangle {
    id: sec
    property string title
    readonly property bool isSettingSection: true
    default property alias content: col.data
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 36
    radius: 14
    color: Theme.alpha(Theme.surfaceContainerHigh, 0.4)
    border.width: 1
    border.color: Theme.alpha(Theme.primary, 0.08)

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 16

        Text {
            visible: sec.title !== ""
            text: sec.title.toUpperCase()
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }
    }
}
