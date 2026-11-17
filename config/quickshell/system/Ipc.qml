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
}
