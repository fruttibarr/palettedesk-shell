import qs.services
import QtQuick

// Pick one of several options. options: [{ label, value, disabled? }]
Flow {
    id: seg
    property var options: []
    property var current
    signal picked(var value)
    spacing: Settings.s.uiSegmentStyle === "underline" ? 14 : 6
    readonly property string look: Settings.s.uiSegmentStyle   // pill | square | soft | underline

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
            radius: seg.look === "square" ? 6 : seg.look === "underline" ? 0 : 15
            color: seg.look === "underline" ? "transparent"
                 : seg.look === "soft" ? (selected ? Theme.alpha(Theme.primary, 0.22) : Theme.alpha(Theme.surfaceContainerHigh, optMouse.containsMouse ? 0.95 : 0.35))
                 : selected ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, optMouse.containsMouse ? 0.95 : 0.6)
            border.width: seg.look === "soft" && selected ? 1 : 0
            border.color: Theme.primary
            Rectangle {   // underline indicator
                visible: seg.look === "underline"
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                color: opt.selected ? Theme.primary : Theme.alpha(Theme.outline, optMouse.containsMouse ? 0.7 : 0.25)
            }
            Behavior on color { ColorAnimation { duration: 160 } }
            Text {
                id: optText
                anchors.centerIn: parent
                text: opt.modelData.label
                color: opt.selected ? (seg.look === "soft" || seg.look === "underline" ? Theme.primary : Theme.textOnPrimary) : Theme.text
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
