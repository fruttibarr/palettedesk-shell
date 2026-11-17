import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Dropdown under the right side of the bar.
// Toggle: click the status chip, SUPER+A, or `qs ipc call controlcenter toggle`.
Scope {
    id: root
    readonly property bool open: Globals.controlCenterOpen
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real volume: sink?.audio?.volume ?? 0
    // which detail list is open under the quick toggles: "", "wifi" or "bt"
    property string expanded: ""
    property string shownDetail: "wifi"   // lags `expanded` so content stays during collapse
    onExpandedChanged: if (expanded) shownDetail = expanded
    onOpenChanged: if (!open) expanded = ""
    function toggleDetail(which) { expanded = expanded === which ? "" : which; }

    PwObjectTracker { objects: [root.sink] }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { Globals.controlCenterOpen = !Globals.controlCenterOpen }
        // open straight to a detail list: `qs ipc call controlcenter wifi` / `bluetooth`
        function wifi(): void { Globals.controlCenterOpen = true; root.expanded = "wifi" }
        function bluetooth(): void { Globals.controlCenterOpen = true; root.expanded = "bt" }
    }

    Overlay {
        id: win
        name: "control-center"
        animScale: Theme.animControlCenter
        // grows out of the status chip, wherever the bar is
        origin: Qt.point(width - 60, Theme.barTop ? Theme.barReserved - 8 : height - Theme.barReserved + 8)
        open: root.open
        onCloseRequested: Globals.controlCenterOpen = false


        GlassPanel {
            id: panel
            anchors.right: parent.right
            anchors.rightMargin: 10
            y: Theme.barTop ? (root.open ? Theme.barReserved : Theme.barReserved - 16)
               : parent.height - height - Theme.barReserved + (root.open ? 0 : 16)
            width: 380
            height: content.implicitHeight + 32
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }


            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    SystemClock { id: ccClock; precision: SystemClock.Minutes }
                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(ccClock.date, "dddd, d MMMM")
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Font.Bold
                    }

                    component HeaderButton: Rectangle {
                        id: hb
                        property string icon
                        property color accent: Theme.primary
                        signal clicked()
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        color: hbMouse.containsMouse ? hb.accent : Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: hb.icon
                            color: hbMouse.containsMouse ? Theme.background : hb.accent
                            font.family: Theme.font
                            font.pixelSize: 15
                        }
                        MouseArea {
                            id: hbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hb.clicked()
                        }
                    }

                    HeaderButton {
                        icon: "󰒓"
                        onClicked: { Globals.controlCenterOpen = false; Globals.settingsOpen = true; }
                    }
                    HeaderButton {
                        icon: "󰌾"
                        onClicked: { Globals.controlCenterOpen = false; Globals.lockRequested(); }
                    }
                    HeaderButton {
                        icon: "󰐥"
                        accent: Theme.error
                        onClicked: { Globals.controlCenterOpen = false; Globals.powerMenuOpen = true; }
                    }
                }

                // Quick toggles
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: NetStatus.icon
                        title: "Wi-Fi"
                        subtitle: NetStatus.label
                        active: NetStatus.wifiEnabled
                        expandable: true
                        expanded: root.expanded === "wifi"
                        onClicked: NetStatus.toggleWifi()
                        onExpandClicked: root.toggleDetail("wifi")
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        enabled: BtStatus.available
                        icon: BtStatus.icon
                        title: "Bluetooth"
                        subtitle: BtStatus.label
                        active: BtStatus.enabled
                        expandable: true
                        expanded: root.expanded === "bt"
                        onClicked: BtStatus.toggle()
                        onExpandClicked: root.toggleDetail("bt")
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: Notifs.dnd ? "󰂛" : "󰂚"
                        title: "Do Not Disturb"
                        subtitle: Notifs.dnd ? "On" : "Off"
                        active: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: Globals.keepAwake ? "󰅶" : "󰛊"
                        title: "Keep awake"
                        subtitle: Globals.keepAwake ? "No sleep or lock" : "Off"
                        active: Globals.keepAwake
                        onClicked: Globals.keepAwake = !Globals.keepAwake
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: Settings.s.nightLight ? "󰖔" : "󰖙"
                        title: "Night light"
                        subtitle: Settings.s.nightLight ? Settings.s.nightTemp + " K" : "Off"
                        active: Settings.s.nightLight
                        onClicked: Settings.set("nightLight", !Settings.s.nightLight)
                    }
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: Recorder.active ? "󰻃" : "󰑊"
                        title: "Screen record"
                        subtitle: Recorder.active ? "Recording " + Recorder.clock : "Tap to start"
                        active: Recorder.active
                        onClicked: { Globals.controlCenterOpen = false; Recorder.toggle(""); }
                    }
                }

                // Wi-Fi / Bluetooth detail list (opened from a tile's chevron)
                Item {
                    id: detail
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.expanded ? detailBox.height : 0
                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 240 * Theme.animControlCenter; easing.type: Easing.OutCubic }
                    }
                    visible: Layout.preferredHeight > 0.5
                    clip: true

                    Rectangle {
                        id: detailBox
                        width: parent.width
                        height: detailLoader.implicitHeight + 20
                        radius: 16
                        color: Theme.alpha(Theme.surfaceContainerHigh, 0.55)

                        Loader {
                            id: detailLoader
                            x: 10
                            y: 10
                            width: parent.width - 20
                            active: root.expanded !== "" || detail.visible
                            sourceComponent: root.shownDetail === "bt" ? btDetail : wifiDetail
                        }
                    }
                    Component {
                        id: wifiDetail
                        WifiPanel { active: root.open && root.expanded === "wifi" }
                    }
                    Component {
                        id: btDetail
                        BluetoothPanel { active: root.open && root.expanded === "bt" }
                    }
                }

                // Power profile selector
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 21
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.55)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Repeater {
                            model: [
                                { profile: PowerProfile.PowerSaver,  icon: "󰌪", name: "Saver" },
                                { profile: PowerProfile.Balanced,    icon: "󰾅", name: "Balanced" },
                                { profile: PowerProfile.Performance, icon: "󰓅", name: "Performance" },
                            ]

                            Rectangle {
                                id: seg
                                required property var modelData
                                readonly property bool selected: PowerProfiles.profile === modelData.profile
                                visible: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: height / 2
                                color: selected ? Theme.primary
                                     : segMouse.containsMouse ? Theme.alpha(Theme.primary, 0.15) : "transparent"
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: seg.modelData.icon + "  " + seg.modelData.name
                                    color: seg.selected ? Theme.textOnPrimary : Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    font.weight: seg.selected ? Font.Bold : Font.Normal
                                }
                                MouseArea {
                                    id: segMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PowerProfiles.profile = seg.modelData.profile
                                }
                            }
                        }
                    }
                }

                // Sliders
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                SliderRow {
                    Layout.fillWidth: true
                    icon: root.muted ? "󰝟" : "󰕾"
                    dim: root.muted
                    value: root.volume
                    onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
                    onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                }
                    // Mixer button
                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: 19
                        color: mixMouse.containsMouse ? Theme.alpha(Theme.primaryContainer, 0.9) : Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                        Text { anchors.centerIn: parent; text: "󰓃"; color: Theme.primary; font.family: Theme.font; font.pixelSize: 17 }
                        MouseArea {
                            id: mixMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Globals.controlCenterOpen = false; Globals.mixerOpen = true; }
                        }
                    }
                    // Equalizer button
                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: 19
                        color: eqMouse.containsMouse || Eq.preset !== "Flat" && Eq.enabled
                               ? Theme.alpha(Theme.primaryContainer, 0.9) : Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: "󰺢"
                            color: Theme.primary
                            font.family: Theme.font
                            font.pixelSize: 17
                        }
                        MouseArea {
                            id: eqMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Globals.controlCenterOpen = false; Globals.equalizerOpen = true; }
                        }
                    }
                }
                SliderRow {
                    Layout.fillWidth: true
                    visible: Brightness.available
                    icon: "󰃠"
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }

                // Now playing
                MediaCard {
                    Layout.fillWidth: true
                    visible: Media.player !== null
                }

                // Notifications
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        visible: Notifs.count > 0
                        implicitWidth: countText.implicitWidth + 12
                        implicitHeight: 18
                        radius: 9
                        color: Theme.primary
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: Notifs.count
                            color: Theme.textOnPrimary
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Bold
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: Notifs.count > 0
                        text: "Clear all"
                        color: clearMouse.containsMouse ? Theme.primary : Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.clearAll()
                        }
                    }
                }

                Text {
                    visible: Notifs.count === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰂚  All caught up"
                    color: Theme.outline
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }

                ListView {
                    visible: Notifs.count > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 320)
                    clip: true
                    spacing: 8
                    model: [...Notifs.history].reverse()
                    delegate: NotifCard {
                        required property var modelData
                        width: ListView.view.width
                        notif: modelData
                        popup: false
                    }
                }
            }
        }
    }
}
