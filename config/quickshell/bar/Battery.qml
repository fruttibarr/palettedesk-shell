import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.widgets
import QtQuick

// Battery; icon breathes while charging, blinks when low.
IconLabel {
    id: root
    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property real raw: dev?.percentage ?? 0
    readonly property int pct: Math.round(raw <= 1 ? raw * 100 : raw)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && !full && pct <= 15
    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    visible: dev?.isLaptopBattery ?? false
    icon: charging || full ? "󰂄" : icons[Math.min(9, Math.floor(pct / 10))]
    label: Settings.s.statusPercent ? pct + "%" : ""
    readonly property bool stateful: Settings.s.statusStateColors
    iconColor: low ? Theme.error : charging ? Theme.primary : stateful ? (pct > 60 ? Theme.primary : pct > 30 ? Theme.tertiary : Theme.secondary) : Theme.tertiary
    showIcon: Settings.s.batteryStyle === "icon"
    labelColor: low ? Theme.error : Theme.text

    onChargingChanged: bump()

    // batteryStyle: ring (gauge) / bar (battery-shaped meter)
    extra: [
    Ring {
        visible: Settings.s.batteryStyle === "ring"
        anchors.verticalCenter: parent.verticalCenter
        value: root.pct / 100
        color: root.iconColor
        thickness: 2.5
        Text {
            visible: root.charging
            anchors.centerIn: parent
            text: "󱐋"
            color: parent.color
            font.family: Theme.font
            font.pixelSize: 9
        }
    },
    Item {
        visible: Settings.s.batteryStyle === "bar"
        width: 26; height: 12
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: 23; height: 12; radius: 3.5
            color: "transparent"
            border.width: 1.4; border.color: Theme.alpha(root.iconColor, 0.8)
            Rectangle {
                x: 2; y: 2; height: parent.height - 4
                width: Math.max(2, (parent.width - 4) * root.pct / 100)
                radius: 2
                color: root.iconColor
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
        Rectangle { x: 24; y: 4; width: 2.5; height: 4; radius: 1; color: Theme.alpha(root.iconColor, 0.8) }
    }
    ]

    SequentialAnimation {
        running: root.charging || root.low
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.iconItem.opacity = 1
        NumberAnimation { target: root.iconItem; property: "opacity"; to: 0.35; duration: root.low ? 500 : 1100; easing.type: Easing.InOutSine }
        NumberAnimation { target: root.iconItem; property: "opacity"; to: 1; duration: root.low ? 500 : 1100; easing.type: Easing.InOutSine }
    }
}
