import qs.services
import QtQuick
import QtQuick.Layouts

// One row in the control center's Wi-Fi / Bluetooth lists.
// `actions` = [{ icon, tip, danger? }]; shown on hover, emit actionClicked(index).
// Children (e.g. a password field) go below the row.
Rectangle {
    id: row
    property string icon
    property string title
    property string subtitle
    property bool current: false     // connected
    property bool busy: false        // connecting / pairing
    property bool error: false       // subtitle shown in error color
    property var actions: []
    default property alias extra: extraCol.data
    signal clicked()
    signal actionClicked(int index)

    implicitHeight: main.height + (extraCol.visibleChildren.length ? extraCol.implicitHeight + 8 : 0)
    radius: 12
    color: current ? Theme.alpha(Theme.primaryContainer, hover.hovered ? 0.95 : 0.75)
         : hover.hovered ? Theme.alpha(Theme.outline, 0.15) : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    HoverHandler { id: hover }

    Item {
        id: main
        width: parent.width
        height: 46

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10

            Text {
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter
                text: row.icon
                color: row.current ? Theme.primary : Theme.text
                font.family: Theme.font
                font.pixelSize: 17

                // gentle pulse while connecting
                property real pulse: 1
                opacity: row.busy ? pulse : 1
                SequentialAnimation on pulse {
                    running: row.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: row.title
                    color: row.current ? Theme.textOnPrimaryContainer : Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: row.current ? Font.Bold : Font.Normal
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    elide: Text.ElideRight
                    text: row.subtitle
                    color: row.error ? Theme.error
                         : row.current ? Theme.alpha(Theme.textOnPrimaryContainer, 0.75) : Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                }
            }

            Repeater {
                model: row.actions
                Rectangle {
                    id: act
                    required property var modelData
                    required property int index
                    visible: hover.hovered
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: actMouse.containsMouse
                           ? (modelData.danger ? Theme.error : Theme.primary)
                           : Theme.alpha(Theme.outline, 0.2)
                    Text {
                        anchors.centerIn: parent
                        text: act.modelData.icon
                        color: actMouse.containsMouse ? Theme.background : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.actionClicked(act.index)
                    }
                    ToolTipLabel {
                        shown: actMouse.containsMouse
                        text: act.modelData.tip
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: extraCol
        anchors.top: main.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6
    }
}
