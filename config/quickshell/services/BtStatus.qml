pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevices: adapter ? adapter.devices.values.filter(d => d.connected) : []

    readonly property string icon: !enabled ? "󰂲" : connectedDevices.length ? "󰂱" : "󰂯"
    readonly property string label: !available ? "Service off"
        : !enabled ? "Off"
        : connectedDevices.length === 1 ? connectedDevices[0].name
        : connectedDevices.length > 1 ? connectedDevices.length + " devices"
        : "On"

    function toggle() { if (adapter) adapter.enabled = !adapter.enabled; }

    // ── Pairing agent ────────────────────────────────────────────────
    // BlueZ refuses to pair without a registered agent, and Quickshell
    // doesn't provide one, so a background `bluetoothctl` acts as the default
    // agent. Its prompts are parsed into `agentPrompt` for the UI:
    //   { kind: "confirm" | "accept" | "display" | "pin" | "passkey", code }
    property var agentPrompt: null

    function agentReply(text) {
        agent.write(text + "\n");
        agentPrompt = null;
    }

    property string _buf: ""
    function _parse(chunk) {
        _buf = (_buf + chunk.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/\r/g, "\n")).slice(-600);
        let m;
        if ((m = _buf.match(/Confirm passkey (\d+) \(yes\/no\)/))) {
            agentPrompt = { kind: "confirm", code: m[1] };
        } else if (/Accept pairing \(yes\/no\)/.test(_buf)) {
            agentPrompt = { kind: "accept", code: "" };
        } else if (/Authorize service .* \(yes\/no\)/.test(_buf)) {
            // a paired device asking to use a profile (audio etc.)
            agent.write("yes\n");
        } else if ((m = _buf.match(/\[agent\] (?:Passkey|PIN code): (\d+)/))) {
            agentPrompt = { kind: "display", code: m[1] };
        } else if (/Enter PIN code:/.test(_buf)) {
            agentPrompt = { kind: "pin", code: "" };
        } else if (/Enter passkey/.test(_buf)) {
            agentPrompt = { kind: "passkey", code: "" };
        } else if (/Request canceled|Paired: yes|Failed to pair/.test(_buf)) {
            agentPrompt = null;
        } else {
            return;
        }
        _buf = "";
    }

    Process {
        id: agent
        command: ["bluetoothctl"]
        running: root.available
        stdinEnabled: true
        onStarted: write("agent KeyboardDisplay\ndefault-agent\n")
        onExited: { root.agentPrompt = null; if (root.available) restart.start(); }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._parse(data)
        }
    }
    Timer {
        id: restart
        interval: 3000
        onTriggered: agent.running = root.available
    }
}
