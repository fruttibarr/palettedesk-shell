import qs.services
import QtQuick
import QtQuick.Layouts

// Appearance page: glass texture and pointer theme.
ColumnLayout {
    id: pg
    readonly property var cfg: Settings.s
    spacing: 16

    SettingSection {
        title: "Glass texture"
        SettingRow {
            label: "Grain"; keywords: "glass noise film grain texture panel frosted"
            description: "A fine noise over every popup and panel, like frosted glass."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.glassGrain; onMoved: v => Settings.set("glassGrain", v) }
        }
        SettingRow {
            label: "Inner glow"; keywords: "glass edge light inner shine accent rim"
            description: "Soft accent light just inside the panel edge."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: pg.cfg.glassInner; onMoved: v => Settings.set("glassInner", v) }
        }
    }
    SettingSection {
        title: "Mouse pointer"
        SettingRow {
            label: "Pointer size"; keywords: "cursor size big small"
            description: "Applies to Wayland and most apps right away; some apps need a restart."
            ValueSlider { from: 16; to: 64; stepSize: 2; suffix: " px"; value: pg.cfg.lookCursorSize; onMoved: v => Settings.set("lookCursorSize", v) }
        }
        SettingRow { label: "Pointer theme"; keywords: "cursor theme icons adwaita qogir"; description: "Installed cursor themes. System default keeps whatever is set today." }
        Segmented {
            Layout.fillWidth: true
            current: pg.cfg.lookCursorTheme
            onPicked: v => Settings.set("lookCursorTheme", v)
            options: [{ label: "System", value: "" }, { label: "Adwaita", value: "Adwaita" }, { label: "Qogir", value: "Qogir" },
                      { label: "Qogir Dark", value: "Qogir-Dark" }, { label: "Qogir Light", value: "Qogir-Light" }]
        }
    }
}
