import qs.services
import QtQuick

// Pick one of several options. options: [{ label, value, disabled? }]
Flow {
    id: seg
    property var options: []
    property var current
    signal picked(var value)
    spacing: 6

    Repeater {
        model: seg.options
        Rectangle {
            id: opt
            required property var modelData
            readonly property bool selected: seg.current === modelData.value
            readonly property bool off: !!modelData.disabled
            opacity: off ? 0.35 : 1
            implicitWidth: optText.implicitWidth + 26
            implicitHeight: 30
            radius: 15
            color: selected ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, optMouse.containsMouse ? 0.95 : 0.6)
            Behavior on color { ColorAnimation { duration: 160 } }
            Text {
                id: optText
                anchors.centerIn: parent
                text: opt.modelData.label
                color: opt.selected ? Theme.textOnPrimary : Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: opt.selected ? Font.Bold : Font.Normal
            }
            MouseArea {
                id: optMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: opt.off ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                onClicked: if (!opt.off) seg.picked(opt.modelData.value)
            }
        }
    }
}
