import Quickshell
import qs.services
import QtQuick

// Current weather (Settings > Behavior > Weather must be on and have a location).
Item {
    id: w
    property var opts: ({})
    readonly property var cur: Weather.data?.current ?? null
    implicitWidth: 240
    implicitHeight: 90
    Component.onCompleted: Weather.refresh(false)
    Text {
        visible: !w.cur
        width: parent.width; wrapMode: Text.Wrap
        text: Weather.enabled ? "Loading weather…" : "Turn on Weather in Settings › Behavior and enter a location."
        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
    }
    Row {
        visible: !!w.cur
        spacing: 14
        Text { text: w.cur ? Weather.describe(w.cur.weather_code)[1] : ""; color: Theme.primary; font.family: Theme.font; font.pixelSize: 56 }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: w.cur ? Math.round(w.cur.temperature_2m) + Weather.unitName : ""; color: Theme.text; font.family: Theme.font; font.pixelSize: 34; font.weight: Font.Light }
            Text { text: w.cur ? Weather.describe(w.cur.weather_code)[0] : ""; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize }
        }
    }
}
