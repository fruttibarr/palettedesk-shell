import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.widgets
import QtQuick

// Active keyboard layout (e.g. "US"); click to switch to the next one. Only shown with several layouts
// configured (Settings > Input > Layout, e.g. "us,de").
Chip {
    id: chip
    property string layoutName: ""
    visible: String(Settings.s.kbLayout).includes(",")
    clickable: true
    onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])

    function short(name) {
        const m = /\(([^)]+)\)/.exec(name);               // "English (US)" -> "US"
        return (m ? m[1] : name).slice(0, 3).toUpperCase();
    }
    Process {
        running: true
        command: ["sh", "-c", "hyprctl devices -j | python3 -c \"import json,sys; k=json.load(sys.stdin)['keyboards']; m=[x for x in k if x.get('main')] or k; print(m[0]['active_keymap'] if m else '')\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) chip.layoutName = text.trim() }
    }
    Connections {
        target: Hyprland
        function onRawEvent(ev) { if (ev.name === "activelayout") chip.layoutName = ev.parse(2)[1] ?? chip.layoutName; }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰌌 " + chip.short(chip.layoutName)
        color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
    }
}
