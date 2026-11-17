import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Volume / brightness indicator: a glass card tinted with the wallpaper
// palette — icon badge with a progress arc, gradient bar with a glowing knob.
Scope {
    id: root
    property string kind: "volume"     // "volume" | "brightness"
    property string icon: ""
    property real value: 0
    property bool dim: false
    property bool shown: false
    property bool ready: false   // ignore the initial values at startup

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function show(kind, icon, value, dim) {
        if (!ready || !Settings.s.osdEnabled || Globals.controlCenterOpen || Globals.locked) return;
        root.kind = kind;
        root.icon = icon;
        root.value = value;
        root.dim = dim;
        shown = true;
        hideTimer.restart();
    }

    function showVolume() {
        const a = sink?.audio;
        if (!a) return;
        show("volume", a.muted ? "󰝟" : a.volume > 0.6 ? "󰕾" : a.volume > 0.25 ? "󰖀" : "󰕿", a.volume, a.muted);
    }

    function showBrightness() {
        const v = Brightness.value;
        show("brightness", v > 0.66 ? "󰃠" : v > 0.33 ? "󰃟" : "󰃞", v, false);
    }

    Timer { interval: 2000; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: Math.round(Settings.s.osdTimeout * 1000); onTriggered: root.shown = false }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged() { root.showVolume(); }
    }
    Connections {
        target: Brightness
        function onCurrentChanged() {  root.showBrightness(); }
    }

    PanelWindow {
        id: win
        visible: root.shown || card.opacity > 0
        ScreenPin { id: pin; frozen: win.visible; followBars: false }
        screen: pin.screen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rice-osd"
        exclusionMode: ExclusionMode.Ignore
        readonly property bool atTop: Settings.s.osdPosition === "top"
        anchors.bottom: !atTop
        anchors.top: atTop
        // keep clear of the bar when it's on the same edge
        margins.bottom: Theme.barTop ? 50 : Theme.barReserved + 10
        margins.top: Theme.barTop ? Theme.barReserved + 10 : 50
        implicitWidth: 360
        implicitHeight: 108
        color: "transparent"
        mask: Region {}   // click-through

        // accent: wallpaper primary, fading to tertiary; grey when muted
        readonly property color accA: root.dim ? Theme.outline : Theme.primary
        readonly property color accB: root.dim ? Theme.outlineVariant : Theme.tertiary
        readonly property real shownValue: Math.max(0, Math.min(1, root.value))

        Rectangle {
            id: card
            width: 320
            height: 76
            anchors.horizontalCenter: parent.horizontalCenter
            // slide in from the screen edge with a little overshoot
            readonly property real slide: root.shown ? 0 : 22
            y: (win.atTop ? 16 + slide * -1 : parent.height - height - 16 + slide)
            Behavior on y {
                NumberAnimation {
                    duration: (root.shown ? 420 : 200) * Theme.animPopups
                    easing.type: root.shown ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.4
                }
            }
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: (root.shown ? 160 : 200) * Theme.animPopups } }
            scale: root.shown ? 1 : 0.94
            Behavior on scale {
                NumberAnimation {
                    duration: (root.shown ? 380 : 200) * Theme.animPopups
                    easing.type: root.shown ? Easing.OutBack : Easing.InCubic
                }
            }

            radius: 26
            color: Theme.alpha(Theme.surface, Math.min(0.9, Theme.panelOpacity))
            border.width: 1
            border.color: Theme.alpha(win.accA, 0.45)
            Behavior on color { ColorAnimation { duration: 400 } }

            // soft tint wash across the card: wallpaper colors bleeding in
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.alpha(win.accA, 0.20) }
                    GradientStop { position: 0.55; color: Theme.alpha(win.accB, 0.05) }
                    GradientStop { position: 1.0; color: Theme.alpha(win.accB, 0.14) }
                }
            }
            // top sheen
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
                anchors.leftMargin: 24; anchors.rightMargin: 24
                height: 1
                color: Theme.alpha(Theme.text, 0.18)
            }

            // ---- icon badge with progress arc ----
            Item {
                id: badge
                width: 52; height: 52
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                // glow behind the badge
                Rectangle {
                    anchors.centerIn: parent
                    width: 64; height: 64; radius: 32
                    color: Theme.alpha(win.accA, 0.16)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.alpha(Theme.primaryContainer, 0.75)
                    border.width: 1
                    border.color: Theme.alpha(win.accA, 0.3)
                }
                Canvas {
                    id: arc
                    anchors.fill: parent
                    property real v: win.shownValue
                    property color c1: win.accA
                    property color c2: win.accB
                    Behavior on v { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    onVChanged: requestPaint()
                    onC1Changed: requestPaint()
                    onC2Changed: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const cx = width / 2, cy = height / 2, r = width / 2 - 2.5;
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke();
                        if (v <= 0.005) return;
                        const g = ctx.createLinearGradient(0, height, width, 0);
                        g.addColorStop(0, c1);
                        g.addColorStop(1, c2);
                        ctx.strokeStyle = g;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v);
                        ctx.stroke();
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.dim ? Theme.outline : Theme.textOnPrimaryContainer
                    font.family: Theme.font
                    font.pixelSize: 22
                    // little pop each time the value changes
                    scale: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // ---- label, percentage, bar ----
            ColumnLayout {
                anchors {
                    left: badge.right; right: parent.right
                    leftMargin: 14; rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.kind === "brightness" ? "BRIGHTNESS" : (root.dim ? "MUTED" : "VOLUME")
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(win.shownValue * 100)
                        color: root.dim ? Theme.outline : Theme.text
                        font.family: Theme.font
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 3
                        text: "%"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 10
                    }
                }

                // bar
                Item {
                    id: bar
                    Layout.fillWidth: true
                    implicitHeight: 14

                    Rectangle {
                        id: track
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Theme.alpha(Theme.outlineVariant, 0.55)
                    }
                    // quarter notches
                    Repeater {
                        model: [0.25, 0.5, 0.75]
                        Rectangle {
                            required property real modelData
                            x: bar.width * modelData - 0.5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1; height: 10
                            color: Theme.alpha(Theme.text, 0.12)
                        }
                    }
                    // glow under the fill
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: fill.width; height: 12; radius: 6
                        color: Theme.alpha(win.accA, 0.22)
                        visible: fill.width > 2
                    }
                    Rectangle {
                        id: fill
                        anchors.verticalCenter: parent.verticalCenter
                        width: bar.width * win.shownValue
                        height: 6
                        radius: 3
                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: win.accA }
                            GradientStop { position: 1.0; color: win.accB }
                        }
                    }
                    // knob
                    Rectangle {
                        x: Math.max(0, fill.width - width / 2 - 1)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: Theme.text
                        border.width: 3
                        border.color: win.accB
                        visible: fill.width > 2
                    }
                }
            }
        }
    }
}
