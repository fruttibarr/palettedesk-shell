import qs.services
import QtQuick
import QtQuick.Layouts

// Windows page: border colours, shadow colour / glow, extra spacing and group-tab looks.
ColumnLayout {
    id: pg
    readonly property var cfg: Settings.s
    spacing: 16

    SettingSection {
        title: "Border colors"
        SettingRow {
            label: "Border style"; keywords: "border color colour gradient accent wallpaper active window outline"
            description: "What colors the focused window's border. Wallpaper = the first two Material colors; the others are shown on the focused window right away."
        }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.borderStyle
            onPicked: v => Settings.set("borderStyle", v)
            options: [{ label: "Wallpaper", value: "wallpaper" }, { label: "Solid accent", value: "solid" },
                      { label: "Three colors", value: "triad" }, { label: "Custom", value: "custom" }]
        }
        SettingRow {
            visible: pg.cfg.borderStyle === "custom"
            label: "Custom colors"; keywords: "border hex colour custom gradient"
            description: "Two colors: click a swatch to pick, or type a hex like #ff5599."
            RowLayout {
                spacing: 8
                ColorField { value: pg.cfg.borderCustomA; placeholder: "#cebdfe"; allowEmpty: false; onPicked: h => Settings.set("borderCustomA", h) }
                ColorField { value: pg.cfg.borderCustomB; placeholder: "#f0b8c5"; allowEmpty: false; onPicked: h => Settings.set("borderCustomB", h) }
            }
        }
        SettingRow {
            visible: pg.cfg.borderStyle !== "solid"
            label: "Gradient angle"; keywords: "border direction rotate gradient degrees"
            description: "Direction of the color blend. With the rotating border on (Animations page) this is the starting angle."
            ValueSlider { from: 0; to: 360; stepSize: 15; suffix: "°"; value: pg.cfg.borderAngle; onMoved: v => Settings.set("borderAngle", v) }
        }
        SettingRow {
            label: "Border opacity"; keywords: "border transparent see-through alpha"
            description: "Lower makes the focused border softer and more glass-like."
            ValueSlider { from: 0.2; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"; value: pg.cfg.borderOpacity; onMoved: v => Settings.set("borderOpacity", v) }
        }
        SettingRow { label: "Unfocused border" ; keywords: "border inactive other windows colour hidden faint"; description: "Windows you are not working in." }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.borderInactiveStyle
            onPicked: v => Settings.set("borderInactiveStyle", v)
            options: [{ label: "Default", value: "default" }, { label: "Faint", value: "faint" },
                      { label: "Accent tint", value: "accent" }, { label: "Hidden", value: "hidden" }]
        }
        SettingRow {
            label: "Border counts as window"; keywords: "border part of window rounding clip transparency blur"
            description: "On: the border sits inside the window (blur and opacity cover it). Off: it is drawn outside."
            Toggle { checked: pg.cfg.borderPartOfWindow; onToggled: v => Settings.set("borderPartOfWindow", v) }
        }
    }

    SettingSection {
        title: "Shadow color & glow"
        SettingRow {
            label: "Shadow color"; keywords: "shadow colour tint accent black wallpaper"
            description: "Tint the window shadows with the accent color for a neon underglow, or keep them black."
        }
        Segmented {
            Layout.fillWidth: true
            visible: pg.cfg.shadowEnabled
            current: pg.cfg.shadowColorMode
            onPicked: v => Settings.set("shadowColorMode", v)
            options: [{ label: "Wallpaper dark", value: "wallpaper" }, { label: "Black", value: "black" },
                      { label: "Accent", value: "accent" }, { label: "Tertiary", value: "tertiary" }]
        }
        SettingRow {
            visible: pg.cfg.shadowEnabled
            label: "Shadow strength"; keywords: "shadow opacity darkness alpha"
            ValueSlider { from: 0.1; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"; value: pg.cfg.shadowOpacity; onMoved: v => Settings.set("shadowOpacity", v) }
        }
        SettingRow {
            visible: pg.cfg.shadowEnabled
            label: "Sharp shadow"; keywords: "shadow hard crisp flat offset"
            description: "A hard-edged drop shadow instead of a soft one."
            Toggle { checked: pg.cfg.shadowSharp; onToggled: v => Settings.set("shadowSharp", v) }
        }
        SettingRow {
            visible: pg.cfg.shadowEnabled
            label: "Shadow spread"; keywords: "shadow scale size grow shrink"
            description: "1 = same size as the window; lower tucks it under, 0 hides it."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; decimals: 2; value: pg.cfg.shadowScale; onMoved: v => Settings.set("shadowScale", v) }
        }
        SettingRow {
            label: "Window glow"; keywords: "glow neon light halo bloom focused window outline"
            description: "A colored halo around the focused window."
            Toggle { checked: pg.cfg.glowEnabled; onToggled: v => Settings.set("glowEnabled", v) }
        }
        SettingRow { visible: pg.cfg.glowEnabled; label: "Glow color" }
        Segmented {
            Layout.fillWidth: true
            visible: pg.cfg.glowEnabled
            current: pg.cfg.glowColorMode
            onPicked: v => Settings.set("glowColorMode", v)
            options: [{ label: "Accent", value: "accent" }, { label: "Secondary", value: "secondary" },
                      { label: "Tertiary", value: "tertiary" }, { label: "Custom", value: "custom" }]
        }
        SettingRow {
            visible: pg.cfg.glowEnabled && pg.cfg.glowColorMode === "custom"
            label: "Custom glow color"; description: "Click the swatch to pick, or type a hex like #33ccff."
            ColorField { value: pg.cfg.glowCustom; placeholder: "#33ccff"; allowEmpty: false; onPicked: h => Settings.set("glowCustom", h) }
        }
        SettingRow {
            visible: pg.cfg.glowEnabled
            label: "Glow size"
            ValueSlider { from: 2; to: 60; stepSize: 1; suffix: " px"; value: pg.cfg.glowRange; onMoved: v => Settings.set("glowRange", v) }
        }
        SettingRow {
            visible: pg.cfg.glowEnabled
            label: "Glow falloff"; keywords: "glow power softness"
            description: "1 = wide and soft, 4 = tight"
            ValueSlider { from: 1; to: 4; stepSize: 1; value: pg.cfg.glowPower; onMoved: v => Settings.set("glowPower", v) }
        }
        SettingRow {
            visible: pg.cfg.glowEnabled
            label: "Glow brightness"; keywords: "glow opacity alpha strength"
            ValueSlider { from: 0.1; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: pg.cfg.glowOpacity; onMoved: v => Settings.set("glowOpacity", v) }
        }
    }

    SettingSection {
        title: "Extra spacing"
        SettingRow {
            label: "Workspace margin"; keywords: "gaps workspaces padding extra around inset"
            description: "Extra empty space around every workspace, on top of the screen-edge gap."
            ValueSlider { from: 0; to: 60; stepSize: 1; suffix: " px"; zeroText: "None"; value: pg.cfg.gapsWorkspaces; onMoved: v => Settings.set("gapsWorkspaces", v) }
        }
        SettingRow {
            label: "Floating window margin"; keywords: "float gaps floating windows keep away from edge"
            description: "Gap kept free around floating windows (0 = use the normal screen-edge gap)."
            ValueSlider { from: 0; to: 60; stepSize: 1; suffix: " px"; zeroText: "Default"; value: pg.cfg.floatGaps; onMoved: v => Settings.set("floatGaps", v) }
        }
    }

    SettingSection {
        visible: pg.cfg.groupbarEnabled
        title: "Group tabs"
        SettingRow {
            label: "Match the accent color"; keywords: "group tab bar colour accent theme"
            description: "Tab strip and group border use the wallpaper accent instead of the default grey/yellow."
            Toggle { checked: pg.cfg.groupbarAccent; onToggled: v => Settings.set("groupbarAccent", v) }
        }
        SettingRow {
            label: "Tab height"
            ValueSlider { from: 8; to: 40; stepSize: 1; suffix: " px"; value: pg.cfg.groupbarHeight; onMoved: v => Settings.set("groupbarHeight", v) }
        }
        SettingRow {
            label: "Tab title size"; keywords: "group font text"
            ValueSlider { from: 6; to: 20; stepSize: 1; suffix: " px"; value: pg.cfg.groupbarFontSize; onMoved: v => Settings.set("groupbarFontSize", v) }
        }
        SettingRow {
            label: "Show titles"; keywords: "group tab names text"
            Toggle { checked: pg.cfg.groupbarTitles; onToggled: v => Settings.set("groupbarTitles", v) }
        }
        SettingRow {
            label: "Tab rounding"; keywords: "group corners"
            ValueSlider { from: 0; to: 20; stepSize: 1; suffix: " px"; value: pg.cfg.groupbarRounding; onMoved: v => Settings.set("groupbarRounding", v) }
        }
        SettingRow {
            label: "Tab gradient fill"; keywords: "group gradient"
            description: "Tabs fade out instead of flat blocks."
            Toggle { checked: pg.cfg.groupbarGradients; onToggled: v => Settings.set("groupbarGradients", v) }
        }
        SettingRow {
            label: "Active tab indicator"; keywords: "group underline thickness"
            ValueSlider { from: 0; to: 12; stepSize: 1; suffix: " px"; value: pg.cfg.groupbarIndicator; onMoved: v => Settings.set("groupbarIndicator", v) }
        }
        SettingRow {
            label: "Space between tabs"
            ValueSlider { from: 0; to: 12; stepSize: 1; suffix: " px"; value: pg.cfg.groupbarGaps; onMoved: v => Settings.set("groupbarGaps", v) }
        }
        SettingRow {
            label: "Blur behind tabs"; keywords: "group frosted glass"
            Toggle { checked: pg.cfg.groupbarBlur; onToggled: v => Settings.set("groupbarBlur", v) }
        }
    }
}
