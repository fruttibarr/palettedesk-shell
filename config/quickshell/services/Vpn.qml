pragma Singleton
import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// VPN profiles known to NetworkManager (type vpn / wireguard): is one connected, and a way to toggle it.
//   qs ipc call vpn toggle | status
Singleton {
    id: root
    property var profiles: []                 // [{ name, type, active }]
    readonly property var activeProfile: profiles.find(p => p.active) ?? null
    readonly property bool available: profiles.length > 0
    property string lastUsed: ""

    function refresh() { list.running = false; list.running = true; }
    function toggle() {
        if (activeProfile) Quickshell.execDetached(["nmcli", "connection", "down", "id", activeProfile.name]);
        else {
            const p = profiles.find(x => x.name === lastUsed) ?? profiles[0];
            if (!p) return;
            lastUsed = p.name;
            Quickshell.execDetached(["nmcli", "connection", "up", "id", p.name]);
        }
        settle.restart();
    }
    Timer { id: settle; interval: 2500; onTriggered: root.refresh() }

    Process {
        id: list
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    // NAME may contain escaped colons (\:), TYPE and ACTIVE never do
                    const m = /^(.*):(vpn|wireguard):(yes|no)$/.exec(line);
                    if (m) out.push({ name: m[1].replace(/\\:/g, ":"), type: m[2], active: m[3] === "yes" });
                }
                root.profiles = out;
            }
        }
    }
    // poll while the control center (the only place it is shown) is open, plus once at start
    Timer { interval: 8000; repeat: true; running: Globals.controlCenterOpen; triggeredOnStart: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    IpcHandler {
        target: "vpn"
        function toggle(): void { root.toggle(); }
        function status(): string {
            return root.available ? (root.activeProfile ? "connected " + root.activeProfile.name : "off") + " (" + root.profiles.length + " profiles)" : "no VPN profiles";
        }
    }
}
