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
    iconColor: low ? Theme.error : charging ? Theme.primary : Theme.tertiary
    labelColor: low ? Theme.error : Theme.text

    onChargingChanged: bump()

    SequentialAnimation {
        running: root.charging || root.low
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.iconItem.opacity = 1
        NumberAnimation { target: root.iconItem; property: "opacity"; to: 0.35; duration: root.low ? 500 : 1100; easing.type: Easing.InOutSine }
        NumberAnimation { target: root.iconItem; property: "opacity"; to: 1; duration: root.low ? 500 : 1100; easing.type: Easing.InOutSine }
    }
}
