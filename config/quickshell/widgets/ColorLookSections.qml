import qs.services
import QtQuick
import QtQuick.Layouts

// Wallpaper & Colors page: how colors are generated, how the shell palette is re-toned, wallpaper effects.
ColumnLayout {
    id: pg
    readonly property var cfg: Settings.s
    spacing: 16

    SettingSection {
        title: "Color generation"
        SettingRow {
            label: "Light or dark"; keywords: "light mode dark mode theme day night bright"
            description: "Re-themes the shell, terminal and app colors. Light mode is experimental: some hand-drawn parts of the shell assume dark."
        }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.colorMode
            onPicked: v => Settings.set("colorMode", v)
            options: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]
        }
        SettingRow {
            label: "Contrast"; keywords: "material contrast accessibility high low colors"
            description: "Material You contrast level. Positive = bolder text and borders, negative = softer."
            ValueSlider { from: -1; to: 1; stepSize: 0.1; decimals: 1; value: pg.cfg.colorContrast; onMoved: v => Settings.set("colorContrast", v) }
        }
        SettingRow {
            label: "Take color from the picture"; keywords: "dominant colour source index second third pick accent"
            description: "Which of the wallpaper's prominent colors seeds the palette. 1 = the most dominant."
            ValueSlider { from: 0; to: 4; stepSize: 1; displayScale: 1; value: pg.cfg.colorSourceIndex; onMoved: v => Settings.set("colorSourceIndex", Math.round(v)) }
        }
        SettingRow {
            label: "Fixed seed color"; keywords: "custom accent hex colour source override fixed brand"
            description: "Ignore the wallpaper and build the whole palette from one hex color, e.g. #ff5599. Leave empty to follow the wallpaper."
            RowLayout {
                spacing: 8
                ColorField { value: pg.cfg.colorSeed; placeholder: "#ff5599"; allowEmpty: true; onPicked: h => Settings.set("colorSeed", h) }
            }
        }
    }

    SettingSection {
        title: "Shell palette"
        SettingRow {
            label: "Color tuning"
            description: "Re-tones the shell's own colors only (bar, popups, this panel). Other apps keep the generated palette."
        }
        SettingRow {
            label: "Saturation"; keywords: "shell colour saturation vivid muted pastel grey"
            ValueSlider { from: 0; to: 1.6; stepSize: 0.05; displayScale: 100; suffix: "%"; value: pg.cfg.lookSaturation; onMoved: v => Settings.set("lookSaturation", v) }
        }
        SettingRow {
            label: "Lightness"; keywords: "shell brightness lighter darker"
            ValueSlider { from: -0.15; to: 0.15; stepSize: 0.01; displayScale: 100; suffix: "%"; value: pg.cfg.lookLightness; onMoved: v => Settings.set("lookLightness", v) }
        }
        SettingRow {
            label: "Hue shift"; keywords: "shell colour rotate hue wheel"
            ValueSlider { from: -180; to: 180; stepSize: 5; suffix: "°"; value: pg.cfg.lookHueShift; onMoved: v => Settings.set("lookHueShift", Math.round(v)) }
        }
        SettingRow {
            label: "Tint color"; keywords: "shell tint wash overlay colour hex warm cool"
            description: "Mixes a color into every shell color. Hex like #ffaa66, empty for none."
            RowLayout {
                spacing: 8
                ColorField { value: pg.cfg.lookTint; placeholder: "#ffaa66"; allowEmpty: true; onPicked: h => Settings.set("lookTint", h) }
            }
        }
        SettingRow {
            visible: Theme.validHex(pg.cfg.lookTint)
            label: "Tint amount"
            ValueSlider { from: 0; to: 0.6; stepSize: 0.02; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.lookTintAmount; onMoved: v => Settings.set("lookTintAmount", v) }
        }
        SettingRow {
            label: "Accent color override"; keywords: "shell accent primary colour custom hex highlight"
            description: "Use your own accent in the shell (bar highlights, toggles, borders on panels) instead of the wallpaper's. Hex, or empty."
            RowLayout {
                spacing: 8
                ColorField { value: pg.cfg.lookAccent; placeholder: "#ff5599"; allowEmpty: true; onPicked: h => Settings.set("lookAccent", h) }
            }
        }
    }

    SettingSection {
        title: "Wallpaper effects"
        SettingRow {
            label: "Blur"; keywords: "wallpaper blur soften depth of field frosted background"
            description: "Softens the wallpaper itself, so windows and text stand out. Costs some GPU, especially on video wallpapers."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.wallBlur; onMoved: v => Settings.set("wallBlur", v) }
        }
        SettingRow {
            label: "Brightness"; keywords: "wallpaper dim darken brighten"
            ValueSlider { from: -0.5; to: 0.3; stepSize: 0.02; displayScale: 100; suffix: "%"; value: pg.cfg.wallBrightness; onMoved: v => Settings.set("wallBrightness", v) }
        }
        SettingRow {
            label: "Saturation"; keywords: "wallpaper colour muted grayscale vivid"
            description: "-100% is black and white."
            ValueSlider { from: -1; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: pg.cfg.wallSaturation; onMoved: v => Settings.set("wallSaturation", v) }
        }
        SettingRow {
            label: "Contrast"; keywords: "wallpaper punch flat"
            ValueSlider { from: -0.5; to: 0.5; stepSize: 0.05; displayScale: 100; suffix: "%"; value: pg.cfg.wallContrast; onMoved: v => Settings.set("wallContrast", v) }
        }
        SettingRow {
            label: "Tint color"; keywords: "wallpaper colour wash overlay duotone hex"
            description: "Washes the wallpaper in one color. Hex like #3355aa, empty for none."
            RowLayout {
                spacing: 8
                ColorField { value: pg.cfg.wallTint; placeholder: "#3355aa"; allowEmpty: true; onPicked: h => Settings.set("wallTint", h) }
            }
        }
        SettingRow {
            visible: Theme.validHex(pg.cfg.wallTint)
            label: "Tint amount"
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.wallTintAmount; onMoved: v => Settings.set("wallTintAmount", v) }
        }
        SettingRow {
            label: "Vignette"; keywords: "wallpaper dark corners edges focus"
            description: "Darkens the wallpaper towards the corners."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.wallVignette; onMoved: v => Settings.set("wallVignette", v) }
        }
        SettingRow {
            label: "Film grain"; keywords: "wallpaper noise texture analog"
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.wallGrain; onMoved: v => Settings.set("wallGrain", v) }
        }
    }
}
