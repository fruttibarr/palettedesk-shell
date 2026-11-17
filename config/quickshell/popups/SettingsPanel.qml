import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Settings panel.  SUPER+,  /  gear in the control center  /  qs ipc call settings toggle
// Everything saves automatically to ~/.config/rice/settings.json.
Scope {
    id: root
    property int page: 0
    readonly property var cfg: Settings.s

    readonly property var pages: [
        { icon: "󰏘", name: "Themes",              component: themesPage },
        { icon: "󰉼", name: "Appearance",          component: appearancePage },
        { icon: "󰸉", name: "Wallpaper & Colors",  component: wallpaperPage },
        { icon: "󰂵", name: "Blur",                component: blurPage },
        { icon: "󰔎", name: "Color & Display",     component: colorPage },
        { icon: "󰖲", name: "Windows",             component: windowsPage },
        { icon: "󰕴", name: "Layouts",             component: layoutsPage },
        { icon: "󰕨", name: "Animations",          component: animationsPage },
        { icon: "󰍹", name: "Displays",            component: displaysPage },
        { icon: "󰖲", name: "Window rules",        component: rulesPage },
        { icon: "󰍜", name: "Bar",                 component: barPage },
        { icon: "󰀻", name: "Launcher",            component: launcherPage },
        { icon: "󰌌", name: "Input",               component: inputPage },
        { icon: "󰘳", name: "Keybinds",            component: keybindsPage },
        { icon: "󰆽", name: "Cursor & Gestures",   component: cursorPage },
        { icon: "󰒓", name: "Behavior",            component: behaviorPage },
        { icon: "󰒲", name: "Idle & Lock",         component: idlePage },
        { icon: "󰂚", name: "Notifications & OSD", component: notifPage },
        { icon: "󰑊", name: "Screen Recording",    component: recordingPage },
    ]

    IpcHandler {
        target: "settings"
        function toggle(): void { Globals.settingsOpen = !Globals.settingsOpen }
        // e.g.  qs ipc call settings set blurSize 12   /   ... set showStats false
        function set(key: string, value: string): string {
            if (!(key in Settings.defaults)) return "unknown setting: " + key;
            let v;
            try { v = JSON.parse(value); } catch (e) { v = value; }
            Settings.set(key, v);
            return "ok";
        }
        function get(key: string): string { return JSON.stringify(Settings.s[key]); }
        function page(index: int): void { root.page = index; Globals.settingsOpen = true; }
        function scroll(y: int): void { flick.contentY = y; }
        // e.g.  qs ipc call settings search "blur"
        function search(text: string): void { Globals.settingsOpen = true; root.query = text; }
        // jump straight to the best match, e.g.  qs ipc call settings jump "blur radius"
        function jump(text: string): string {
            Globals.settingsOpen = true;
            root.query = text;
            const r = root.results[0];
            if (!r) { return "no match"; }
            root.openResult(r);
            return root.pages[r.page].name + " > " + (r.section ? r.section + " > " : "") + r.label;
        }
    }

    // ---------- shared pieces ----------
    component PageHeader: RowLayout {
        id: ph
        property string title
        property string subtitle
        property var keys: []
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: ph.title
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 9
                font.weight: Font.Bold
            }
            Text {
                Layout.fillWidth: true
                text: ph.subtitle
                wrapMode: Text.Wrap
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
        ActionButton {
            visible: ph.keys.length > 0
            text: "󰑓  Reset page"
            onClicked: Settings.reset(ph.keys)
        }
    }

    component ActionButton: Rectangle {
        id: ab
        property string text
        property bool primary: false
        signal clicked()
        implicitWidth: abText.implicitWidth + 28
        implicitHeight: 34
        radius: 17
        color: primary ? (abMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
                       : Theme.alpha(Theme.surfaceContainerHigh, abMouse.containsMouse ? 0.95 : 0.6)
        scale: abMouse.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            id: abText
            anchors.centerIn: parent
            text: ab.text
            color: ab.primary ? Theme.textOnPrimary : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: abMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ab.clicked()
        }
    }

    component MiniButton: Rectangle {
        id: mb
        property string icon
        property bool enabledState: true
        signal clicked()
        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        opacity: enabledState ? 1 : 0.35
        color: Theme.alpha(Theme.surfaceContainerHigh, mbMouse.containsMouse && enabledState ? 0.95 : 0.6)
        Text {
            anchors.centerIn: parent
            text: mb.icon
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: 14
        }
        MouseArea {
            id: mbMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: mb.enabledState
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.clicked()
        }
    }

    // ---------- pages ----------
    Component {
        id: themesPage
        ColumnLayout {
            id: themes
            spacing: 16
            property string saveMsg: ""
            property string exportName: ""
            property bool bundleWall: false
            property string rights: ""
            property string shareMsg: ""
            PageHeader {
                title: "Themes"
                subtitle: "One click changes the wallpaper, colors, bar, window style and layout together. Tweak anything on the other pages afterwards; input, keybinds and display scale are never touched."
            }
            SettingSection {
                title: "Built-in themes"
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    Repeater {
                        model: Presets.builtins
                        ThemeCard {}
                    }
                }
            }
            SettingSection {
                title: "Share themes"
                SettingRow {
                    label: "Import a theme pack"; keywords: "pdtheme import share download theme pack"
                    description: themes.shareMsg || "Enter the path of a .pdtheme file. Packs can only carry visual settings: never keybinds or commands."
                    SettingText {
                        placeholder: "~/Downloads/theme.pdtheme"
                        onSubmitted: t => { const r = Presets.importPack(t); themes.shareMsg = r === "ok" ? "󰄬 Importing… you'll get a notification" : "Not imported: " + r; }
                    }
                }
                SettingRow {
                    label: "Export a theme"; keywords: "pdtheme export share save theme pack"
                    description: "Type the theme's name, then the file to write, and press Enter."
                    ColumnLayout {
                        spacing: 6
                        SettingText { placeholder: "Theme name (e.g. Frosted Glass)"; text: themes.exportName; onSubmitted: t => themes.exportName = t }
                        SettingText {
                            placeholder: "~/MyTheme.pdtheme"
                            onSubmitted: t => { const r = Presets.exportPack(themes.exportName, t, themes.bundleWall, themes.rights);
                                                themes.shareMsg = r === "ok" ? "󰄬 Exporting… you'll get a notification" : "Not exported: " + r; }
                        }
                    }
                }
                SettingRow {
                    label: "Include the wallpaper"
                    description: "Only if you have the right to share it (your own work, or its license allows it). Otherwise the pack carries settings only, which is the safe default."
                    Toggle { checked: themes.bundleWall; onToggled: v => themes.bundleWall = v }
                }
                SettingRow {
                    visible: themes.bundleWall
                    label: "Rights statement"
                    description: "Recorded in the pack, e.g. “my own render” or “CC0”."
                    SettingText { placeholder: "I have the right to share this because…"; text: themes.rights; onSubmitted: t => themes.rights = t }
                }
            }
            SettingSection {
                title: "Theme other apps"
                SettingRow {
                    label: "btop"; keywords: "app theme matugen btop"
                    description: "Off by default. Writes only colour files into the app's own folder: ~/.config/btop/themes/palettedesk.theme (pick it in btop's options)."
                    Toggle { checked: Settings.appThemeOn("btop") && root.cfg.appThemes !== ""; onToggled: v => Settings.setAppTheme("btop", v) }
                }
                SettingRow {
                    label: "Dark mode for GTK / libadwaita apps"; keywords: "app theme matugen gtk"
                    description: "Sets the system dark-mode preference (gsettings). Colours themselves already come from GTK CSS."
                    Toggle { checked: Settings.appThemeOn("gtk") && root.cfg.appThemes !== ""; onToggled: v => Settings.setAppTheme("gtk", v) }
                }
                SettingRow {
                    label: "VS Code"; keywords: "app theme matugen vscode"
                    description: "Writes a PaletteDesk colour theme into ~/.vscode/extensions; select it once in VS Code."
                    Toggle { checked: Settings.appThemeOn("vscode") && root.cfg.appThemes !== ""; onToggled: v => Settings.setAppTheme("vscode", v) }
                }
                SettingRow {
                    label: "Vesktop / Discord"; keywords: "app theme matugen vesktop"
                    description: "Writes ~/.config/vesktop/themes/palettedesk.theme.css; enable it in Vesktop's settings."
                    Toggle { checked: Settings.appThemeOn("vesktop") && root.cfg.appThemes !== ""; onToggled: v => Settings.setAppTheme("vesktop", v) }
                }
                SettingRow {
                    label: "Spotify (spicetify)"; keywords: "app theme matugen spicetify"
                    description: "Writes a PaletteDesk colour scheme into spicetify's Themes folder; needs spicetify."
                    Toggle { checked: Settings.appThemeOn("spicetify") && root.cfg.appThemes !== ""; onToggled: v => Settings.setAppTheme("spicetify", v) }
                }
            }
            SettingSection {
                title: "Your themes"
                SettingRow {
                    label: "Save current look as a theme"
                    keywords: "preset presets layout style rice profile save custom own look"
                    description: themes.saveMsg || "Keeps the current wallpaper and every visual setting. Type a name and press Enter; an existing name is overwritten."
                    SettingText {
                        placeholder: "Theme name"
                        onSubmitted: t => {
                            const r = Presets.saveCurrent(t);
                            themes.saveMsg = r === "ok" ? "󰄬 Saved “" + t.trim() + "”" : "Not saved: " + r;
                        }
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    visible: Presets.user.length > 0
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    Repeater {
                        model: Presets.user
                        ThemeCard {}
                    }
                    // keep cards the same width as above when there are fewer than three
                    Repeater {
                        model: Math.max(0, 3 - Presets.user.length)
                        Item { Layout.fillWidth: true; Layout.preferredWidth: 10 }
                    }
                }
            }
        }
    }

    Component {
        id: colorPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Color & Display"
                subtitle: "Adjust how the whole screen looks, like a monitor's picture menu. Applies live to everything, including games and videos."
                keys: ["adjBrightness", "adjContrast", "adjSaturation", "adjVibrance", "adjGamma", "adjHue", "adjRed", "adjGreen", "adjBlue", "screenShader", "nightLight", "nightTemp"]
            }
            SettingSection {
                title: "Picture"
                SettingRow {
                    label: "Brightness"; keywords: "brightness light dark exposure"
                    description: "Lifts or lowers everything on screen."
                    ValueSlider { from: -0.3; to: 0.3; stepSize: 0.01; displayScale: 100; suffix: ""; value: root.cfg.adjBrightness; onMoved: v => Settings.set("adjBrightness", v) }
                }
                SettingRow {
                    label: "Contrast"; keywords: "contrast punch"
                    description: "Separates lights from darks."
                    ValueSlider { from: 0.6; to: 1.6; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjContrast; onMoved: v => Settings.set("adjContrast", v) }
                }
                SettingRow {
                    label: "Saturation"; keywords: "saturation color colour vivid vibrancy intensity"
                    description: "0% is black and white, 100% is normal."
                    ValueSlider { from: 0; to: 2; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjSaturation; onMoved: v => Settings.set("adjSaturation", v) }
                }
                SettingRow {
                    label: "Vibrance"; keywords: "vibrance vibrant smart saturation"
                    description: "Boosts dull colors more than already vivid ones, so skin and skies stay natural."
                    ValueSlider { from: 0; to: 1; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjVibrance; onMoved: v => Settings.set("adjVibrance", v) }
                }
                SettingRow {
                    label: "Gamma"; keywords: "gamma midtones"
                    description: "Brightens or darkens the midtones without clipping."
                    ValueSlider { from: 0.6; to: 1.8; stepSize: 0.02; value: root.cfg.adjGamma; onMoved: v => Settings.set("adjGamma", v) }
                }
                SettingRow {
                    label: "Hue shift"; keywords: "hue rotate tint color wheel"
                    description: "Rotates every color around the color wheel."
                    ValueSlider { from: -180; to: 180; stepSize: 5; suffix: "°"; value: root.cfg.adjHue; onMoved: v => Settings.set("adjHue", v) }
                }
            }
            SettingSection {
                title: "Color balance"
                SettingRow {
                    label: "Red balance"; keywords: "color balance white point rgb red channel"
                    ValueSlider { from: 0.6; to: 1.4; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjRed; onMoved: v => Settings.set("adjRed", v) }
                }
                SettingRow {
                    label: "Green balance"; keywords: "color balance white point rgb green channel"
                    ValueSlider { from: 0.6; to: 1.4; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjGreen; onMoved: v => Settings.set("adjGreen", v) }
                }
                SettingRow {
                    label: "Blue balance"; keywords: "color balance white point rgb blue channel"
                    ValueSlider { from: 0.6; to: 1.4; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.adjBlue; onMoved: v => Settings.set("adjBlue", v) }
                }
            }
            SettingSection {
                title: "Night light"
                SettingRow {
                    label: "Warm the screen"; keywords: "night light blue light filter hyprsunset color temperature"
                    description: "Needs the hyprsunset package"
                    Toggle { checked: root.cfg.nightLight; onToggled: v => Settings.set("nightLight", v) }
                }
                SettingRow {
                    label: "Color temperature"
                    description: "Lower is warmer"
                    ValueSlider { from: 2000; to: 6500; stepSize: 100; suffix: " K"; value: root.cfg.nightTemp; onMoved: v => Settings.set("nightTemp", v) }
                }
            }
            SettingSection {
                title: "Special effect"
                SettingRow {
                    label: "Effect"; keywords: "shader grayscale sepia crt invert colorblind filter"
                    description: "Combines with the adjustments above. Uses a little more power and turns off direct scanout (fullscreen games)."
                    Flow {
                        width: 440; spacing: 6
                        Repeater {
                            model: Settings.shaderList
                            Rectangle {
                                required property var modelData
                                readonly property bool sel: root.cfg.screenShader === modelData.id
                                width: chipText.implicitWidth + 24; height: 30; radius: 15
                                color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, 0.7)
                                Text { id: chipText; anchors.centerIn: parent; text: parent.modelData.label; color: parent.sel ? Theme.textOnPrimary : Theme.text
                                       font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("screenShader", parent.modelData.id) }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearancePage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Appearance"
                subtitle: "Display scale and how the shell's glass panels look. Blur strength is on the Blur page."
                keys: ["monitorScale", "barOpacity", "panelOpacity", "terminalOpacity", "shellRadius", "fontSize", "fontFamily", "popupZoom", "shellAnimScale", "animLauncher", "animControlCenter", "animNotifs", "animPopups"]
            }
            SettingSection {
                title: "Display"
                SettingRow {
                    label: "Display scale"
                    keywords: "zoom zoomed big small dpi hidpi resolution size ui scaling"
                    description: "How big everything is. Lower = more room on screen. Auto picks 150% on this laptop, which feels zoomed in."
                }
                Segmented {
                    current: root.cfg.monitorScale
                    onPicked: v => Settings.set("monitorScale", v)
                    options: [{ label: "100%", value: 1 }, { label: "125%", value: 1.25 }, { label: "150%", value: 1.5 },
                              { label: "175%", value: 1.75 }, { label: "200%", value: 2 }, { label: "Auto", value: 0 }]
                }
            }
            SettingSection {
                title: "Transparency"
                SettingRow {
                    label: "Bar opacity"
                    description: "Lower = more see-through glass"
                    ValueSlider { from: 0.05; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.barOpacity; onMoved: v => Settings.set("barOpacity", v) }
                }
                SettingRow {
                    label: "Popup opacity"
                    description: "Control center, launcher, menus, notifications"
                    ValueSlider { from: 0.2; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.panelOpacity; onMoved: v => Settings.set("panelOpacity", v) }
                }
                SettingRow {
                    label: "Terminal opacity"
                    description: "kitty background (applies to newly opened windows)"
                    ValueSlider { from: 0.3; to: 1; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.terminalOpacity; onMoved: v => Settings.set("terminalOpacity", v) }
                }
            }
            SettingSection {
                title: "Shape & text"
                SettingRow {
                    label: "Shell corner radius"
                    description: "Bar and popups. Window corners are on the Windows page."
                    ValueSlider { from: 0; to: 24; stepSize: 1; suffix: " px"; value: root.cfg.shellRadius; onMoved: v => Settings.set("shellRadius", v) }
                }
                SettingRow {
                    label: "Font size"
                    ValueSlider { from: 10; to: 18; stepSize: 1; suffix: " px"; value: root.cfg.fontSize; onMoved: v => Settings.set("fontSize", v) }
                }
                SettingRow {
                    label: "Font"; keywords: "typeface family"
                    description: "Any installed family. Use a Nerd Font or the icons turn into boxes."
                    SettingText { text: root.cfg.fontFamily; placeholder: "JetBrainsMono Nerd Font"; onSubmitted: t => Settings.set("fontFamily", t.trim() || "JetBrainsMono Nerd Font") }
                }
            }
            SettingSection {
                title: "Popup motion"
                SettingRow {
                    label: "Zoom popups in"
                    description: "Launcher, control center and this panel grow slightly as they open. Off = plain fade."
                    Toggle { checked: root.cfg.popupZoom; onToggled: v => Settings.set("popupZoom", v) }
                }
                SettingRow {
                    label: "Popup animation length"
                    description: "Below 1× is snappier, above is more relaxed"
                    ValueSlider { from: 0.3; to: 2; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.shellAnimScale; onMoved: v => Settings.set("shellAnimScale", v) }
                }
            }
            SettingSection {
                title: "Individual popups"
                SettingRow {
                    label: "Per-popup animation length"
                    description: "Multiplies the overall length above. Below 1× is faster, above is slower."
                }
                SettingRow {
                    label: "Launcher"; keywords: "launcher app menu dock speed slow fast duration"
                    description: "Opening, closing and the bottom-dock slide"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animLauncher; onMoved: v => Settings.set("animLauncher", v) }
                }
                SettingRow {
                    label: "Control center"; keywords: "control center quick settings speed slow fast duration"
                    description: "Zoom in/out and the Wi-Fi / Bluetooth list"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animControlCenter; onMoved: v => Settings.set("animControlCenter", v) }
                }
                SettingRow {
                    label: "Notifications"; keywords: "notification toast popup speed slow fast duration"
                    description: "Toasts sliding in and out"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animNotifs; onMoved: v => Settings.set("animNotifs", v) }
                }
                SettingRow {
                    label: "Other popups"; keywords: "settings wallpaper clipboard power menu speed slow fast duration"
                    description: "This panel, wallpaper picker, clipboard, power menu, …"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animPopups; onMoved: v => Settings.set("animPopups", v) }
                }
            }
        }
    }

    Component {
        id: wallpaperPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Wallpaper & Colors"
                subtitle: "The whole desktop is themed from the wallpaper with Material You colors."
                keys: ["colorScheme", "parallaxEnabled", "parallaxStrength", "animatedWallpapers", "pauseOnBattery", "pauseWhenFullscreen", "wallCrispPixels", "albumWallpaper", "albumWallStyle", "albumWallKeepPaused", "albumVisualizer", "albumVizStyle", "albumVizColor", "albumVizBars", "albumVizOpacity", "albumVizHeight"]
            }
            SettingSection {
                title: "Current wallpaper"
                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    radius: 12
                    color: Theme.surfaceContainer
                    Image {
                        anchors.fill: parent
                        source: Theme.wallpaperStill ? "file://" + Theme.wallpaperStill : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 900
                        asynchronous: true
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: Theme.albumActive ? "󰎆  Album cover · " + (Media.player?.trackTitle || "now playing")
                                                : Theme.wallpaper.split("/").pop()
                        elide: Text.ElideMiddle
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                    ActionButton {
                        text: "󰒝  Random"
                        onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/set-wallpaper.sh"])
                    }
                    ActionButton {
                        primary: true
                        text: "󰸉  Choose…"
                        onClicked: { Globals.settingsOpen = false; Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"]); }
                    }
                }
            }
            SettingSection {
                title: "Album cover"
                SettingRow {
                    label: "Album cover wallpaper"; keywords: "music song track art artwork dynamic spotify now playing media cover"
                    description: "While music plays, the cover of the current track becomes the wallpaper and every color follows it. Your own wallpaper comes back when the music stops."
                    Toggle { checked: root.cfg.albumWallpaper; onToggled: v => Settings.set("albumWallpaper", v) }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper
                    label: "Cover style"; keywords: "album blur fill crop"
                    description: "Floating = the whole cover over a blurred copy of itself. Fill = the cover stretched across the screen (edges are cropped)."
                    Segmented {
                        current: root.cfg.albumWallStyle
                        onPicked: v => Settings.set("albumWallStyle", v)
                        options: [{ value: "cover", label: "Floating" }, { value: "fill", label: "Fill" }]
                    }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper
                    label: "Keep while paused"; keywords: "album pause stop"
                    description: "Off = go back to your wallpaper as soon as playback pauses"
                    Toggle { checked: root.cfg.albumWallKeepPaused; onToggled: v => Settings.set("albumWallKeepPaused", v) }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper
                    label: "Visualizer"; keywords: "audio music spectrum bars cava equalizer wave dots sound reactive"
                    description: "Animated audio bars behind your windows, reacting to whatever is playing"
                    Toggle { checked: root.cfg.albumVisualizer; onToggled: v => Settings.set("albumVisualizer", v) }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper && root.cfg.albumVisualizer
                    label: "Visualizer style"; keywords: "spectrum bars mirror wave dots"
                    description: "Mirrored puts the bass in the middle"
                    Segmented {
                        current: root.cfg.albumVizStyle
                        onPicked: v => Settings.set("albumVizStyle", v)
                        options: [{ value: "bars", label: "Bars" }, { value: "mirror", label: "Mirrored" },
                                  { value: "wave", label: "Wave" }, { value: "dots", label: "Dots" }]
                    }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper && root.cfg.albumVisualizer
                    label: "Visualizer color"
                    description: "Always taken from the cover's colors"
                    Segmented {
                        current: root.cfg.albumVizColor
                        onPicked: v => Settings.set("albumVizColor", v)
                        options: [{ value: "accent", label: "Accent" }, { value: "gradient", label: "Gradient" }, { value: "light", label: "Light" }]
                    }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper && root.cfg.albumVisualizer
                    label: "Detail"; keywords: "bars count resolution"
                    description: "How many bars"
                    Segmented {
                        current: root.cfg.albumVizBars
                        onPicked: v => Settings.set("albumVizBars", v)
                        options: [{ value: 24, label: "Few" }, { value: 48, label: "Normal" }, { value: 80, label: "Many" }]
                    }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper && root.cfg.albumVisualizer
                    label: "Height"
                    description: "How tall it can grow, as a share of the screen"
                    ValueSlider { from: 0.1; to: 0.6; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.albumVizHeight; onMoved: v => Settings.set("albumVizHeight", v) }
                }
                SettingRow {
                    visible: root.cfg.albumWallpaper && root.cfg.albumVisualizer
                    label: "Opacity"
                    ValueSlider { from: 0.2; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.albumVizOpacity; onMoved: v => Settings.set("albumVizOpacity", v) }
                }
            }
            SettingSection {
                title: "Parallax"
                SettingRow {
                    label: "Workspace parallax"
                    description: "The wallpaper slides a little as you move between workspaces"
                    Toggle { checked: root.cfg.parallaxEnabled; onToggled: v => Settings.set("parallaxEnabled", v) }
                }
                SettingRow {
                    visible: root.cfg.parallaxEnabled
                    label: "Strength"
                    description: "How far it travels from the first to the last workspace"
                    ValueSlider { from: 0.04; to: 0.4; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.parallaxStrength; onMoved: v => Settings.set("parallaxStrength", v) }
                }
            }
            SettingSection {
                title: "Animated wallpapers"
                Text {
                    Layout.fillWidth: true
                    text: "GIFs and videos (mp4, webm, mkv, mov) are supported. Find them under Animated in the picker. Colors come from a frame of the animation."
                    wrapMode: Text.Wrap
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
                SettingRow {
                    label: "Play animations"
                    description: "Off = show a still frame (saves battery and GPU)"
                    Toggle { checked: root.cfg.animatedWallpapers; onToggled: v => Settings.set("animatedWallpapers", v) }
                }
                SettingRow {
                    label: "Pause on battery"
                    Toggle { checked: root.cfg.pauseOnBattery; onToggled: v => Settings.set("pauseOnBattery", v) }
                }
                SettingRow {
                    label: "Pause under fullscreen windows"
                    description: "No point animating what you can't see"
                    Toggle { checked: root.cfg.pauseWhenFullscreen; onToggled: v => Settings.set("pauseWhenFullscreen", v) }
                }
                SettingRow {
                    label: "Crisp pixel art"; keywords: "blurry sharp nearest pixelated low resolution upscale"
                    description: "Wallpapers stretched 2x or more (pixel art, small GIFs) keep hard pixel edges instead of going blurry"
                    Toggle { checked: root.cfg.wallCrispPixels; onToggled: v => Settings.set("wallCrispPixels", v) }
                }
            }
            SettingSection {
                title: "Palette"
                Row {
                    spacing: 8
                    Repeater {
                        model: [
                            { c: Theme.primary, n: "Primary" }, { c: Theme.secondary, n: "Secondary" },
                            { c: Theme.tertiary, n: "Tertiary" }, { c: Theme.primaryContainer, n: "Container" },
                            { c: Theme.surfaceContainerHigh, n: "Surface" }, { c: Theme.error, n: "Error" },
                        ]
                        Column {
                            required property var modelData
                            spacing: 4
                            Rectangle {
                                width: 64; height: 36; radius: 10
                                color: parent.modelData.c
                                border.width: 1
                                border.color: Theme.alpha(Theme.outline, 0.3)
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.modelData.n
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }
                SettingRow {
                    label: "Color style"
                    description: "How colors are extracted from the wallpaper. Re-themes everything."
                }
                Segmented {
                    Layout.fillWidth: true
                    current: root.cfg.colorScheme
                    onPicked: v => Settings.set("colorScheme", v)
                    options: [
                        { label: "Tonal spot", value: "scheme-tonal-spot" },
                        { label: "Vibrant", value: "scheme-vibrant" },
                        { label: "Expressive", value: "scheme-expressive" },
                        { label: "Fidelity", value: "scheme-fidelity" },
                        { label: "Content", value: "scheme-content" },
                        { label: "Rainbow", value: "scheme-rainbow" },
                        { label: "Fruit salad", value: "scheme-fruit-salad" },
                        { label: "Neutral", value: "scheme-neutral" },
                        { label: "Monochrome", value: "scheme-monochrome" },
                    ]
                }
            }
        }
    }

    Component {
        id: blurPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Blur"
                subtitle: "Frosted glass behind the bar, popups, menus and translucent windows."
                keys: ["blurEnabled", "blurSize", "blurPasses", "blurBrightness", "blurVibrancy", "blurNoise", "blurPopups", "blurXray",
                       "blurContrast", "blurVibrancyDarkness", "blurSpecial"]
            }
            SettingSection {
                title: "Strength"
                SettingRow {
                    label: "Enable blur"
                    Toggle { checked: root.cfg.blurEnabled; onToggled: v => Settings.set("blurEnabled", v) }
                }
                SettingRow {
                    label: "Blur radius"; keywords: "size strength amount"
                    description: "How far each pass spreads"
                    ValueSlider { from: 1; to: 20; stepSize: 1; value: root.cfg.blurSize; onMoved: v => Settings.set("blurSize", v) }
                }
                SettingRow {
                    label: "Passes"; keywords: "quality strength iterations"
                    description: "More passes = stronger, smoother blur, but more GPU work"
                    ValueSlider { from: 1; to: 6; stepSize: 1; value: root.cfg.blurPasses; onMoved: v => Settings.set("blurPasses", v) }
                }
            }
            SettingSection {
                title: "Look"
                SettingRow {
                    label: "Brightness"
                    description: "Below 1 darkens the glass so text stays readable"
                    ValueSlider { from: 0.5; to: 1.3; stepSize: 0.05; decimals: 2; value: root.cfg.blurBrightness; onMoved: v => Settings.set("blurBrightness", v) }
                }
                SettingRow {
                    label: "Vibrancy"
                    description: "Boosts wallpaper colors seen through the blur"
                    ValueSlider { from: 0; to: 1; stepSize: 0.05; decimals: 2; value: root.cfg.blurVibrancy; onMoved: v => Settings.set("blurVibrancy", v) }
                }
                SettingRow {
                    label: "Grain"; keywords: "noise banding dither"
                    description: "Faint noise that hides color banding"
                    ValueSlider { from: 0; to: 0.1; stepSize: 0.005; decimals: 3; value: root.cfg.blurNoise; onMoved: v => Settings.set("blurNoise", v) }
                }
                SettingRow {
                    label: "Contrast"
                    ValueSlider { from: 0.5; to: 1.8; stepSize: 0.05; decimals: 2; value: root.cfg.blurContrast; onMoved: v => Settings.set("blurContrast", v) }
                }
                SettingRow {
                    label: "Vibrancy in dark areas"
                    description: "How much vibrancy also boosts darker colors"
                    ValueSlider { from: 0; to: 1; stepSize: 0.05; decimals: 2; value: root.cfg.blurVibrancyDarkness; onMoved: v => Settings.set("blurVibrancyDarkness", v) }
                }
            }
            SettingSection {
                title: "Where"
                SettingRow {
                    label: "Blur menus and dropdowns"
                    Toggle { checked: root.cfg.blurPopups; onToggled: v => Settings.set("blurPopups", v) }
                }
                SettingRow {
                    label: "X-ray"; keywords: "performance fast wallpaper"
                    description: "Floating windows blur only the wallpaper, not windows behind them. Faster."
                    Toggle { checked: root.cfg.blurXray; onToggled: v => Settings.set("blurXray", v) }
                }
                SettingRow {
                    label: "Blur behind the scratchpad"
                    description: "Frosts the desktop when the special workspace (SUPER+S) is open"
                    Toggle { checked: root.cfg.blurSpecial; onToggled: v => Settings.set("blurSpecial", v) }
                }
            }
        }
    }

    Component {
        id: windowsPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Windows"
                subtitle: "Spacing, borders, snapping and window effects. The tiling layout is on the Layouts page."
                keys: ["gapsIn", "gapsOut", "borderSize", "rounding", "activeOpacity", "inactiveOpacity", "dimInactive", "dimStrength", "shadowEnabled", "shadowRange", "drawTerminal", "drawTerminalCommand",
                       "roundingPower", "fullscreenOpacity", "dimSpecial", "shadowRenderPower", "shadowOffsetY", "resizeOnBorder", "borderGrabArea", "snapEnabled", "snapGap", "groupbarEnabled"]
            }
            SettingSection {
                title: "Draw a terminal"
                SettingRow {
                    label: "SUPER + drag on the desktop"
                    description: "Sketch a rectangle on an empty spot to open a floating terminal right there. SUPER+SHIFT+Enter works anywhere."
                    Toggle { checked: root.cfg.drawTerminal; onToggled: v => Settings.set("drawTerminal", v) }
                }
                SettingRow {
                    label: "Command"
                    description: "What to launch, e.g. kitty  or  kitty -e btop"
                    SettingText { text: root.cfg.drawTerminalCommand; placeholder: "kitty"; onSubmitted: t => Settings.set("drawTerminalCommand", t.trim() || "kitty") }
                }
            }
            SettingSection {
                title: "Spacing"
                SettingRow {
                    label: "Gaps between windows"
                    ValueSlider { from: 0; to: 30; stepSize: 1; suffix: " px"; value: root.cfg.gapsIn; onMoved: v => Settings.set("gapsIn", v) }
                }
                SettingRow {
                    label: "Gaps around the screen edge"
                    description: "The bar's margin follows this too"
                    ValueSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: root.cfg.gapsOut; onMoved: v => Settings.set("gapsOut", v) }
                }
            }
            SettingSection {
                title: "Borders"
                SettingRow {
                    label: "Border width"
                    ValueSlider { from: 0; to: 6; stepSize: 1; suffix: " px"; value: root.cfg.borderSize; onMoved: v => Settings.set("borderSize", v) }
                }
                SettingRow {
                    label: "Corner rounding"
                    ValueSlider { from: 0; to: 30; stepSize: 1; suffix: " px"; value: root.cfg.rounding; onMoved: v => Settings.set("rounding", v) }
                }
                SettingRow {
                    label: "Corner curve"; keywords: "squircle rounding power smooth"
                    description: "2 = circular, higher = smoother squircle corners"
                    ValueSlider { from: 1; to: 10; stepSize: 0.5; decimals: 1; value: root.cfg.roundingPower; onMoved: v => Settings.set("roundingPower", v) }
                }
                SettingRow {
                    label: "Resize by dragging borders"
                    description: "Grab a window's edge or the gap next to it to resize"
                    Toggle { checked: root.cfg.resizeOnBorder; onToggled: v => Settings.set("resizeOnBorder", v) }
                }
                SettingRow {
                    visible: root.cfg.resizeOnBorder
                    label: "Grab area"
                    description: "Extra invisible border you can grab"
                    ValueSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: root.cfg.borderGrabArea; onMoved: v => Settings.set("borderGrabArea", v) }
                }
            }
            SettingSection {
                title: "Floating windows"
                SettingRow {
                    label: "Snap to edges"
                    description: "Floating windows stick to screen edges and other windows while dragged"
                    Toggle { checked: root.cfg.snapEnabled; onToggled: v => Settings.set("snapEnabled", v) }
                }
                SettingRow {
                    visible: root.cfg.snapEnabled
                    label: "Snap distance"
                    ValueSlider { from: 2; to: 50; stepSize: 1; suffix: " px"; value: root.cfg.snapGap; onMoved: v => Settings.set("snapGap", v) }
                }
                SettingRow {
                    label: "Group tab bar"
                    description: "Tab strip shown above grouped windows"
                    Toggle { checked: root.cfg.groupbarEnabled; onToggled: v => Settings.set("groupbarEnabled", v) }
                }
            }
            SettingSection {
                title: "Opacity & dimming"
                SettingRow {
                    label: "Focused window opacity"
                    description: "Affects the whole window including text"
                    ValueSlider { from: 0.5; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"; value: root.cfg.activeOpacity; onMoved: v => Settings.set("activeOpacity", v) }
                }
                SettingRow {
                    label: "Unfocused window opacity"
                    ValueSlider { from: 0.5; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"; value: root.cfg.inactiveOpacity; onMoved: v => Settings.set("inactiveOpacity", v) }
                }
                SettingRow {
                    label: "Dim unfocused windows"
                    Toggle { checked: root.cfg.dimInactive; onToggled: v => Settings.set("dimInactive", v) }
                }
                SettingRow {
                    visible: root.cfg.dimInactive
                    label: "Dim strength"
                    ValueSlider { from: 0.05; to: 0.6; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.dimStrength; onMoved: v => Settings.set("dimStrength", v) }
                }
                SettingRow {
                    label: "Fullscreen window opacity"
                    ValueSlider { from: 0.5; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"; value: root.cfg.fullscreenOpacity; onMoved: v => Settings.set("fullscreenOpacity", v) }
                }
                SettingRow {
                    label: "Dim behind the scratchpad"; keywords: "special workspace darken"
                    description: "Darkens the workspace under the special workspace"
                    ValueSlider { from: 0; to: 0.8; stepSize: 0.05; displayScale: 100; suffix: "%"; zeroText: "Off"; value: root.cfg.dimSpecial; onMoved: v => Settings.set("dimSpecial", v) }
                }
            }
            SettingSection {
                title: "Shadows"
                SettingRow {
                    label: "Window shadows"
                    Toggle { checked: root.cfg.shadowEnabled; onToggled: v => Settings.set("shadowEnabled", v) }
                }
                SettingRow {
                    visible: root.cfg.shadowEnabled
                    label: "Shadow size"
                    ValueSlider { from: 2; to: 50; stepSize: 1; suffix: " px"; value: root.cfg.shadowRange; onMoved: v => Settings.set("shadowRange", v) }
                }
                SettingRow {
                    visible: root.cfg.shadowEnabled
                    label: "Falloff"; keywords: "shadow power sharpness softness"
                    description: "1 = soft and wide, 4 = tight and dark"
                    ValueSlider { from: 1; to: 4; stepSize: 1; value: root.cfg.shadowRenderPower; onMoved: v => Settings.set("shadowRenderPower", v) }
                }
                SettingRow {
                    visible: root.cfg.shadowEnabled
                    label: "Drop"; keywords: "shadow offset"
                    description: "Moves the shadow downward, like light from above"
                    ValueSlider { from: -10; to: 20; stepSize: 1; suffix: " px"; value: root.cfg.shadowOffsetY; onMoved: v => Settings.set("shadowOffsetY", v) }
                }
            }
        }
    }

    Component {
        id: layoutsPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Layouts"
                subtitle: "How tiled windows are arranged. Options for the other layouts are kept for when you switch."
                keys: ["layout", "dwindlePreserveSplit", "dwindleSmartSplit", "dwindleForceSplit", "dwindleSmartResizing",
                       "masterNewStatus", "masterMfact", "masterOrientation", "masterNewOnTop", "scrollColumnWidth", "scrollFullscreenOne"]
            }
            SettingSection {
                title: "Tiling layout"
                SettingRow {
                    label: "Layout"
                    description: "Dwindle splits in a spiral, Master keeps one big window, Scrolling places windows in columns"
                }
                Segmented {
                    current: root.cfg.layout
                    onPicked: v => Settings.set("layout", v)
                    options: [{ label: "Dwindle", value: "dwindle" }, { label: "Master", value: "master" }, { label: "Scrolling", value: "scrolling" }]
                }
            }
            SettingSection {
                visible: root.cfg.layout === "dwindle"
                title: "Dwindle"
                SettingRow {
                    label: "New windows split"
                    description: "Which side of the focused window a new one goes"
                }
                Segmented {
                    current: root.cfg.dwindleForceSplit
                    onPicked: v => Settings.set("dwindleForceSplit", v)
                    options: [{ label: "Toward the mouse", value: 0 }, { label: "Left / top", value: 1 }, { label: "Right / bottom", value: 2 }]
                }
                SettingRow {
                    label: "Smart split"
                    description: "Split direction follows exactly where the pointer is over the window"
                    Toggle { checked: root.cfg.dwindleSmartSplit; onToggled: v => Settings.set("dwindleSmartSplit", v) }
                }
                SettingRow {
                    label: "Keep split direction"
                    description: "A split stays horizontal/vertical even when the window is resized (SUPER+J flips it)"
                    Toggle { checked: root.cfg.dwindlePreserveSplit; onToggled: v => Settings.set("dwindlePreserveSplit", v) }
                }
                SettingRow {
                    label: "Smart resizing"
                    description: "Resizing moves the edge nearest the pointer"
                    Toggle { checked: root.cfg.dwindleSmartResizing; onToggled: v => Settings.set("dwindleSmartResizing", v) }
                }
            }
            SettingSection {
                visible: root.cfg.layout === "master"
                title: "Master"
                SettingRow { label: "Master area position" }
                Segmented {
                    current: root.cfg.masterOrientation
                    onPicked: v => Settings.set("masterOrientation", v)
                    options: [{ label: "Left", value: "left" }, { label: "Right", value: "right" }, { label: "Top", value: "top" },
                              { label: "Bottom", value: "bottom" }, { label: "Center", value: "center" }]
                }
                SettingRow {
                    label: "Master size"
                    ValueSlider { from: 0.2; to: 0.9; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.masterMfact; onMoved: v => Settings.set("masterMfact", v) }
                }
                SettingRow { label: "New windows become" }
                Segmented {
                    current: root.cfg.masterNewStatus
                    onPicked: v => Settings.set("masterNewStatus", v)
                    options: [{ label: "Master", value: "master" }, { label: "Stack", value: "slave" }, { label: "Same as focused", value: "inherit" }]
                }
                SettingRow {
                    label: "New windows on top of the stack"
                    Toggle { checked: root.cfg.masterNewOnTop; onToggled: v => Settings.set("masterNewOnTop", v) }
                }
            }
            SettingSection {
                visible: root.cfg.layout === "scrolling"
                title: "Scrolling"
                SettingRow {
                    label: "Column width"
                    description: "Width of a new column, as a share of the screen"
                    ValueSlider { from: 0.2; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.scrollColumnWidth; onMoved: v => Settings.set("scrollColumnWidth", v) }
                }
                SettingRow {
                    label: "Lone column fills the screen"
                    Toggle { checked: root.cfg.scrollFullscreenOne; onToggled: v => Settings.set("scrollFullscreenOne", v) }
                }
            }
        }
    }

    Component {
        id: animationsPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Animations"
                subtitle: "Window, workspace and border motion. Popup motion is on the Appearance page."
                keys: ["animationsEnabled", "rotatingBorder", "animScale", "windowAnimStyle", "wsAnimStyle", "borderRotateSpeed", "animateResizes", "animateDrag", "animWinIn", "animWinOut", "animWinMove", "animFade", "animWorkspaces"]
            }
            SettingSection {
                title: "Motion"
                SettingRow {
                    label: "Window & workspace animations"
                    description: "Turning this off makes everything instant"
                    Toggle { checked: root.cfg.animationsEnabled; onToggled: v => Settings.set("animationsEnabled", v) }
                }
                SettingRow {
                    visible: root.cfg.animationsEnabled
                    label: "Animation length"
                    description: "Below 1× is snappier, above is slower and floatier"
                    ValueSlider { from: 0.3; to: 2.5; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animScale; onMoved: v => Settings.set("animScale", v) }
                }
            }
            SettingSection {
                visible: root.cfg.animationsEnabled
                title: "Individual animations"
                SettingRow {
                    label: "Per-animation length"
                    description: "Multiplies the overall length above. Below 1× is faster, above is slower."
                }
                SettingRow {
                    label: "Window open"; keywords: "window open spawn speed slow fast duration"
                    description: "New windows appearing"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animWinIn; onMoved: v => Settings.set("animWinIn", v) }
                }
                SettingRow {
                    label: "Window close"; keywords: "window close speed slow fast duration"
                    description: "Windows disappearing"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animWinOut; onMoved: v => Settings.set("animWinOut", v) }
                }
                SettingRow {
                    label: "Window move & resize"; keywords: "window move tile speed slow fast duration"
                    description: "Tiling layout changes and moving windows"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animWinMove; onMoved: v => Settings.set("animWinMove", v) }
                }
                SettingRow {
                    label: "Fades"; keywords: "fade opacity speed slow fast duration"
                    description: "Opacity fades (windows, dimming)"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animFade; onMoved: v => Settings.set("animFade", v) }
                }
                SettingRow {
                    label: "Workspace switch"; keywords: "workspace switch speed slow fast duration"
                    description: "Switching between workspaces"
                    ValueSlider { from: 0.3; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.animWorkspaces; onMoved: v => Settings.set("animWorkspaces", v) }
                }
            }
            SettingSection {
                visible: root.cfg.animationsEnabled
                title: "Styles"
                SettingRow { label: "Windows open with" }
                Segmented {
                    current: root.cfg.windowAnimStyle
                    onPicked: v => Settings.set("windowAnimStyle", v)
                    options: [{ label: "Pop in", value: "popin 80%" }, { label: "Big pop", value: "popin 50%" },
                              { label: "Slide", value: "slide" }, { label: "Genie", value: "gnomed" }]
                }
                SettingRow { label: "Workspaces switch with" }
                Segmented {
                    current: root.cfg.wsAnimStyle
                    onPicked: v => Settings.set("wsAnimStyle", v)
                    options: [{ label: "Slide + fade", value: "slidefade 12%" }, { label: "Slide", value: "slide" },
                              { label: "Vertical slide", value: "slidevert" }, { label: "Vertical + fade", value: "slidefadevert 15%" },
                              { label: "Fade", value: "fade" }]
                }
                SettingRow {
                    label: "Animate manual resizes"
                    description: "Smooth resizing with SUPER+right-drag (can feel laggy)"
                    Toggle { checked: root.cfg.animateResizes; onToggled: v => Settings.set("animateResizes", v) }
                }
                SettingRow {
                    label: "Animate window dragging"
                    description: "Windows trail slightly behind the pointer while moved"
                    Toggle { checked: root.cfg.animateDrag; onToggled: v => Settings.set("animateDrag", v) }
                }
            }
            SettingSection {
                title: "Border"
                SettingRow {
                    label: "Rotating border gradient"; keywords: "border animation spin"
                    description: "Slowly spins the active window's border colors. Runs continuously; turn off to save battery."
                    Toggle { checked: root.cfg.rotatingBorder; onToggled: v => Settings.set("rotatingBorder", v) }
                }
                SettingRow {
                    visible: root.cfg.rotatingBorder
                    label: "Time per rotation"; keywords: "border speed spin"
                    description: "Higher = slower spin"
                    ValueSlider { from: 10; to: 100; stepSize: 5; suffix: " ds"; value: root.cfg.borderRotateSpeed; onMoved: v => Settings.set("borderRotateSpeed", v) }
                }
            }
        }
    }

    // ---- bar layout helpers ----
    readonly property var barModules: [
        { id: "workspaces", icon: "󰍹", name: "Workspaces" },
        { id: "title",      icon: "󰖯", name: "Window title" },
        { id: "media",      icon: "󰎆", name: "Now playing" },
        { id: "lyrics",     icon: "󰎈", name: "Live lyrics" },
        { id: "record",     icon: "󰑊", name: "Recording timer (only while recording)" },
        { id: "clock",      icon: "󰥔", name: "Clock" },
        { id: "tray",       icon: "󰀻", name: "System tray" },
        { id: "stats",      icon: "󰍛", name: "CPU & RAM" },
        { id: "kbd",        icon: "󰌌", name: "Keyboard layout (only with several layouts)" },
        { id: "status",     icon: "󰂚", name: "Status (control center)" },
        { id: "launcher",   icon: "󰣇", name: "Launcher button" },
        { id: "power",      icon: "󰐥", name: "Power button" },
    ]
    function cloneLayout() {
        const L = cfg.barLayout ?? {};
        return { left: [...(L.left ?? [])], center: [...(L.center ?? [])], right: [...(L.right ?? [])] };
    }
    function zoneOf(id) {
        const L = cfg.barLayout ?? {};
        for (const z of ["left", "center", "right"]) if ((L[z] ?? []).includes(id)) return z;
        return "hidden";
    }
    function moveModule(id, zone) {
        const L = cloneLayout();
        for (const z of ["left", "center", "right"]) L[z] = L[z].filter(x => x !== id);
        if (zone !== "hidden") L[zone].push(id);
        Settings.set("barLayout", L);
    }
    function shiftModule(id, dir) {
        const L = cloneLayout();
        const z = zoneOf(id);
        if (z === "hidden") return;
        const arr = L[z], i = arr.indexOf(id), j = i + dir;
        if (j < 0 || j >= arr.length) return;
        [arr[i], arr[j]] = [arr[j], arr[i]];
        Settings.set("barLayout", L);
    }

    Component {
        id: barPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Bar"
                subtitle: "Position, style, layout and every module. Changes show live."
                keys: ["barPosition", "barStyle", "barHeight", "barFollowGaps", "barMargin", "barOpacity", "barVibrancy",
                       "barBorder", "barShadow", "barSheen", "chipStyle", "chipShape", "barLayout",
                       "wsCount", "wsStyle", "wsShowEmpty", "wsOpacity", "wsActiveOpacity", "clock24h", "clockSeconds", "showDate", "dateFormat", "clockIcon",
                       "statusBell", "statusNetwork", "statusBluetooth", "statusVolume", "statusBattery", "statusPercent",
                       "statsStyle", "mediaMaxWidth", "mediaBars", "lyricsMaxWidth", "lyricsOffset", "titleMaxWidth"]
            }

            SettingSection {
                title: "Position & style"
                SettingRow { label: "Position" }
                Segmented {
                    current: root.cfg.barPosition
                    onPicked: v => Settings.set("barPosition", v)
                    options: [{ label: "󰁝  Top", value: "top" }, { label: "󰁅  Bottom", value: "bottom" }]
                }
                SettingRow {
                    label: "Style"
                    description: "Floating: rounded with a gap · Attached: edge to edge · Islands: no bar, just floating chips"
                }
                Segmented {
                    current: root.cfg.barStyle
                    onPicked: v => Settings.set("barStyle", v)
                    options: [{ label: "Floating", value: "floating" }, { label: "Attached", value: "attached" }, { label: "Islands", value: "islands" }]
                }
                SettingRow {
                    label: "Height"
                    ValueSlider { from: 28; to: 56; stepSize: 1; suffix: " px"; value: root.cfg.barHeight; onMoved: v => Settings.set("barHeight", v) }
                }
                SettingRow {
                    visible: root.cfg.barStyle !== "attached"
                    label: "Match window gaps"
                    description: "Use the screen-edge gap from the Windows page as the bar's margin"
                    Toggle { checked: root.cfg.barFollowGaps; onToggled: v => Settings.set("barFollowGaps", v) }
                }
                SettingRow {
                    visible: root.cfg.barStyle !== "attached" && !root.cfg.barFollowGaps
                    label: "Margin"
                    ValueSlider { from: 0; to: 40; stepSize: 1; suffix: " px"; value: root.cfg.barMargin; onMoved: v => Settings.set("barMargin", v) }
                }
            }

            SettingSection {
                title: "Look"
                SettingRow {
                    label: "Background opacity"
                    ValueSlider { from: 0.05; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.barOpacity; onMoved: v => Settings.set("barOpacity", v) }
                }
                SettingRow {
                    label: "Vibrancy"; keywords: "bar vibrancy vibrant color tint accent saturation"
                    description: "Tints the bar toward your wallpaper's accent color. 0% is the plain dark surface."
                    ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.barVibrancy; onMoved: v => Settings.set("barVibrancy", v) }
                }
                SettingRow {
                    label: "Border"
                    Toggle { checked: root.cfg.barBorder; onToggled: v => Settings.set("barBorder", v) }
                }
                SettingRow {
                    label: "Drop shadow"
                    Toggle { checked: root.cfg.barShadow; onToggled: v => Settings.set("barShadow", v) }
                }
                SettingRow {
                    label: "Color sheen"
                    description: "Faint wallpaper-colored gradient and glass highlight"
                    Toggle { checked: root.cfg.barSheen; onToggled: v => Settings.set("barSheen", v) }
                }
                SettingRow { label: "Module style" }
                Segmented {
                    current: root.cfg.chipStyle
                    onPicked: v => Settings.set("chipStyle", v)
                    options: [{ label: "Filled", value: "filled" }, { label: "Outlined", value: "outlined" }, { label: "Flat", value: "flat" }]
                }
                SettingRow { label: "Module shape" }
                Segmented {
                    current: root.cfg.chipShape
                    onPicked: v => Settings.set("chipShape", v)
                    options: [{ label: "Pill", value: "pill" }, { label: "Rounded", value: "rounded" }, { label: "Square", value: "square" }]
                }
            }

            SettingSection {
                title: "Layout"
                Text {
                    Layout.fillWidth: true
                    text: "Pick where each module goes. Arrows change the order inside its zone."
                    wrapMode: Text.Wrap
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
                Repeater {
                    model: root.barModules
                    RowLayout {
                        id: modRow
                        required property var modelData
                        readonly property string zone: root.zoneOf(modelData.id)
                        readonly property var zoneList: (root.cfg.barLayout ?? {})[zone] ?? []
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: modRow.modelData.icon
                            color: modRow.zone === "hidden" ? Theme.outline : Theme.primary
                            font.family: Theme.font
                            font.pixelSize: 16
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modRow.modelData.name
                            elide: Text.ElideRight
                            color: modRow.zone === "hidden" ? Theme.subtext : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        MiniButton {
                            icon: "󰁍"
                            visible: modRow.zone !== "hidden"
                            enabledState: modRow.zoneList.indexOf(modRow.modelData.id) > 0
                            onClicked: root.shiftModule(modRow.modelData.id, -1)
                        }
                        MiniButton {
                            icon: "󰁔"
                            visible: modRow.zone !== "hidden"
                            enabledState: modRow.zoneList.indexOf(modRow.modelData.id) < modRow.zoneList.length - 1
                            onClicked: root.shiftModule(modRow.modelData.id, 1)
                        }
                        Segmented {
                            current: modRow.zone
                            onPicked: v => root.moveModule(modRow.modelData.id, v)
                            options: [{ label: "Left", value: "left" }, { label: "Center", value: "center" },
                                      { label: "Right", value: "right" }, { label: "Off", value: "hidden" }]
                        }
                    }
                }
            }

            SettingSection {
                title: "Workspaces"
                SettingRow {
                    label: "Always show"
                    description: "Workspaces beyond this appear while they have windows"
                    ValueSlider { from: 1; to: 10; stepSize: 1; value: root.cfg.wsCount; onMoved: v => Settings.set("wsCount", v) }
                }
                SettingRow {
                    label: "Show empty workspaces"
                    Toggle { checked: root.cfg.wsShowEmpty; onToggled: v => Settings.set("wsShowEmpty", v) }
                }
                SettingRow {
                    label: "Background opacity"
                    description: "How see-through the workspaces capsule is"
                    keywords: "workspaces transparency transparent alpha opaque"
                    ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.wsOpacity; onMoved: v => Settings.set("wsOpacity", v) }
                }
                SettingRow {
                    label: "Active pill opacity"
                    description: "The highlight behind the current workspace"
                    keywords: "workspaces transparency transparent alpha opaque indicator"
                    ValueSlider { from: 0; to: 1; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.wsActiveOpacity; onMoved: v => Settings.set("wsActiveOpacity", v) }
                }
                SettingRow { label: "Style" }
                Segmented {
                    current: root.cfg.wsStyle
                    onPicked: v => Settings.set("wsStyle", v)
                    options: [{ label: "1 2 3", value: "numbers" }, { label: "● ○ ○", value: "dots" },
                              { label: "I II III", value: "roman" }, { label: "一 二 三", value: "kanji" }]
                }
            }

            SettingSection {
                title: "Clock"
                SettingRow {
                    label: "24-hour time"
                    Toggle { checked: root.cfg.clock24h; onToggled: v => Settings.set("clock24h", v) }
                }
                SettingRow {
                    label: "Show seconds"
                    Toggle { checked: root.cfg.clockSeconds; onToggled: v => Settings.set("clockSeconds", v) }
                }
                SettingRow {
                    label: "Clock icon"
                    Toggle { checked: root.cfg.clockIcon; onToggled: v => Settings.set("clockIcon", v) }
                }
                SettingRow {
                    label: "Show date"
                    description: "Hovering the clock always shows the full date"
                    Toggle { checked: root.cfg.showDate; onToggled: v => Settings.set("showDate", v) }
                }
                Segmented {
                    visible: root.cfg.showDate
                    current: root.cfg.dateFormat
                    onPicked: v => Settings.set("dateFormat", v)
                    options: [{ label: "Mon 16 Nov", value: "short" }, { label: "Monday, 16 November", value: "long" },
                              { label: "16/11/2026", value: "numeric" }, { label: "2026-11-16", value: "iso" }]
                }
            }

            SettingSection {
                title: "Status area"
                SettingRow {
                    label: "Notifications bell"
                    Toggle { checked: root.cfg.statusBell; onToggled: v => Settings.set("statusBell", v) }
                }
                SettingRow {
                    label: "Network"
                    Toggle { checked: root.cfg.statusNetwork; onToggled: v => Settings.set("statusNetwork", v) }
                }
                SettingRow {
                    label: "Bluetooth"
                    Toggle { checked: root.cfg.statusBluetooth; onToggled: v => Settings.set("statusBluetooth", v) }
                }
                SettingRow {
                    label: "Volume"
                    Toggle { checked: root.cfg.statusVolume; onToggled: v => Settings.set("statusVolume", v) }
                }
                SettingRow {
                    label: "Battery"
                    Toggle { checked: root.cfg.statusBattery; onToggled: v => Settings.set("statusBattery", v) }
                }
                SettingRow {
                    label: "Show percentages"
                    description: "Off = icons only"
                    Toggle { checked: root.cfg.statusPercent; onToggled: v => Settings.set("statusPercent", v) }
                }
            }

            SettingSection {
                title: "Other modules"
                SettingRow { label: "CPU & RAM style" }
                Segmented {
                    current: root.cfg.statsStyle
                    onPicked: v => Settings.set("statsStyle", v)
                    options: [{ label: "◔ Rings", value: "rings" }, { label: "󰍛 Icons", value: "text" }]
                }
                SettingRow {
                    label: "Now playing: max title width"
                    ValueSlider { from: 80; to: 400; stepSize: 10; suffix: " px"; value: root.cfg.mediaMaxWidth; onMoved: v => Settings.set("mediaMaxWidth", v) }
                }
                SettingRow {
                    label: "Now playing: bouncing bars"
                    Toggle { checked: root.cfg.mediaBars; onToggled: v => Settings.set("mediaBars", v) }
                }
                SettingRow {
                    label: "Live lyrics: max width"
                    description: "Longer lines scroll while they're sung"
                    keywords: "lrclib song karaoke"
                    ValueSlider { from: 120; to: 700; stepSize: 10; suffix: " px"; value: root.cfg.lyricsMaxWidth; onMoved: v => Settings.set("lyricsMaxWidth", v) }
                }
                SettingRow {
                    label: "Live lyrics: timing"
                    description: "Positive shows lines earlier, negative later"
                    keywords: "lrclib sync offset delay"
                    ValueSlider { from: -3000; to: 3000; stepSize: 100; suffix: " ms"; value: root.cfg.lyricsOffset; onMoved: v => Settings.set("lyricsOffset", v) }
                }
                SettingRow {
                    label: "Window title: max width"
                    ValueSlider { from: 80; to: 500; stepSize: 10; suffix: " px"; value: root.cfg.titleMaxWidth; onMoved: v => Settings.set("titleMaxWidth", v) }
                }
            }
        }
    }

    Component {
        id: launcherPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Launcher"
                subtitle: "Everything about the app launcher (SUPER+Space). Changes show the next time it opens."
                keys: ["launcherWidth", "launcherHeight", "launcherPosition", "launcherDockFlares", "launcherDefaultView", "launcherIconSize", "launcherShowFrequent",
                       "launcherFrequentCount", "launcherShowCategories", "launcherShowFooter", "launcherShowCount", "launcherShowDesc",
                       "launcherShowActions", "launcherHints", "launcherOrbs", "launcherOrbStrength", "launcherPulse", "launcherStagger",
                       "launcherLaunchAnim", "launcherRankByUsage", "launcherMaxResults", "launcherCalc", "launcherRun", "launcherWeb",
                       "launcherWebEngine", "launcherTerminal", "launcherHidden"]
            }
            RowLayout {
                ActionButton {
                    primary: true
                    text: "󰀻  Open launcher"
                    onClicked: { Globals.settingsOpen = false; Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"]); }
                }
            }
            SettingSection {
                title: "Size & position"
                SettingRow {
                    label: "Width"
                    ValueSlider { from: 480; to: 1200; stepSize: 20; suffix: " px"; value: root.cfg.launcherWidth; onMoved: v => Settings.set("launcherWidth", v) }
                }
                SettingRow {
                    label: "Height"
                    ValueSlider { from: 360; to: 900; stepSize: 20; suffix: " px"; value: root.cfg.launcherHeight; onMoved: v => Settings.set("launcherHeight", v) }
                }
                SettingRow {
                    label: "Position"; keywords: "dock docked bottom edge slide up pop out"
                    description: root.cfg.barPosition === "bottom" ? "Docked to bottom isn't available while the bar is at the bottom" : ""
                }
                Segmented {
                    current: root.cfg.launcherPosition === "bottom" && root.cfg.barPosition === "bottom" ? "upper" : root.cfg.launcherPosition
                    onPicked: v => Settings.set("launcherPosition", v)
                    options: [{ label: "Upper third", value: "upper" }, { label: "Centered", value: "center" },
                              { label: "Docked to bottom", value: "bottom", disabled: root.cfg.barPosition === "bottom" }]
                }
                SettingRow {
                    visible: root.cfg.launcherPosition === "bottom" && root.cfg.barPosition !== "bottom"
                    label: "Edge flares"; keywords: "dock corners curve concave"
                    description: "Curved corners where the launcher meets the screen edge, so it looks like it grows out of it"
                    Toggle { checked: root.cfg.launcherDockFlares; onToggled: v => Settings.set("launcherDockFlares", v) }
                }
            }
            SettingSection {
                title: "Browsing"
                SettingRow {
                    label: "Show apps as"
                    description: "What you see before typing anything"
                }
                Segmented {
                    current: root.cfg.launcherDefaultView
                    onPicked: v => Settings.set("launcherDefaultView", v)
                    options: [{ label: "󰕰  Grid", value: "grid" }, { label: "󰉹  List", value: "list" }]
                }
                SettingRow {
                    visible: root.cfg.launcherDefaultView === "grid"
                    label: "Grid icon size"
                    ValueSlider { from: 32; to: 72; stepSize: 2; suffix: " px"; value: root.cfg.launcherIconSize; onMoved: v => Settings.set("launcherIconSize", v) }
                }
                SettingRow {
                    label: "Category chips"
                    description: "Develop, Internet, Media… (Tab cycles them)"
                    Toggle { checked: root.cfg.launcherShowCategories; onToggled: v => Settings.set("launcherShowCategories", v) }
                }
                SettingRow {
                    label: "Frequent apps"
                    description: "Your most-launched apps above the grid. Alt+number launches them."
                    Toggle { checked: root.cfg.launcherShowFrequent; onToggled: v => Settings.set("launcherShowFrequent", v) }
                }
                SettingRow {
                    visible: root.cfg.launcherShowFrequent
                    label: "How many"
                    ValueSlider { from: 3; to: 9; stepSize: 1; value: root.cfg.launcherFrequentCount; onMoved: v => Settings.set("launcherFrequentCount", v) }
                }
            }
            SettingSection {
                title: "Search"
                SettingRow {
                    label: "Rank by how often you use apps"
                    Toggle { checked: root.cfg.launcherRankByUsage; onToggled: v => Settings.set("launcherRankByUsage", v) }
                }
                SettingRow {
                    label: "Max results"
                    ValueSlider { from: 5; to: 100; stepSize: 5; value: root.cfg.launcherMaxResults; onMoved: v => Settings.set("launcherMaxResults", v) }
                }
                SettingRow {
                    label: "App descriptions"
                    Toggle { checked: root.cfg.launcherShowDesc; onToggled: v => Settings.set("launcherShowDesc", v) }
                }
                SettingRow {
                    label: "App actions"
                    description: "Buttons like New Private Window under the selected app"
                    Toggle { checked: root.cfg.launcherShowActions; onToggled: v => Settings.set("launcherShowActions", v) }
                }
                SettingRow {
                    label: "Result count"
                    Toggle { checked: root.cfg.launcherShowCount; onToggled: v => Settings.set("launcherShowCount", v) }
                }
                RowLayout {
                    ActionButton {
                        text: "󰑓  Forget usage history"
                        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "resetUsage"])
                    }
                }
            }
            SettingSection {
                title: "Quick modes"
                SettingRow {
                    label: "Calculator"
                    description: "Type a sum like 12*7 or =2^10. Enter copies the answer."
                    Toggle { checked: root.cfg.launcherCalc; onToggled: v => Settings.set("launcherCalc", v) }
                }
                SettingRow {
                    label: "Run commands"
                    description: "Start with >  to run something in a terminal"
                    Toggle { checked: root.cfg.launcherRun; onToggled: v => Settings.set("launcherRun", v) }
                }
                SettingRow {
                    visible: root.cfg.launcherRun
                    label: "Terminal for commands"
                    description: "The command is appended as  sh -c '…'"
                    SettingText { text: root.cfg.launcherTerminal; placeholder: "kitty --hold"; onSubmitted: t => Settings.set("launcherTerminal", t.trim() || "kitty --hold") }
                }
                SettingRow {
                    label: "Web search"
                    description: "Start with ?  or pick the last result of any search"
                    Toggle { checked: root.cfg.launcherWeb; onToggled: v => Settings.set("launcherWeb", v) }
                }
                Segmented {
                    visible: root.cfg.launcherWeb
                    current: root.cfg.launcherWebEngine
                    onPicked: v => Settings.set("launcherWebEngine", v)
                    options: [{ label: "DuckDuckGo", value: "duckduckgo" }, { label: "Google", value: "google" }, { label: "Brave", value: "brave" },
                              { label: "Startpage", value: "startpage" }, { label: "Bing", value: "bing" }, { label: "Kagi", value: "kagi" }]
                }
            }
            SettingSection {
                title: "Look & motion"
                SettingRow {
                    label: "Drifting background light"
                    description: "Slowly moving wallpaper-colored glow behind the glass"
                    Toggle { checked: root.cfg.launcherOrbs; onToggled: v => Settings.set("launcherOrbs", v) }
                }
                SettingRow {
                    visible: root.cfg.launcherOrbs
                    label: "Glow strength"
                    ValueSlider { from: 0.05; to: 0.8; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.launcherOrbStrength; onMoved: v => Settings.set("launcherOrbStrength", v) }
                }
                SettingRow {
                    label: "Pulsing search border"
                    Toggle { checked: root.cfg.launcherPulse; onToggled: v => Settings.set("launcherPulse", v) }
                }
                SettingRow {
                    label: "Cascading entrance"
                    description: "Apps rise in one after another"
                    Toggle { checked: root.cfg.launcherStagger; onToggled: v => Settings.set("launcherStagger", v) }
                }
                SettingRow {
                    label: "Launch animation"
                    description: "The panel swells and fades as an app opens. Off = closes instantly."
                    Toggle { checked: root.cfg.launcherLaunchAnim; onToggled: v => Settings.set("launcherLaunchAnim", v) }
                }
                SettingRow {
                    label: "Rotating hints"
                    Toggle { checked: root.cfg.launcherHints; onToggled: v => Settings.set("launcherHints", v) }
                }
                SettingRow {
                    label: "Key hints footer"
                    Toggle { checked: root.cfg.launcherShowFooter; onToggled: v => Settings.set("launcherShowFooter", v) }
                }
            }
            SettingSection {
                title: "Hidden apps"
                SettingRow {
                    label: "Hide these apps"
                    keywords: "remove exclude blacklist hidden"
                    description: "Comma-separated names. Tip: right-click an app in the launcher to hide it."
                    SettingText { text: root.cfg.launcherHidden; placeholder: "e.g. XTerm, UXTerm"; onSubmitted: t => Settings.set("launcherHidden", t.trim()) }
                }
                RowLayout {
                    visible: root.cfg.launcherHidden !== ""
                    ActionButton { text: "󰈈  Show all hidden apps"; onClicked: Settings.set("launcherHidden", "") }
                }
            }
        }
    }

    Component {
        id: inputPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Input"
                subtitle: "Keyboard, mouse and touchpad."
                keys: ["kbLayout", "kbOptions", "followMouse", "sensitivity", "naturalScroll", "tapToClick", "disableWhileTyping", "scrollFactor", "middleAsRight", "infiniteDesktop", "infiniteFloat",
                       "repeatRate", "repeatDelay", "numlockOn", "accelProfile", "leftHanded", "mouseNaturalScroll", "clickfinger", "middleEmulation", "tapAndDrag"]
            }
            SettingSection {
                title: "Keyboard"
                SettingRow {
                    label: "Layout"
                    description: "XKB layout code, e.g. us, gb, de. Several: us,de"
                    SettingText { text: root.cfg.kbLayout; placeholder: "us"; onSubmitted: t => Settings.set("kbLayout", t.trim() || "us") }
                }
                SettingRow {
                    label: "Options"
                    description: "e.g. caps:escape  or  grp:alt_shift_toggle (switch layouts)"
                    SettingText { text: root.cfg.kbOptions; placeholder: "none"; onSubmitted: t => Settings.set("kbOptions", t.trim()) }
                }
                SettingRow {
                    label: "Key repeat delay"; keywords: "keyboard typematic hold"
                    description: "How long to hold a key before it repeats"
                    ValueSlider { from: 150; to: 1000; stepSize: 25; suffix: " ms"; value: root.cfg.repeatDelay; onMoved: v => Settings.set("repeatDelay", v) }
                }
                SettingRow {
                    label: "Key repeat rate"; keywords: "keyboard speed typematic"
                    ValueSlider { from: 10; to: 80; stepSize: 1; suffix: "/s"; value: root.cfg.repeatRate; onMoved: v => Settings.set("repeatRate", v) }
                }
                SettingRow {
                    label: "Num Lock on at login"
                    Toggle { checked: root.cfg.numlockOn; onToggled: v => Settings.set("numlockOn", v) }
                }
            }
            SettingSection {
                title: "Mouse"
                SettingRow {
                    label: "Focus"
                    description: "How windows get focus as the pointer moves"
                }
                Segmented {
                    current: root.cfg.followMouse
                    onPicked: v => Settings.set("followMouse", v)
                    options: [{ label: "Click to focus", value: 0 }, { label: "Follow mouse", value: 1 }, { label: "Follow loosely", value: 2 }]
                }
                SettingRow {
                    label: "Pointer speed"; keywords: "mouse sensitivity"
                    ValueSlider { from: -1; to: 1; stepSize: 0.05; decimals: 2; value: root.cfg.sensitivity; onMoved: v => Settings.set("sensitivity", v) }
                }
                SettingRow {
                    label: "Acceleration"
                    description: "Flat = the pointer moves exactly as far as the mouse (good for games)"
                }
                Segmented {
                    current: root.cfg.accelProfile === "flat" ? "flat" : "adaptive"
                    onPicked: v => Settings.set("accelProfile", v)
                    options: [{ label: "Adaptive", value: "adaptive" }, { label: "Flat", value: "flat" }]
                }
                SettingRow {
                    label: "Left-handed"
                    description: "Swap the left and right buttons"
                    Toggle { checked: root.cfg.leftHanded; onToggled: v => Settings.set("leftHanded", v) }
                }
                SettingRow {
                    label: "Natural scrolling for mice"
                    Toggle { checked: root.cfg.mouseNaturalScroll; onToggled: v => Settings.set("mouseNaturalScroll", v) }
                }
            }
            SettingSection {
                title: "Buttons"
                Component.onCompleted: ydoProbe.running = true
                SettingRow {
                    label: "Middle click acts as right click"
                    keywords: "mouse button remap swap middle right context menu wheel"
                    description: root.ydoState === "ready" ? "Pressing the wheel opens context menus. Holding it right-drags."
                               : root.ydoState === "stopped" ? "The click helper isn't running. Start it below."
                               : root.ydoState === "setting-up" ? "Setting up… enter your password in the prompt."
                               : root.ydoState === "failed" ? "Setup didn't finish (cancelled or failed). Try again."
                               : "Needs a one-time setup (installs ydotool, asks for your password)."
                    Toggle {
                        enabled: !root.cfg.infiniteDesktop && (root.ydoState === "ready" || root.cfg.middleAsRight)
                        opacity: enabled ? 1 : 0.4
                        checked: root.cfg.middleAsRight
                        onToggled: v => Settings.set("middleAsRight", v)
                    }
                }
                SettingRow {
                    label: "Infinite desktop"
                    keywords: "zoom out canvas pan roam scroll drag middle mouse wheel free workspace dark shadow infinite"
                    description: "Hold the middle button and move the mouse to roam the desktop; press Super+minus / Super+equals to zoom out and in. Windows float on an endless canvas. Replaces middle-click while on. Super+Home resets the view."
                    Toggle { checked: root.cfg.infiniteDesktop; onToggled: v => Settings.set("infiniteDesktop", v) }
                }
                SettingRow {
                    visible: root.cfg.infiniteDesktop
                    label: "Float new windows"
                    keywords: "infinite desktop floating tile"
                    description: "Open every window floating so it can be panned. Tiled windows are floated on the first pan."
                    Toggle { checked: root.cfg.infiniteFloat; onToggled: v => Settings.set("infiniteFloat", v) }
                }
                RowLayout {
                    visible: root.ydoState !== "ready" && root.ydoState !== "unknown"
                    spacing: 8
                    ActionButton {
                        visible: root.ydoState === "missing" || root.ydoState === "failed"
                        primary: true
                        text: "󰏗  Set up"
                        onClicked: { root.ydoState = "setting-up"; ydoSetup.running = true; }
                    }
                    ActionButton {
                        visible: root.ydoState === "stopped"
                        primary: true
                        text: "󰐊  Start helper"
                        onClicked: root.ydoStart()
                    }
                }
            }
            SettingSection {
                title: "Touchpad"
                SettingRow {
                    label: "Natural scrolling"
                    description: "Content follows your fingers"
                    Toggle { checked: root.cfg.naturalScroll; onToggled: v => Settings.set("naturalScroll", v) }
                }
                SettingRow {
                    label: "Tap to click"
                    Toggle { checked: root.cfg.tapToClick; onToggled: v => Settings.set("tapToClick", v) }
                }
                SettingRow {
                    label: "Disable while typing"
                    Toggle { checked: root.cfg.disableWhileTyping; onToggled: v => Settings.set("disableWhileTyping", v) }
                }
                SettingRow {
                    label: "Scroll speed"; keywords: "touchpad scrolling sensitivity"
                    ValueSlider { from: 0.2; to: 3; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.scrollFactor; onMoved: v => Settings.set("scrollFactor", v) }
                }
                SettingRow {
                    label: "Tap and drag"
                    description: "Double-tap and hold to drag"
                    Toggle { checked: root.cfg.tapAndDrag; onToggled: v => Settings.set("tapAndDrag", v) }
                }
                SettingRow {
                    label: "Click with fingers"
                    description: "Pressing with 2 fingers = right click, 3 = middle (instead of using pad areas)"
                    Toggle { checked: root.cfg.clickfinger; onToggled: v => Settings.set("clickfinger", v) }
                }
                SettingRow {
                    label: "Middle-click emulation"
                    description: "Press left and right together for a middle click"
                    Toggle { checked: root.cfg.middleEmulation; onToggled: v => Settings.set("middleEmulation", v) }
                }
            }
        }
    }

    Component {
        id: cursorPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Cursor & Gestures"
                subtitle: "Pointer behavior, screen zoom and touchpad swipes."
                keys: ["cursorHideAfter", "cursorHideOnKey", "cursorNoWarps", "cursorWarpOnWs", "cursorZoom",
                       "swipeDistance", "swipeInvert", "swipeForever", "swipeCreateNew", "swipeCancelRatio"]
            }
            SettingSection {
                title: "Cursor"
                SettingRow {
                    label: "Hide when idle"
                    ValueSlider { from: 0; to: 30; stepSize: 1; suffix: " s"; zeroText: "Never"; value: root.cfg.cursorHideAfter; onMoved: v => Settings.set("cursorHideAfter", v) }
                }
                SettingRow {
                    label: "Hide while typing"
                    Toggle { checked: root.cfg.cursorHideOnKey; onToggled: v => Settings.set("cursorHideOnKey", v) }
                }
                SettingRow {
                    label: "Don't move the cursor on focus"
                    description: "Stops the pointer jumping to windows focused with the keyboard"
                    Toggle { checked: root.cfg.cursorNoWarps; onToggled: v => Settings.set("cursorNoWarps", v) }
                }
                SettingRow {
                    visible: !root.cfg.cursorNoWarps
                    label: "Jump to the window when switching workspace"
                    Toggle { checked: root.cfg.cursorWarpOnWs; onToggled: v => Settings.set("cursorWarpOnWs", v) }
                }
            }
            SettingSection {
                title: "Zoom"
                SettingRow {
                    label: "Screen magnifier"; keywords: "zoom magnify accessibility"
                    description: "Zooms in around the pointer. Handy for presentations or accessibility."
                    ValueSlider { from: 1; to: 4; stepSize: 0.1; decimals: 1; suffix: "×"; value: root.cfg.cursorZoom; onMoved: v => Settings.set("cursorZoom", v) }
                }
                RowLayout {
                    visible: root.cfg.cursorZoom > 1
                    ActionButton { text: "󰍉  Reset zoom"; onClicked: Settings.set("cursorZoom", 1.0) }
                }
            }
            SettingSection {
                title: "Workspace swipe (3 fingers)"
                SettingRow {
                    label: "Swipe distance"
                    description: "How far to swipe for a full workspace change"
                    ValueSlider { from: 100; to: 1000; stepSize: 25; suffix: " px"; value: root.cfg.swipeDistance; onMoved: v => Settings.set("swipeDistance", v) }
                }
                SettingRow {
                    label: "Commit threshold"
                    description: "How much of the swipe is needed before it switches"
                    ValueSlider { from: 0.1; to: 0.9; stepSize: 0.05; displayScale: 100; suffix: "%"; value: root.cfg.swipeCancelRatio; onMoved: v => Settings.set("swipeCancelRatio", v) }
                }
                SettingRow {
                    label: "Inverted direction"
                    description: "Content follows your fingers (like natural scrolling)"
                    Toggle { checked: root.cfg.swipeInvert; onToggled: v => Settings.set("swipeInvert", v) }
                }
                SettingRow {
                    label: "Swipe through several"
                    description: "Keep going past the next workspace in one swipe"
                    Toggle { checked: root.cfg.swipeForever; onToggled: v => Settings.set("swipeForever", v) }
                }
                SettingRow {
                    label: "Create a new workspace at the end"
                    Toggle { checked: root.cfg.swipeCreateNew; onToggled: v => Settings.set("swipeCreateNew", v) }
                }
            }
        }
    }

    Component {
        id: displaysPage
        DisplaysPage {}
    }
    Component {
        id: rulesPage
        RulesPage {}
    }
    Component {
        id: behaviorPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Behavior"
                subtitle: "Focus, workspaces, fullscreen, terminal swallowing and display."
                keys: ["focusOnActivate", "middleClickPaste", "enableSwallow", "swallowRegex", "closeSpecialOnEmpty", "hideSpecialOnWsChange",
                       "wsBackAndForth", "allowWsCycles", "onFocusUnderFullscreen", "exitRetainsFullscreen", "mouseWakes", "keyWakes",
                       "vrr", "directScanout", "xwaylandZeroScaling", "watchdogRssMb", "nightLight", "nightTemp", "weatherEnabled", "weatherLat", "weatherLon", "weatherPlace", "weatherUnit"]
            }
            SettingSection {
                title: "Focus"
                SettingRow {
                    label: "Apps can steal focus"; keywords: "activate urgent focus stealing"
                    description: "Focus windows that ask for attention, e.g. a link opening in the browser"
                    Toggle { checked: root.cfg.focusOnActivate; onToggled: v => Settings.set("focusOnActivate", v) }
                }
                SettingRow {
                    label: "Middle-click paste"
                    description: "Paste the last selected text with the middle mouse button"
                    Toggle { checked: root.cfg.middleClickPaste; onToggled: v => Settings.set("middleClickPaste", v) }
                }
            }
            SettingSection {
                title: "Workspaces"
                SettingRow {
                    label: "Back and forth"; keywords: "previous workspace toggle"
                    description: "Pressing the current workspace's key goes back to the previous one"
                    Toggle { checked: root.cfg.wsBackAndForth; onToggled: v => Settings.set("wsBackAndForth", v) }
                }
                SettingRow {
                    label: "Cycle through history"
                    description: "Repeating 'previous workspace' keeps walking back instead of toggling two"
                    Toggle { checked: root.cfg.allowWsCycles; onToggled: v => Settings.set("allowWsCycles", v) }
                }
                SettingRow {
                    label: "Close scratchpad when empty"
                    Toggle { checked: root.cfg.closeSpecialOnEmpty; onToggled: v => Settings.set("closeSpecialOnEmpty", v) }
                }
                SettingRow {
                    label: "Hide scratchpad when switching workspace"
                    Toggle { checked: root.cfg.hideSpecialOnWsChange; onToggled: v => Settings.set("hideSpecialOnWsChange", v) }
                }
            }
            SettingSection {
                title: "Weather (dashboard)"
                SettingRow {
                    label: "Show weather"; keywords: "forecast temperature open-meteo dashboard"
                    description: "Off by default. When on, your coordinates are sent to open-meteo.com (no account) about every 30 minutes."
                    Toggle { checked: root.cfg.weatherEnabled; onToggled: v => Settings.set("weatherEnabled", v) }
                }
                SettingRow {
                    label: "Place"; description: "Just a label for the dashboard"
                    SettingText { text: root.cfg.weatherPlace; placeholder: "Home"; onSubmitted: t => Settings.set("weatherPlace", t) }
                }
                SettingRow {
                    label: "Latitude"; description: "e.g. 51.5072 (north is positive)"
                    SettingText { text: String(root.cfg.weatherLat); placeholder: "51.5072"
                                  onSubmitted: t => { const v = parseFloat(t); if (!isNaN(v)) Settings.set("weatherLat", Math.max(-90, Math.min(90, v))); } }
                }
                SettingRow {
                    label: "Longitude"; description: "e.g. -0.1276 (east is positive)"
                    SettingText { text: String(root.cfg.weatherLon); placeholder: "-0.1276"
                                  onSubmitted: t => { const v = parseFloat(t); if (!isNaN(v)) Settings.set("weatherLon", Math.max(-180, Math.min(180, v))); } }
                }
                SettingRow {
                    label: "Units"
                    Segmented { current: root.cfg.weatherUnit; onPicked: v => Settings.set("weatherUnit", v)
                                options: [{ label: "°C  km/h", value: "metric" }, { label: "°F  mph", value: "imperial" }] }
                }
            }
            SettingSection {
                title: "Shell health"
                SettingRow {
                    label: "Warn when the shell uses a lot of memory"; keywords: "memory ram leak watchdog restart slow frozen animation"
                    description: "Shows a notification with a Restart shell button. Never restarts by itself. 0 = off"
                    ValueSlider { from: 0; to: 3000; stepSize: 100; suffix: " MB"; value: root.cfg.watchdogRssMb; onMoved: v => Settings.set("watchdogRssMb", v) }
                }
            }
            SettingSection {
                title: "Fullscreen"
                SettingRow {
                    label: "Opening a window over fullscreen"
                    description: "What happens to the fullscreen window"
                }
                Segmented {
                    current: root.cfg.onFocusUnderFullscreen
                    onPicked: v => Settings.set("onFocusUnderFullscreen", v)
                    options: [{ label: "Stay behind it", value: 0 }, { label: "Take over fullscreen", value: 1 }, { label: "Leave fullscreen", value: 2 }]
                }
                SettingRow {
                    label: "Keep fullscreen when a window closes"
                    description: "The next window on the workspace goes fullscreen"
                    Toggle { checked: root.cfg.exitRetainsFullscreen; onToggled: v => Settings.set("exitRetainsFullscreen", v) }
                }
            }
            SettingSection {
                title: "Terminal swallowing"
                SettingRow {
                    label: "Swallow the terminal"; keywords: "swallowing hide terminal mpv"
                    description: "When you launch a GUI app (mpv, imv, zathura…) from a terminal, it takes the terminal's place until it closes"
                    Toggle { checked: root.cfg.enableSwallow; onToggled: v => Settings.set("enableSwallow", v) }
                }
                SettingRow {
                    visible: root.cfg.enableSwallow
                    label: "Terminals (class regex)"
                    description: "Which windows can be swallowed"
                    SettingText { text: root.cfg.swallowRegex; placeholder: "^(kitty)$"; onSubmitted: t => Settings.set("swallowRegex", t.trim() || "^(kitty)$") }
                }
            }
            SettingSection {
                title: "Display"
                SettingRow {
                    label: "Variable refresh rate"
                    description: "Adaptive sync / FreeSync, if your monitor supports it"
                }
                Segmented {
                    current: root.cfg.vrr
                    onPicked: v => Settings.set("vrr", v)
                    options: [{ label: "Off", value: 0 }, { label: "Always", value: 1 }, { label: "Fullscreen only", value: 2 }]
                }
                SettingRow {
                    label: "Direct scanout"
                    description: "Lower latency for fullscreen games; can cause glitches on some GPUs"
                }
                Segmented {
                    current: root.cfg.directScanout
                    onPicked: v => Settings.set("directScanout", v)
                    options: [{ label: "Off", value: 0 }, { label: "On", value: 1 }, { label: "Games only", value: 2 }]
                }
                SettingRow {
                    label: "Sharp XWayland apps"
                    description: "Stops blurry upscaling of X11 apps on scaled monitors (they may render small)"
                    Toggle { checked: root.cfg.xwaylandZeroScaling; onToggled: v => Settings.set("xwaylandZeroScaling", v) }
                }
                SettingRow {
                    label: "Mouse wakes the screen"
                    Toggle { checked: root.cfg.mouseWakes; onToggled: v => Settings.set("mouseWakes", v) }
                }
                SettingRow {
                    label: "Keyboard wakes the screen"
                    Toggle { checked: root.cfg.keyWakes; onToggled: v => Settings.set("keyWakes", v) }
                }
            }
        }
    }

    Component {
        id: idlePage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Idle & Lock"
                subtitle: "What happens when you step away. Each step counts from your last input."
                keys: ["dimAfter", "lockAfter", "screenOffAfter", "suspendAfter", "suspendOnBatteryOnly", "lockBlur", "lockDim", "lockSeconds", "lockShowDate"]
            }
            SettingSection {
                title: "Timers"
                SettingRow {
                    label: "Dim screen after"
                    ValueSlider { from: 0; to: 30; stepSize: 1; suffix: " min"; zeroText: "Never"; value: root.cfg.dimAfter; onMoved: v => Settings.set("dimAfter", v) }
                }
                SettingRow {
                    label: "Lock after"
                    ValueSlider { from: 0; to: 60; stepSize: 1; suffix: " min"; zeroText: "Never"; value: root.cfg.lockAfter; onMoved: v => Settings.set("lockAfter", v) }
                }
                SettingRow {
                    label: "Turn screen off after"
                    ValueSlider { from: 0; to: 60; stepSize: 1; suffix: " min"; zeroText: "Never"; value: root.cfg.screenOffAfter; onMoved: v => Settings.set("screenOffAfter", v) }
                }
                SettingRow {
                    label: "Suspend after"
                    ValueSlider { from: 0; to: 120; stepSize: 5; suffix: " min"; zeroText: "Never"; value: root.cfg.suspendAfter; onMoved: v => Settings.set("suspendAfter", v) }
                }
                SettingRow {
                    label: "Only suspend on battery"
                    description: "When plugged in, never auto-suspend"
                    Toggle { checked: root.cfg.suspendOnBatteryOnly; onToggled: v => Settings.set("suspendOnBatteryOnly", v) }
                }
            }
            SettingSection {
                title: "Right now"
                SettingRow {
                    label: "Keep awake"; keywords: "caffeine inhibit idle sleep"
                    description: "Temporarily block dimming, locking and sleep (not saved)"
                    Toggle { checked: Globals.keepAwake; onToggled: v => Globals.keepAwake = v }
                }
            }
            SettingSection {
                title: "Lock screen"
                SettingRow {
                    label: "Blur the wallpaper"
                    Toggle { checked: root.cfg.lockBlur; onToggled: v => Settings.set("lockBlur", v) }
                }
                SettingRow {
                    label: "Darken"; keywords: "dim lock brightness"
                    ValueSlider { from: 0; to: 0.7; stepSize: 0.02; displayScale: 100; suffix: "%"; value: root.cfg.lockDim; onMoved: v => Settings.set("lockDim", v) }
                }
                SettingRow {
                    label: "Show seconds"
                    description: "12/24-hour follows the bar clock setting"
                    Toggle { checked: root.cfg.lockSeconds; onToggled: v => Settings.set("lockSeconds", v) }
                }
                SettingRow {
                    label: "Show date"
                    Toggle { checked: root.cfg.lockShowDate; onToggled: v => Settings.set("lockShowDate", v) }
                }
                RowLayout {
                    ActionButton {
                        text: "󰌾  Preview (unlocks after 15 s)"
                        onClicked: { Globals.settingsOpen = false; Quickshell.execDetached(["qs", "ipc", "call", "lock", "testLock"]); }
                    }
                }
            }
        }
    }

    Component {
        id: keybindsPage
        ColumnLayout {
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                PageHeader {
                    title: "Keybinds"
                    subtitle: "Click a shortcut to change it: toggle the modifiers, then press the key. Esc cancels. Changes apply instantly."
                }
                ActionButton {
                    visible: root.cfg.keybinds !== "{}"
                    text: "󰑓  Reset all"
                    onClicked: Settings.resetBinds()
                }
            }
            Repeater {
                model: [...new Set(Settings.bindActions.map(a => a.group))]
                SettingSection {
                    id: bindSec
                    required property string modelData
                    title: modelData
                    Repeater {
                        model: Settings.bindActions.filter(a => a.group === bindSec.modelData)
                        SettingRow {
                            id: bindRow
                            required property var modelData
                            readonly property string combo: { root.cfg.keybinds; return Settings.bindFor(modelData.id); }
                            readonly property var clashes: Settings.bindConflicts(modelData.id, combo)
                            label: modelData.label
                            keywords: "keybind shortcut hotkey key " + modelData.def
                            description: clashes.length ? "󰀦 Also bound to: " + clashes.join(", ") : ""
                            KeyCombo {
                                combo: bindRow.combo
                                defaultCombo: bindRow.modelData.def
                                onPicked: c => Settings.setBind(bindRow.modelData.id, c)
                            }
                        }
                    }
                }
            }
            SettingSection {
                title: "Fixed"
                SettingRow { label: "Go to workspace 1–10"; description: "SUPER + 1 … 0  (edit in hyprland.lua)" }
                SettingRow { label: "Move window to workspace 1–10"; description: "SUPER + SHIFT + 1 … 0" }
                SettingRow { label: "Move / resize window"; description: "SUPER + left drag / right drag" }
                SettingRow { label: "Cycle workspaces"; description: "SUPER + scroll" }
                SettingRow { label: "Volume, brightness and media keys"; description: "The keyboard's media keys" }
            }
        }
    }

    Component {
        id: notifPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Notifications & OSD"
                subtitle: "Popups, Do Not Disturb, and the volume/brightness indicator."
                keys: ["notifTimeout", "notifPosition", "notifMaxPopups", "notifWidth", "osdEnabled", "osdPosition", "osdTimeout"]
            }
            SettingSection {
                title: "Popups"
                SettingRow {
                    label: "Show popups for"; keywords: "timeout duration notification"
                    description: "Apps can request their own duration; critical alerts always stay"
                    ValueSlider { from: 2; to: 20; stepSize: 1; suffix: " s"; value: root.cfg.notifTimeout; onMoved: v => Settings.set("notifTimeout", v) }
                }
                SettingRow {
                    label: "Do Not Disturb"; keywords: "dnd mute silence"
                    description: "Hide popups (they still go to history). Not saved."
                    Toggle { checked: Notifs.dnd; onToggled: v => Notifs.dnd = v }
                }
                SettingRow { label: "Position" }
                Segmented {
                    current: root.cfg.notifPosition
                    onPicked: v => Settings.set("notifPosition", v)
                    options: [{ label: "Left", value: "left" }, { label: "Center", value: "center" }, { label: "Right", value: "right" }]
                }
                SettingRow {
                    label: "Max on screen"
                    description: "Older popups are moved to history"
                    ValueSlider { from: 1; to: 10; stepSize: 1; value: root.cfg.notifMaxPopups; onMoved: v => Settings.set("notifMaxPopups", v) }
                }
                SettingRow {
                    label: "Width"
                    ValueSlider { from: 280; to: 560; stepSize: 10; suffix: " px"; value: root.cfg.notifWidth; onMoved: v => Settings.set("notifWidth", v) }
                }
                RowLayout {
                    ActionButton {
                        text: "󰂞  Send test notification"
                        onClicked: Quickshell.execDetached(["notify-send", "-a", "Settings", "Test notification", "This is how notifications look right now."])
                    }
                }
            }
            SettingSection {
                title: "Volume & brightness indicator"
                SettingRow {
                    label: "Show indicator"; keywords: "osd volume brightness popup"
                    Toggle { checked: root.cfg.osdEnabled; onToggled: v => Settings.set("osdEnabled", v) }
                }
                SettingRow {
                    visible: root.cfg.osdEnabled
                    label: "Position"
                }
                Segmented {
                    visible: root.cfg.osdEnabled
                    current: root.cfg.osdPosition
                    onPicked: v => Settings.set("osdPosition", v)
                    options: [{ label: "󰁅  Bottom", value: "bottom" }, { label: "󰁝  Top", value: "top" }]
                }
                SettingRow {
                    visible: root.cfg.osdEnabled
                    label: "Stays for"
                    ValueSlider { from: 0.5; to: 5; stepSize: 0.25; decimals: 2; suffix: " s"; value: root.cfg.osdTimeout; onMoved: v => Settings.set("osdTimeout", v) }
                }
            }
        }
    }

    Component {
        id: recordingPage
        ColumnLayout {
            spacing: 16
            PageHeader {
                title: "Screen Recording"
                subtitle: "Record the screen, a window or a region with wf-recorder. Start and stop from the keybinds, the control center, or the red timer in the bar."
                keys: ["recMode", "recFormat", "recFps", "recQuality", "recEncoder", "recAudio", "recDir", "recCountdown", "recNotify", "recCopyPath"]
            }
            RowLayout {
                spacing: 10
                ActionButton {
                    primary: !Recorder.active
                    text: Recorder.active ? "󰓛  Stop recording (" + Recorder.clock + ")" : "󰑊  Start recording"
                    onClicked: { Globals.settingsOpen = false; Recorder.toggle(""); }
                }
                ActionButton {
                    text: "󰉋  Open recordings folder"
                    onClicked: Quickshell.execDetached(["sh", "-c", "d=\"" + root.cfg.recDir.replace(/^~/, "$HOME") + "\"; mkdir -p \"$d\"; xdg-open \"$d\""])
                }
            }
            SettingSection {
                title: "What to record"
                SettingRow {
                    label: "Default target"; keywords: "region area window screen monitor full"
                    description: "Used by the toggle keybind, the control center tile and the Start button"
                }
                Segmented {
                    current: root.cfg.recMode
                    onPicked: v => Settings.set("recMode", v)
                    options: [{ label: "󰆞  Region", value: "region" }, { label: "󰖯  Window", value: "window" }, { label: "󰍹  Whole screen", value: "full" }]
                }
                SettingRow {
                    label: "Countdown"; keywords: "delay timer wait"
                    description: "Seconds to wait after picking the target, so you can get ready"
                    ValueSlider { from: 0; to: 10; stepSize: 1; suffix: " s"; value: root.cfg.recCountdown; onMoved: v => Settings.set("recCountdown", v) }
                }
            }
            SettingSection {
                title: "Quality"
                SettingRow { label: "Format"; keywords: "container mp4 mkv webm file type" }
                Segmented {
                    current: root.cfg.recFormat
                    onPicked: v => Settings.set("recFormat", v)
                    options: [{ label: "MP4", value: "mp4" }, { label: "MKV", value: "mkv" }, { label: "WebM", value: "webm" }]
                }
                SettingRow { label: "Frame rate"; keywords: "fps smooth" }
                Segmented {
                    current: root.cfg.recFps
                    onPicked: v => Settings.set("recFps", v)
                    options: [{ label: "24", value: 24 }, { label: "30", value: 30 }, { label: "60", value: 60 }]
                }
                SettingRow { label: "Quality"; keywords: "bitrate crf size compression" ; description: "Higher looks better and makes bigger files" }
                Segmented {
                    current: root.cfg.recQuality
                    onPicked: v => Settings.set("recQuality", v)
                    options: [{ label: "Small file", value: "low" }, { label: "Balanced", value: "medium" }, { label: "High", value: "high" }]
                }
                SettingRow {
                    visible: root.cfg.recFormat !== "webm"
                    label: "Encoder"; keywords: "gpu vaapi hardware software cpu x264 h264 amd"
                    description: "Hardware (VAAPI, your GPU) uses far less CPU; software (x264) is the safest"
                }
                Segmented {
                    visible: root.cfg.recFormat !== "webm"
                    current: root.cfg.recEncoder
                    onPicked: v => Settings.set("recEncoder", v)
                    options: [{ label: "Software (x264)", value: "software" }, { label: "Hardware (VAAPI)", value: "hardware" }]
                }
            }
            SettingSection {
                title: "Audio"
                SettingRow { label: "Record sound from"; keywords: "microphone mic system desktop speakers sound" }
                Segmented {
                    current: root.cfg.recAudio
                    onPicked: v => Settings.set("recAudio", v)
                    options: [{ label: "None", value: "none" }, { label: "󰓃  System audio", value: "system" }, { label: "󰍬  Microphone", value: "mic" }]
                }
            }
            SettingSection {
                title: "Saving"
                SettingRow {
                    label: "Save to"; keywords: "folder directory path location"
                    SettingText { text: root.cfg.recDir; placeholder: "~/Videos/Recordings"; onSubmitted: t => Settings.set("recDir", t.trim() || "~/Videos/Recordings") }
                }
                SettingRow {
                    label: "Notify when saved"; keywords: "notification toast"
                    description: "Shows a thumbnail; click it to play"
                    Toggle { checked: root.cfg.recNotify; onToggled: v => Settings.set("recNotify", v) }
                }
                SettingRow {
                    label: "Copy file path when done"; keywords: "clipboard"
                    Toggle { checked: root.cfg.recCopyPath; onToggled: v => Settings.set("recCopyPath", v) }
                }
            }
        }
    }

    // ---------- middle click helper (ydotool) ----------
    property string ydoState: "unknown"   // ready | missing | stopped | setting-up | failed
    Process {
        id: ydoProbe
        command: ["sh", "-c", "command -v ydotool >/dev/null || { echo missing; exit; }; [ -w /dev/uinput ] || { echo missing; exit; }; "
                  + "pgrep -x ydotoold >/dev/null && echo ready || echo stopped"]
        stdout: StdioCollector { onStreamFinished: root.ydoState = this.text.trim() || "missing" }
    }
    Process {
        id: ydoSetup
        command: ["sh", "-c", "pkexec \"$HOME/.config/quickshell/scripts/setup-ydotool.sh\" && "
                  + "{ systemctl --user enable --now ydotool.service 2>/dev/null || (setsid ydotoold >/dev/null 2>&1 &); sleep 1; }"]
        onExited: code => { if (code !== 0) root.ydoState = "failed"; else ydoProbe.running = true; }
    }
    function ydoStart() {
        Quickshell.execDetached(["sh", "-c", "systemctl --user enable --now ydotool.service 2>/dev/null || (setsid ydotoold >/dev/null 2>&1 &)"]);
        ydoRecheck.restart();
    }
    Timer { id: ydoRecheck; interval: 1200; onTriggered: ydoProbe.running = true }

    // ---------- search ----------
    // The index is harvested from the pages themselves (every SettingRow,
    // SettingSection and page title), so new settings are searchable automatically.
    property string query: ""
    readonly property string q: query.trim().toLowerCase()
    property var searchIndex: []
    property int sel: 0
    property var pendingTarget: null
    readonly property var results: q === "" || searchIndex.length === 0 ? [] : search(q)
    onQChanged: { if (q !== "" && searchIndex.length === 0) buildIndex(); sel = 0; }

    // what people type -> words the settings actually use
    readonly property var synonyms: ({
        "transparent": ["opacity", "glass"], "transparency": ["opacity", "glass"], "translucent": ["opacity"],
        "see": ["opacity"], "alpha": ["opacity"], "opaque": ["opacity"],
        "frosted": ["blur"], "glass": ["blur", "opacity"], "acrylic": ["blur"], "mica": ["blur"],
        "dark": ["dim", "darken", "brightness"], "darker": ["dim", "darken"], "bright": ["brightness"],
        "corner": ["rounding", "radius", "curve"], "corners": ["rounding", "radius"], "round": ["rounding", "radius"], "squircle": ["curve"],
        "gap": ["gaps", "spacing", "margin"], "padding": ["gaps", "margin"], "spacing": ["gaps"], "margin": ["gaps", "margin"],
        "speed": ["length", "rate", "speed", "time"], "fast": ["length", "speed", "rate"], "slow": ["length", "time"], "duration": ["length", "time", "for"],
        "mouse": ["pointer", "cursor", "mouse"], "pointer": ["cursor", "pointer"], "trackpad": ["touchpad"], "touch": ["touchpad"],
        "swipe": ["gesture", "swipe"], "gesture": ["swipe"], "gestures": ["swipe"], "finger": ["fingers", "swipe"],
        "sleep": ["suspend", "idle"], "hibernate": ["suspend"], "screensaver": ["idle", "lock", "dim"], "away": ["idle"],
        "password": ["lock"], "lockscreen": ["lock"], "wallpaper": ["wallpaper", "background"], "background": ["wallpaper"],
        "theme": ["color", "palette", "scheme"], "colour": ["color"], "colours": ["color"], "colors": ["color"], "accent": ["color", "palette"],
        "material": ["color", "scheme"], "matugen": ["color", "scheme"],
        "taskbar": ["bar"], "panel": ["bar", "popup"], "waybar": ["bar"], "statusbar": ["bar"], "dock": ["bar"],
        "time": ["clock"], "date": ["date", "clock"], "seconds": ["seconds", "clock"], "ampm": ["24-hour"], "12h": ["24-hour"], "24h": ["24-hour"],
        "keyboard": ["key", "keyboard", "layout"], "keys": ["key"], "caps": ["options"], "capslock": ["options"], "xkb": ["layout", "options"],
        "language": ["layout"], "numlock": ["num lock"], "typing": ["typing", "key"],
        "freesync": ["variable refresh"], "gsync": ["variable refresh"], "vrr": ["variable refresh"], "adaptive": ["variable refresh", "adaptive"],
        "hz": ["refresh"], "refresh": ["refresh"], "latency": ["scanout"], "tearing": ["scanout"], "gaming": ["scanout", "flat", "fullscreen"], "game": ["scanout", "flat", "fullscreen"],
        "dnd": ["do not disturb"], "disturb": ["do not disturb"], "silent": ["do not disturb"], "quiet": ["do not disturb"],
        "toast": ["popup", "notification"], "toasts": ["popup"], "alerts": ["notification"],
        "volume": ["indicator", "volume"], "osd": ["indicator"], "brightness": ["indicator", "brightness"],
        "magnifier": ["zoom", "magnifier"], "magnify": ["zoom"], "accessibility": ["zoom", "magnifier", "font"],
        "animation": ["animation", "motion"], "animations": ["animation"], "effects": ["animation", "blur", "shadow"], "motion": ["animation"], "bounce": ["pop"],
        "outline": ["border"], "frame": ["border"], "tiling": ["layout", "dwindle", "master", "scrolling"], "tile": ["layout"],
        "scratchpad": ["scratchpad", "special"], "special": ["scratchpad"], "fullscreen": ["fullscreen"], "maximize": ["fullscreen"],
        "battery": ["battery"], "power": ["suspend", "battery", "power"], "laptop": ["battery", "touchpad", "suspend"],
        "terminal": ["terminal", "kitty"], "kitty": ["terminal"], "swallow": ["swallow"],
        "font": ["font"], "text": ["font", "size"], "size": ["size", "width", "height"], "big": ["size", "zoom"], "small": ["size"],
        "focus": ["focus"], "click": ["click", "tap"], "rightclick": ["fingers"], "middle": ["middle"], "paste": ["paste"],
        "sensitivity": ["speed", "pointer"], "acceleration": ["acceleration"], "accel": ["acceleration"],
        "scroll": ["scroll", "scrolling"], "invert": ["natural", "inverted"], "reverse": ["natural", "inverted"],
        "workspace": ["workspace"], "desktop": ["workspace", "wallpaper"], "desktops": ["workspace"],
        "parallax": ["parallax"], "video": ["animated", "wallpaper"], "gif": ["animated"], "live": ["animated"],
        "tray": ["tray"], "music": ["playing", "media"], "media": ["playing"], "spotify": ["playing"], "player": ["playing"],
        "cpu": ["cpu"], "ram": ["cpu"], "memory": ["cpu"], "network": ["network"], "wifi": ["network"], "bluetooth": ["bluetooth"],
        "snap": ["snap"], "float": ["floating"], "floating": ["floating"], "drag": ["drag", "dragging"], "resize": ["resize", "resizes"],
        "x11": ["xwayland"], "blurry": ["xwayland"], "scale": ["xwayland", "scaling"], "hidpi": ["xwayland"],
        "reset": ["reset"], "default": ["reset"],
        "preset": ["themes", "theme"], "presets": ["themes", "theme"], "look": ["themes", "theme"], "style": ["themes"],
        "rice": ["themes"], "profile": ["themes"], "profiles": ["themes"]
    })

    function buildIndex() {
        const out = [];
        root.pages.forEach((p, pi) => {
            const obj = p.component.createObject(harvestHost);
            if (!obj) return;
            let subtitle = "";
            const walk = (o, section) => {
                for (const c of o.children ?? []) {
                    if (c.isSettingSection) {
                        if (c.title) out.push({ kind: "section", page: pi, label: c.title, section: c.title, description: "", keywords: "" });
                        walk(c, c.title);
                    } else if (c.isSettingRow) {
                        if (c.label) out.push({ kind: "row", page: pi, label: c.label, section: section, description: c.description ?? "", keywords: c.keywords ?? "" });
                    } else {
                        if (c.subtitle !== undefined && c.title !== undefined && c.keys !== undefined) subtitle = c.subtitle;
                        walk(c, section);
                    }
                }
            };
            walk(obj, "");
            out.push({ kind: "page", page: pi, label: p.name, section: "", description: subtitle, keywords: "" });
            obj.destroy();
        });
        searchIndex = out;
    }

    function norm(s) { return String(s).toLowerCase().replace(/[^a-z0-9%×+ -]/g, " "); }
    function words(s) { return norm(s).split(/[\s-]+/).filter(w => w); }

    // edit distance <= 1 (substitution, insertion, deletion, transposition)
    function near(a, b) {
        if (Math.abs(a.length - b.length) > 1) return false;
        let i = 0;
        while (i < a.length && i < b.length && a[i] === b[i]) i++;
        if (i >= Math.min(a.length, b.length)) return true;
        return a.slice(i + 1) === b.slice(i + 1) || a.slice(i) === b.slice(i + 1) || a.slice(i + 1) === b.slice(i)
            || (a[i] === b[i + 1] && a[i + 1] === b[i] && a.slice(i + 2) === b.slice(i + 2));
    }
    // letters in order and close together ("dimstr" -> "dim strength")
    function subseq(t, s) {
        for (let start = s.indexOf(t[0]); start >= 0; start = s.indexOf(t[0], start + 1)) {
            let i = 1, j = start + 1;
            for (; j < s.length && i < t.length && j - start < t.length * 2; j++) if (s[j] === t[i]) i++;
            if (i === t.length) return true;
        }
        return false;
    }

    // how well one term matches one field
    function fieldScore(term, text, ws, w) {
        if (!text) return 0;
        if (ws.some(x => x === term)) return 10 * w;
        if (ws.some(x => x.startsWith(term))) return 8 * w;
        if (text.includes(term)) return 6 * w;
        if (term.length >= 4 && ws.some(x => x.length >= 4 && near(term, x))) return 4 * w;
        return 0;
    }

    function search(query) {
        const tokens = words(query);
        if (tokens.length === 0) return [];
        const phrase = norm(query).trim();
        const res = [];
        for (const e of searchIndex) {
            const f = {
                label: norm(e.label), section: norm(e.section), page: norm(root.pages[e.page].name),
                desc: norm(e.description), kw: norm(e.keywords)
            };
            const fw = { label: words(e.label), section: words(e.section), page: words(root.pages[e.page].name), desc: words(e.description), kw: words(e.keywords) };
            let total = 0, ok = true;
            for (const t of tokens) {
                const terms = [[t, 1]];
                for (const s of synonyms[t] ?? []) terms.push([s, 0.75]);
                if (t.length >= 3) for (const k in synonyms) if (k !== t && k.startsWith(t)) for (const s of synonyms[k]) terms.push([s, 0.6]);
                let best = 0;
                for (const [term, w] of terms) {
                    best = Math.max(best,
                        fieldScore(term, f.label, fw.label, 1.6 * w),
                        fieldScore(term, f.kw, fw.kw, 1.2 * w),
                        fieldScore(term, f.section, fw.section, 0.9 * w),
                        fieldScore(term, f.page, fw.page, 0.8 * w),
                        fieldScore(term, f.desc, fw.desc, 0.7 * w));
                }
                if (best === 0 && t.length >= 3 && subseq(t, f.label.replace(/ /g, ""))) best = 3;
                if (best === 0) { ok = false; break; }
                total += best;
            }
            if (!ok) continue;
            if (f.label === phrase) total += 30;
            else if (f.label.startsWith(phrase)) total += 18;
            else if (f.label.includes(phrase)) total += 10;
            if (e.kind === "section") total *= 0.85;
            if (e.kind === "page") total *= 0.9;
            res.push(Object.assign({ score: total }, e));
        }
        res.sort((a, b) => b.score - a.score || a.page - b.page);
        return res.slice(0, 50);
    }

    // label with the typed words highlighted
    function highlight(label) {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const lower = label.toLowerCase();
        const mark = new Array(label.length).fill(false);
        for (const t of words(query)) {
            let i = lower.indexOf(t);
            while (i >= 0) { for (let k = i; k < i + t.length; k++) mark[k] = true; i = lower.indexOf(t, i + t.length); }
        }
        let out = "", on = false;
        for (let i = 0; i < label.length; i++) {
            if (mark[i] !== on) { out += mark[i] ? `<font color="${Theme.primary}"><b>` : "</b></font>"; on = mark[i]; }
            out += esc(label[i]);
        }
        return out + (on ? "</b></font>" : "");
    }

    function openResult(r) {
        if (!r) return;
        query = "";
        keys.forceActiveFocus();
        pendingTarget = r;
        if (page === r.page) locateTimer.restart();
        else page = r.page;
    }

    // find the row/section on the loaded page, scroll to it and flash it
    function locate() {
        const r = pendingTarget;
        pendingTarget = null;
        if (!r || !pageLoader.item || r.kind === "page") return;
        let found = null, foundSection = null;
        const walk = (o, sec) => {
            for (const c of o.children ?? []) {
                if (found) return;
                if (c.isSettingSection) {
                    if (r.kind === "section" && c.title === r.label) { found = c; return; }
                    if (c.title === r.section) foundSection = c;
                    walk(c, c);
                } else if (c.isSettingRow && r.kind === "row" && c.label === r.label && (sec?.title ?? "") === r.section) {
                    found = c.visible && sec?.visible !== false ? c : (sec?.visible !== false ? sec : null);
                    return;
                } else walk(c, sec);
            }
        };
        walk(pageLoader.item, null);
        const target = found ?? foundSection;
        if (!target || !target.visible) return;
        const p = target.mapToItem(pageLoader, 0, 0);
        flash.x = p.x - 8; flash.y = p.y - 6;
        flash.width = target.width + 16; flash.height = target.height + 12;
        scrollAnim.to = Math.max(0, Math.min(flick.contentHeight - flick.height, p.y - flick.height * 0.3));
        scrollAnim.restart();
        flashAnim.restart();
    }

    Timer { id: locateTimer; interval: 60; onTriggered: root.locate() }
    Connections {
        target: Globals
        function onSettingsOpenChanged() { if (!Globals.settingsOpen) root.query = ""; }
    }

    // ---------- window ----------
    Overlay {
        name: "settings"
        open: Globals.settingsOpen
        onCloseRequested: Globals.settingsOpen = false

        GlassPanel {
            id: panel
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1000)
            height: Math.min(parent.height - 90, 700)

            Item {
                id: keys
                focus: true
                Keys.onPressed: e => {
                    const plain = !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
                    if ((e.key === Qt.Key_F && (e.modifiers & Qt.ControlModifier)) || e.key === Qt.Key_Slash) {
                        searchInput.forceActiveFocus(); e.accepted = true; return;
                    }
                    if (plain && e.text.length === 1 && e.text > " " ) {
                        root.query += e.text; searchInput.forceActiveFocus(); searchInput.cursorPosition = root.query.length;
                        e.accepted = true; return;
                    }
                    if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)))
                        root.page = (root.page + 1) % root.pages.length;
                    else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
                        root.page = (root.page + root.pages.length - 1) % root.pages.length;
                    else return;
                    e.accepted = true;
                }
            }

            // pages are instantiated here briefly to build the search index
            Item { id: harvestHost; visible: false; width: 600; height: 10 }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 230
                    color: Theme.alpha(Theme.surfaceContainer, 0.45)
                    radius: panel.radius
                    // square off the right edge
                    Rectangle {
                        anchors.right: parent.right
                        width: parent.radius; height: parent.height
                        color: parent.color
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        RowLayout {
                            Layout.bottomMargin: 12
                            Layout.leftMargin: 6
                            spacing: 10
                            Rectangle {
                                implicitWidth: 34; implicitHeight: 34; radius: 10
                                color: Theme.primary
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒓"
                                    color: Theme.textOnPrimary
                                    font.family: Theme.font
                                    font.pixelSize: 18
                                }
                            }
                            Text {
                                text: "Settings"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 4
                                font.weight: Font.Bold
                            }
                        }

                        // search field
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 10
                            implicitHeight: 36
                            radius: 18
                            color: Theme.alpha(Theme.surfaceContainerHigh, searchInput.activeFocus ? 0.95 : 0.6)
                            border.width: searchInput.activeFocus ? 2 : 1
                            border.color: searchInput.activeFocus ? Theme.primary : Theme.alpha(Theme.outline, 0.25)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: searchIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍉"
                                color: searchInput.activeFocus ? Theme.primary : Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 15
                            }
                            TextInput {
                                id: searchInput
                                anchors.left: searchIcon.right
                                anchors.right: clearBtn.left
                                anchors.leftMargin: 9
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.query
                                onTextEdited: root.query = text
                                color: Theme.text
                                selectionColor: Theme.primary
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                clip: true
                                Keys.onPressed: e => {
                                    if (e.key === Qt.Key_Down) root.sel = Math.min(root.results.length - 1, root.sel + 1);
                                    else if (e.key === Qt.Key_Up) root.sel = Math.max(0, root.sel - 1);
                                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.openResult(root.results[root.sel]);
                                    else if (e.key === Qt.Key_Escape) {
                                        if (root.query !== "") root.query = "";
                                        else keys.forceActiveFocus();
                                    } else return;
                                    e.accepted = true;
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !searchInput.text
                                    text: searchInput.activeFocus ? "Type to search…" : "Search  (just type)"
                                    color: Theme.outline
                                    font: searchInput.font
                                }
                            }
                            Text {
                                id: clearBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.query !== ""
                                text: "󰅖"
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 13
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.query = ""; keys.forceActiveFocus(); }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: navCol.implicitHeight

                            // sliding selection highlight
                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 12
                                y: root.page * (34 + navCol.spacing)
                                color: Theme.alpha(Theme.primary, root.q !== "" ? 0.35 : 0.9)
                                Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                            }

                            Column {
                                id: navCol
                                width: parent.width
                                spacing: 2
                                Repeater {
                                    model: root.pages
                                    Item {
                                        id: nav
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: root.page === index
                                        width: navCol.width
                                        height: 34

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 12
                                            color: Theme.primary
                                            opacity: navMouse.containsMouse && !nav.current ? 0.12 : 0
                                            Behavior on opacity { NumberAnimation { duration: 120 } }
                                        }
                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            spacing: 12
                                            Text {
                                                text: nav.modelData.icon
                                                color: nav.current ? Theme.textOnPrimary : Theme.primary
                                                font.family: Theme.font
                                                font.pixelSize: 16
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                            Text {
                                                text: nav.modelData.name
                                                color: nav.current ? Theme.textOnPrimary : Theme.text
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize - 1
                                                font.weight: nav.current ? Font.Bold : Font.Normal
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                        }
                                        MouseArea {
                                            id: navMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.query = ""; root.page = nav.index; }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 6
                            text: "󰄬  Changes apply instantly\n     and save automatically"
                            color: Theme.outline
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }

                // Content
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: flick
                        visible: root.q === ""
                        anchors.fill: parent
                        anchors.margins: 26
                        anchors.rightMargin: 20
                        contentHeight: pageLoader.implicitHeight + 10
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Loader {
                            id: pageLoader
                            width: flick.width - 10
                            sourceComponent: root.pages[root.page].component
                            transform: Translate { id: pageShift }
                            onLoaded: { flick.contentY = 0; pageIn.restart(); if (root.pendingTarget) locateTimer.restart(); }

                            // highlight that pulses around a setting opened from search
                            Rectangle {
                                id: flash
                                z: 10
                                radius: 12
                                opacity: 0
                                color: Theme.alpha(Theme.primary, 0.12)
                                border.width: 2
                                border.color: Theme.primary
                                SequentialAnimation {
                                    id: flashAnim
                                    NumberAnimation { target: flash; property: "opacity"; from: 0; to: 1; duration: 180 }
                                    NumberAnimation { target: flash; property: "opacity"; to: 0.45; duration: 380 }
                                    NumberAnimation { target: flash; property: "opacity"; to: 1; duration: 380 }
                                    PauseAnimation { duration: 600 }
                                    NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 700; easing.type: Easing.InCubic }
                                }
                            }
                            ParallelAnimation {
                                id: pageIn
                                NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
                                NumberAnimation { target: pageShift; property: "y"; from: 14; to: 0; duration: 380; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    NumberAnimation { id: scrollAnim; target: flick; property: "contentY"; duration: 420; easing.type: Easing.OutCubic }

                    // search results
                    ColumnLayout {
                        visible: root.q !== ""
                        anchors.fill: parent
                        anchors.margins: 26
                        anchors.rightMargin: 20
                        spacing: 12

                        Text {
                            text: root.results.length === 0 ? "No results" : root.results.length + (root.results.length === 1 ? " result" : " results")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 9
                            font.weight: Font.Bold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.results.length === 0
                                ? "Nothing matches \u201c" + root.query.trim() + "\u201d. Try a simpler word, like blur, gaps, mouse or clock."
                                : "↑↓ to choose · Enter to open · Esc to clear"
                            wrapMode: Text.Wrap
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }

                        ListView {
                            id: resultsView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.results
                            currentIndex: root.sel
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 140
                            highlight: Rectangle {
                                radius: 12
                                color: Theme.alpha(Theme.primary, 0.16)
                                border.width: 1
                                border.color: Theme.alpha(Theme.primary, 0.5)
                            }

                            delegate: Item {
                                id: res
                                required property var modelData
                                required property int index
                                width: resultsView.width
                                height: resCol.implicitHeight + 18

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14

                                    Rectangle {
                                        implicitWidth: 32; implicitHeight: 32; radius: 10
                                        color: Theme.alpha(Theme.primary, res.index === root.sel ? 0.9 : 0.15)
                                        Text {
                                            anchors.centerIn: parent
                                            text: res.modelData.kind === "row" ? root.pages[res.modelData.page].icon
                                                : res.modelData.kind === "section" ? "󰉋" : "󰏗"
                                            color: res.index === root.sel ? Theme.textOnPrimary : Theme.primary
                                            font.family: Theme.font
                                            font.pixelSize: 15
                                        }
                                    }
                                    ColumnLayout {
                                        id: resCol
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            textFormat: Text.StyledText
                                            text: root.highlight(res.modelData.label)
                                                + (res.modelData.kind === "page" ? "  <font color='" + Theme.outline + "'>· page</font>"
                                                 : res.modelData.kind === "section" ? "  <font color='" + Theme.outline + "'>· section</font>" : "")
                                            elide: Text.ElideRight
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.pages[res.modelData.page].name
                                                + (res.modelData.kind === "row" && res.modelData.section ? "  ›  " + res.modelData.section : "")
                                            elide: Text.ElideRight
                                            color: Theme.primary
                                            opacity: 0.85
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 3
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            visible: res.modelData.description !== ""
                                            text: res.modelData.description
                                            elide: Text.ElideRight
                                            color: Theme.subtext
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 2
                                        }
                                    }
                                    Text {
                                        text: "󰌑"
                                        visible: res.index === root.sel
                                        color: Theme.primary
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.sel = res.index
                                    onClicked: root.openResult(res.modelData)
                                }
                            }
                        }
                    }

                    // scroll indicator
                    Rectangle {
                        visible: root.q === "" && flick.contentHeight > flick.height
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        y: flick.y + flick.visibleArea.yPosition * flick.height
                        width: 4
                        height: Math.max(30, flick.visibleArea.heightRatio * flick.height)
                        radius: 2
                        color: Theme.alpha(Theme.primary, flick.moving ? 0.8 : 0.35)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }
    }
}
