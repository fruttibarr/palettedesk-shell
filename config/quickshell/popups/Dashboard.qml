import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Dashboard: month calendar, weather (opt-in) and timers. Click the clock, or:  qs ipc call dashboard toggle
Scope {
    id: root
    property int shownYear: new Date().getFullYear()
    property int shownMonth: new Date().getMonth()
    // make sure the services run from startup (timers must fire even when this is closed)
    Component.onCompleted: { Timers.items; Weather.enabled; }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { Globals.dashboardOpen = !Globals.dashboardOpen; }
    }
    readonly property bool open: Globals.dashboardOpen
    onOpenChanged: if (open) { shownYear = new Date().getFullYear(); shownMonth = new Date().getMonth(); Weather.refresh(false); }

    function monthCells() {
        const first = new Date(shownYear, shownMonth, 1);
        const lead = (first.getDay() - Qt.locale().firstDayOfWeek + 7) % 7;
        const days = new Date(shownYear, shownMonth + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < lead; i++) cells.push(0);
        for (let d = 1; d <= days; d++) cells.push(d);
        while (cells.length < 42) cells.push(0);
        return cells;
    }
    function weekdayName(i) { return ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][(Qt.locale().firstDayOfWeek + i) % 7]; }
    function step(n) { const d = new Date(shownYear, shownMonth + n, 1); shownYear = d.getFullYear(); shownMonth = d.getMonth(); }

    component Card: Rectangle {
        default property alias content: inner.data
        property string heading: ""
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 28
        radius: 14
        color: Theme.alpha(Theme.surfaceContainerHigh, 0.55)
        ColumnLayout {
            id: inner
            anchors.fill: parent; anchors.margins: 14; spacing: 8
            Text { visible: parent.parent.heading !== ""; text: parent.parent.heading; color: Theme.primary
                   font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.Bold; font.letterSpacing: 1 }
        }
    }
    component Lbl: Text { color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
    component RoundBtn: Rectangle {
        property string label: ""
        signal clicked()
        height: 28; width: t.implicitWidth + 22; radius: 14
        color: m.containsMouse ? Theme.primary : Theme.alpha(Theme.surface, 0.6)
        Text { id: t; anchors.centerIn: parent; text: parent.label; color: m.containsMouse ? Theme.textOnPrimary : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Overlay {
        name: "dashboard"
        open: Globals.dashboardOpen
        onCloseRequested: Globals.dashboardOpen = false

        GlassPanel {
            anchors.centerIn: parent
            width: 780
            height: Math.min(parent.height - 80, row.implicitHeight + 50)

            RowLayout {
                id: row
                anchors.fill: parent; anchors.margins: 22; spacing: 14

                // ---------------- calendar ----------------
                Card {
                    Layout.preferredWidth: 330; Layout.fillWidth: false; Layout.alignment: Qt.AlignTop
                    RowLayout {
                        Layout.fillWidth: true
                        RoundBtn { label: "‹"; onClicked: root.step(-1) }
                        Item { Layout.fillWidth: true }
                        Text { text: Qt.locale().monthName(root.shownMonth) + " " + root.shownYear; color: Theme.text; font.family: Theme.font
                               font.pixelSize: Theme.fontSize + 2; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        RoundBtn { label: "›"; onClicked: root.step(1) }
                    }
                    GridLayout {
                        columns: 7; rowSpacing: 4; columnSpacing: 4; Layout.fillWidth: true
                        Repeater { model: 7
                            Lbl { required property int index; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                                  text: root.weekdayName(index); color: Theme.subtext; font.pixelSize: Theme.fontSize - 3 } }
                        Repeater { model: root.open ? root.monthCells() : []
                            Rectangle {
                                required property int modelData
                                readonly property bool today: modelData > 0 && new Date().getDate() === modelData
                                    && new Date().getMonth() === root.shownMonth && new Date().getFullYear() === root.shownYear
                                Layout.fillWidth: true; Layout.preferredHeight: 34; radius: 17
                                color: today ? Theme.primary : "transparent"
                                Lbl { anchors.centerIn: parent; text: parent.modelData > 0 ? parent.modelData : ""
                                      color: parent.today ? Theme.textOnPrimary : Theme.text; font.weight: parent.today ? Font.Bold : Font.Normal }
                            }
                        }
                    }
                    RoundBtn { label: "Today"; Layout.alignment: Qt.AlignHCenter; onClicked: { root.shownYear = new Date().getFullYear(); root.shownMonth = new Date().getMonth(); } }
                }

                ColumnLayout {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 14

                    // ---------------- weather ----------------
                    Card {
                        heading: "WEATHER" + (Settings.s.weatherPlace ? "  ·  " + Settings.s.weatherPlace.toUpperCase() : "")
                        Lbl { visible: !Weather.enabled; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.subtext
                              text: "Off. Enable it in Settings › Behavior › Weather." }
                        Lbl { visible: Weather.enabled && !Weather.data; text: Weather.error || "Loading…"; color: Theme.subtext }
                        RowLayout {
                            visible: !!Weather.data; spacing: 14
                            Text { text: Weather.describe(Weather.data?.current?.weather_code)[1]; color: Theme.primary; font.family: Theme.font; font.pixelSize: 42 }
                            ColumnLayout { spacing: 0
                                Text { text: Math.round(Weather.data?.current?.temperature_2m ?? 0) + Weather.unitName; color: Theme.text; font.family: Theme.font
                                       font.pixelSize: Theme.fontSize + 12; font.weight: Font.Bold }
                                Lbl { text: Weather.describe(Weather.data?.current?.weather_code)[0]; color: Theme.subtext } }
                            Item { Layout.fillWidth: true }
                            ColumnLayout { spacing: 2
                                Lbl { text: "Feels like " + Math.round(Weather.data?.current?.apparent_temperature ?? 0) + Weather.unitName; color: Theme.subtext }
                                Lbl { text: "Humidity " + (Weather.data?.current?.relative_humidity_2m ?? 0) + "%"; color: Theme.subtext }
                                Lbl { text: "Wind " + Math.round(Weather.data?.current?.wind_speed_10m ?? 0) + (Settings.s.weatherUnit === "imperial" ? " mph" : " km/h"); color: Theme.subtext } }
                        }
                        RowLayout {
                            visible: !!Weather.data?.daily; Layout.fillWidth: true; spacing: 6
                            Repeater { model: Weather.data?.daily?.time?.slice(1) ?? []
                                ColumnLayout { required property string modelData; required property int index; Layout.fillWidth: true; spacing: 0
                                    Lbl { Layout.alignment: Qt.AlignHCenter; color: Theme.subtext; font.pixelSize: Theme.fontSize - 3
                                          text: Qt.locale().dayName(new Date(modelData + "T12:00").getDay(), Locale.ShortFormat) }
                                    Text { Layout.alignment: Qt.AlignHCenter; color: Theme.primary; font.family: Theme.font; font.pixelSize: 20
                                           text: Weather.describe(Weather.data.daily.weather_code[index + 1])[1] }
                                    Lbl { Layout.alignment: Qt.AlignHCenter; font.pixelSize: Theme.fontSize - 3
                                          text: Math.round(Weather.data.daily.temperature_2m_max[index + 1]) + "° / " + Math.round(Weather.data.daily.temperature_2m_min[index + 1]) + "°" } } }
                        }
                    }

                    // ---------------- timers ----------------
                    Card {
                        heading: "TIMERS"
                        Flow {
                            Layout.fillWidth: true; spacing: 6
                            Repeater { model: [{ m: 5, l: "5 min" }, { m: 10, l: "10 min" }, { m: 25, l: "Pomodoro 25" }, { m: 45, l: "45 min" }, { m: 60, l: "1 hour" }]
                                RoundBtn { required property var modelData; label: modelData.l; onClicked: Timers.start(modelData.m, modelData.m === 25 ? "Pomodoro" : modelData.l) } }
                        }
                        Lbl { visible: Timers.items.length === 0; text: "No timers running"; color: Theme.subtext }
                        Repeater { model: Timers.items
                            ColumnLayout { required property var modelData; Layout.fillWidth: true; spacing: 3
                                RowLayout { Layout.fillWidth: true
                                    Lbl { text: modelData.label; Layout.fillWidth: true }
                                    Lbl { text: Timers.clock(Timers.remaining(modelData)); color: Theme.primary; font.weight: Font.Bold }
                                    RoundBtn { label: "✕"; onClicked: Timers.cancel(modelData.id) } }
                                Rectangle { Layout.fillWidth: true; height: 5; radius: 3; color: Theme.alpha(Theme.surface, 0.6)
                                    Rectangle { height: parent.height; radius: 3; color: Theme.primary
                                                width: parent.width * (1 - Timers.remaining(modelData) / modelData.total) } } }
                        }
                    }
                }
            }
        }
    }
}
