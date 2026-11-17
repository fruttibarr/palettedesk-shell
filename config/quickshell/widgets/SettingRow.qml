import qs.services
import QtQuick
import QtQuick.Layouts

// Label + optional description on the left, a control on the right.
RowLayout {
    id: row
    property string label
    property string description
    property string keywords           // extra words for settings search
    readonly property bool isSettingRow: true
    default property alias control: holder.data
    Layout.fillWidth: true
    spacing: 20

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            Layout.fillWidth: true
            text: row.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        Text {
            Layout.fillWidth: true
            visible: row.description !== ""
            text: row.description
            wrapMode: Text.Wrap
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
        }
    }

    Row {
        id: holder
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    }
}
