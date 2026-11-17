import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import QtQuick

// Hot corners: park the pointer in a screen corner for a moment to run an action.
// Settings > Behavior > Hot corners. Each corner is a tiny transparent layer window.
Scope {
    id: root
    readonly property var corners: Settings.s.hotCorners ?? ({})

    // action id -> IPC call [target, function]
    readonly property var ipc: ({
        overview: ["overview", "toggle"], launcher: ["launcher", "toggle"], controlcenter: ["controlcenter", "toggle"],
        dashboard: ["dashboard", "toggle"], settings: ["settings", "toggle"], lock: ["lock", "lock"],
        cheatsheet: ["cheatsheet", "toggle"], clipboard: ["clipboard", "toggle"], power: ["power", "toggle"],
        wallpaper: ["wallpaper", "toggle"],
    })

    function run(corner) {
        const c = corners[corner] ?? {};
        if (c.action === "command") { if (c.command) Quickshell.execDetached(["sh", "-c", c.command]); }
        else if (c.action === "special") Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.workspace.toggle_special("magic")']);
        else if (c.action in ipc) Quickshell.execDetached(["qs", "ipc", "call", ipc[c.action][0], ipc[c.action][1]]);
    }

    // Skip while a fullscreen window is up (unless allowed): ask Hyprland just before firing.
    property string pending: ""
    function fire(corner) {
        if (Settings.s.hotCornersFullscreen) { run(corner); return; }
        pending = corner;
        fsCheck.running = false; fsCheck.running = true;
    }
    Process {
        id: fsCheck
        command: ["hyprctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                let fs = false;
                try { fs = !!JSON.parse(text).hasfullscreen; } catch (e) {}
                if (!fs && root.pending) root.run(root.pending);
                root.pending = "";
            }
        }
    }

    component Corner: PanelWindow {
        id: win
        required property string corner     // tl | tr | bl | br
        readonly property string action: root.corners[corner]?.action ?? "none"
        visible: Settings.s.hotCornersEnabled && action !== "none"
        anchors { top: corner[0] === "t"; bottom: corner[0] === "b"; left: corner[1] === "l"; right: corner[1] === "r" }
        implicitWidth: Settings.s.hotCornerSize
        implicitHeight: Settings.s.hotCornerSize
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rice-hotcorner"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Timer { id: dwell; interval: Settings.s.hotCornerDelay; onTriggered: root.fire(win.corner) }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: dwell.restart()
            onExited: dwell.stop()
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: perScreen
            required property ShellScreen modelData
            Corner { screen: perScreen.modelData; corner: "tl" }
            Corner { screen: perScreen.modelData; corner: "tr" }
            Corner { screen: perScreen.modelData; corner: "bl" }
            Corner { screen: perScreen.modelData; corner: "br" }
        }
    }

    IpcHandler {
        target: "hotcorners"
        function trigger(corner: string): void { root.run(corner); }   // tl | tr | bl | br
    }
}
