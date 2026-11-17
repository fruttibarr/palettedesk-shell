pragma Singleton
import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Current weather and a 4-day outlook from Open-Meteo (https://open-meteo.com, no account or key).
// OFF by default: when enabled, your latitude/longitude are sent to open-meteo.com about every 30 minutes
// while the dashboard is in use. Location is entered by hand (Settings > Behavior > Weather); nothing is guessed from your IP.
Singleton {
    id: root
    readonly property bool enabled: Settings.s.weatherEnabled && (Settings.s.weatherLat !== 0 || Settings.s.weatherLon !== 0)
    property var data: null          // parsed API reply
    property string error: ""
    property real fetchedAt: 0
    readonly property string unitName: Settings.s.weatherUnit === "imperial" ? "°F" : "°C"

    // WMO weather codes -> [description, nerd-font icon]
    function describe(code) {
        const t = { 0: ["Clear", "󰖙"], 1: ["Mostly clear", "󰖕"], 2: ["Partly cloudy", "󰖕"], 3: ["Overcast", "󰖐"],
                    45: ["Fog", "󰖑"], 48: ["Fog", "󰖑"], 51: ["Light drizzle", "󰖗"], 53: ["Drizzle", "󰖗"], 55: ["Heavy drizzle", "󰖗"],
                    61: ["Light rain", "󰖗"], 63: ["Rain", "󰖗"], 65: ["Heavy rain", "󰖖"], 71: ["Light snow", "󰖘"], 73: ["Snow", "󰖘"],
                    75: ["Heavy snow", "󰼶"], 80: ["Showers", "󰖗"], 81: ["Showers", "󰖗"], 82: ["Heavy showers", "󰖖"],
                    95: ["Thunderstorm", "󰖓"], 96: ["Thunderstorm", "󰖓"], 99: ["Thunderstorm", "󰖓"] };
        return t[code] ?? ["Unknown", "󰖐"];
    }

    function refresh(force) {
        if (!enabled) return;
        if (!force && Date.now() - fetchedAt < 30 * 60 * 1000) return;
        fetch.running = false; fetch.running = true;
    }

    Process {
        id: fetch
        command: ["curl", "-fsS", "--max-time", "15", "-A", "palettedesk-shell",
                  "https://api.open-meteo.com/v1/forecast?latitude=" + Settings.s.weatherLat + "&longitude=" + Settings.s.weatherLon
                  + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"
                  + "&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=4&timezone=auto"
                  + (Settings.s.weatherUnit === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text); root.error = ""; root.fetchedAt = Date.now(); }
                catch (e) { root.error = "Could not read the weather reply"; }
            }
        }
        onExited: (code, status) => { if (code !== 0) root.error = "Weather unavailable (offline?)"; }
    }
    Timer { interval: 30 * 60 * 1000; repeat: true; running: root.enabled; onTriggered: root.refresh(true) }
    Connections { target: Settings.s; function onWeatherLatChanged() { root.refresh(true); } function onWeatherLonChanged() { root.refresh(true); }
                  function onWeatherUnitChanged() { root.refresh(true); } function onWeatherEnabledChanged() { root.refresh(true); } }
}
