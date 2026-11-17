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
        "colorScheme", "barOpacity", "barVibrancy", "panelOpacity", "terminalOpacity", "shellRadius",
        "blurEnabled", "blurSize", "blurPasses", "blurBrightness", "blurVibrancy", "blurNoise", "blurContrast", "blurXray",
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "roundingPower",
        "activeOpacity", "inactiveOpacity", "dimInactive", "dimStrength", "shadowEnabled", "shadowRange",
        "rotatingBorder", "borderRotateSpeed", "windowAnimStyle", "wsAnimStyle", "animScale",
        "barPosition", "barStyle", "barHeight", "barFollowGaps", "barMargin", "barBorder", "barShadow", "barSheen",
        "chipStyle", "chipShape", "barLayout", "wsStyle", "wsOpacity", "wsActiveOpacity", "statsStyle",
        "launcherPosition", "launcherOrbs", "parallaxEnabled",
        // added with the big styling pass: bar / panels / windows / motion / colour / finish
        "chipEffect", "chipGlow", "chipAccent", "chipHover", "chipEntrance", "barDensity", "barEdge", "barEdgeWidth", "barDivider", "barFill", "barFlares", "barIconSize", "barIconColor", "wsIndicator", "wsColor", "wsIcons", "clockLayout", "clockDisplay", "batteryStyle", "statusStateColors", "statsLabels", "statsHeat", "statsWarn", "trayTint", "trayIconSize", "titleStyle", "titleIcon",
        "panelVibrancy", "panelGloss", "panelRadiusExtra", "panelBorderMode", "panelBorderWidth", "panelAccentEdge", "panelGlow", "panelShadow", "popupEntrance", "popupDim", "uiSidebarStyle", "uiSidebarWidth", "uiPageTransition", "uiCardStyle", "uiCardRadius", "uiSectionTitle", "uiDensity", "uiRowDividers", "uiToggleStyle", "uiSliderStyle", "uiSegmentStyle", "ccTileHeight", "ccTileRadius", "ccActiveStyle", "ccIconShape", "notifRadius", "notifAccent", "notifProgress", "osdRadius", "osdWidth", "osdNotches",
        "borderStyle", "borderAngle", "borderCustomA", "borderCustomB", "borderOpacity", "borderInactiveStyle", "shadowColorMode", "shadowOpacity", "shadowSharp", "shadowScale", "glowEnabled", "glowRange", "glowPower", "glowColorMode", "glowCustom", "glowOpacity", "gapsWorkspaces", "floatGaps", "groupbarHeight", "groupbarFontSize", "groupbarRounding", "groupbarGradients", "groupbarTitles", "groupbarIndicator", "groupbarGaps", "groupbarBlur", "groupbarAccent", "blurIgnoreOpacity", "blurPopupsAlpha",
        "animCurve", "animBorderSpeed", "animLayerStyle", "animLayerSpeed", "animWsWrap",
        "glassGrain", "glassInner", "colorMode", "colorContrast", "colorSeed", "lookSaturation", "lookLightness", "lookHueShift", "lookTint", "lookTintAmount", "lookAccent", "wallBlur", "wallBrightness", "wallSaturation", "wallContrast", "wallTint", "wallTintAmount", "wallVignette", "wallGrain", "adjVignette", "adjGrain", "adjSharpen",
        "screenShader"
    ]

    // Built-in themes start from this, so the result never depends on what was set before.
    readonly property var base: ({
        "colorScheme": "scheme-tonal-spot", "barOpacity": 0.35, "barVibrancy": 0, "panelOpacity": 0.5, "terminalOpacity": 0.72, "shellRadius": 12,
        "blurEnabled": true, "blurSize": 8, "blurPasses": 3, "blurBrightness": 0.9, "blurVibrancy": 0.25, "blurNoise": 0.015,
        "blurContrast": 1.0, "blurXray": false,
        "layout": "dwindle", "gapsIn": 5, "gapsOut": 10, "borderSize": 2, "rounding": 12, "roundingPower": 2.0,
        "activeOpacity": 1.0, "inactiveOpacity": 1.0, "dimInactive": false, "dimStrength": 0.15,
        "shadowEnabled": true, "shadowRange": 18, "rotatingBorder": true, "borderRotateSpeed": 80,
        "windowAnimStyle": "popin 80%", "wsAnimStyle": "slidefade 12%", "animScale": 1.0,
        "barPosition": "top", "barStyle": "floating", "barHeight": 38, "barFollowGaps": true, "barMargin": 10,
        "barBorder": true, "barShadow": true, "barSheen": true, "chipStyle": "filled", "chipShape": "pill",
        "barLayout": { "left": ["workspaces", "media"], "center": ["clock"], "right": ["lyrics", "tray", "stats", "status"] },
        "wsStyle": "numbers", "wsOpacity": 0.6, "wsActiveOpacity": 1.0, "statsStyle": "rings", "launcherPosition": "upper", "launcherOrbs": true, "parallaxEnabled": true,
        "chipEffect": "none", "chipGlow": 0, "chipAccent": "none", "chipHover": "lift", "chipEntrance": "rise", "barDensity": "comfortable", "barEdge": "none", "barEdgeWidth": 2, "barDivider": "none", "barFill": "solid", "barFlares": false, "barIconSize": 0, "barIconColor": "accent", "wsIndicator": "pill", "wsColor": "primary", "wsIcons": false, "clockLayout": "inline", "clockDisplay": "digital", "batteryStyle": "icon", "statusStateColors": false, "statsLabels": false, "statsHeat": false, "statsWarn": 0.85, "trayTint": "none", "trayIconSize": 18, "titleStyle": "normal", "titleIcon": true,
        "panelVibrancy": 0.0, "panelGloss": 0.0, "panelRadiusExtra": 6, "panelBorderMode": "accent", "panelBorderWidth": 1, "panelAccentEdge": "none", "panelGlow": 0.0, "panelShadow": 0.0, "popupEntrance": "zoom", "popupDim": 0.0, "uiSidebarStyle": "pill", "uiSidebarWidth": 230, "uiPageTransition": "slide", "uiCardStyle": "filled", "uiCardRadius": 14, "uiSectionTitle": "caps", "uiDensity": "normal", "uiRowDividers": false, "uiToggleStyle": "pill", "uiSliderStyle": "round", "uiSegmentStyle": "pill", "ccTileHeight": 62, "ccTileRadius": 16, "ccActiveStyle": "container", "ccIconShape": "circle", "notifRadius": 16, "notifAccent": "left", "notifProgress": false, "osdRadius": 26, "osdWidth": 320, "osdNotches": true,
        "borderStyle": "wallpaper", "borderAngle": 45, "borderCustomA": "#cebdfe", "borderCustomB": "#f0b8c5", "borderOpacity": 0.933, "borderInactiveStyle": "default", "shadowColorMode": "wallpaper", "shadowOpacity": 0.867, "shadowSharp": false, "shadowScale": 1.0, "glowEnabled": false, "glowRange": 10, "glowPower": 3, "glowColorMode": "accent", "glowCustom": "#33ccff", "glowOpacity": 0.8, "gapsWorkspaces": 0, "floatGaps": 0, "groupbarHeight": 14, "groupbarFontSize": 8, "groupbarRounding": 1, "groupbarGradients": false, "groupbarTitles": true, "groupbarIndicator": 3, "groupbarGaps": 2, "groupbarBlur": false, "groupbarAccent": false, "blurIgnoreOpacity": true, "blurPopupsAlpha": 0.2,
        "animCurve": "default", "animBorderSpeed": 1.0, "animLayerStyle": "slide", "animLayerSpeed": 1.0, "animWsWrap": false,
        "glassGrain": 0.0, "glassInner": 0.0, "colorMode": "dark", "colorContrast": 0.0, "colorSeed": "", "lookSaturation": 1.0, "lookLightness": 0.0, "lookHueShift": 0, "lookTint": "", "lookTintAmount": 0.0, "lookAccent": "", "wallBlur": 0.0, "wallBrightness": 0.0, "wallSaturation": 0.0, "wallContrast": 0.0, "wallTint": "", "wallTintAmount": 0.0, "wallVignette": 0.0, "wallGrain": 0.0, "adjVignette": 0.0, "adjGrain": 0.0, "adjSharpen": 0.0,
        "screenShader": ""
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
        },
        // ---- the second collection: each one leans on the newer bar / panel / border / finish options ----
        {
            name: "Neon Cyberpunk", icon: "󰚌", isNew: true,
            description: "Glowing neon chips with rainbow accents, hot borders, bloom over a wet night city",
            wallpaper: "DenverCoder1-minimalistic-wallpaper-collection/images/wp5102649-neon-retro-city-ps4-wallpapers.png",
            colors: ["#73d7d0", "#eeb8ca", "#eab6e5"],
            set: { colorScheme: "scheme-expressive", barStyle: "islands", barFollowGaps: false, barMargin: 6, barHeight: 38, barOpacity: 0.22,
                   chipEffect: "neon", chipGlow: 0.6, chipAccent: "rainbow", chipHover: "pulse", barEdge: "animated", barEdgeWidth: 2,
                   wsIndicator: "glow", wsStyle: "numbers", statsStyle: "ticks", statsHeat: true, statusStateColors: true, titleStyle: "caps",
                   rounding: 6, roundingPower: 2.0, shellRadius: 8, gapsIn: 5, gapsOut: 10, borderSize: 2, borderStyle: "triad", borderAngle: 90, borderRotateSpeed: 30,
                   glowEnabled: true, glowRange: 18, glowPower: 3, glowColorMode: "accent", glowOpacity: 0.85, shadowColorMode: "accent", shadowOpacity: 0.7,
                   blurSize: 8, blurVibrancy: 0.9, blurBrightness: 0.75, terminalOpacity: 0.7, panelOpacity: 0.45,
                   panelBorderMode: "gradient", panelBorderWidth: 2, panelGlow: 0.5, panelAccentEdge: "top", panelRadiusExtra: 2,
                   uiCardStyle: "outlined", uiCardRadius: 8, uiToggleStyle: "square", uiSliderStyle: "glow", uiSegmentStyle: "underline", uiSidebarStyle: "outline",
                   ccTileRadius: 8, ccIconShape: "square", ccActiveStyle: "outline", notifRadius: 8, notifAccent: "top", notifProgress: true, osdRadius: 10,
                   animCurve: "snappy", animBorderSpeed: 1.5, popupEntrance: "bounce", screenShader: "bloom", adjSharpen: 0.2 }
        },
        {
            name: "Glass Aurora", icon: "󱠃", isNew: true,
            description: "Frosted chips, gradient borders and high-vibrancy glass under northern lights",
            wallpaper: "JaKooLit-Wallpaper-Bank/wallpapers/Northern Lights3.png",
            colors: ["#00e297", "#a2d0c2", "#8cd3cf"],
            set: { colorScheme: "scheme-vibrant", barOpacity: 0.16, barVibrancy: 0.4, barHeight: 40, chipEffect: "glass", chipAccent: "gradient", chipGlow: 0.15,
                   barFill: "fade", barEdge: "line", barEdgeWidth: 1, wsIndicator: "glow", wsColor: "tertiary", barDensity: "spacious",
                   rounding: 18, roundingPower: 3.0, shellRadius: 18, gapsIn: 7, gapsOut: 14, borderStyle: "triad", borderAngle: 135, borderOpacity: 0.9, rotatingBorder: false,
                   blurSize: 12, blurPasses: 3, blurVibrancy: 0.75, blurBrightness: 0.9, blurNoise: 0.02, shadowColorMode: "accent", shadowOpacity: 0.5, shadowRange: 26,
                   panelOpacity: 0.32, panelVibrancy: 0.55, panelGloss: 0.5, panelBorderMode: "gradient", panelBorderWidth: 1, panelRadiusExtra: 10, panelGlow: 0.2,
                   glassGrain: 0.03, glassInner: 0.4, terminalOpacity: 0.55, blurPopupsAlpha: 0.1,
                   uiCardStyle: "glass", uiCardRadius: 18, uiSidebarStyle: "soft", uiPageTransition: "fade", uiSliderStyle: "round", ccTileRadius: 20, notifRadius: 20, osdRadius: 30,
                   animCurve: "smooth", animScale: 1.2, popupEntrance: "fade", statsHeat: true }
        },
        {
            name: "Paper Light", icon: "󰈙", isNew: true,
            description: "A bright, calm light theme: flat cards, underline chips, soft long shadows",
            wallpaper: "DenverCoder1-minimalistic-wallpaper-collection/images/chrisostrowski-the-esteemed-palace-light.jpg",
            colors: ["#125f98", "#4b6078", "#7b488a"],
            set: { colorScheme: "scheme-content", colorMode: "light", barOpacity: 0.8, panelOpacity: 0.88, terminalOpacity: 0.94, barSheen: false,
                   chipEffect: "underline", chipShape: "rounded", chipHover: "none", barEdge: "none", barShadow: true, wsIndicator: "underline", barDivider: "dot",
                   rounding: 10, shellRadius: 10, gapsIn: 6, gapsOut: 12, borderSize: 1, rotatingBorder: false, borderStyle: "solid", borderOpacity: 0.7,
                   blurSize: 4, blurPasses: 2, blurVibrancy: 0.1, blurBrightness: 1.0, shadowRange: 34, shadowColorMode: "black", shadowOpacity: 0.28,
                   panelBorderMode: "soft", panelBorderWidth: 1, panelShadow: 0.6, panelRadiusExtra: 4, panelGloss: 0,
                   uiCardStyle: "flat", uiCardRadius: 10, uiSectionTitle: "plain", uiRowDividers: true, uiToggleStyle: "ios", uiSliderStyle: "thin", uiSegmentStyle: "soft", uiSidebarStyle: "soft",
                   ccTileRadius: 10, ccActiveStyle: "accent", ccIconShape: "rounded", notifRadius: 10, notifAccent: "left", osdRadius: 14, osdNotches: false,
                   animCurve: "smooth", windowAnimStyle: "fade", wsAnimStyle: "fade", popupEntrance: "fade", uiPageTransition: "fade", statsStyle: "text", launcherOrbs: false }
        },
        {
            name: "Terminal Mono", icon: "󰆍", isNew: true,
            description: "Square, tight and monochrome: bracket chips, bar meters, caps titles, no frills",
            wallpaper: "vyrx-dev-Wallpapers/monochrome/a_hallway_with_lights_on_the_ceiling.png",
            colors: ["#ffffff", "#c6c6c6", "#e2e2e2"],
            set: { colorScheme: "scheme-monochrome", barStyle: "attached", barHeight: 28, barDensity: "compact", barOpacity: 0.9, barSheen: false, barShadow: false,
                   chipShape: "square", chipEffect: "bracket", chipHover: "none", chipEntrance: "none", barIconColor: "mono", trayTint: "mono", barDivider: "slash",
                   wsStyle: "numbers", wsOpacity: 0.85, wsIndicator: "block", titleStyle: "caps", statsStyle: "bars", statsLabels: true, batteryStyle: "bar", statusStateColors: true,
                   rounding: 0, shellRadius: 0, gapsIn: 2, gapsOut: 4, borderSize: 1, rotatingBorder: false, borderStyle: "solid", borderOpacity: 1, borderInactiveStyle: "faint",
                   blurEnabled: false, shadowEnabled: false, panelOpacity: 0.95, terminalOpacity: 0.96, panelBorderMode: "accent", panelBorderWidth: 1, panelRadiusExtra: 0,
                   uiCardStyle: "outlined", uiCardRadius: 0, uiSectionTitle: "line", uiDensity: "compact", uiToggleStyle: "square", uiSliderStyle: "thin", uiSegmentStyle: "square",
                   uiSidebarStyle: "rail", uiPageTransition: "none", ccTileRadius: 0, ccTileHeight: 54, ccIconShape: "none", ccActiveStyle: "outline",
                   notifRadius: 0, notifAccent: "left", osdRadius: 0, osdNotches: false, popupEntrance: "fade", animScale: 0.5, windowAnimStyle: "fade", wsAnimStyle: "fade",
                   animCurve: "linear", launcherOrbs: false, parallaxEnabled: false, launcherPosition: "center",
                   barLayout: { left: ["workspaces", "title"], center: [], right: ["media", "tray", "stats", "status", "clock"] } }
        },
        {
            name: "Sakura Zen", icon: "󰉊", isNew: true,
            description: "Soft pink pastels, kanji numerals, squircle everything and slow, gentle motion",
            wallpaper: "JaKooLit-Wallpaper-Bank/wallpapers/River-Moutains-Cherry-Blosums.png",
            colors: ["#f4a3bb", "#dbb9f9", "#ffb1c7"],
            set: { colorScheme: "scheme-fruit-salad", colorSeed: "#f2a0b8", lookAccent: "#f4a3bb", lookTint: "#ffc6d6", lookTintAmount: 0.12, barOpacity: 0.3, barHeight: 40, barDensity: "spacious",
                   chipEffect: "soft", chipShape: "pill", chipAccent: "tertiary", barDivider: "dot", wsStyle: "kanji", wsIndicator: "pill", wsColor: "tertiary",
                   clockDisplay: "kanji", barIconColor: "tertiary", statsStyle: "rings",
                   rounding: 22, roundingPower: 4.0, shellRadius: 22, gapsIn: 8, gapsOut: 16, borderSize: 1, rotatingBorder: false, borderStyle: "triad", borderOpacity: 0.75,
                   blurSize: 10, blurVibrancy: 0.45, shadowRange: 28, shadowColorMode: "accent", shadowOpacity: 0.35, glassGrain: 0.02, wallVignette: 0.15,
                   panelOpacity: 0.42, panelBorderMode: "soft", panelRadiusExtra: 10, panelGloss: 0.25,
                   uiCardStyle: "filled", uiCardRadius: 22, uiDensity: "roomy", uiToggleStyle: "ios", uiSliderStyle: "round", uiSidebarStyle: "soft", uiPageTransition: "fade",
                   ccTileRadius: 22, ccTileHeight: 66, notifRadius: 22, notifAccent: "none", osdRadius: 30,
                   animCurve: "smooth", animScale: 1.5, animLayerSpeed: 1.3, windowAnimStyle: "popin 80%", wsAnimStyle: "fade", popupEntrance: "drop",
                   barLayout: { left: ["workspaces"], center: ["clock"], right: ["media", "tray", "status"] } }
        },
        {
            name: "Synthwave Sunset", icon: "󰖙", isNew: true,
            description: "Gradient bar and chips, an animated neon edge, magenta glow and a duotone wash",
            wallpaper: "D3Ext-aesthetic-wallpapers/images/cyberpunk_car.png",
            colors: ["#ffade1", "#eeb8cb", "#ffb2be"],
            set: { colorScheme: "scheme-vibrant", barOpacity: 0.25, barFill: "gradient", barEdge: "animated", barEdgeWidth: 2, chipEffect: "gradient", chipAccent: "gradient", chipGlow: 0.3,
                   chipHover: "bounce", wsIndicator: "underline", clockLayout: "stacked", barHeight: 42, barDensity: "spacious", statsHeat: true, statsStyle: "rings",
                   rounding: 14, roundingPower: 2.5, shellRadius: 14, gapsIn: 6, gapsOut: 12, borderSize: 2, borderStyle: "triad", borderAngle: 160, borderRotateSpeed: 50,
                   glowEnabled: true, glowRange: 14, glowColorMode: "secondary", glowOpacity: 0.75, shadowColorMode: "accent", shadowOpacity: 0.65, shadowRange: 24,
                   blurVibrancy: 0.9, blurBrightness: 0.8, panelOpacity: 0.4, panelBorderMode: "gradient", panelBorderWidth: 2, panelAccentEdge: "bottom", panelGlow: 0.3, panelGloss: 0.3,
                   uiCardStyle: "stripe", uiCardRadius: 12, uiSliderStyle: "glow", uiSidebarStyle: "pill", ccActiveStyle: "accent", ccTileRadius: 14, notifAccent: "top", notifProgress: true,
                   animCurve: "overshoot", popupEntrance: "bounce", wallVignette: 0.3, wallContrast: 0.1, screenShader: "duotone", adjGrain: 0.03 }
        },
        {
            name: "Brutalist", icon: "󰟶", isNew: true,
            description: "Raw concrete: thick borders, hard offset shadows, square corners, zero blur",
            wallpaper: "vyrx-dev-Wallpapers/monochrome/a_black_and_white_building_with_a_fire_escape.jpg",
            colors: ["#ffffff", "#c6c6c6", "#e2e2e2"],
            set: { colorScheme: "scheme-monochrome", barStyle: "attached", barHeight: 38, barOpacity: 1, barSheen: false, barBorder: true, barShadow: false, barEdge: "line", barEdgeWidth: 4,
                   chipStyle: "outlined", chipShape: "square", chipHover: "none", chipEntrance: "none", barDivider: "line", titleStyle: "caps", wsIndicator: "block", wsStyle: "roman", wsOpacity: 0.9,
                   statsStyle: "text", statsLabels: true, barIconColor: "mono",
                   rounding: 0, shellRadius: 0, gapsIn: 8, gapsOut: 12, borderSize: 4, rotatingBorder: false, borderStyle: "solid", borderOpacity: 1, borderInactiveStyle: "faint",
                   blurEnabled: false, shadowEnabled: true, shadowSharp: true, shadowRange: 2, shadowColorMode: "black", shadowOpacity: 1, shadowScale: 1.0,
                   panelOpacity: 1, terminalOpacity: 1, panelBorderMode: "accent", panelBorderWidth: 3, panelShadow: 1, panelRadiusExtra: 0, panelGloss: 0,
                   uiCardStyle: "outlined", uiCardRadius: 0, uiSectionTitle: "caps", uiToggleStyle: "square", uiSliderStyle: "thick", uiSegmentStyle: "square", uiSidebarStyle: "outline", uiPageTransition: "none",
                   ccTileRadius: 0, ccIconShape: "square", ccActiveStyle: "accent", notifRadius: 0, notifAccent: "top", notifProgress: true, osdRadius: 0, osdNotches: false,
                   animCurve: "linear", animScale: 0.5, windowAnimStyle: "slide", wsAnimStyle: "slide", popupEntrance: "slide", launcherOrbs: false, parallaxEnabled: false, launcherPosition: "center" }
        },
        {
            name: "Deep Ocean", icon: "󰖌", isNew: true,
            description: "Calm blues, a faint blue glow and long, slow, unhurried animations",
            wallpaper: "DenverCoder1-minimalistic-wallpaper-collection/images/chilledcow-kupla-kingdom-in-blue.jpg",
            colors: ["#a0cafd", "#bac8db", "#d6bee5"],
            set: { colorScheme: "scheme-tonal-spot", colorSeed: "#2f80c8", lookTint: "#0a3a6b", lookTintAmount: 0.08, barOpacity: 0.28, chipEffect: "soft", chipGlow: 0.2, wsStyle: "dots", wsIndicator: "glow",
                   statsStyle: "rings", statsHeat: true, barEdge: "line", barEdgeWidth: 1, barDensity: "comfortable",
                   rounding: 16, shellRadius: 16, gapsIn: 6, gapsOut: 12, borderSize: 1, rotatingBorder: true, borderRotateSpeed: 160, borderStyle: "solid", borderOpacity: 0.7,
                   glowEnabled: true, glowRange: 22, glowPower: 4, glowColorMode: "secondary", glowOpacity: 0.45, shadowColorMode: "accent", shadowOpacity: 0.55, shadowRange: 30,
                   blurSize: 12, blurPasses: 3, blurVibrancy: 0.5, blurBrightness: 0.85, panelOpacity: 0.4, panelVibrancy: 0.35, panelBorderMode: "soft", panelGlow: 0.2, glassInner: 0.2,
                   uiCardStyle: "glass", uiCardRadius: 16, uiSidebarStyle: "soft", uiPageTransition: "fade", uiSliderStyle: "round", ccTileRadius: 18, notifRadius: 18, osdRadius: 26,
                   animCurve: "smooth", animScale: 1.7, animLayerSpeed: 1.5, animBorderSpeed: 0.5, windowAnimStyle: "popin 80%", wsAnimStyle: "slidefade 12%", popupEntrance: "fade", wallBlur: 0.0, wallVignette: 0.2 }
        },
        {
            name: "Retro CRT", icon: "󰍹", isNew: true,
            description: "Amber phosphor: scanlines, grain and vignette, bracket chips and glowing edges",
            wallpaper: "JaKooLit-Wallpaper-Bank/wallpapers/Arcade_decay_red.png",
            colors: ["#ffd597", "#ecbf7e", "#a1e5ff"],
            set: { colorScheme: "scheme-fidelity", colorSeed: "#ffb000", barStyle: "attached", barHeight: 32, barDensity: "compact", barOpacity: 0.85, chipShape: "square", chipEffect: "bracket", chipHover: "none",
                   barDivider: "slash", wsOpacity: 0.85, titleStyle: "caps", statsStyle: "ticks", statsLabels: true, statsHeat: true, batteryStyle: "bar", statusStateColors: true, wsIndicator: "outline", barIconColor: "accent",
                   rounding: 4, shellRadius: 4, gapsIn: 3, gapsOut: 6, borderSize: 2, rotatingBorder: false, borderStyle: "solid", borderOpacity: 1,
                   glowEnabled: true, glowRange: 9, glowPower: 3, glowColorMode: "accent", glowOpacity: 0.55, shadowEnabled: false, blurSize: 5, blurPasses: 2, blurVibrancy: 0.1,
                   panelOpacity: 0.85, terminalOpacity: 0.88, panelBorderMode: "accent", panelBorderWidth: 1, panelRadiusExtra: 2, panelGlow: 0.35, glassGrain: 0.05,
                   uiCardStyle: "outlined", uiCardRadius: 4, uiSectionTitle: "line", uiToggleStyle: "square", uiSliderStyle: "dotted", uiSegmentStyle: "underline", uiSidebarStyle: "rail",
                   uiPageTransition: "rise", ccTileRadius: 4, ccIconShape: "square", ccActiveStyle: "outline", notifRadius: 4, notifAccent: "left", notifProgress: true, osdRadius: 4,
                   animCurve: "linear", animScale: 0.8, windowAnimStyle: "slide", wsAnimStyle: "slide", popupEntrance: "fade", parallaxEnabled: false, launcherOrbs: false,
                   screenShader: "crt", adjVignette: 0.3, adjGrain: 0.05, wallGrain: 0.1, wallVignette: 0.25 }
        },
        {
            name: "Minimal Dock", icon: "󰍜", isNew: true,
            description: "A thin attached bar with dock flares, flat chips and a bottom launcher: calm and tidy",
            wallpaper: "DenverCoder1-minimalistic-wallpaper-collection/images/dalle2-minimalistic-colorful-flat-mountain-landscape.png",
            colors: ["#c3c6d6", "#c5c6d0", "#c0c6dc"],
            set: { colorScheme: "scheme-neutral", barStyle: "attached", barFlares: true, barHeight: 32, barDensity: "compact", barOpacity: 0.78, barSheen: false, barEdge: "line", barEdgeWidth: 1,
                   chipStyle: "flat", chipShape: "rounded", chipEffect: "none", barDivider: "dot", wsStyle: "dots", wsIndicator: "pill", statsStyle: "text", batteryStyle: "ring", trayIconSize: 16,
                   rounding: 10, shellRadius: 10, gapsIn: 4, gapsOut: 8, borderSize: 1, rotatingBorder: false, borderStyle: "solid", borderOpacity: 0.6,
                   blurSize: 8, blurPasses: 3, shadowRange: 20, shadowOpacity: 0.5, panelOpacity: 0.6, panelBorderMode: "soft", panelBorderWidth: 1, panelRadiusExtra: 4,
                   uiCardStyle: "flat", uiCardRadius: 12, uiRowDividers: true, uiSectionTitle: "plain", uiToggleStyle: "ios", uiSliderStyle: "thin", uiSegmentStyle: "underline", uiSidebarStyle: "soft",
                   uiPageTransition: "fade", ccTileHeight: 56, ccTileRadius: 12, ccActiveStyle: "outline", notifRadius: 12, notifAccent: "none", osdRadius: 16, osdWidth: 260, osdNotches: false,
                   animCurve: "smooth", popupEntrance: "slide", launcherPosition: "bottom", launcherOrbs: false,
                   barLayout: { left: ["workspaces", "title"], center: ["clock"], right: ["media", "tray", "stats", "status"] } }
        }
    ]

    readonly property var builtins: builtinSpecs.map(p => ({
        name: p.name, icon: p.icon, description: p.description, builtin: true, isNew: !!p.isNew,
        wallpaper: walls + p.wallpaper, still: "", colors: p.colors,
        values: Object.assign({}, base, p.set)
    }))

    // your own: [{ name, wallpaper, still, colors, values, auto }]   (auto = the look saved before the first theme was applied)
    readonly property var user: store.user ?? []
    readonly property var all: builtins.concat(user)

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

    // does the desktop currently look exactly like this theme?
    // a theme saved before a setting existed gets that setting's default
    function full(p) { return Object.assign({}, base, p.values); }
    function isActive(p) {
        if (!p || p.wallpaper !== Theme.baseWallpaper) return false;
        const v = full(p);
        for (const k in v) if (!same(Settings.s[k], v[k])) return false;
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
        Settings.applyLook(full(p), p.wallpaper);
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

    // ---------------------------------------------------------------------------------------------
    // Random theme. Not "random settings": a random *design*. A style (glass / neon / soft / minimal /
    // brutal / synth) fixes the combinations that are known to work together (the same recipes the
    // built-in themes use), and only the amounts vary inside safe ranges: one corner radius drives every
    // radius so the shape language stays consistent, opacities never drop below readable, the colour mode
    // is always dark, and the wallpaper is picked by brightness/saturation to suit the style.
    // ---------------------------------------------------------------------------------------------
    property string lastRoll: ""        // "Neon · scheme-vibrant" after a roll
    property string lastRollStyle: ""
    property var rolledFull: null       // every value the last roll applied, to tell if you changed anything since
    property bool rolling: false
    property var rollValues: ({})
    property string rollStyleName: ""

    function pick(a) { return a[Math.floor(Math.random() * a.length)]; }
    function rnd(a, b) { return Math.round((a + Math.random() * (b - a)) * 100) / 100; }
    function rint(a, b) { return a + Math.floor(Math.random() * (b - a + 1)); }
    function chance(p) { return Math.random() < p; }
    // every radius from one number, so cards / tiles / toasts / OSD / windows agree
    function radii(r) {
        return { rounding: r, shellRadius: Math.min(r, 22), uiCardRadius: Math.min(28, r + 2), ccTileRadius: Math.min(32, r + 4),
                 notifRadius: Math.min(30, r + 4), osdRadius: r === 0 ? 0 : Math.min(38, Math.round(r * 1.5 + 6)),
                 panelRadiusExtra: r < 4 ? 0 : Math.min(12, Math.round(r / 2)) };
    }

    readonly property var rollStyles: [
        { id: "glass", name: "Glass", wall: { lmin: 12, lmax: 50, smin: 18 }, make: () => Object.assign(radii(rint(14, 22)), {
            colorScheme: pick(["scheme-vibrant", "scheme-tonal-spot", "scheme-expressive", "scheme-fidelity"]),
            barOpacity: rnd(0.14, 0.24), barVibrancy: rnd(0.2, 0.5), barHeight: pick([38, 40, 42]), barDensity: pick(["comfortable", "spacious"]),
            chipEffect: "glass", chipAccent: pick(["none", "gradient"]), chipGlow: rnd(0, 0.2), barFill: pick(["solid", "fade"]),
            barEdge: pick(["none", "line"]), barEdgeWidth: 1, wsIndicator: pick(["glow", "pill"]), wsColor: pick(["primary", "tertiary"]),
            roundingPower: 3.0, gapsIn: rint(5, 8), gapsOut: rint(10, 16),
            borderStyle: "triad", borderAngle: rint(0, 359), borderOpacity: 0.9, rotatingBorder: chance(0.4),
            blurSize: rint(10, 13), blurPasses: 3, blurVibrancy: rnd(0.5, 0.8), blurBrightness: 0.9, blurNoise: 0.02, blurPopupsAlpha: 0.1,
            shadowColorMode: "accent", shadowOpacity: 0.5, shadowRange: rint(22, 30),
            panelOpacity: rnd(0.28, 0.38), panelVibrancy: rnd(0.35, 0.6), panelGloss: rnd(0.3, 0.5), panelBorderMode: "gradient", panelGlow: rnd(0, 0.25),
            glassGrain: 0.03, glassInner: rnd(0.25, 0.45), terminalOpacity: rnd(0.55, 0.65),
            uiCardStyle: "glass", uiSidebarStyle: pick(["soft", "pill"]), uiPageTransition: "fade",
            animCurve: "smooth", popupEntrance: pick(["fade", "zoom"]), statsHeat: chance(0.5) }) },

        { id: "neon", name: "Neon", wall: { lmin: 5, lmax: 35, smin: 25 }, make: () => Object.assign(radii(rint(4, 10)), {
            colorScheme: pick(["scheme-expressive", "scheme-vibrant"]),
            barStyle: "islands", barFollowGaps: false, barMargin: 6, barHeight: 38, barOpacity: 0.22,
            chipEffect: "neon", chipGlow: rnd(0.4, 0.7), chipAccent: pick(["rainbow", "gradient"]), chipHover: "pulse",
            barEdge: pick(["animated", "glow"]), barEdgeWidth: 2, wsIndicator: pick(["glow", "outline"]), statsStyle: pick(["ticks", "rings"]),
            statsHeat: true, statusStateColors: true, titleStyle: pick(["caps", "normal"]),
            gapsIn: rint(4, 6), gapsOut: rint(8, 12), borderSize: 2, borderStyle: "triad", borderAngle: rint(0, 359), rotatingBorder: chance(0.6), borderRotateSpeed: 30,
            glowEnabled: true, glowRange: rint(14, 20), glowPower: 3, glowColorMode: "accent", glowOpacity: 0.85, shadowColorMode: "accent", shadowOpacity: 0.7,
            blurSize: 8, blurVibrancy: 0.9, blurBrightness: 0.75, terminalOpacity: 0.7, panelOpacity: 0.45,
            panelBorderMode: "gradient", panelBorderWidth: 2, panelGlow: rnd(0.3, 0.55), panelAccentEdge: pick(["top", "none"]),
            uiCardStyle: "outlined", uiToggleStyle: "square", uiSliderStyle: "glow", uiSegmentStyle: "underline", uiSidebarStyle: "outline",
            ccActiveStyle: "outline", ccIconShape: "square", notifAccent: "top", notifProgress: true,
            animCurve: "snappy", popupEntrance: "bounce", screenShader: chance(0.3) ? "bloom" : "" }) },

        { id: "soft", name: "Soft", wall: { lmin: 15, lmax: 55, smin: 10 }, make: () => Object.assign(radii(rint(16, 26)), {
            colorScheme: pick(["scheme-tonal-spot", "scheme-content", "scheme-fidelity"]),
            barOpacity: rnd(0.3, 0.45), barHeight: pick([38, 40]), barDensity: pick(["comfortable", "spacious"]),
            chipShape: "pill", chipEffect: "soft", chipAccent: pick(["none", "tertiary"]), wsIndicator: "pill",
            roundingPower: 3.0, gapsIn: rint(6, 9), gapsOut: rint(12, 18), borderSize: pick([1, 2]), borderStyle: pick(["wallpaper", "solid"]),
            shadowRange: rint(24, 32), shadowOpacity: 0.5, blurSize: 9, panelOpacity: rnd(0.45, 0.6), panelBorderMode: "soft",
            uiCardStyle: pick(["filled", "stripe"]), uiDensity: "roomy", uiToggleStyle: "ios", uiSliderStyle: "round", uiSegmentStyle: "soft", uiSidebarStyle: "soft",
            ccIconShape: "circle", notifAccent: "left", animCurve: pick(["smooth", "bouncy"]), animScale: 1.15, popupEntrance: pick(["zoom", "fade"]) }) },

        { id: "minimal", name: "Minimal", wall: { lmin: 10, lmax: 45, smin: 8 }, make: () => {
            const attached = chance(0.5);
            return Object.assign(radii(rint(6, 10)), {
                colorScheme: pick(["scheme-tonal-spot", "scheme-content"]),
                barStyle: attached ? "attached" : "floating", barHeight: attached ? pick([30, 32, 34]) : 36, barOpacity: attached ? 0.8 : 0.35,
                barFlares: attached && chance(0.5), launcherPosition: attached ? "bottom" : "upper",
                chipShape: "rounded", chipEffect: pick(["none", "underline"]), barDivider: pick(["dot", "line", "none"]),
                wsIndicator: pick(["underline", "pill"]), statsStyle: pick(["text", "bars"]),
                gapsIn: rint(3, 5), gapsOut: rint(5, 10), borderSize: 1, rotatingBorder: false, borderStyle: "solid", borderOpacity: 0.8,
                shadowRange: 14, blurSize: 6, panelOpacity: 0.6, panelBorderMode: "soft",
                uiCardStyle: "flat", uiRowDividers: true, uiSectionTitle: "plain", uiToggleStyle: "ios", uiSliderStyle: "thin", uiSegmentStyle: "soft",
                animCurve: "snappy", popupEntrance: "fade", uiPageTransition: "fade" });
        } },

        { id: "brutal", name: "Brutalist", wall: { lmin: 5, lmax: 40, smin: 0 }, make: () => Object.assign(radii(0), {
            colorScheme: pick(["scheme-monochrome", "scheme-neutral"]),
            barStyle: "attached", barHeight: rint(34, 40), barOpacity: 1, barSheen: false, barShadow: false, barEdge: "line", barEdgeWidth: rint(3, 4),
            chipStyle: "outlined", chipShape: "square", chipHover: "none", chipEntrance: "none", barDivider: "line", titleStyle: "caps",
            wsIndicator: "block", wsStyle: pick(["roman", "numbers"]), wsOpacity: 0.9, statsStyle: "text", statsLabels: true, barIconColor: "mono",
            gapsIn: rint(6, 9), gapsOut: rint(10, 14), borderSize: rint(3, 4), rotatingBorder: false, borderStyle: "solid", borderOpacity: 1, borderInactiveStyle: "faint",
            blurEnabled: false, shadowSharp: true, shadowRange: 2, shadowColorMode: "black", shadowOpacity: 1,
            panelOpacity: 1, terminalOpacity: 1, panelBorderMode: "accent", panelBorderWidth: 3, panelShadow: 1, panelGloss: 0,
            uiCardStyle: "outlined", uiToggleStyle: "square", uiSliderStyle: "thick", uiSegmentStyle: "square", uiSidebarStyle: "outline", uiPageTransition: "none",
            ccIconShape: "square", ccActiveStyle: "accent", notifAccent: "top", notifProgress: true, osdNotches: false,
            animCurve: "linear", animScale: 0.5, windowAnimStyle: "slide", wsAnimStyle: "slide", popupEntrance: "slide",
            launcherOrbs: false, parallaxEnabled: false, launcherPosition: "center" }) },

        { id: "synth", name: "Synth", wall: { lmin: 8, lmax: 42, smin: 30 }, make: () => Object.assign(radii(rint(10, 16)), {
            colorScheme: pick(["scheme-vibrant", "scheme-expressive"]),
            barOpacity: 0.25, barFill: "gradient", barEdge: "animated", barEdgeWidth: 2, chipEffect: "gradient", chipAccent: "gradient", chipGlow: rnd(0.2, 0.4),
            chipHover: pick(["bounce", "lift"]), wsIndicator: pick(["underline", "glow"]), barHeight: pick([40, 42]), barDensity: "spacious", statsHeat: true,
            roundingPower: 2.5, gapsIn: rint(5, 7), gapsOut: rint(10, 14), borderSize: 2, borderStyle: "triad", borderAngle: rint(0, 359), borderRotateSpeed: 50,
            glowEnabled: true, glowRange: rint(12, 16), glowColorMode: pick(["secondary", "accent"]), glowOpacity: 0.75, shadowColorMode: "accent", shadowOpacity: 0.65, shadowRange: 24,
            blurVibrancy: 0.9, blurBrightness: 0.8, panelOpacity: 0.4, panelBorderMode: "gradient", panelBorderWidth: 2, panelAccentEdge: pick(["bottom", "top"]),
            panelGlow: rnd(0.2, 0.35), panelGloss: 0.3, terminalOpacity: 0.65,
            uiCardStyle: "stripe", uiSliderStyle: "glow", uiSidebarStyle: "pill", ccActiveStyle: "accent", notifAccent: "top", notifProgress: true,
            animCurve: "overshoot", popupEntrance: "bounce", wallVignette: 0.25, screenShader: chance(0.4) ? "duotone" : "", adjGrain: 0.03 }) }
    ]

    // Roll a theme. style = "" (surprise me) or one of the ids above. Result lands in lastRoll.
    function random(style) {
        if (rolling) return "busy";
        let st = rollStyles.find(x => x.id === style);
        if (!st) {
            const others = rollStyles.filter(x => x.id !== lastRollStyle);
            st = pick(others);
        }
        const vals = st.make();
        // readability guards, whatever the style rolled
        vals.panelOpacity = Math.max(0.3, vals.panelOpacity ?? base.panelOpacity);
        vals.terminalOpacity = Math.max(0.55, vals.terminalOpacity ?? base.terminalOpacity);
        vals.colorMode = "dark";
        rollValues = vals;
        rollStyleName = st.name;
        lastRollStyle = st.id;
        rolling = true;
        wallPicker.command = ["python3", "-I", Quickshell.shellDir + "/scripts/random-wall.py",
            "--lmin", String(st.wall.lmin), "--lmax", String(st.wall.lmax), "--smin", String(st.wall.smin), "--avoid", Theme.baseWallpaper];
        wallPicker.running = true;
        return st.name;
    }
    Process {
        id: wallPicker
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                const vals = root.rollValues;
                root.rolling = false;
                // keep the look from before the first roll so "Previous look" can bring it back
                // (the look is still exactly what the last roll applied = nothing of yours to keep)
                const prev = root.rolledFull;
                const untouched = prev !== null && Object.keys(prev).every(k => root.same(Settings.s[k], prev[k]));
                if (untouched) root.lastApply = Date.now();
                const theme = { name: "Random", wallpaper: path || Theme.baseWallpaper, values: vals };
                root.rolledFull = root.full(theme);
                root.apply(theme);
                root.lastRoll = root.rollStyleName + " · " + String(vals.colorScheme).replace("scheme-", "");
            }
        }
    }

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
        function random(style: string): string { return root.random(style); }
        // qs ipc call themes exportTheme "Pixel Den" ~/pixel.pdtheme   |   exportWithWallpaper <name> <file> "<rights statement>"   |   import <file>
        function exportTheme(name: string, path: string): string { return root.exportPack(name, path, false, ""); }
        function exportWithWallpaper(name: string, path: string, rights: string): string { return root.exportPack(name, path, true, rights); }
        function importPack(path: string): string { return root.importPack(path); }
    }
}
