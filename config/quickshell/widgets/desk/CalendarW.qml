import Quickshell
import qs.services
import QtQuick

// Month grid with today highlighted.
Item {
    id: w
    property var opts: ({})
    implicitWidth: 7 * 34
    implicitHeight: head.implicitHeight + 8 + 7 * 28
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property date d: clk.date
    readonly property var cells: {
        const y = d.getFullYear(), m = d.getMonth();
        const lead = (new Date(y, m, 1).getDay() - Qt.locale().firstDayOfWeek + 7) % 7;
        const days = new Date(y, m + 1, 0).getDate();
        const c = [];
        for (let i = 0; i < lead; i++) c.push(0);
        for (let n = 1; n <= days; n++) c.push(n);
        return c;
    }
    Text { id: head; text: Qt.formatDateTime(w.d, "MMMM yyyy"); color: Theme.primary; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2; font.weight: Font.Bold }
    Grid {
        y: head.implicitHeight + 8
        columns: 7
        Repeater {
            model: 7
            Text {
                required property int index
                width: 34; height: 28
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.NarrowFormat)
                color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
        }
        Repeater {
            model: w.cells
            Item {
                required property int modelData
                width: 34; height: 28
                Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; visible: parent.modelData === w.d.getDate(); color: Theme.primary }
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData > 0 ? parent.modelData : ""
                    color: parent.modelData === w.d.getDate() ? Theme.textOnPrimary : Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
