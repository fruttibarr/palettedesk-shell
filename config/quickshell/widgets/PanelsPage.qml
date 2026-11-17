import qs.services
import QtQuick
import QtQuick.Layouts

// Settings page: how popups, panels and the settings window itself look.
ColumnLayout {
    id: page
    readonly property var cfg: Settings.s
    spacing: 16

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "Popups & Panels"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 9
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: "The look of popups, the control center, notifications, the OSD and this settings window."
                wrapMode: Text.Wrap
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
        Rectangle {
            implicitWidth: rt.implicitWidth + 28
            implicitHeight: 34
            radius: 17
            color: Theme.alpha(Theme.surfaceContainerHigh, rm.containsMouse ? 0.95 : 0.6)
            Text { id: rt; anchors.centerIn: parent; text: "󰑓  Reset page"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold }
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.reset(page.keys) }
        }
    }

            SettingSection {
                title: "Panel surface"
            SettingRow {
                label: "Accent tint"; keywords: "vibrancy color tint glass popups"
                description: "Colours the glass with the wallpaper accent. 0 = plain surface."
                ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: cfg.panelVibrancy; onMoved: v => Settings.set("panelVibrancy", v) }
            }
            SettingRow {
                label: "Gloss"; keywords: "shine sheen highlight reflection"
                description: "A soft highlight across the top of every popup"
                ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: cfg.panelGloss; onMoved: v => Settings.set("panelGloss", v) }
            }
            SettingRow {
                label: "Corner roundness"; keywords: "corners rounded radius"
                description: "Extra radius on top of the shell corner radius"
                ValueSlider { from: -6; to: 24; stepSize: 1; suffix: " px"; value: cfg.panelRadiusExtra; onMoved: v => Settings.set("panelRadiusExtra", v) }
            }
            SettingRow {
                label: "Border colour"; keywords: "outline stroke"
                description: "What the panel outline is drawn with"
                Segmented { current: cfg.panelBorderMode; onPicked: v => Settings.set("panelBorderMode", v); options: [{ label: "Accent", value: "accent" }, { label: "Gradient", value: "gradient" }, { label: "Soft grey", value: "soft" }, { label: "Tertiary", value: "tertiary" }, { label: "None", value: "none" }] }
            }
            SettingRow {
                label: "Border width"; keywords: "outline stroke thickness"
                description: ""
                ValueSlider { from: 0; to: 4; stepSize: 1; suffix: " px"; value: cfg.panelBorderWidth; onMoved: v => Settings.set("panelBorderWidth", v) }
            }
            SettingRow {
                label: "Edge accent line"; keywords: "stripe bar header"
                description: "A coloured accent line along one edge"
                Segmented { current: cfg.panelAccentEdge; onPicked: v => Settings.set("panelAccentEdge", v); options: [{ label: "None", value: "none" }, { label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }, { label: "Left", value: "left" }, { label: "Right", value: "right" }] }
            }
            SettingRow {
                label: "Glow"; keywords: "neon bloom halo"
                description: "Soft accent halo around popups"
                ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: cfg.panelGlow; onMoved: v => Settings.set("panelGlow", v) }
            }
            SettingRow {
                label: "Shadow"; keywords: "depth elevation"
                description: "Drop shadow under popups"
                ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: cfg.panelShadow; onMoved: v => Settings.set("panelShadow", v) }
            }
            }

            SettingSection {
                title: "Popup entrance"
            SettingRow {
                label: "Entrance style"; keywords: "animation open appear"
                description: "How launcher, menus and this panel appear"
                Segmented { current: cfg.popupEntrance; onPicked: v => Settings.set("popupEntrance", v); options: [{ label: "Zoom", value: "zoom" }, { label: "Bounce", value: "bounce" }, { label: "Slide up", value: "slide" }, { label: "Drop down", value: "drop" }, { label: "Fade", value: "fade" }] }
            }
            SettingRow {
                label: "Dim background"; keywords: "backdrop scrim overlay darken"
                description: "Darken the screen behind an open popup"
                ValueSlider { from: 0; to: 0.8; stepSize: 0.05; displayScale: 100; suffix: "%"; value: cfg.popupDim; onMoved: v => Settings.set("popupDim", v) }
            }
            }

            SettingSection {
                title: "Settings window"
            SettingRow {
                label: "Sidebar style"; keywords: "navigation menu"
                description: "How the selected page is marked"
                Segmented { current: cfg.uiSidebarStyle; onPicked: v => Settings.set("uiSidebarStyle", v); options: [{ label: "Pill", value: "pill" }, { label: "Soft", value: "soft" }, { label: "Outline", value: "outline" }, { label: "Rail", value: "rail" }] }
            }
            SettingRow {
                label: "Sidebar width";
                description: ""
                ValueSlider { from: 170; to: 320; stepSize: 10; suffix: " px"; value: cfg.uiSidebarWidth; onMoved: v => Settings.set("uiSidebarWidth", v) }
            }
            SettingRow {
                label: "Page transition"; keywords: "animation"
                description: "How a page appears when you switch"
                Segmented { current: cfg.uiPageTransition; onPicked: v => Settings.set("uiPageTransition", v); options: [{ label: "Slide", value: "slide" }, { label: "Rise", value: "rise" }, { label: "Side", value: "side" }, { label: "Fade", value: "fade" }, { label: "None", value: "none" }] }
            }
            SettingRow {
                label: "Card style"; keywords: "section group box"
                description: "How setting groups are drawn"
                Segmented { current: cfg.uiCardStyle; onPicked: v => Settings.set("uiCardStyle", v); options: [{ label: "Filled", value: "filled" }, { label: "Outlined", value: "outlined" }, { label: "Flat", value: "flat" }, { label: "Stripe", value: "stripe" }, { label: "Glass", value: "glass" }] }
            }
            SettingRow {
                label: "Card roundness";
                description: ""
                ValueSlider { from: 0; to: 28; stepSize: 1; suffix: " px"; value: cfg.uiCardRadius; onMoved: v => Settings.set("uiCardRadius", v) }
            }
            SettingRow {
                label: "Section titles"; keywords: "heading header"
                description: ""
                Segmented { current: cfg.uiSectionTitle; onPicked: v => Settings.set("uiSectionTitle", v); options: [{ label: "CAPS", value: "caps" }, { label: "Plain", value: "plain" }, { label: "Ruled", value: "line" }] }
            }
            SettingRow {
                label: "Density"; keywords: "padding spacing compact"
                description: "Spacing inside setting groups"
                Segmented { current: cfg.uiDensity; onPicked: v => Settings.set("uiDensity", v); options: [{ label: "Compact", value: "compact" }, { label: "Normal", value: "normal" }, { label: "Roomy", value: "roomy" }] }
            }
            SettingRow {
                label: "Row dividers"; keywords: "separator line"
                description: "A hairline between settings"
                Toggle { checked: cfg.uiRowDividers; onToggled: v => Settings.set("uiRowDividers", v) }
            }
            }

            SettingSection {
                title: "Controls"
            SettingRow {
                label: "Switch style"; keywords: "toggle checkbox"
                description: "Every on/off switch in the shell settings"
                Segmented { current: cfg.uiToggleStyle; onPicked: v => Settings.set("uiToggleStyle", v); options: [{ label: "Pill", value: "pill" }, { label: "Square", value: "square" }, { label: "iOS", value: "ios" }, { label: "Dot", value: "dot" }] }
            }
            SettingRow {
                label: "Slider style"; keywords: "knob track"
                description: ""
                Segmented { current: cfg.uiSliderStyle; onPicked: v => Settings.set("uiSliderStyle", v); options: [{ label: "Round", value: "round" }, { label: "Thin", value: "thin" }, { label: "Thick", value: "thick" }, { label: "Glow", value: "glow" }, { label: "Dotted", value: "dotted" }] }
            }
            SettingRow {
                label: "Option buttons"; keywords: "segmented tabs chips"
                description: "The multiple-choice buttons you are looking at"
                Segmented { current: cfg.uiSegmentStyle; onPicked: v => Settings.set("uiSegmentStyle", v); options: [{ label: "Pill", value: "pill" }, { label: "Square", value: "square" }, { label: "Soft", value: "soft" }, { label: "Underline", value: "underline" }] }
            }
            }

            SettingSection {
                title: "Control center"
            SettingRow {
                label: "Tile height"; keywords: "density size"
                description: ""
                ValueSlider { from: 48; to: 90; stepSize: 2; suffix: " px"; value: cfg.ccTileHeight; onMoved: v => Settings.set("ccTileHeight", v) }
            }
            SettingRow {
                label: "Tile roundness"; keywords: "corners radius"
                description: ""
                ValueSlider { from: 0; to: 32; stepSize: 1; suffix: " px"; value: cfg.ccTileRadius; onMoved: v => Settings.set("ccTileRadius", v) }
            }
            SettingRow {
                label: "Active tile colour"; keywords: "wifi bluetooth toggle"
                description: "How an enabled tile stands out"
                Segmented { current: cfg.ccActiveStyle; onPicked: v => Settings.set("ccActiveStyle", v); options: [{ label: "Container", value: "container" }, { label: "Solid accent", value: "accent" }, { label: "Outline", value: "outline" }] }
            }
            SettingRow {
                label: "Icon shape"; keywords: "badge"
                description: ""
                Segmented { current: cfg.ccIconShape; onPicked: v => Settings.set("ccIconShape", v); options: [{ label: "Circle", value: "circle" }, { label: "Rounded", value: "rounded" }, { label: "Square", value: "square" }, { label: "None", value: "none" }] }
            }
            }

            SettingSection {
                title: "Notification cards"
            SettingRow {
                label: "Corner roundness"; keywords: "toast radius"
                description: ""
                ValueSlider { from: 0; to: 30; stepSize: 1; suffix: " px"; value: cfg.notifRadius; onMoved: v => Settings.set("notifRadius", v) }
            }
            SettingRow {
                label: "Accent bar"; keywords: "stripe"
                description: ""
                Segmented { current: cfg.notifAccent; onPicked: v => Settings.set("notifAccent", v); options: [{ label: "Left", value: "left" }, { label: "Top", value: "top" }, { label: "None", value: "none" }] }
            }
            SettingRow {
                label: "Time-left bar"; keywords: "progress timer countdown"
                description: "A thin bar that shrinks until the toast disappears"
                Toggle { checked: cfg.notifProgress; onToggled: v => Settings.set("notifProgress", v) }
            }
            }

            SettingSection {
                title: "Volume / brightness OSD"
            SettingRow {
                label: "Corner roundness"; keywords: "radius"
                description: ""
                ValueSlider { from: 0; to: 38; stepSize: 1; suffix: " px"; value: cfg.osdRadius; onMoved: v => Settings.set("osdRadius", v) }
            }
            SettingRow {
                label: "Width"; keywords: "size"
                description: ""
                ValueSlider { from: 220; to: 520; stepSize: 10; suffix: " px"; value: cfg.osdWidth; onMoved: v => Settings.set("osdWidth", v) }
            }
            SettingRow {
                label: "Quarter notches"; keywords: "ticks marks"
                description: "Tick marks on the level bar"
                Toggle { checked: cfg.osdNotches; onToggled: v => Settings.set("osdNotches", v) }
            }
            }

    readonly property var keys: ["panelVibrancy", "panelGloss", "panelRadiusExtra", "panelBorderMode", "panelBorderWidth", "panelAccentEdge", "panelGlow", "panelShadow", "popupEntrance", "popupDim", "uiSidebarStyle", "uiSidebarWidth", "uiPageTransition", "uiCardStyle", "uiCardRadius", "uiSectionTitle", "uiDensity", "uiRowDividers", "uiToggleStyle", "uiSliderStyle", "uiSegmentStyle", "ccTileHeight", "ccTileRadius", "ccActiveStyle", "ccIconShape", "notifRadius", "notifAccent", "notifProgress", "osdRadius", "osdWidth", "osdNotches"]
}
