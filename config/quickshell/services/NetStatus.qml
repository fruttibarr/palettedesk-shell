pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

// Wi-Fi / ethernet status via Quickshell's NetworkManager backend.
Singleton {
    id: root

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var active: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property real strength: {
        const s = active?.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }

    readonly property string icon: wired ? "󰈀"
        : !wifiEnabled ? "󰤮"
        : !active ? "󰤯"
        : strength > 0.75 ? "󰤨" : strength > 0.5 ? "󰤥" : strength > 0.25 ? "󰤢" : "󰤟"

    readonly property string label: wired ? "Ethernet"
        : !wifiEnabled ? "Off"
        : active ? active.name : "Not connected"

    readonly property bool connected: wired || active !== null

    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled; }
}
