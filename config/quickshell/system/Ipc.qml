import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// IPC used by the hardware keys in hyprland.lua.
Scope {
    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.set(Brightness.value + 0.05); }
        function down(): void { Brightness.set(Brightness.value - 0.05); }
        function get(): real { return Brightness.value; }
    }

    IpcHandler {
        target: "media"
        function playpause(): void { Media.player?.togglePlaying(); }
        function next(): void { Media.player?.next(); }
        function prev(): void { Media.player?.previous(); }
    }

    // qs ipc call recorder toggle|start|stop [region|full|window]
    IpcHandler {
        target: "recorder"
        function toggle(mode: string): void { Recorder.toggle(mode); }
        function start(mode: string): void { Recorder.start(mode); }
        function stop(): void { Recorder.stop(); }
        function status(): string { return Recorder.active ? "recording " + Recorder.clock + " " + Recorder.file : "idle"; }
    }

    // qs ipc call shell wallState   (JSON: per screen, is the wallpaper animating, and if not, why)
    IpcHandler {
        target: "shell"
        function wallState(): string { return JSON.stringify(Globals.wallWindows.map(w => w.state())); }
        // qs ipc call shell popupOn <screen>   (the next popup opens on that screen; for keybinds and tests)
        function popupOn(screen: string): void { Globals.popupFrom(screen); }
        function popupScreen(): string { return Globals.popupScreen; }
    }

    // qs ipc call shader set <name> | off | cycle | list     (full-screen effect, see Settings > Blur)
    IpcHandler {
        target: "shader"
        function set(name: string): string {
            const ok = Settings.shaderList.some(x => x.id === name);
            if (!ok) return "unknown shader: " + name;
            Settings.set("screenShader", name);
            return "ok";
        }
        function off(): void { Settings.set("screenShader", ""); }
        function cycle(): string {
            const l = Settings.shaderList;
            const i = l.findIndex(x => x.id === Settings.s.screenShader);
            const next = l[(i + 1) % l.length];
            Settings.set("screenShader", next.id);
            return next.id || "none";
        }
        function list(): string { return Settings.shaderList.map(x => x.id || "none").join(" "); }
    }
}
