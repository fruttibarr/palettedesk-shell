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
    // 0 = plain surface colour, 1 = the bar is drawn mostly in the accent colour
    readonly property real barVibrancy: Settings.s.barVibrancy
    readonly property color barColor: {
        const t = barVibrancy * 0.7, a = surface, b = primaryContainer;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, barOpacity);
    }
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

    // Per-monitor wallpapers: {"<monitor name>": "/path"} (scripts/set-wallpaper.sh --monitor). Kept apart from
    // colors.json because matugen rewrites that file on every change.
    property var walls: ({})
    function wallpaperFor(monitorName) { return (walls && walls[monitorName]) || wallpaper; }
    FileView {
        path: root.stateDir + "/walls.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.walls = JSON.parse(text()); } catch (e) { root.walls = ({}); } }
        onLoadFailed: root.walls = ({})
    }

    // ---- palette adjustments (Wallpaper & Colors → Shell palette): the matugen colours in `raw`, re-toned for the shell ----
    // Shell-only: other apps keep the matugen colours. All at their defaults = the colours pass through untouched.
    function validHex(v) { return /^#[0-9a-fA-F]{6}$/.test(String(v || "").trim()); }
    function tone(v) {
        const col = Qt.color(v), S = Settings.s;
        const sat = S.lookSaturation, lig = S.lookLightness, hs = S.lookHueShift, ta = S.lookTintAmount;
        if (sat === 1 && lig === 0 && hs === 0 && !(ta > 0 && validHex(S.lookTint))) return col;
        let h = col.hslHue, s = Math.min(1, col.hslSaturation * sat), l = Math.max(0, Math.min(1, col.hslLightness + lig));
        if (h >= 0) h = (((h * 360 + hs) % 360) + 360) % 360 / 360;
        let out = h >= 0 ? Qt.hsla(h, s, l, col.a) : Qt.hsla(0, 0, l, col.a);
        if (ta > 0 && validHex(S.lookTint)) {
            const t = Qt.color(S.lookTint);
            out = Qt.rgba(out.r + (t.r - out.r) * ta, out.g + (t.g - out.g) * ta, out.b + (t.b - out.b) * ta, out.a);
        }
        return out;
    }
    // custom accent colour: replaces the primary pair; everything else keeps following the wallpaper
    function accentOr(name, v) {
        const a = Settings.s.lookAccent;
        if (!validHex(a)) return tone(v);
        const base = Qt.color(a), h = Math.max(0, base.hslHue), light = Settings.s.colorMode === "light";
        switch (name) {
        case "primary": return base;
        case "primaryContainer": return Qt.hsla(h, base.hslSaturation * 0.7, light ? 0.88 : 0.28, 1);
        case "textOnPrimary": return base.hslLightness > 0.58 ? Qt.rgba(0.1, 0.1, 0.12, 1) : Qt.rgba(1, 1, 1, 1);
        default: return Qt.hsla(h, base.hslSaturation * 0.8, light ? 0.16 : 0.9, 1);   // textOnPrimaryContainer
        }
    }
    QtObject {
        id: c
        readonly property string wallpaper: raw.wallpaper
        readonly property string still: raw.still
        readonly property string base: raw.base
        readonly property color background: root.tone(raw.background)
        readonly property color surface: root.tone(raw.surface)
        readonly property color surfaceContainer: root.tone(raw.surfaceContainer)
        readonly property color surfaceContainerHigh: root.tone(raw.surfaceContainerHigh)
        readonly property color text: root.tone(raw.text)
        readonly property color subtext: root.tone(raw.subtext)
        readonly property color primary: root.accentOr("primary", raw.primary)
        readonly property color textOnPrimary: root.accentOr("textOnPrimary", raw.textOnPrimary)
        readonly property color secondary: root.tone(raw.secondary)
        readonly property color tertiary: root.tone(raw.tertiary)
        readonly property color outline: root.tone(raw.outline)
        readonly property color outlineVariant: root.tone(raw.outlineVariant)
        readonly property color error: root.tone(raw.error)
        readonly property color primaryContainer: root.accentOr("primaryContainer", raw.primaryContainer)
        readonly property color textOnPrimaryContainer: root.accentOr("textOnPrimaryContainer", raw.textOnPrimaryContainer)
        readonly property color secondaryContainer: root.tone(raw.secondaryContainer)
        readonly property color tertiaryContainer: root.tone(raw.tertiaryContainer)
    }

    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: raw
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
