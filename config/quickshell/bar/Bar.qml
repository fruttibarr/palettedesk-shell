import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Effects

// The bar. Everything here is driven by Settings (Settings panel → Bar):
// position, style, height, margins, look, and which modules go where.
PanelWindow {
    id: bar

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
        color: Theme.alpha(Theme.surface, Theme.barOpacity)
        border.width: Settings.s.barBorder && !Theme.barAttached ? 1 : 0
        border.color: Theme.alpha(Theme.primary, 0.2)
        Behavior on color { ColorAnimation { duration: 400 } }

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
                Ring {
                    visible: Settings.s.statsStyle === "rings"
                    anchors.verticalCenter: parent.verticalCenter
                    value: parent.value
                    color: parent.value > 0.85 ? Theme.error : parent.tint
                }
                Text {
                    visible: Settings.s.statsStyle === "text"
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.icon
                    color: parent.value > 0.85 ? Theme.error : parent.tint
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
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
            Gauge { value: Stats.cpu; tint: Theme.primary; icon: "󰍛" }
            Gauge { value: Stats.ram; tint: Theme.tertiary; icon: "󰘚" }
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
                iconColor: Notifs.dnd ? Theme.outline : Notifs.count > 0 ? Theme.tertiary : Theme.primary
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
                iconColor: NetStatus.connected ? Theme.primary : Theme.outline
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

    // A zone: loads its modules in order.
    component Zone: Row {
        id: zone
        property var ids: []
        property int delayBase: 0
        spacing: 8
        Repeater {
            model: zone.ids.filter(id => bar.hasContent[id] !== false)
            Loader {
                required property string modelData
                required property int index
                anchors.verticalCenter: parent?.verticalCenter
                sourceComponent: bar.modules[modelData] ?? null
                onLoaded: if (item && "appearDelay" in item) item.appearDelay = zone.delayBase + index * 70
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
        }
        Zone {
            anchors.centerIn: parent
            ids: bar.layout.center ?? []
            delayBase: 140
        }
        Zone {
            anchors.right: parent.right
            anchors.rightMargin: Theme.barIslands ? 0 : 5
            anchors.verticalCenter: parent.verticalCenter
            ids: bar.layout.right ?? []
            delayBase: 210
        }
    }
}
