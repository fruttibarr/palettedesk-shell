import qs.services
import QtQuick
import QtQuick.Layouts

// Animations page: easing character and layer / border motion.
ColumnLayout {
    id: pg
    readonly property var cfg: Settings.s
    spacing: 16
    visible: cfg.animationsEnabled

    SettingSection {
        title: "Feel"
        SettingRow {
            label: "Motion curve"; keywords: "easing bezier spring bounce snappy smooth linear overshoot elastic feel"
            description: "The character of window, fade and workspace motion. Default keeps the springy pop-in."
        }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.animCurve
            onPicked: v => Settings.set("animCurve", v)
            options: [{ label: "Default", value: "default" }, { label: "Snappy", value: "snappy" }, { label: "Smooth", value: "smooth" },
                      { label: "Overshoot", value: "overshoot" }, { label: "Bouncy", value: "bouncy" }, { label: "Linear", value: "linear" }]
        }
        SettingRow {
            label: "Border color fade"; keywords: "border animation speed focus change"
            description: "How fast the border color changes when focus moves. Above 1× is slower."
            ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: pg.cfg.animBorderSpeed; onMoved: v => Settings.set("animBorderSpeed", v) }
        }
        SettingRow {
            label: "Wrap around workspaces"; keywords: "workspace wraparound loop first last"
            description: "Scrolling past the last workspace jumps back to the first, with the slide animation."
            Toggle { checked: pg.cfg.animWsWrap; onToggled: v => Settings.set("animWsWrap", v) }
        }
    }
    SettingSection {
        title: "Bar & layer motion"
        SettingRow { label: "Bar and overlays appear with"; keywords: "layer animation bar slide popin fade" }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.animLayerStyle
            onPicked: v => Settings.set("animLayerStyle", v)
            options: [{ label: "Slide", value: "slide" }, { label: "Pop in", value: "popin 80%" }, { label: "Fade", value: "fade" }]
        }
        SettingRow {
            label: "Layer animation length"; keywords: "bar layer speed slow fast duration"
            description: "Speed of Hyprland-level layer animations (menus, notifications from other apps)."
            ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: pg.cfg.animLayerSpeed; onMoved: v => Settings.set("animLayerSpeed", v) }
        }
    }
}
