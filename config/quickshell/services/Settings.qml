pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// All rice settings. Saved to ~/.config/rice/settings.json.
// Hyprland options are written to ~/.config/hypr/rice-settings.lua (loaded
// at the end of hyprland.lua) and applied live with `hyprctl eval`.
// (Generated from a spec list: keep defaults and JsonAdapter in sync.)
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string luaPath: home + "/.config/hypr/rice-settings.lua"
    property alias s: adapter

    readonly property var defaults: ({
            "barOpacity": 0.35,
            "barVibrancy": 0,
            "panelOpacity": 0.5,
            "shellRadius": 12,
            "fontSize": 13,
            "terminalOpacity": 0.72,
            "colorScheme": "scheme-tonal-spot",
            "blurEnabled": true,
            "blurSize": 9,
            "blurPasses": 4,
            "blurBrightness": 0.9,
            "blurVibrancy": 0.25,
            "blurNoise": 0.015,
            "blurPopups": true,
            "blurXray": false,
            "layout": "dwindle",
            "gapsIn": 5,
            "gapsOut": 10,
            "borderSize": 2,
            "rounding": 12,
            "activeOpacity": 1.0,
            "inactiveOpacity": 1.0,
            "dimInactive": false,
            "dimStrength": 0.15,
            "shadowEnabled": true,
            "shadowRange": 18,
            "animationsEnabled": true,
            "rotatingBorder": true,
            "showMedia": true,
            "showStats": true,
            "showTray": true,
            "clock24h": true,
            "showDate": true,
            "kbLayout": "us",
            "kbOptions": "",
            "followMouse": 1,
            "sensitivity": 0.0,
            "naturalScroll": false,
            "tapToClick": true,
            "disableWhileTyping": true,
            "scrollFactor": 1.0,
            "dimAfter": 4,
            "lockAfter": 5,
            "screenOffAfter": 6,
            "suspendAfter": 15,
            "suspendOnBatteryOnly": true,
            "notifTimeout": 5,
        "drawTerminal": true,
        "drawTerminalCommand": "kitty",
        "barPosition": "top",
        "barStyle": "floating",
        "barHeight": 38,
        "barFollowGaps": true,
        "barMargin": 10,
        "barBorder": true,
        "barShadow": true,
        "barSheen": true,
        "chipStyle": "filled",
        "chipShape": "pill",
        "barLayout": {"left": ["workspaces", "media"], "center": ["clock"], "right": ["tray", "stats", "status"]},
        "wsCount": 5,
        "wsStyle": "numbers",
        "wsShowEmpty": true,
        "wsOpacity": 0.6,
        "wsActiveOpacity": 1.0,
        "clockSeconds": false,
        "dateFormat": "short",
        "clockIcon": true,
        "statusBell": true,
        "statusNetwork": true,
        "statusBluetooth": true,
        "statusVolume": true,
        "statusBattery": true,
        "statusPercent": true,
        "statsStyle": "rings",
        "mediaMaxWidth": 200,
        "mediaBars": true,
        "lyricsMaxWidth": 220,
        "lyricsOffset": 0,
        "titleMaxWidth": 260,
        "parallaxEnabled": true,
        "wallCrispPixels": true,
        "parallaxStrength": 0.12,
        "animatedWallpapers": true,
        "watchdogRssMb": 1500,
        "monitors": "{}",
        "windowRules": "[]",
        "workspaceRules": "[]",
        "autostart": "[]",
        "appThemes": "[]",
        "screenShader": "",
        "weatherEnabled": false,
        "weatherLat": 0,
        "weatherLon": 0,
        "weatherPlace": "",
        "weatherUnit": "metric",
        "nightLight": false,
        "nightTemp": 4000,
        "pauseOnBattery": false,
        "pauseWhenFullscreen": true,
        "albumWallpaper": false,
        "albumWallStyle": "cover",
        "albumWallKeepPaused": true,
        "albumVisualizer": false,
        "albumVizStyle": "bars",
        "albumVizColor": "gradient",
        "albumVizBars": 48,
        "albumVizOpacity": 0.75,
        "albumVizHeight": 0.28,
        "roundingPower": 2.0,
        "fullscreenOpacity": 1.0,
        "dimSpecial": 0.2,
        "shadowRenderPower": 3,
        "shadowOffsetY": 4,
        "resizeOnBorder": false,
        "borderGrabArea": 15,
        "snapEnabled": false,
        "snapGap": 10,
        "groupbarEnabled": true,
        "blurContrast": 1.0,
        "blurVibrancyDarkness": 0.2,
        "blurSpecial": true,
        "dwindlePreserveSplit": true,
        "dwindleSmartSplit": false,
        "dwindleForceSplit": 0,
        "dwindleSmartResizing": true,
        "masterNewStatus": "master",
        "masterMfact": 0.55,
        "masterOrientation": "left",
        "masterNewOnTop": false,
        "scrollColumnWidth": 0.5,
        "scrollFullscreenOne": true,
        "animScale": 1.0,
        "windowAnimStyle": "popin 80%",
        "wsAnimStyle": "slidefade 12%",
        "borderRotateSpeed": 80,
        "animateResizes": false,
        "animateDrag": false,
        "repeatRate": 25,
        "repeatDelay": 600,
        "numlockOn": false,
        "accelProfile": "adaptive",
        "leftHanded": false,
        "mouseNaturalScroll": false,
        "clickfinger": false,
        "middleEmulation": false,
        "tapAndDrag": true,
        "swipeDistance": 300,
        "swipeInvert": true,
        "swipeForever": false,
        "swipeCreateNew": true,
        "swipeCancelRatio": 0.5,
        "cursorHideAfter": 0,
        "cursorHideOnKey": false,
        "cursorNoWarps": false,
        "cursorWarpOnWs": false,
        "cursorZoom": 1.0,
        "focusOnActivate": false,
        "middleClickPaste": true,
        "enableSwallow": false,
        "swallowRegex": "^(kitty)$",
        "closeSpecialOnEmpty": true,
        "hideSpecialOnWsChange": false,
        "wsBackAndForth": false,
        "allowWsCycles": false,
        "onFocusUnderFullscreen": 2,
        "exitRetainsFullscreen": false,
        "mouseWakes": false,
        "keyWakes": false,
        "vrr": 0,
        "directScanout": 0,
        "xwaylandZeroScaling": false,
        "fontFamily": "JetBrainsMono Nerd Font",
        "popupZoom": true,
        "shellAnimScale": 1.0,
        "animLauncher": 1.0,
        "animControlCenter": 1.0,
        "animNotifs": 1.0,
        "animPopups": 1.0,
        "animWinIn": 1.0,
        "animWinOut": 1.0,
        "animWinMove": 1.0,
        "animFade": 1.0,
        "animWorkspaces": 1.0,
        "notifPosition": "right",
        "notifMaxPopups": 5,
        "notifWidth": 380,
        "osdEnabled": true,
        "osdPosition": "bottom",
        "osdTimeout": 1.5,
        "lockBlur": true,
        "lockDim": 0.18,
        "lockSeconds": false,
        "lockShowDate": true,
        "monitorScale": 1.25,
        "launcherWidth": 740,
        "launcherHeight": 600,
        "launcherPosition": "upper",
        "launcherDockFlares": true,
        "recMode": "region",
        "recFormat": "mp4",
        "recFps": 30,
        "recQuality": "medium",
        "recEncoder": "software",
        "recAudio": "none",
        "recDir": "~/Videos/Recordings",
        "recCountdown": 3,
        "recNotify": true,
        "recCopyPath": false,
        "launcherDefaultView": "grid",
        "launcherIconSize": 46,
        "launcherShowFrequent": true,
        "launcherFrequentCount": 6,
        "launcherShowCategories": true,
        "launcherShowFooter": true,
        "launcherShowCount": true,
        "launcherShowDesc": true,
        "launcherShowActions": true,
        "launcherHints": true,
        "launcherOrbs": true,
        "launcherOrbStrength": 0.32,
        "launcherPulse": true,
        "launcherStagger": true,
        "launcherLaunchAnim": true,
        "launcherRankByUsage": true,
        "launcherMaxResults": 40,
        "launcherCalc": true,
        "launcherRun": true,
        "launcherWeb": true,
        "launcherWebEngine": "duckduckgo",
        "launcherTerminal": "kitty --hold",
        "launcherHidden": "",
        "middleAsRight": false,
        "infiniteDesktop": false,
        "infiniteFloat": true,
        "keybinds": "{}"
    })

    // full-screen shaders shipped in config/hypr/shaders (id = file name without .frag)
    readonly property var shaderList: [
        { id: "", label: "None" }, { id: "grayscale", label: "Grayscale" }, { id: "sepia", label: "Sepia" },
        { id: "vibrant", label: "Vibrant" }, { id: "crt", label: "Retro CRT" }, { id: "invert", label: "Invert" },
        { id: "colorblind", label: "Color-blind aid" }
    ]

    // setting key -> Hyprland option path
    readonly property var hyprMap: ({
            "blurEnabled": "decoration.blur.enabled",
            "blurSize": "decoration.blur.size",
            "blurPasses": "decoration.blur.passes",
            "blurBrightness": "decoration.blur.brightness",
            "blurVibrancy": "decoration.blur.vibrancy",
            "blurNoise": "decoration.blur.noise",
            "blurPopups": "decoration.blur.popups",
            "blurXray": "decoration.blur.xray",
            "layout": "general.layout",
            "gapsIn": "general.gaps_in",
            "gapsOut": "general.gaps_out",
            "borderSize": "general.border_size",
            "rounding": "decoration.rounding",
            "activeOpacity": "decoration.active_opacity",
            "inactiveOpacity": "decoration.inactive_opacity",
            "dimInactive": "decoration.dim_inactive",
            "dimStrength": "decoration.dim_strength",
            "shadowEnabled": "decoration.shadow.enabled",
            "shadowRange": "decoration.shadow.range",
            "animationsEnabled": "animations.enabled",
            "kbLayout": "input.kb_layout",
            "kbOptions": "input.kb_options",
            "followMouse": "input.follow_mouse",
            "sensitivity": "input.sensitivity",
            "naturalScroll": "input.touchpad.natural_scroll",
            "tapToClick": "input.touchpad.tap_to_click",
            "disableWhileTyping": "input.touchpad.disable_while_typing",
            "scrollFactor": "input.touchpad.scroll_factor",
            "roundingPower": "decoration.rounding_power",
            "fullscreenOpacity": "decoration.fullscreen_opacity",
            "dimSpecial": "decoration.dim_special",
            "shadowRenderPower": "decoration.shadow.render_power",
            "shadowOffsetY": "decoration.shadow.offset",
            "resizeOnBorder": "general.resize_on_border",
            "borderGrabArea": "general.extend_border_grab_area",
            "snapEnabled": "general.snap.enabled",
            "snapGap": "general.snap.window_gap",
            "groupbarEnabled": "group.groupbar.enabled",
            "blurContrast": "decoration.blur.contrast",
            "blurVibrancyDarkness": "decoration.blur.vibrancy_darkness",
            "blurSpecial": "decoration.blur.special",
            "dwindlePreserveSplit": "dwindle.preserve_split",
            "dwindleSmartSplit": "dwindle.smart_split",
            "dwindleForceSplit": "dwindle.force_split",
            "dwindleSmartResizing": "dwindle.smart_resizing",
            "masterNewStatus": "master.new_status",
            "masterMfact": "master.mfact",
            "masterOrientation": "master.orientation",
            "masterNewOnTop": "master.new_on_top",
            "scrollColumnWidth": "scrolling.column_width",
            "scrollFullscreenOne": "scrolling.fullscreen_on_one_column",
            "animateResizes": "misc.animate_manual_resizes",
            "animateDrag": "misc.animate_mouse_windowdragging",
            "repeatRate": "input.repeat_rate",
            "repeatDelay": "input.repeat_delay",
            "numlockOn": "input.numlock_by_default",
            "accelProfile": "input.accel_profile",
            "leftHanded": "input.left_handed",
            "mouseNaturalScroll": "input.natural_scroll",
            "clickfinger": "input.touchpad.clickfinger_behavior",
            "middleEmulation": "input.touchpad.middle_button_emulation",
            "tapAndDrag": "input.touchpad.tap_and_drag",
            "swipeDistance": "gestures.workspace_swipe_distance",
            "swipeInvert": "gestures.workspace_swipe_invert",
            "swipeForever": "gestures.workspace_swipe_forever",
            "swipeCreateNew": "gestures.workspace_swipe_create_new",
            "swipeCancelRatio": "gestures.workspace_swipe_cancel_ratio",
            "cursorHideAfter": "cursor.inactive_timeout",
            "cursorHideOnKey": "cursor.hide_on_key_press",
            "cursorNoWarps": "cursor.no_warps",
            "cursorWarpOnWs": "cursor.warp_on_change_workspace",
            "cursorZoom": "cursor.zoom_factor",
            "focusOnActivate": "misc.focus_on_activate",
            "middleClickPaste": "misc.middle_click_paste",
            "enableSwallow": "misc.enable_swallow",
            "swallowRegex": "misc.swallow_regex",
            "closeSpecialOnEmpty": "misc.close_special_on_empty",
            "hideSpecialOnWsChange": "binds.hide_special_on_workspace_change",
            "wsBackAndForth": "binds.workspace_back_and_forth",
            "allowWsCycles": "binds.allow_workspace_cycles",
            "onFocusUnderFullscreen": "misc.on_focus_under_fullscreen",
            "exitRetainsFullscreen": "misc.exit_window_retains_fullscreen",
            "mouseWakes": "misc.mouse_move_enables_dpms",
            "keyWakes": "misc.key_press_enables_dpms",
            "vrr": "misc.vrr",
            "directScanout": "render.direct_scanout",
            "screenShader": "decoration.screen_shader",
            "xwaylandZeroScaling": "xwayland.force_zero_scaling"
    })

    // keys that aren't plain options but still regenerate the Lua file
    readonly property var hyprExtraKeys: ["rotatingBorder", "animScale", "windowAnimStyle", "wsAnimStyle", "borderRotateSpeed", "animWinIn", "animWinOut", "animWinMove", "animFade", "animWorkspaces", "monitorScale", "middleAsRight", "infiniteDesktop", "infiniteFloat", "keybinds", "monitors", "windowRules", "workspaceRules", "autostart"]

    // settings stored as bool/number that Hyprland wants in another shape
    readonly property var hyprTransform: ({
            "shadowOffsetY": v => "0 " + Math.round(v),
            "screenShader": v => v ? home + "/.config/hypr/shaders/" + String(v).replace(/[^A-Za-z0-9_-]/g, "") + ".frag" : "",
            "wsBackAndForth": v => v ? 1 : 0,
            "cursorWarpOnWs": v => v ? 1 : 0,
            "exitRetainsFullscreen": v => v ? 1 : 0,
            "accelProfile": v => v === "flat" ? "flat" : "adaptive"
    })
    // one setting that drives several options
    readonly property var hyprAlso: ({
            "snapGap": ["general.snap.monitor_gap"]
    })

    function set(key, value) {
        if (adapter[key] === value) return;
        adapter[key] = value;
        saveTimer.restart();
        if (key in hyprMap || hyprExtraKeys.includes(key)) hyprTimer.restart();
        if (key === "terminalOpacity") kittyTimer.restart();
        if (key === "infiniteDesktop" && !value)
            Quickshell.execDetached(["python3", "-I", Quickshell.shellDir + "/scripts/infinite-pan.py", "retile"]);
        if (key === "colorScheme") {
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/set-wallpaper.sh", Theme.wallpaper, value]);
        }
    }

    // Apply a whole theme at once (see Presets.qml): many settings plus a wallpaper,
    // with a single re-theme instead of one per key.
    // Opt-in colour files for other apps (btop, VS Code, ...): scripts/app-themes.sh renders only the enabled ones.
    function appThemeOn(n) { try { return JSON.parse(adapter.appThemes).includes(n); } catch (e) { return false; } }
    function setAppTheme(n, on) {
        let l; try { l = JSON.parse(adapter.appThemes); } catch (e) { l = []; }
        l = l.filter(x => x !== n); if (on) l.push(n);
        adapter.appThemes = JSON.stringify(l); saveTimer.restart();
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/app-themes.sh"]);
    }
    function applyLook(values, wallpaper) {
        let hypr = false, kitty = false;
        for (const k in values) {
            if (!(k in defaults) || JSON.stringify(adapter[k]) === JSON.stringify(values[k])) continue;
            adapter[k] = JSON.parse(JSON.stringify(values[k]));
            if (k in hyprMap || hyprExtraKeys.includes(k)) hypr = true;
            if (k === "terminalOpacity") kitty = true;
        }
        saveTimer.restart();
        if (hypr) hyprTimer.restart();
        if (kitty) kittyTimer.restart();
        // a theme whose wallpaper file is gone keeps the current wallpaper
        Quickshell.execDetached(["sh", "-c", '[ -f "$1" ] || set -- "$3" "$2"; exec "$0" "$1" "$2"',
            Quickshell.shellDir + "/scripts/set-wallpaper.sh", wallpaper || Theme.wallpaper, adapter.colorScheme, Theme.wallpaper]);
    }

    function reset(keys) {
        for (const k of keys) set(k, defaults[k]);
    }

    // ---- Hyprland Lua generation ----
    function luaValue(v) {
        if (typeof v === "boolean") return v ? "true" : "false";
        if (typeof v === "number") return String(Number(v.toFixed(4)));
        // proper Lua string literal: escape \ and ", drop control characters
        return '"' + String(v).replace(/[\x00-\x1f\x7f]/g, "").replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }

    function luaTable(obj, indent) {
        const pad = "    ".repeat(indent);
        const lines = Object.keys(obj).map(k => {
            const v = obj[k];
            const val = typeof v === "object" ? luaTable(v, indent + 1) : luaValue(v);
            return `${pad}    ${k} = ${val},`;
        });
        return "{\n" + lines.join("\n") + "\n" + pad + "}";
    }

    function generateLua() {
        const tree = {};
        for (const key in hyprMap) {
            const value = key in hyprTransform ? hyprTransform[key](adapter[key]) : adapter[key];
            for (const path of [hyprMap[key], ...(hyprAlso[key] ?? [])]) {
                const parts = path.split(".");
                let node = tree;
                for (let i = 0; i < parts.length - 1; i++) node = node[parts[i]] = node[parts[i]] || {};
                node[parts[parts.length - 1]] = value;
            }
        }
        return "-- Generated by the Quickshell settings panel (SUPER+, or control center gear).\n"
             + "-- Edits here are overwritten; change settings in the panel instead.\n\n"
             + "hl.config(" + luaTable(tree, 0) + ")\n\n"
             + `hl.animation({ leaf = "borderangle", enabled = ${adapter.rotatingBorder}, speed = ${Math.max(1, Math.min(100, Math.round(adapter.borderRotateSpeed)))}, bezier = "linear", style = "loop" })\n`
             + animationLua()
             + monitorLua()
             + rulesLua()
             + middleClickLua()
             + infiniteLua()
             + keybindLua();
    }

    // Middle button sends a right click through ydotool (Input page).
    // Unbind first so re-applying never stacks duplicate binds.
    function middleClickLua() {
        let out = '\n-- middle click acts as right click (Input page)\npcall(hl.unbind, "mouse:274")\n';
        if (adapter.middleAsRight && !adapter.infiniteDesktop)
            out += 'hl.bind("mouse:274", hl.dsp.exec_cmd("ydotool click 0x41"))\n'
                 + 'hl.bind("mouse:274", hl.dsp.exec_cmd("ydotool click 0x81"), { release = true })\n';
        return out;
    }

    // Infinite desktop (Input page): hold the middle button and drag to pan every
    // floating window (scripts/infinite-pan.py). Takes over mouse:274.
    function infiniteLua() {
        const py = "python3 -I ~/.config/quickshell/scripts/infinite-pan.py ";
        let out = '\n-- infinite desktop (Input page)\n';
        if (adapter.infiniteDesktop)
            out += 'pcall(hl.unbind, "mouse:274")\n'
                 + `hl.bind("mouse:274", hl.dsp.exec_cmd("${py}start"))\n`
                 + `hl.bind("mouse:274", hl.dsp.exec_cmd("${py}stop"), { release = true })\n`;
        // ThinkPad trackpoints turn "middle held + move" into scrolling and swallow the button
        const sm = adapter.infiniteDesktop ? "no_scroll" : "on_button_down";
        for (const n of ["tpps/2-elan-trackpoint", "tpps/2-ibm-trackpoint", "tpps/2-synaptics-trackpoint", "trackpoint"])
            out += `pcall(hl.device, { name = "${n}", scroll_method = "${sm}" })\n`;
        const floatOn = adapter.infiniteDesktop && adapter.infiniteFloat;
        out += `if _G.rice_inf_rule then _G.rice_inf_rule:set_enabled(${floatOn}) else _G.rice_inf_rule = hl.window_rule({ name = "rice-infinite-float", match = { class = ".*" }, float = true, enabled = ${floatOn} }) end\n`;
        return out;
    }

    // ---- Keybinds (Keybinds page) ----
    // Rebindable actions. `def` must match the bind in hyprland.lua; `lua` is the
    // Hyprland action expression; `opts` an optional Lua options table.
    readonly property var bindActions: [
        { id: "terminal",      group: "Apps", label: "Terminal",                    def: "SUPER + RETURN",       lua: 'hl.dsp.exec_cmd("kitty")' },
        { id: "terminal2",     group: "Apps", label: "Terminal (second key)",       def: "SUPER + T",            lua: 'hl.dsp.exec_cmd("kitty")' },
        { id: "drawTerminal",  group: "Apps", label: "Draw a terminal",             def: "SUPER + SHIFT + RETURN", lua: 'hl.dsp.exec_cmd("qs ipc call termdraw arm")' },
        { id: "files",         group: "Apps", label: "File manager",                def: "SUPER + E",            lua: 'hl.dsp.exec_cmd("thunar")' },
        { id: "launcher",      group: "Apps", label: "App launcher",                def: "SUPER + SPACE",        lua: 'hl.dsp.exec_cmd("qs ipc call launcher toggle")' },
        { id: "launcher2",     group: "Apps", label: "App launcher (second key)",   def: "SUPER + D",            lua: 'hl.dsp.exec_cmd("qs ipc call launcher toggle")' },
        { id: "launcher3",     group: "Apps", label: "App launcher (third key)",    def: "SUPER + R",            lua: 'hl.dsp.exec_cmd("qs ipc call launcher toggle")' },

        { id: "wallpaper",     group: "Shell", label: "Wallpaper picker",           def: "SUPER + W",            lua: 'hl.dsp.exec_cmd("qs ipc call wallpaper toggle")' },
        { id: "randomWall",    group: "Shell", label: "Random wallpaper",           def: "SUPER + SHIFT + W",    lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/set-wallpaper.sh")' },
        { id: "controlCenter", group: "Shell", label: "Control center",             def: "SUPER + A",            lua: 'hl.dsp.exec_cmd("qs ipc call controlcenter toggle")' },
        { id: "equalizer",     group: "Shell", label: "Equalizer",                  def: "SUPER + SHIFT + A",    lua: 'hl.dsp.exec_cmd("qs ipc call equalizer toggle")' },
        { id: "settings",      group: "Shell", label: "Settings",                   def: "SUPER + COMMA",        lua: 'hl.dsp.exec_cmd("qs ipc call settings toggle")' },
        { id: "clipboard",     group: "Shell", label: "Clipboard history",          def: "SUPER + V",            lua: 'hl.dsp.exec_cmd("qs ipc call clipboard toggle")' },
        { id: "lock",          group: "Shell", label: "Lock screen",                def: "SUPER + L",            lua: 'hl.dsp.exec_cmd("qs ipc call lock lock")' },
        { id: "power",         group: "Shell", label: "Power menu",                 def: "SUPER + SHIFT + E",    lua: 'hl.dsp.exec_cmd("qs ipc call power toggle")' },

        { id: "close",         group: "Windows", label: "Close window",             def: "SUPER + Q",            lua: 'hl.dsp.window.close()' },
        { id: "switcher",      group: "Windows", label: "Switch windows (Alt-Tab)",         def: "ALT + Tab",            lua: 'hl.dsp.exec_cmd("qs ipc call switcher next")' },
        { id: "switcherPrev",  group: "Windows", label: "Switch windows backwards",         def: "ALT + SHIFT + Tab",    lua: 'hl.dsp.exec_cmd("qs ipc call switcher prev")' },
        { id: "overview",      group: "Windows", label: "Workspace overview",               def: "SUPER + Tab",          lua: 'hl.dsp.exec_cmd("qs ipc call overview toggle")' },
        { id: "fullscreen",    group: "Windows", label: "Fullscreen",               def: "SUPER + F",            lua: 'hl.dsp.window.fullscreen()' },
        { id: "float",         group: "Windows", label: "Toggle floating",          def: "SUPER + SHIFT + V",    lua: 'hl.dsp.window.float({ action = "toggle" })' },
        { id: "zoomOut",       group: "Windows", label: "Infinite desktop: zoom out",   def: "SUPER + MINUS",  lua: 'hl.dsp.exec_cmd("python3 -I ~/.config/quickshell/scripts/infinite-pan.py zoomout")' },
        { id: "zoomIn",        group: "Windows", label: "Infinite desktop: zoom in",    def: "SUPER + EQUAL",  lua: 'hl.dsp.exec_cmd("python3 -I ~/.config/quickshell/scripts/infinite-pan.py zoomin")' },
        { id: "panHome",       group: "Windows", label: "Infinite desktop: back to origin", def: "SUPER + HOME", lua: 'hl.dsp.exec_cmd("python3 -I ~/.config/quickshell/scripts/infinite-pan.py home")' },
        { id: "pseudo",        group: "Windows", label: "Pseudo-tile",              def: "SUPER + P",            lua: 'hl.dsp.window.pseudo()' },
        { id: "split",         group: "Windows", label: "Toggle split (dwindle)",   def: "SUPER + J",            lua: 'hl.dsp.layout("togglesplit")' },
        { id: "special",       group: "Windows", label: "Show scratchpad",          def: "SUPER + S",            lua: 'hl.dsp.workspace.toggle_special("magic")' },
        { id: "toSpecial",     group: "Windows", label: "Send window to scratchpad", def: "SUPER + SHIFT + S",   lua: 'hl.dsp.window.move({ workspace = "special:magic" })' },

        { id: "focusLeft",     group: "Focus & move", label: "Focus left",          def: "SUPER + left",         lua: 'hl.dsp.focus({ direction = "left" })' },
        { id: "focusRight",    group: "Focus & move", label: "Focus right",         def: "SUPER + right",        lua: 'hl.dsp.focus({ direction = "right" })' },
        { id: "focusUp",       group: "Focus & move", label: "Focus up",            def: "SUPER + up",           lua: 'hl.dsp.focus({ direction = "up" })' },
        { id: "focusDown",     group: "Focus & move", label: "Focus down",          def: "SUPER + down",         lua: 'hl.dsp.focus({ direction = "down" })' },
        { id: "moveLeft",      group: "Focus & move", label: "Move window left",    def: "SUPER + SHIFT + left", lua: 'hl.dsp.window.move({ direction = "left" })' },
        { id: "moveRight",     group: "Focus & move", label: "Move window right",   def: "SUPER + SHIFT + right", lua: 'hl.dsp.window.move({ direction = "right" })' },
        { id: "moveUp",        group: "Focus & move", label: "Move window up",      def: "SUPER + SHIFT + up",   lua: 'hl.dsp.window.move({ direction = "up" })' },
        { id: "moveDown",      group: "Focus & move", label: "Move window down",    def: "SUPER + SHIFT + down", lua: 'hl.dsp.window.move({ direction = "down" })' },

        { id: "shotRegion",    group: "Screenshots", label: "Screenshot a region",  def: "Print",                lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenshot.sh region")' },
        { id: "shotFull",      group: "Screenshots", label: "Screenshot the screen", def: "SHIFT + Print",       lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenshot.sh full")' },
        { id: "shotEdit",      group: "Screenshots", label: "Screenshot and annotate", def: "ALT + Print",       lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenshot.sh edit")' },
        { id: "colorPick",     group: "Screenshots", label: "Pick a color",        def: "SUPER + SHIFT + C",    lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/colorpick.sh")' },
        { id: "ocr",           group: "Screenshots", label: "Copy text from the screen", def: "SUPER + SHIFT + O", lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/ocr.sh")' },
        { id: "shotWindow",    group: "Screenshots", label: "Screenshot a window",  def: "SUPER + Print",        lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenshot.sh window")' },

        { id: "recToggle",     group: "Screen recording", label: "Start / stop recording",       def: "CTRL + Print",   lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenrec.sh toggle")' },
        { id: "recRegion",     group: "Screen recording", label: "Record a region",              def: "CTRL + ALT + Print", lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenrec.sh toggle region")' },
        { id: "recFull",       group: "Screen recording", label: "Record the whole screen",      def: "CTRL + SHIFT + Print", lua: 'hl.dsp.exec_cmd("~/.config/quickshell/scripts/screenrec.sh toggle full")' }
    ]
    // Binds in hyprland.lua that the page doesn't edit (shown for conflicts)
    readonly property var fixedBinds: {
        const out = [];
        for (let i = 1; i <= 10; i++) {
            out.push({ combo: "SUPER + " + (i % 10), label: "Go to workspace " + i });
            out.push({ combo: "SUPER + SHIFT + " + (i % 10), label: "Move window to workspace " + i });
        }
        return out;
    }
    readonly property var bindOverrides: { try { return JSON.parse(adapter.keybinds) || {}; } catch (e) { return {}; } }
    function bindFor(id) {
        const a = bindActions.find(x => x.id === id);
        return id in bindOverrides ? bindOverrides[id] : (a ? a.def : "");
    }
    function setBind(id, combo) {
        const o = Object.assign({}, bindOverrides);
        const a = bindActions.find(x => x.id === id);
        if (a && normCombo(combo) === normCombo(a.def)) delete o[id]; else o[id] = combo;
        set("keybinds", JSON.stringify(o));
    }
    function resetBinds() { set("keybinds", "{}"); }
    // Canonical form for comparing combos: modifiers in fixed order, case-insensitive key
    function normCombo(c) {
        const parts = String(c).split("+").map(x => x.trim()).filter(x => x);
        if (!parts.length) return "";
        const key = parts.pop().toUpperCase();
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const mods = order.filter(m => parts.some(p => p.toUpperCase() === m || (m === "CTRL" && p.toUpperCase() === "CONTROL")));
        return mods.concat([key]).join(" + ");
    }
    // Other actions using the same combo as `id` would
    function bindConflicts(id, combo) {
        const n = normCombo(combo);
        if (!n) return [];
        return bindActions.filter(a => a.id !== id && normCombo(bindFor(a.id)) === n).map(a => a.label)
               .concat(fixedBinds.filter(f => normCombo(f.combo) === n).map(f => f.label));
    }

    // Unbind every combo we might own (defaults, current, and what we bound last time),
    // then bind. Two phases so swapping two keys works; re-applying never stacks binds.
    function keybindLua() {
        const touched = new Set();
        const binds = [];
        for (const a of bindActions) {
            touched.add(a.def);
            const c = bindFor(a.id);
            if (c) { touched.add(c); binds.push([c, a]); }
        }
        let out = "\n-- keybinds (Keybinds page)\ndo\n"
                + "    for _, k in ipairs(_G.rice_bound or {}) do pcall(hl.unbind, k) end\n";
        for (const k of touched) out += `    pcall(hl.unbind, ${luaValue(k)})\n`;
        out += "    local bound = {}\n";
        for (const [c, a] of binds)
            out += `    if pcall(hl.bind, ${luaValue(c)}, ${a.lua}${a.opts ? ", " + a.opts : ""}) then table.insert(bound, ${luaValue(c)}) end\n`;
        return out + "    _G.rice_bound = bound\nend\n";
    }

    // Display scale for every monitor (0 = let Hyprland pick)
    function monitorLua() {
        const sc = Number(adapter.monitorScale);
        const v = sc > 0 ? String(Number(sc.toFixed(4))) : '"auto"';
        let out = `\n-- display scale (Appearance page)\nhl.monitor({ output = "", mode = "preferred", position = "auto", scale = ${v} })\n`;
        // per-monitor layout (Displays page): JSON {"desc:<description>": {enabled, mode, x, y, scale, transform}}
        let cfg = {};
        try { cfg = JSON.parse(adapter.monitors || "{}"); } catch (e) { cfg = {}; }
        const q = t => String(t).replace(/[\\"\n]/g, "");
        let lines = "";
        for (const key of Object.keys(cfg)) {
            const m = cfg[key];
            if (!m || typeof m !== "object") continue;
            if (m.enabled === false) { lines += `hl.monitor({ output = "${q(key)}", disabled = true })\n`; continue; }
            const mode = m.mode ? `"${q(m.mode)}"` : '"preferred"';
            const pos = (typeof m.x === "number" && typeof m.y === "number") ? `"${Math.round(m.x)}x${Math.round(m.y)}"` : '"auto"';
            const scale = Number(m.scale) > 0 ? String(Number(m.scale)) : '"auto"';
            lines += `hl.monitor({ output = "${q(key)}", mode = ${mode}, position = ${pos}, scale = ${scale}, transform = ${(m.transform | 0) & 7} })\n`;
        }
        // Removing a rule from this file does not undo one Hyprland already applied, so remember which monitors
        // we configured last time (Lua globals persist between applies) and reset the ones that are gone.
        const keySet = Object.keys(cfg).map(k => `["${q(k)}"] = true`).join(", ");
        out += "-- per-monitor layout (Displays page)\n" + lines +
            `local now = { ${keySet} }\n` +
            `for k in pairs(_G.rice_monitor_keys or {}) do\n` +
            `    if not now[k] then hl.monitor({ output = k, mode = "preferred", position = "auto", scale = ${v}, transform = 0, disabled = false }) end\n` +
            `end\n_G.rice_monitor_keys = now\n`;
        return out;
    }

    // Window rules, workspace rules and autostart (Window rules page). Rules are kept as handles that are disabled and
    // recreated on every apply, so repeated applies never stack; autostart commands only run at Hyprland's own startup.
    function rulesLua() {
        const parse = t => { try { const v = JSON.parse(t || "[]"); return Array.isArray(v) ? v : []; } catch (e) { return []; } };
        const q = t => String(t ?? "").replace(/[\\"\n\r]/g, "");
        let out = "\n-- window / workspace rules and autostart (Window rules page)\n"
            + "for _, h in ipairs(_G.rice_rules or {}) do h:set_enabled(false) end\n_G.rice_rules = {}\n"
            + "local function keep(h) if h and h.set_enabled then table.insert(_G.rice_rules, h) end end\n";
        let n = 0;
        for (const r of parse(adapter.windowRules)) {
            if (r.enabled === false) continue;
            const match = [];
            if (r.class) match.push(`class = "${q(r.class)}"`);
            if (r.title) match.push(`title = "${q(r.title)}"`);
            if (!match.length) continue;                 // a rule that matches every window is almost surely a mistake
            const props = [];
            if (r.float) props.push("float = true");
            if (r.pin) props.push("pin = true");
            if (r.noBlur) props.push("no_blur = true");
            if (r.noInitialFocus) props.push("no_initial_focus = true");
            if (r.workspace) props.push(`workspace = "${q(r.workspace)}"`);
            if (r.opacity) props.push(`opacity = "${q(r.opacity)}"`);
            if (r.size) props.push(`size = "${q(r.size)}"`);
            if (!props.length) continue;
            out += `keep(hl.window_rule({ name = "rice-win-${++n}", match = { ${match.join(", ")} }, ${props.join(", ")} }))\n`;
        }
        for (const w of parse(adapter.workspaceRules)) {
            if (!w.workspace) continue;
            const props = [`workspace = "${q(w.workspace)}"`];
            if (w.monitor) props.push(`monitor = "${q(w.monitor)}"`);
            if (w.default) props.push("default = true");
            if (w.persistent) props.push("persistent = true");
            out += `keep(hl.workspace_rule({ ${props.join(", ")} }))\n`;
        }
        const cmds = parse(adapter.autostart).filter(c => typeof c === "string" && c.trim() !== "").map(c => `"${q(c)}"`);
        out += `_G.rice_autostart = { ${cmds.join(", ")} }\n`
            + "if not _G.rice_autostart_hooked then\n    _G.rice_autostart_hooked = true\n"
            + "    hl.on(\"hyprland.start\", function() for _, c in ipairs(_G.rice_autostart or {}) do hl.exec_cmd(c) end end)\nend\n";
        return out;
    }

    // Window / workspace animations, scaled by animScale (curves live in hyprland.lua)
    readonly property var windowStyles: ["popin 80%", "popin 50%", "slide", "gnomed"]
    readonly property var wsStyles: ["slidefade 12%", "slide", "slidevert", "slidefadevert 15%", "fade"]
    function animationLua() {
        const k = Math.max(0.2, Math.min(4, Number(adapter.animScale) || 1));
        const win = windowStyles.includes(adapter.windowAnimStyle) ? adapter.windowAnimStyle : windowStyles[0];
        const ws = wsStyles.includes(adapter.wsAnimStyle) ? adapter.wsAnimStyle : wsStyles[0];
        const outStyle = win.startsWith("popin") ? "popin 85%" : win;
        // per-animation length multipliers (Animations page → "Individual animations")
        const m = key => Math.max(0.2, Math.min(4, Number(adapter[key]) || 1));
        const rows = [
            ["windows", 4.79, 'spring = "easy"', "", m("animWinMove")],
            ["windowsIn", 4.5, 'spring = "bouncy"', win, m("animWinIn")],
            ["windowsOut", 2, 'bezier = "md3Accel"', outStyle, m("animWinOut")],
            ["windowsMove", 4.5, 'spring = "easy"', "", m("animWinMove")],
            ["fadeIn", 2, 'bezier = "md3Decel"', "", m("animFade")],
            ["fadeOut", 1.6, 'bezier = "md3Accel"', "", m("animFade")],
            ["workspaces", 4, 'bezier = "md3Decel"', ws, m("animWorkspaces")],
        ];
        return "\n-- animations (Animations page)\n" + rows.map(([leaf, speed, curve, style, mult]) =>
            `hl.animation({ leaf = "${leaf}", enabled = true, speed = ${Number((speed * k * mult).toFixed(2))}, ${curve}${style ? `, style = "${style}"` : ""} })`
        ).join("\n") + "\n";
    }

    function applyHyprland() {
        luaFile.setText(generateLua());
        Quickshell.execDetached(["hyprctl", "eval", `dofile("${luaPath}")`]);
    }

    Timer { id: saveTimer; interval: 400; onTriggered: file.writeAdapter() }
    Timer { id: hyprTimer; interval: 120; onTriggered: root.applyHyprland() }
    Timer {
        id: kittyTimer
        interval: 300
        onTriggered: Quickshell.execDetached(["sh", "-c",
            `sed -i "s/^background_opacity .*/background_opacity ${Number(adapter.terminalOpacity.toFixed(2))}/" "$HOME/.config/kitty/kitty.conf"; pkill -USR1 -x kitty || true`])
    }

    FileView {
        id: luaFile
        path: root.luaPath
        blockWrites: true
    }

    FileView {
        id: file
        path: root.home + "/.config/rice/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: hyprTimer.restart()
        onLoadFailed: { writeAdapter(); hyprTimer.restart(); }

        JsonAdapter {
            id: adapter
            property real barOpacity: 0.35
            property real barVibrancy: 0
            property real panelOpacity: 0.5
            property int shellRadius: 12
            property int fontSize: 13
            property real terminalOpacity: 0.72
            property string colorScheme: "scheme-tonal-spot"
            property bool blurEnabled: true
            property int blurSize: 9
            property int blurPasses: 4
            property real blurBrightness: 0.9
            property real blurVibrancy: 0.25
            property real blurNoise: 0.015
            property bool blurPopups: true
            property bool blurXray: false
            property string layout: "dwindle"
            property int gapsIn: 5
            property int gapsOut: 10
            property int borderSize: 2
            property int rounding: 12
            property real activeOpacity: 1.0
            property real inactiveOpacity: 1.0
            property bool dimInactive: false
            property real dimStrength: 0.15
            property bool shadowEnabled: true
            property int shadowRange: 18
            property bool animationsEnabled: true
            property bool rotatingBorder: true
            property bool showMedia: true
            property bool showStats: true
            property bool showTray: true
            property bool clock24h: true
            property bool showDate: true
            property string kbLayout: "us"
            property string kbOptions: ""
            property int followMouse: 1
            property real sensitivity: 0.0
            property bool naturalScroll: false
            property bool tapToClick: true
            property bool disableWhileTyping: true
            property real scrollFactor: 1.0
            property int dimAfter: 4
            property int lockAfter: 5
            property int screenOffAfter: 6
            property int suspendAfter: 15
            property bool suspendOnBatteryOnly: true
            property int notifTimeout: 5
            property bool drawTerminal: true
            property string drawTerminalCommand: "kitty"
            property string barPosition: "top"
            property string barStyle: "floating"
            property int barHeight: 38
            property bool barFollowGaps: true
            property int barMargin: 10
            property bool barBorder: true
            property bool barShadow: true
            property bool barSheen: true
            property string chipStyle: "filled"
            property string chipShape: "pill"
            property var barLayout: ({"left": ["workspaces", "media"], "center": ["clock"], "right": ["tray", "stats", "status"]})
            property int wsCount: 5
            property string wsStyle: "numbers"
            property bool wsShowEmpty: true
            property real wsOpacity: 0.6
            property real wsActiveOpacity: 1.0
            property bool clockSeconds: false
            property string dateFormat: "short"
            property bool clockIcon: true
            property bool statusBell: true
            property bool statusNetwork: true
            property bool statusBluetooth: true
            property bool statusVolume: true
            property bool statusBattery: true
            property bool statusPercent: true
            property string statsStyle: "rings"
            property int mediaMaxWidth: 200
            property bool mediaBars: true
            property int lyricsMaxWidth: 220
            property int lyricsOffset: 0
            property int titleMaxWidth: 260
            property bool parallaxEnabled: true
            property bool wallCrispPixels: true
            property real parallaxStrength: 0.12
            property bool animatedWallpapers: true
            property int watchdogRssMb: 1500
            property string monitors: "{}"
            property string windowRules: "[]"
            property string workspaceRules: "[]"
            property string autostart: "[]"
            property string appThemes: "[]"
            property string screenShader: ""
            property bool weatherEnabled: false
            property real weatherLat: 0
            property real weatherLon: 0
            property string weatherPlace: ""
            property string weatherUnit: "metric"
            property bool nightLight: false
            property int nightTemp: 4000
            property bool pauseOnBattery: false
            property bool pauseWhenFullscreen: true
            property bool albumWallpaper: false
            property string albumWallStyle: "cover"
            property bool albumWallKeepPaused: true
            property bool albumVisualizer: false
            property string albumVizStyle: "bars"
            property string albumVizColor: "gradient"
            property int albumVizBars: 48
            property real albumVizOpacity: 0.75
            property real albumVizHeight: 0.28
            property real roundingPower: 2.0
            property real fullscreenOpacity: 1.0
            property real dimSpecial: 0.2
            property int shadowRenderPower: 3
            property int shadowOffsetY: 4
            property bool resizeOnBorder: false
            property int borderGrabArea: 15
            property bool snapEnabled: false
            property int snapGap: 10
            property bool groupbarEnabled: true
            property real blurContrast: 1.0
            property real blurVibrancyDarkness: 0.2
            property bool blurSpecial: true
            property bool dwindlePreserveSplit: true
            property bool dwindleSmartSplit: false
            property int dwindleForceSplit: 0
            property bool dwindleSmartResizing: true
            property string masterNewStatus: "master"
            property real masterMfact: 0.55
            property string masterOrientation: "left"
            property bool masterNewOnTop: false
            property real scrollColumnWidth: 0.5
            property bool scrollFullscreenOne: true
            property real animScale: 1.0
            property string windowAnimStyle: "popin 80%"
            property string wsAnimStyle: "slidefade 12%"
            property int borderRotateSpeed: 80
            property bool animateResizes: false
            property bool animateDrag: false
            property int repeatRate: 25
            property int repeatDelay: 600
            property bool numlockOn: false
            property string accelProfile: "adaptive"
            property bool leftHanded: false
            property bool mouseNaturalScroll: false
            property bool clickfinger: false
            property bool middleEmulation: false
            property bool tapAndDrag: true
            property int swipeDistance: 300
            property bool swipeInvert: true
            property bool swipeForever: false
            property bool swipeCreateNew: true
            property real swipeCancelRatio: 0.5
            property int cursorHideAfter: 0
            property bool cursorHideOnKey: false
            property bool cursorNoWarps: false
            property bool cursorWarpOnWs: false
            property real cursorZoom: 1.0
            property bool focusOnActivate: false
            property bool middleClickPaste: true
            property bool enableSwallow: false
            property string swallowRegex: "^(kitty)$"
            property bool closeSpecialOnEmpty: true
            property bool hideSpecialOnWsChange: false
            property bool wsBackAndForth: false
            property bool allowWsCycles: false
            property int onFocusUnderFullscreen: 2
            property bool exitRetainsFullscreen: false
            property bool mouseWakes: false
            property bool keyWakes: false
            property int vrr: 0
            property int directScanout: 0
            property bool xwaylandZeroScaling: false
            property string fontFamily: "JetBrainsMono Nerd Font"
            property bool popupZoom: true
            property real shellAnimScale: 1.0
            property real animLauncher: 1.0
            property real animControlCenter: 1.0
            property real animNotifs: 1.0
            property real animPopups: 1.0
            property real animWinIn: 1.0
            property real animWinOut: 1.0
            property real animWinMove: 1.0
            property real animFade: 1.0
            property real animWorkspaces: 1.0
            property string notifPosition: "right"
            property int notifMaxPopups: 5
            property int notifWidth: 380
            property bool osdEnabled: true
            property string osdPosition: "bottom"
            property real osdTimeout: 1.5
            property bool lockBlur: true
            property real lockDim: 0.18
            property bool lockSeconds: false
            property bool lockShowDate: true
            property real monitorScale: 1.25
            property int launcherWidth: 740
            property int launcherHeight: 600
            property string launcherPosition: "upper"
            property bool launcherDockFlares: true
            property string recMode: "region"
            property string recFormat: "mp4"
            property int recFps: 30
            property string recQuality: "medium"
            property string recEncoder: "software"
            property string recAudio: "none"
            property string recDir: "~/Videos/Recordings"
            property int recCountdown: 3
            property bool recNotify: true
            property bool recCopyPath: false
            property string launcherDefaultView: "grid"
            property int launcherIconSize: 46
            property bool launcherShowFrequent: true
            property int launcherFrequentCount: 6
            property bool launcherShowCategories: true
            property bool launcherShowFooter: true
            property bool launcherShowCount: true
            property bool launcherShowDesc: true
            property bool launcherShowActions: true
            property bool launcherHints: true
            property bool launcherOrbs: true
            property real launcherOrbStrength: 0.32
            property bool launcherPulse: true
            property bool launcherStagger: true
            property bool launcherLaunchAnim: true
            property bool launcherRankByUsage: true
            property int launcherMaxResults: 40
            property bool launcherCalc: true
            property bool launcherRun: true
            property bool launcherWeb: true
            property string launcherWebEngine: "duckduckgo"
            property string launcherTerminal: "kitty --hold"
            property string launcherHidden: ""
            property bool middleAsRight: false
            property bool infiniteDesktop: false
            property bool infiniteFloat: true
            property string keybinds: "{}"   // JSON { actionId: "SUPER + KEY" } overrides (Keybinds page)
        }
    }
}
