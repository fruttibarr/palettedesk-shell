import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// The bar. Everything here is driven by Settings (Settings panel → Bar):
// position, style, height, margins, look, and which modules go where.
PanelWindow {
    id: bar
    readonly property var root2: bar

    readonly property int barHeight: Theme.barHeight
    readonly property bool top: Theme.barTop
    readonly property var layout: Settings.s.barLayout
    readonly property var monitor: Hyprland.monitorFor(screen)   // this bar's own monitor

    WlrLayershell.namespace: "rice-bar"   // Hyprland blurs + slides this (layer rules)
    anchors { top: bar.top; bottom: !bar.top; left: true; right: true }
    margins {
        top: bar.top ? Theme.barMarginPx : 0
        bottom: bar.top ? 0 : Theme.barMarginPx
        left: Theme.barMarginPx
        right: Theme.barMarginPx
    }
    exclusiveZone: barHeight
    implicitHeight: barHeight + 16        // extra room for the drop shadow
    color: "transparent"

    function toggleControlCenter() { Globals.popupFrom(bar.screen?.name); Globals.controlCenterOpen = !Globals.controlCenterOpen; }

    // The bar strip sits at the screen-side edge of the window; the extra
    // 16px is for the shadow, on the inner side.
    readonly property real stripY: top ? 0 : implicitHeight - barHeight

    // ---- Glass background ----
    Rectangle {
        id: glass
        visible: !Theme.barIslands
        y: bar.stripY
        width: parent.width
        height: bar.barHeight
        radius: Theme.barAttached ? 0 : Theme.radius + 2
        color: Settings.s.barFill === "fade" ? "transparent" : Theme.barColor
        border.width: Settings.s.barBorder && !Theme.barAttached ? 1 : 0
        border.color: Theme.alpha(Theme.primary, 0.2)
        Behavior on color { ColorAnimation { duration: 400 } }

        Rectangle {   // barFill: gradient (accent wash towards the screen edge) / fade (solid centre, see-through ends)
            visible: Settings.s.barFill !== "solid"
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Settings.s.barFill === "fade" ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: Settings.s.barFill === "fade" ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.04)
                                                : Theme.alpha(Theme.primaryContainer, bar.top ? 0.55 : 0) }
                GradientStop { position: Settings.s.barFill === "fade" ? 0.5 : 1; color: Settings.s.barFill === "fade" ? Theme.barColor
                                                : Theme.alpha(Theme.primaryContainer, bar.top ? 0 : 0.55) }
                GradientStop { position: 1; color: Settings.s.barFill === "fade" ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.04) : Theme.alpha(Theme.primaryContainer, bar.top ? 0 : 0.55) }
            }
        }

        Rectangle {   // barEdge: accent line on the inner edge (line / glow / animated flowing gradient)
            id: edgeLine
            visible: Settings.s.barEdge !== "none"
            readonly property real inset: Theme.barAttached ? 0 : parent.radius
            readonly property real w: Settings.s.barEdgeWidth
            x: inset
            width: parent.width - inset * 2
            height: w
            y: bar.top ? parent.height - height : 0
            property real phase: 0
            NumberAnimation on phase { running: Settings.s.barEdge === "animated" && edgeLine.visible; from: 0; to: 1; duration: 6000; loops: Animation.Infinite }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: Settings.s.barEdge === "animated" ? 0.1 + 0.4 * edgeLine.phase : 0.2; color: Theme.primary }
                GradientStop { position: Settings.s.barEdge === "animated" ? 0.5 + 0.4 * edgeLine.phase : 0.8; color: Theme.tertiary }
                GradientStop { position: 1; color: "transparent" }
            }
            Rectangle {   // soft glow beside the line
                visible: Settings.s.barEdge === "glow"
                anchors.left: parent.left; anchors.right: parent.right
                height: 12
                y: bar.top ? -height : parent.height
                gradient: Gradient {
                    GradientStop { position: 0; color: bar.top ? "transparent" : Theme.alpha(Theme.primary, 0.35) }
                    GradientStop { position: 1; color: bar.top ? Theme.alpha(Theme.primary, 0.35) : "transparent" }
                }
            }
        }

        Rectangle {   // wallpaper-tinted sheen
            visible: Settings.s.barSheen
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            opacity: 0.12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.primary }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1; color: Theme.tertiary }
            }
        }

        Rectangle {   // glass edge highlight (top edge)
            visible: Settings.s.barSheen && !Theme.barAttached
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - parent.radius * 2
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Rectangle {   // attached style: hairline on the inner edge
            visible: Theme.barAttached && Settings.s.barBorder
            width: parent.width
            height: 1
            y: bar.top ? parent.height - 1 : 0
            color: Theme.alpha(Theme.primary, 0.2)
        }
    }

    // barFlares: inverse-corner "dock" flares where an attached bar meets the screen sides
    BarFlare { mirror: false; bar: root2 }
    BarFlare { mirror: true; bar: root2 }

    MultiEffect {
        visible: glass.visible && Settings.s.barShadow
        source: glass
        anchors.fill: glass
        z: -1
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.7
        shadowVerticalOffset: bar.top ? 3 : -3
        autoPaddingEnabled: true
        opacity: 0.9
    }

    // ---- Modules ----
    readonly property var modules: ({
        workspaces: workspacesModule, media: mediaModule, lyrics: lyricsModule, record: recordModule, clock: clockModule, title: titleModule,
        tray: trayModule, stats: statsModule, status: statusModule, launcher: launcherModule, power: powerModule, kbd: kbdModule,
    })

    Component {
        id: workspacesModule
        Chip { tint: Theme.primaryContainer; alphaOverride: Settings.s.wsOpacity; padding: 4; Workspaces { monitor: bar.monitor } }
    }
    Component {
        id: mediaModule
        MediaChip { visible: Media.player !== null; onClicked: bar.toggleControlCenter() }
    }
    Component {
        id: lyricsModule
        LyricsChip {}
    }
    Component {
        id: recordModule
        Chip {
            clickable: true
            tint: Theme.error
            tintOpacity: 0.85
            onClicked: Recorder.stop()
            Text {
                id: dot
                anchors.verticalCenter: parent.verticalCenter
                text: "󰑊"
                color: Theme.surface
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: Recorder.active
                    NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Recorder.clock
                color: Theme.surface
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }
        }
    }
    Component {
        id: clockModule
        Chip { clickable: true; onClicked: { Globals.popupFrom(bar.screen?.name); Globals.dashboardOpen = !Globals.dashboardOpen; } Clock {} }
    }
    Component {
        id: kbdModule
        KbdChip {}
    }
    Component {
        id: titleModule
        WindowTitle { monitor: bar.monitor }
    }
    Component {
        id: trayModule
        Chip {
            visible: SystemTray.items.values.length > 0
            padding: 10
            spacing: 10
            Repeater {
                model: SystemTray.items
                TrayItem { barWindow: bar }
            }
        }
    }
    Component {
        id: statsModule
        Chip {
            spacing: 12
            clickable: true
            onClicked: { Globals.popupFrom(bar.screen?.name); Globals.sysmonOpen = !Globals.sysmonOpen; }
            component Gauge: Row {
                property real value
                property color tint
                property string icon
                spacing: 6
                property string name
                readonly property real warn: Settings.s.statsWarn
                // statsHeat: colour shifts from the accent towards the error colour as load climbs
                readonly property color shade: {
                    if (value > warn) return Theme.error;
                    if (!Settings.s.statsHeat) return tint;
                    const t = Math.max(0, Math.min(1, (value - 0.35) / Math.max(0.1, warn - 0.35)));
                    const a = tint, b = Theme.error;
                    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
                }
                Text {
                    visible: Settings.s.statsLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.name
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.DemiBold
                }
                Ring {
                    visible: Settings.s.statsStyle === "rings"
                    anchors.verticalCenter: parent.verticalCenter
                    value: parent.value
                    color: parent.shade
                }
                Text {
                    visible: Settings.s.statsStyle === "text"
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.icon
                    color: parent.shade
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                }
                Rectangle {   // "bars" style: thin horizontal meter
                    visible: Settings.s.statsStyle === "bars"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 5; radius: 2.5
                    color: Theme.alpha(parent.shade, 0.22)
                    Rectangle {
                        width: parent.width * Math.max(0.04, Math.min(1, parent.parent.value)); height: parent.height; radius: parent.radius
                        color: parent.parent.shade
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
                Row {   // "ticks" style: five-segment level meter
                    visible: Settings.s.statsStyle === "ticks"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: 6
                        Rectangle {
                            required property int index
                            width: 3; height: 4 + index * 1.6; radius: 1
                            anchors.bottom: parent.bottom
                            color: parent.parent.value * 6 > index + 0.3 ? parent.parent.shade : Theme.alpha(parent.parent.shade, 0.2)
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(parent.value * 100) + "%"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.features: { "tnum": 1 }
                }
            }
            Gauge { value: Stats.cpu; tint: Theme.primary; icon: "󰍛"; name: "CPU" }
            Gauge { value: Stats.ram; tint: Theme.tertiary; icon: "󰘚"; name: "RAM" }
        }
    }
    Component {
        id: statusModule
        Chip {
            clickable: true
            onClicked: bar.toggleControlCenter()
            tint: Globals.controlCenterOpen ? Theme.primaryContainer : Theme.surfaceContainerHigh
            tintOpacity: Globals.controlCenterOpen ? 0.85 : 0.5
            spacing: 12

            IconLabel {
                id: bell
                visible: Settings.s.statusBell
                icon: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󰂚" : "󰂜"
                label: Notifs.count > 0 && !Notifs.dnd ? Notifs.count : ""
                iconColor: Notifs.dnd ? (Settings.s.statusStateColors ? Theme.secondary : Theme.outline) : Notifs.count > 0 ? Theme.tertiary : Theme.primary
                property int lastCount: Notifs.count
                Connections {
                    target: Notifs
                    function onCountChanged() {
                        if (Notifs.count > bell.lastCount && !Notifs.dnd) wiggle.restart();
                        bell.lastCount = Notifs.count;
                    }
                }
                SequentialAnimation {
                    id: wiggle
                    RotationAnimation { target: bell.iconItem; to: 18; duration: 80 }
                    RotationAnimation { target: bell.iconItem; to: -16; duration: 120 }
                    RotationAnimation { target: bell.iconItem; to: 10; duration: 110 }
                    RotationAnimation { target: bell.iconItem; to: -6; duration: 100 }
                    RotationAnimation { target: bell.iconItem; to: 0; duration: 140; easing.type: Easing.OutBack }
                }
            }
            IconLabel {
                visible: Settings.s.statusNetwork
                icon: NetStatus.icon
                iconColor: NetStatus.connected ? Theme.primary : Settings.s.statusStateColors ? Theme.error : Theme.outline
            }
            IconLabel {
                visible: Settings.s.statusBluetooth && BtStatus.available
                icon: BtStatus.icon
                iconColor: BtStatus.enabled ? Theme.primary : Theme.outline
            }
            Volume { visible: Settings.s.statusVolume }
            Battery { visible: Settings.s.statusBattery && (dev?.isLaptopBattery ?? false) }
        }
    }
    Component {
        id: launcherModule
        Chip {
            clickable: true
            padding: 10
            onClicked: { Globals.popupFrom(bar.screen?.name); Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"]); }
            Text {
                text: "󰣇"
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 4
            }
        }
    }
    Component {
        id: powerModule
        Chip {
            clickable: true
            padding: 10
            onClicked: { Globals.popupFrom(bar.screen?.name); Globals.powerMenuOpen = true; }
            Text {
                text: "󰐥"
                color: Theme.error
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
            }
        }
    }

    // Modules with nothing to show are skipped so they take no space.
    readonly property var hasContent: ({
        media: Media.player !== null,
        lyrics: Media.player !== null,
        record: Recorder.active,
        tray: SystemTray.items.values.length > 0,
    })

    function isShown(id) {
        if (id.startsWith("custom:")) return CustomModules.shown(id);
        return hasContent[id] !== false;
    }
    Component { id: customModule; CustomChip {} }

    readonly property real densityK: ({ compact: 0.7, spacious: 1.35 })[Settings.s.barDensity] ?? 1
    readonly property string divider: Settings.s.barDivider

    // A zone: loads its modules in order (accentPos spreads the accent colours across the bar).
    component Zone: Row {
        id: zone
        property var ids: []
        property int delayBase: 0
        property real posBase: 0
        property real posSpan: 0.33
        readonly property var shown: ids.filter(id => bar.isShown(id))
        readonly property real gap: 8 * bar.densityK
        spacing: bar.divider === "none" ? gap : 0
        Repeater {
            model: zone.shown
            Row {
                id: cell
                required property string modelData
                required property int index
                anchors.verticalCenter: parent?.verticalCenter
                spacing: 0
                Item {   // separator between modules
                    visible: cell.index > 0 && bar.divider !== "none"
                    anchors.verticalCenter: parent.verticalCenter
                    width: visible ? zone.gap * 2 + 4 : 0
                    height: 14
                    Rectangle {
                        anchors.centerIn: parent
                        visible: bar.divider === "dot" || bar.divider === "diamond"
                        width: bar.divider === "dot" ? 3 : 4; height: width
                        radius: bar.divider === "dot" ? 1.5 : 0.5
                        rotation: bar.divider === "diamond" ? 45 : 0
                        color: Theme.alpha(Theme.primary, 0.6)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        visible: bar.divider === "line"
                        width: 1; height: 14
                        color: Theme.alpha(Theme.text, 0.22)
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: bar.divider === "slash"
                        text: "/"
                        color: Theme.alpha(Theme.primary, 0.55)
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: bar.modules[cell.modelData] ?? (cell.modelData.startsWith("custom:") ? customModule : null)
                    onLoaded: if (item) {
                        if ("moduleId" in item) item.moduleId = cell.modelData;
                        if ("appearDelay" in item) item.appearDelay = zone.delayBase + cell.index * 70;
                        if ("accentPos" in item) item.accentPos = zone.posBase + zone.posSpan * (zone.shown.length > 1 ? cell.index / (zone.shown.length - 1) : 0.5);
                    }
                }
            }
        }
    }

    Item {
        y: bar.stripY
        width: parent.width
        height: bar.barHeight

        Zone {
            anchors.left: parent.left
            anchors.leftMargin: Theme.barIslands ? 0 : 5
            anchors.verticalCenter: parent.verticalCenter
            ids: bar.layout.left ?? []
            delayBase: 0
            posBase: 0
        }
        Zone {
            anchors.centerIn: parent
            ids: bar.layout.center ?? []
            delayBase: 140
            posBase: 0.36
            posSpan: 0.28
        }
        Zone {
            anchors.right: parent.right
            anchors.rightMargin: Theme.barIslands ? 0 : 5
            anchors.verticalCenter: parent.verticalCenter
            ids: bar.layout.right ?? []
            delayBase: 210
            posBase: 0.67
        }
    }
}
