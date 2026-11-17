import Quickshell
import qs.services
import qs.widgets
import QtQuick

// CPU and RAM rings.
Item {
    id: w
    property var opts: ({})
    implicitWidth: 2 * 110 + 20
    implicitHeight: 130
    Row {
        spacing: 20
        Repeater {
            model: [{ n: "CPU", v: Stats.cpu, c: Theme.primary }, { n: "RAM", v: Stats.ram, c: Theme.tertiary }]
            Item {
                required property var modelData
                width: 110; height: 130
                Ring { id: r; anchors.horizontalCenter: parent.horizontalCenter; width: 100; height: 100; value: parent.modelData.v; color: parent.modelData.c; thickness: 8 }
                Text { anchors.centerIn: r; text: Math.round(parent.modelData.v * 100) + "%"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 6; font.weight: Font.Bold }
                Text { anchors { horizontalCenter: parent.horizontalCenter; top: r.bottom; topMargin: 4 } text: parent.modelData.n; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
            }
        }
    }
}
