import qs.services
import QtQuick
import QtQuick.Layouts

// Blur page: one-tap blur looks plus the advanced switches.
ColumnLayout {
    id: pg
    readonly property var cfg: Settings.s
    spacing: 16
    readonly property var presets: [
        { label: "Subtle", v: { blurSize: 4, blurPasses: 2, blurBrightness: 1.0, blurVibrancy: 0.1, blurNoise: 0.01, blurContrast: 1.0 } },
        { label: "Balanced", v: { blurSize: 9, blurPasses: 4, blurBrightness: 0.9, blurVibrancy: 0.25, blurNoise: 0.015, blurContrast: 1.0 } },
        { label: "Frosted", v: { blurSize: 12, blurPasses: 4, blurBrightness: 1.05, blurVibrancy: 0.15, blurNoise: 0.04, blurContrast: 0.9 } },
        { label: "Deep dark", v: { blurSize: 14, blurPasses: 5, blurBrightness: 0.7, blurVibrancy: 0.4, blurNoise: 0.02, blurContrast: 1.15 } },
        { label: "Dreamy", v: { blurSize: 18, blurPasses: 6, blurBrightness: 1.0, blurVibrancy: 0.7, blurNoise: 0.01, blurContrast: 0.95 } }
    ]
    function matches(p) { for (const k in p.v) if (Math.abs(cfg[k] - p.v[k]) > 0.0001) return false; return true; }

    SettingSection {
        title: "Quick looks"
        SettingRow {
            label: "Blur look"; keywords: "blur preset quick frosted subtle dreamy dark glass"
            description: "Sets radius, passes, brightness, vibrancy, grain and contrast together. Fine-tune below."
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: pg.presets
                Rectangle {
                    required property var modelData
                    readonly property bool sel: pg.matches(modelData)
                    width: lbl.implicitWidth + 24; height: 30; radius: 15
                    color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, 0.7)
                    Text { id: lbl; anchors.centerIn: parent; text: parent.modelData.label; color: parent.sel ? Theme.textOnPrimary : Theme.text
                           font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { for (const k in parent.modelData.v) Settings.set(k, parent.modelData.v[k]); } }
                }
            }
        }
    }
    SettingSection {
        title: "Advanced"
        SettingRow {
            label: "Fast blur path"; keywords: "new optimizations performance cache"
            description: "Caches the blurred background so it is cheaper to draw. Turn off if blur flickers."
            Toggle { checked: pg.cfg.blurNewOptimizations; onToggled: v => Settings.set("blurNewOptimizations", v) }
        }
        SettingRow {
            label: "Blur see-through windows fully"; keywords: "ignore opacity transparent windows terminal"
            description: "Translucent windows (like a terminal at 70%) get the full blur behind them."
            Toggle { checked: pg.cfg.blurIgnoreOpacity; onToggled: v => Settings.set("blurIgnoreOpacity", v) }
        }
        SettingRow {
            label: "Menu blur cutoff"; keywords: "popups ignore alpha threshold transparent pixels"
            description: "Menu and popup pixels more transparent than this are not blurred."
            ValueSlider { from: 0; to: 1; stepSize: 0.05; decimals: 2; value: pg.cfg.blurPopupsAlpha; onMoved: v => Settings.set("blurPopupsAlpha", v) }
        }
        SettingRow {
            label: "Blur input method popups"; keywords: "ime keyboard candidate"
            Toggle { checked: pg.cfg.blurInputMethods; onToggled: v => Settings.set("blurInputMethods", v) }
        }
    }
}
