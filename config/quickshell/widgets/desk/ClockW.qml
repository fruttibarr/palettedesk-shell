import Quickshell
import qs.services
import QtQuick

// Big clock. opts: { h24, seconds, date, size }
Item {
    id: w
    property var opts: ({})
    readonly property real sz: opts.size ?? 72
    implicitWidth: Math.max(timeText.implicitWidth, dateText.visible ? dateText.implicitWidth : 0)
    implicitHeight: timeText.implicitHeight + (dateText.visible ? dateText.implicitHeight : 0)
    SystemClock { id: clk; precision: w.opts.seconds ? SystemClock.Seconds : SystemClock.Minutes }
    Text {
        id: timeText
        text: Qt.formatDateTime(clk.date, (w.opts.h24 === false ? "h:mm" : "HH:mm") + (w.opts.seconds ? ":ss" : "") + (w.opts.h24 === false ? " AP" : ""))
        color: Theme.text
        font.family: Theme.font; font.pixelSize: w.sz; font.weight: Font.Light
    }
    Text {
        id: dateText
        visible: w.opts.date !== false
        anchors.top: timeText.bottom
        text: Qt.formatDateTime(clk.date, "dddd, d MMMM")
        color: Theme.primary
        font.family: Theme.font; font.pixelSize: Math.max(12, w.sz * 0.28)
    }
}
