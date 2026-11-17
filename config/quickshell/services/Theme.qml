pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Colors come from ~/.local/state/rice/colors.json, written by matugen
// whenever the wallpaper changes. Values below are fallbacks for first run.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/rice"
    readonly property string font: Settings.s.fontFamily || "JetBrainsMono Nerd Font"
    // multiplier for shell popup animation durations (Appearance page)
    readonly property real anim: Math.max(0.1, Settings.s.shellAnimScale)
    // per-popup multipliers on top of `anim` (Appearance → Popup motion)
    readonly property real animLauncher: anim * Math.max(0.1, Settings.s.animLauncher)
    readonly property real animControlCenter: anim * Math.max(0.1, Settings.s.animControlCenter)
    readonly property real animNotifs: anim * Math.max(0.1, Settings.s.animNotifs)
    readonly property real animPopups: anim * Math.max(0.1, Settings.s.animPopups)
    readonly property int fontSize: Settings.s.fontSize
    readonly property int radius: Settings.s.shellRadius

    readonly property string wallpaper: c.wallpaper
    // a still frame (same as wallpaper for images) for lock screen, previews
    readonly property string wallpaperStill: c.still || c.wallpaper
    // while an album cover is the wallpaper (system/AlbumWall.qml): the one it replaced
    readonly property string baseWallpaper: c.base || c.wallpaper
    readonly property bool albumActive: c.base !== "" && c.base !== c.wallpaper
    readonly property color background: c.background
    readonly property color surface: c.surface
    readonly property color surfaceContainer: c.surfaceContainer
    readonly property color surfaceContainerHigh: c.surfaceContainerHigh
    readonly property color text: c.text
    readonly property color subtext: c.subtext
    readonly property color primary: c.primary
    readonly property color textOnPrimary: c.textOnPrimary
    readonly property color secondary: c.secondary
    readonly property color tertiary: c.tertiary
    readonly property color outline: c.outline
    readonly property color outlineVariant: c.outlineVariant
    readonly property color error: c.error
    readonly property color primaryContainer: c.primaryContainer
    readonly property color textOnPrimaryContainer: c.textOnPrimaryContainer
    readonly property color secondaryContainer: c.secondaryContainer
    readonly property color tertiaryContainer: c.tertiaryContainer

    // Bar glass: how opaque the bar background is (0 = invisible, 1 = solid)
    readonly property real barOpacity: Settings.s.barOpacity
    readonly property real panelOpacity: Settings.s.panelOpacity

    function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a); }

    // ---- bar geometry (popups use these to position themselves) ----
    readonly property bool barTop: Settings.s.barPosition !== "bottom"
    readonly property bool barAttached: Settings.s.barStyle === "attached"
    readonly property bool barIslands: Settings.s.barStyle === "islands"
    readonly property int barHeight: Settings.s.barHeight
    readonly property int barMarginPx: barAttached ? 0 : (Settings.s.barFollowGaps ? Settings.s.gapsOut : Settings.s.barMargin)
    // distance from the bar's screen edge to just past the bar
    readonly property int barReserved: barMarginPx + barHeight + 8

    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: c
            property string wallpaper: ""
            property string still: ""
            property string base: ""
            property string background: "#141318"
            property string surface: "#141318"
            property string surfaceContainer: "#201f24"
            property string surfaceContainerHigh: "#2b292f"
            property string text: "#e6e1e9"
            property string subtext: "#cac4cf"
            property string primary: "#cebdfe"
            property string textOnPrimary: "#35275e"
            property string secondary: "#cbc3dc"
            property string tertiary: "#f0b8c5"
            property string outline: "#948f99"
            property string outlineVariant: "#49454e"
            property string error: "#ffb4ab"
            property string primaryContainer: "#4c3e76"
            property string textOnPrimaryContainer: "#e8ddff"
            property string secondaryContainer: "#4a4458"
            property string tertiaryContainer: "#633b48"
        }
    }
}
