import Quickshell
import qs.services
import QtQuick

// Settings: clock24h, clockSeconds, showDate, dateFormat, clockIcon.
// Hover reveals the full date.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property bool seconds: Settings.s.clockSeconds
    readonly property string timeFormat: Settings.s.clock24h ? (seconds ? "HH:mm:ss" : "HH:mm")
                                                           : (seconds ? "h:mm:ss AP" : "h:mm AP")
    readonly property string dateFormat: ({
        short: "ddd d MMM", long: "dddd, d MMMM", numeric: "dd/MM/yyyy", iso: "yyyy-MM-dd"
    })[Settings.s.dateFormat] ?? "ddd d MMM"

    SystemClock { id: clock; precision: root.seconds ? SystemClock.Seconds : SystemClock.Minutes }
    HoverHandler { id: hover }
    readonly property bool expanded: hover.hovered

    Row {
        id: row
        spacing: 8

        Text {
            id: icon
            visible: Settings.s.clockIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "󰥔"
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            RotationAnimation on rotation {
                id: spin
                running: false
                from: 0; to: 360; duration: 700
                easing.type: Easing.OutBack
            }
        }

        Text {
            id: time
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, root.timeFormat)
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
            transform: Translate { id: tickY }
            property string minute: Qt.formatDateTime(clock.date, "HH:mm")
            onMinuteChanged: { tick.restart(); spin.restart(); }
            ParallelAnimation {
                id: tick
                NumberAnimation { target: tickY; property: "y"; from: 8; to: 0; duration: 420; easing.type: Easing.OutBack }
                NumberAnimation { target: time; property: "opacity"; from: 0; to: 1; duration: 300 }
            }
        }

        Item {
            visible: Settings.s.showDate || root.expanded
            anchors.verticalCenter: parent.verticalCenter
            width: root.expanded ? full.implicitWidth : short.implicitWidth
            height: short.implicitHeight
            clip: true
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            Text {
                id: short
                text: Settings.s.showDate ? Qt.formatDateTime(clock.date, root.dateFormat) : ""
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                opacity: root.expanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
            Text {
                id: full
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                opacity: root.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }
            }
        }
    }
}
