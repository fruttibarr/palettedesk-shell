pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Themes (Settings → Themes): a wallpaper plus a full set of visual settings,
// applied in one go. Built-in ones live here; your own are saved to
// ~/.config/rice/presets.json.
Singleton {
    id: root

    readonly property string walls: Quickshell.env("HOME") + "/Pictures/Wallpapers/"
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/rice/thumbs/"

    // Every setting a theme owns. Input, keybinds, display scale, idle etc. are never touched.
    readonly property var lookKeys: [
        "colorScheme", "barOpacity", "panelOpacity", "terminalOpacity", "shellRadius",
        "blurEnabled", "blurSize", "blurPasses", "blurBrightness", "blurVibrancy", "blurNoise", "blurContrast", "blurXray",
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "roundingPower",
        "activeOpacity", "inactiveOpacity", "dimInactive", "dimStrength", "shadowEnabled", "shadowRange",
        "rotatingBorder", "borderRotateSpeed", "windowAnimStyle", "wsAnimStyle", "animScale",
        "barPosition", "barStyle", "barHeight", "barFollowGaps", "barMargin", "barBorder", "barShadow", "barSheen",
        "chipStyle", "chipShape", "barLayout", "wsStyle", "wsOpacity", "wsActiveOpacity", "statsStyle",
        "launcherPosition", "launcherOrbs", "parallaxEnabled"
    ]

    // Built-in themes start from this, so the result never depends on what was set before.
    readonly property var base: ({
        "colorScheme": "scheme-tonal-spot", "barOpacity": 0.35, "panelOpacity": 0.5, "terminalOpacity": 0.72, "shellRadius": 12,
        "blurEnabled": true, "blurSize": 8, "blurPasses": 3, "blurBrightness": 0.9, "blurVibrancy": 0.25, "blurNoise": 0.015,
        "blurContrast": 1.0, "blurXray": false,
        "layout": "dwindle", "gapsIn": 5, "gapsOut": 10, "borderSize": 2, "rounding": 12, "roundingPower": 2.0,
        "activeOpacity": 1.0, "inactiveOpacity": 1.0, "dimInactive": false, "dimStrength": 0.15,
        "shadowEnabled": true, "shadowRange": 18, "rotatingBorder": true, "borderRotateSpeed": 80,
        "windowAnimStyle": "popin 80%", "wsAnimStyle": "slidefade 12%", "animScale": 1.0,
        "barPosition": "top", "barStyle": "floating", "barHeight": 38, "barFollowGaps": true, "barMargin": 10,
        "barBorder": true, "barShadow": true, "barSheen": true, "chipStyle": "filled", "chipShape": "pill",
        "barLayout": { "left": ["workspaces", "media"], "center": ["clock"], "right": ["lyrics", "tray", "stats", "status"] },
        "wsStyle": "numbers", "wsOpacity": 0.6, "wsActiveOpacity": 1.0, "statsStyle": "rings", "launcherPosition": "upper", "launcherOrbs": true, "parallaxEnabled": true
    })

    // name, what it is, wallpaper (under ~/Pictures/Wallpapers), swatches for the card, and what differs from `base`
    readonly property var builtinSpecs: [
        {
            name: "Frosted Glass", icon: "󰂵",
            description: "Deep blur, floating pill bar, soft round windows",
            wallpaper: "DenverCoder1-minimalistic-wallpaper-collection/images/denis-istomin-midnight-gazing.png",
            colors: ["#4359aa", "#b997f2", "#ebd3fb"],
            set: { colorScheme: "scheme-vibrant", barOpacity: 0.25, panelOpacity: 0.45, terminalOpacity: 0.6,
                   blurSize: 10, blurVibrancy: 0.6, blurBrightness: 0.85, rounding: 14, gapsIn: 6, gapsOut: 12, shellRadius: 14 }
        },
        {
            name: "Mocha Islands", icon: "󰄛",
            description: "Separate glass islands, big gaps, launcher docked at the bottom",
            wallpaper: "orangci-walls-catppuccin-mocha/dominik-mayer-10.jpg",
            colors: ["#363949", "#5f6572", "#ccd5d1"],
            set: { barStyle: "islands", barHeight: 40, barFollowGaps: false, barMargin: 6, rounding: 16, gapsIn: 8, gapsOut: 16,
                   wsStyle: "dots", launcherPosition: "bottom", shellRadius: 16, barOpacity: 0.3, terminalOpacity: 0.7,
                   barLayout: { left: ["workspaces"], center: ["clock", "media"], right: ["lyrics", "tray", "stats", "status"] } }
        },
        {
            name: "Gruvbox Workshop", icon: "󰌢",
            description: "Warm and solid: attached bar, master layout, tight gaps",
            wallpaper: "AngelJumbo-gruvbox-wallpapers/wallpapers/mix/desk-gruvbox-material.jpg",
            colors: ["#705c4b", "#ad8f76", "#46423e"],
            set: { colorScheme: "scheme-fidelity", barStyle: "attached", barHeight: 34, chipShape: "rounded", chipStyle: "outlined",
                   layout: "master", rounding: 6, gapsIn: 3, gapsOut: 8, shellRadius: 6, rotatingBorder: false,
                   barOpacity: 0.85, panelOpacity: 0.8, terminalOpacity: 0.92, blurSize: 5, blurPasses: 2,
                   windowAnimStyle: "slide", statsStyle: "text", launcherOrbs: false,
                   barLayout: { left: ["workspaces", "title"], center: ["clock"], right: ["media", "tray", "stats", "status"] } }
        },
        {
            name: "Nordic Taskbar", icon: "󰖲",
            description: "Cool and quiet: bottom bar with the clock on the right, thin borders",
            wallpaper: "linuxdotexe-nordic-wallpapers/wallpapers/nord_valley.png",
            colors: ["#414e60", "#91bbc0", "#d3dce5"],
            set: { colorScheme: "scheme-neutral", barPosition: "bottom", barStyle: "attached", barHeight: 36, chipStyle: "flat", chipShape: "rounded",
                   rounding: 8, gapsIn: 3, gapsOut: 6, borderSize: 1, shellRadius: 8, rotatingBorder: false, shadowEnabled: false,
                   barOpacity: 0.7, panelOpacity: 0.7, terminalOpacity: 0.85, wsStyle: "dots", launcherPosition: "center",
                   wsAnimStyle: "slide",
                   barLayout: { left: ["workspaces", "title"], center: [], right: ["media", "tray", "stats", "status", "clock"] } }
        },
        {
            name: "Everforest Zen", icon: "󰐅",
            description: "Scrolling columns, dimmed inactive windows, slow gentle motion",
            wallpaper: "Apeiros-46B-everforest-walls/nature/mist_forest_1.png",
            colors: ["#2c353b", "#506057", "#4b5a56"],
            set: { colorScheme: "scheme-content", layout: "scrolling", rounding: 10, gapsIn: 6, gapsOut: 14, borderSize: 1,
                   rotatingBorder: false, dimInactive: true, dimStrength: 0.12, inactiveOpacity: 0.95, animScale: 1.3,
                   wsAnimStyle: "fade", wsStyle: "kanji", barOpacity: 0.2, barSheen: false, terminalOpacity: 0.66, launcherPosition: "center",
                   barLayout: { left: ["workspaces"], center: ["clock"], right: ["tray", "status"] } }
        },
        {
            name: "Rosé Pine Soft", icon: "󰧱",
            description: "Extra-round squircles, outlined chips, floating bar at the bottom",
            wallpaper: "rose-pine-wallpapers/illustration/leafy.png",
            colors: ["#191724", "#484558", "#474057"],
            set: { barPosition: "bottom", chipStyle: "outlined", rounding: 20, roundingPower: 4.0, gapsIn: 6, gapsOut: 12,
                   shellRadius: 18, wsStyle: "roman", launcherPosition: "center", borderRotateSpeed: 100, blurVibrancy: 0.4,
                   barLayout: { left: ["workspaces", "media"], center: ["clock"], right: ["lyrics", "tray", "status"] } }
        },
        {
            name: "Pixel Den", icon: "󰊴",
            description: "Square corners, chunky borders, no blur. Made for pixel art",
            wallpaper: "AngelJumbo-gruvbox-wallpapers/wallpapers/pixelart/girl-reading-book.png",
            colors: ["#50372b", "#c78e4a", "#2f302a"],
            set: { colorScheme: "scheme-fidelity", barStyle: "attached", barHeight: 36, chipShape: "square", rounding: 0, shellRadius: 2,
                   borderSize: 3, gapsIn: 4, gapsOut: 8, rotatingBorder: false, blurEnabled: false, shadowRange: 8,
                   barOpacity: 0.95, panelOpacity: 0.92, terminalOpacity: 0.95, barSheen: false, launcherOrbs: false,
                   windowAnimStyle: "slide", wsAnimStyle: "slide", statsStyle: "text", parallaxEnabled: false }
        },
        {
            name: "Mono Focus", icon: "󰈈",
            description: "Black and white, no gaps, no effects, fast animations",
            wallpaper: "whoisYoges-lwalpapers/wallpapers/b-065.jpg",
            colors: ["#0b0b0b", "#555555", "#bbbbbb"],
            set: { colorScheme: "scheme-monochrome", barStyle: "attached", barHeight: 30, chipStyle: "flat", chipShape: "square",
                   rounding: 0, shellRadius: 4, borderSize: 1, gapsIn: 0, gapsOut: 0, rotatingBorder: false, blurEnabled: false,
                   shadowEnabled: false, dimInactive: true, dimStrength: 0.2, barOpacity: 1.0, panelOpacity: 0.95, terminalOpacity: 1.0,
                   barBorder: false, barShadow: false, barSheen: false, animScale: 0.6, wsAnimStyle: "fade", statsStyle: "text",
                   launcherPosition: "center", launcherOrbs: false, parallaxEnabled: false,
                   barLayout: { left: ["workspaces", "title"], center: [], right: ["status", "clock"] } }
        },
        {
            name: "Neon Transit", icon: "󰔬",
            description: "Animated pixel city, vivid colors, fast glowing borders",
            wallpaper: "Animated/elapse-d-foo-Wallpaper-Feh-Gif/gif/trains.gif",
            colors: ["#364798", "#845ed7", "#c9b8ff"],
            set: { colorScheme: "scheme-vibrant", barStyle: "islands", barFollowGaps: false, barMargin: 6, chipShape: "rounded",
                   rounding: 10, gapsIn: 7, gapsOut: 14, borderRotateSpeed: 40, blurVibrancy: 1.0, blurBrightness: 0.8,
                   barOpacity: 0.2, panelOpacity: 0.45, terminalOpacity: 0.62, windowAnimStyle: "gnomed", wsAnimStyle: "slidevert",
                   launcherPosition: "bottom", parallaxEnabled: false }
        }
    ]

    readonly property var builtins: builtinSpecs.map(p => ({
        name: p.name, icon: p.icon, description: p.description, builtin: true,
        wallpaper: walls + p.wallpaper, still: "", colors: p.colors,
        values: Object.assign({}, base, p.set)
    }))

    // your own: [{ name, wallpaper, still, colors, values, auto }]   (auto = the look saved before the first theme was applied)
    readonly property var user: store.user ?? []
    readonly property var all: builtins.concat(user)

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

    // does the desktop currently look exactly like this theme?
    function isActive(p) {
        if (!p || p.wallpaper !== Theme.baseWallpaper) return false;
        for (const k in p.values) if (!same(Settings.s[k], p.values[k])) return false;
        return true;
    }
    readonly property string activeName: {
        for (const p of all) if (isActive(p)) return p.name;
        return "";
    }

    function snapshot(name) {
        const values = {};
        for (const k of lookKeys) values[k] = JSON.parse(JSON.stringify(Settings.s[k]));
        return {
            name: name, wallpaper: Theme.baseWallpaper, still: Theme.albumActive ? "" : Theme.wallpaperStill,
            colors: [String(Theme.primary), String(Theme.secondary), String(Theme.tertiary)],
            values: values
        };
    }

    function write(list) {
        store.user = list;
        presetFile.writeAdapter();
    }

    function apply(p) {
        if (!p) return;
        // first time away from a look that isn't saved anywhere: keep it so it can be restored
        // (not while a theme picked a moment ago is still loading its wallpaper)
        if (activeName === "" && Date.now() - lastApply > 20000) {
            const snap = snapshot("Previous look");
            snap.auto = true;
            write(user.filter(u => !u.auto).concat([snap]));
        }
        lastApply = Date.now();
        Settings.applyLook(p.values, p.wallpaper);
    }
    property real lastApply: 0
    function applyByName(name) {
        const p = all.find(x => x.name.toLowerCase() === String(name).toLowerCase());
        if (p) apply(p);
        return !!p;
    }

    // Save the current wallpaper + look under a name (same name = overwrite)
    function saveCurrent(name) {
        name = String(name).trim().slice(0, 40);
        if (!name) return "empty name";
        if (builtins.some(b => b.name.toLowerCase() === name.toLowerCase())) return "that name is a built-in theme";
        const snap = snapshot(name);
        write(user.filter(u => u.name.toLowerCase() !== name.toLowerCase()).concat([snap]));
        return "ok";
    }
    function remove(name) { write(user.filter(u => u.name !== name)); }

    FileView {
        id: presetFile
        path: Quickshell.env("HOME") + "/.config/rice/presets.json"
        printErrors: false   // no file until the first theme is saved
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: store
            property var user: []
        }
    }

    // ---- theme packs (.pdtheme): scripts/theme-pack.py does the work and validates everything ----
    function expand(path) { return String(path).trim().replace(/^~(?=\/|$)/, Quickshell.env("HOME")); }
    function pack(args) { Quickshell.execDetached(["python3", "-I", Quickshell.shellDir + "/scripts/theme-pack.py"].concat(args).concat(["--notify"])); }
    function exportPack(name, path, withWallpaper, rights) {
        const p = all.find(x => x.name.toLowerCase() === String(name).trim().toLowerCase());
        if (!p) return "no such theme: " + name;
        if (!String(path).trim()) return "type where to save it";
        const args = ["export", "--theme-json", JSON.stringify({ name: p.name, colors: p.colors, values: p.values }), "--out", expand(path)];
        if (withWallpaper) {
            if (!String(rights).trim()) return "state that you have the right to share the wallpaper";
            if (!p.wallpaper) return "this theme has no wallpaper to include";
            args.push("--wallpaper", p.wallpaper, "--rights", String(rights));
        }
        pack(args);
        return "ok";
    }
    function importPack(path) {
        if (!String(path).trim()) return "type the path of a .pdtheme file";
        pack(["import", expand(path)]);
        return "ok";
    }

    IpcHandler {
        target: "themes"
        // e.g.  qs ipc call themes apply "Pixel Den"
        function apply(name: string): string { return root.applyByName(name) ? "ok" : "no such theme: " + name; }
        function save(name: string): string { return root.saveCurrent(name); }
        function remove(name: string): void { root.remove(name); }
        function list(): string { return root.all.map(p => (root.isActive(p) ? "* " : "  ") + p.name).join("\n"); }
        function active(): string { return root.activeName; }
        // qs ipc call themes exportTheme "Pixel Den" ~/pixel.pdtheme   |   exportWithWallpaper <name> <file> "<rights statement>"   |   import <file>
        function exportTheme(name: string, path: string): string { return root.exportPack(name, path, false, ""); }
        function exportWithWallpaper(name: string, path: string, rights: string): string { return root.exportPack(name, path, true, rights); }
        function importPack(path: string): string { return root.importPack(path); }
    }
}
