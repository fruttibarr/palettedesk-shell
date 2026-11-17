import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Night light: warms the screen with hyprsunset while Settings.nightLight is on.
//   qs ipc call nightlight toggle | on | off | temp 3500 | status
Scope {
    id: root
    readonly property bool wanted: Settings.s.nightLight
    readonly property int temp: Settings.s.nightTemp

    Process {
        id: proc
        command: ["hyprsunset", "-t", String(root.temp)]
        // hyprsunset not installed: stay quiet (the setting simply does nothing)
        onExited: (code, status) => { if (code === 127) root.missing = true; }
    }
    property bool missing: false

    // (re)start when switched on or when the temperature changes; stop when switched off
    function apply() {
        proc.running = false;
        restart.restart();
    }
    Timer { id: restart; interval: 300; onTriggered: proc.running = root.wanted && !root.missing }
    onWantedChanged: apply()
    onTempChanged: if (wanted) apply()
    Component.onCompleted: if (wanted) apply()

    IpcHandler {
        target: "nightlight"
        function toggle(): void { Settings.set("nightLight", !Settings.s.nightLight); }
        function on(): void { Settings.set("nightLight", true); }
        function off(): void { Settings.set("nightLight", false); }
        function temp(kelvin: int): void { Settings.set("nightTemp", Math.max(1500, Math.min(6500, kelvin))); }
        function status(): string { return (Settings.s.nightLight ? "on " : "off ") + Settings.s.nightTemp + "K" + (proc.running ? " running" : "") + (root.missing ? " (hyprsunset not installed)" : ""); }
    }
}
