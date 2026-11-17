import Quickshell
import qs.services
import QtQuick

// Settings: clock24h, clockSeconds, showDate, dateFormat, clockIcon.
// Hover reveals the full date.
Item {
    id: root
    implicitWidth: stacked ? col.implicitWidth : row.implicitWidth
    implicitHeight: stacked ? col.implicitHeight : row.implicitHeight

    // clockLayout: inline / stacked (time over date); clockDisplay: digital / kanji / fuzzy
    readonly property bool stacked: Settings.s.clockLayout === "stacked"
    readonly property string display: Settings.s.clockDisplay
    function kanjiNum(n) {
        const d = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
        if (n < 10) return d[n];
        return (n >= 20 ? d[Math.floor(n / 10)] : "") + "十" + (n % 10 ? d[n % 10] : "");
    }
    function fuzzy(date) {
        const hours = ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"];
        const m = Math.round(date.getMinutes() / 5) % 12, extra = Math.round(date.getMinutes() / 5) === 12 ? 1 : 0;
        const h = (date.getHours() + extra + (m > 6 ? 1 : 0)) % 12;
        const parts = ["", "five past", "ten past", "quarter past", "twenty past", "twenty-five past", "half past", "twenty-five to", "twenty to", "quarter to", "ten to", "five to"];
        return m === 0 ? hours[h] + " o'clock" : parts[m] + " " + hours[h];
    }
    function timeText(date) {
        if (display === "kanji") {
            const h = Settings.s.clock24h ? date.getHours() : (date.getHours() % 12 || 12);
            const mi = date.getMinutes();
            return kanjiNum(h) + "時" + (mi ? kanjiNum(mi) + "分" : "") + (root.seconds ? kanjiNum(date.getSeconds()) + "秒" : "");
        }
        if (display === "fuzzy") return fuzzy(date);
        return Qt.formatDateTime(date, root.timeFormat);
    }

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
        visible: !root.stacked
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
            text: root.timeText(clock.date)
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

    // stacked layout: time on top, date underneath
    Column {
        id: col
        visible: root.stacked
        spacing: -1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText(clock.date)
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, root.expanded ? "dddd, d MMMM" : root.dateFormat)
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 4
        }
    }
}
