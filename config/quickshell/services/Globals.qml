pragma Singleton
import Quickshell
import QtQuick

// Shared UI state and cross-component requests.
Singleton {
    property bool controlCenterOpen: false
    property bool powerMenuOpen: false
    property bool equalizerOpen: false
    property bool mixerOpen: false
    property bool sysmonOpen: false
    property bool dashboardOpen: false
    property bool settingsOpen: false
    property bool lyricsOpen: false
    property real lyricsAnchorX: -1   // screen x the lyrics viewer drops from (set by the chip)
    property bool keepAwake: false
    property bool locked: false
    property var wallWindows: []      // the Wallpaper window of each screen, for `qs ipc call shell wallState`

    // A bar sets this just before opening a popup, so the popup appears on the bar's own screen instead of
    // wherever focus happens to be. Cleared shortly after (see widgets/Overlay.qml for the consumer).
    property string popupScreen: ""
    function popupFrom(screenName: string): void {
        popupScreen = screenName ?? "";
        popupScreenClear.restart();
    }
    Timer { id: popupScreenClear; interval: 600; onTriggered: Globals.popupScreen = "" }

    signal lockRequested()

    // Lock first, then suspend once the lock surface is up.
    function suspend() {
        lockRequested();
        Quickshell.execDetached(["sh", "-c", "sleep 1; systemctl suspend"]);
    }
}
