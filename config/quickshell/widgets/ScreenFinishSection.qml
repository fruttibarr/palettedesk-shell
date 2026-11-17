import qs.services
import QtQuick
import QtQuick.Layouts

// Color & Display page: lens-style finishing touches composed into the screen shader.
SettingSection {
    title: "Finish"
    SettingRow {
        label: "Vignette"; keywords: "screen dark corners edges cinematic"
        description: "Darkens the screen towards the corners."
        ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: Settings.s.adjVignette; onMoved: v => Settings.set("adjVignette", v) }
    }
    SettingRow {
        label: "Film grain"; keywords: "screen noise texture analog cinematic"
        description: "Fine static noise over everything, strongest in the midtones."
        ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: Settings.s.adjGrain; onMoved: v => Settings.set("adjGrain", v) }
    }
    SettingRow {
        label: "Sharpen"; keywords: "screen crisp detail unsharp clarity"
        description: "Brings out edges and text. High values look harsh."
        ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: Settings.s.adjSharpen; onMoved: v => Settings.set("adjSharpen", v) }
    }
}
