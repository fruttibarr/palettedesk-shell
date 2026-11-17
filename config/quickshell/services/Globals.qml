pragma Singleton
import Quickshell
import QtQuick

// Shared UI state and cross-component requests.
Singleton {
    property bool controlCenterOpen: false
    property bool powerMenuOpen: false
    property bool equalizerOpen: false
    property bool settingsOpen: false
    property bool lyricsOpen: false
    property real lyricsAnchorX: -1   // screen x the lyrics viewer drops from (set by the chip)
    property bool keepAwake: false
    property bool locked: false
    property var wallWindows: []      // the Wallpaper window of each screen, for `qs ipc call shell wallState`

    signal lockRequested()

    // Lock first, then suspend once the lock surface is up.
    function suspend() {
        lockRequested();
        Quickshell.execDetached(["sh", "-c", "sleep 1; systemctl suspend"]);
    }
}
