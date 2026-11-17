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

    // uiRowDividers: hairline between two consecutive rows
    property bool nextIsRow: false
    function checkNext() {
        const kids = row.parent ? row.parent.children : [];
        for (let i = 0; i < kids.length; i++) {
            if (kids[i] !== row) continue;
            for (let j = i + 1; j < kids.length; j++) {
                if (!kids[j].visible) continue;
                row.nextIsRow = !!kids[j].isSettingRow;
                return;
            }
            row.nextIsRow = false;
            return;
        }
    }
    Component.onCompleted: Qt.callLater(checkNext)
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

    // zero-size layout item; its child draws the line across the whole row
    Item {
        id: dividerAnchor
        visible: Settings.s.uiRowDividers && row.nextIsRow
        Layout.preferredWidth: 0; Layout.maximumWidth: 0; Layout.preferredHeight: 0
        Layout.leftMargin: -row.spacing
        Rectangle {
            x: -dividerAnchor.x
            y: row.height + (row.parent && row.parent.spacing !== undefined ? row.parent.spacing / 2 : 8) - dividerAnchor.y
            width: row.width; height: 1
            color: Theme.alpha(Theme.outline, 0.18)
        }
    }
}
