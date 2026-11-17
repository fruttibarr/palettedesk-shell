import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Audio mixer: output and input devices, and a volume + mute for every app that is playing or recording.
//   qs ipc call mixer toggle | micToggle | sinkNext
Scope {
    id: root

    // a node's audio state is only readable while it is tracked
    readonly property var all: Pipewire.nodes.values
    PwObjectTracker { objects: root.all }

    function cls(n) { return String(n.properties["media.class"] ?? ""); }
    function isEq(n) { return String(n.name).includes("eq32") || String(n.properties["node.name"] ?? "").includes("eq32"); }
    readonly property var sinks: all.filter(n => n.audio && cls(n) === "Audio/Sink" && !isEq(n))
    readonly property var sources: all.filter(n => n.audio && cls(n) === "Audio/Source" && !isEq(n))
    readonly property var playing: all.filter(n => n.audio && cls(n) === "Stream/Output/Audio" && !isEq(n))
    readonly property var recording: all.filter(n => n.audio && cls(n) === "Stream/Input/Audio" && !isEq(n))

    readonly property var defSink: Pipewire.preferredDefaultAudioSink
    readonly property var defSource: Pipewire.preferredDefaultAudioSource
    readonly property bool viaEq: String(Pipewire.defaultAudioSink?.name ?? "").startsWith("eq32")

    function label(n) { return n.nickname || n.description || n.name; }
    function appLabel(n) {
        const app = n.properties["application.name"] || n.nickname || n.description || n.name;
        const media = n.properties["media.name"];
        return media && media !== app ? app + "  ·  " + media : app;
    }
    function nextSink() {
        const list = sinks; if (list.length < 2) return;
        const i = list.findIndex(n => n === defSink);
        Pipewire.preferredDefaultAudioSink = list[(i + 1) % list.length];
    }

    IpcHandler {
        target: "mixer"
        function toggle(): void { Globals.mixerOpen = !Globals.mixerOpen; }
        function micToggle(): void { const a = root.defSource?.audio; if (a) a.muted = !a.muted; }
        function sinkNext(): void { root.nextSink(); }
        function status(): string {
            return "output=" + (root.defSink ? root.label(root.defSink) : "none") + " sinks=" + root.sinks.length +
                   " sources=" + root.sources.length + " apps=" + root.playing.length + (root.viaEq ? " (via equalizer)" : "");
        }
    }

    component Section: Text {
        Layout.topMargin: 6
        color: Theme.primary; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.Bold
        font.letterSpacing: 1
    }

    // one volume row: icon button (mute), name, slider
    component VolRow: RowLayout {
        id: vr
        property var node: null
        property string title: ""
        spacing: 10
        Layout.fillWidth: true
        Rectangle {
            Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
            color: Theme.alpha(Theme.surfaceContainerHigh, 0.7)
            Text { anchors.centerIn: parent; text: vr.node?.audio?.muted ? "󰝟" : "󰕾"; color: vr.node?.audio?.muted ? Theme.outline : Theme.primary
                   font.family: Theme.font; font.pixelSize: 15 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (vr.node?.audio) vr.node.audio.muted = !vr.node.audio.muted; } }
        }
        Text {
            Layout.preferredWidth: 170; elide: Text.ElideRight; text: vr.title
            color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
        }
        ValueSlider {
            Layout.fillWidth: true
            from: 0; to: 1; stepSize: 0.01; displayScale: 100; suffix: "%"
            value: vr.node?.audio?.volume ?? 0
            onMoved: v => { if (vr.node?.audio) vr.node.audio.volume = v; }
        }
    }

    Overlay {
        name: "mixer"
        open: Globals.mixerOpen
        onCloseRequested: Globals.mixerOpen = false

        GlassPanel {
            anchors.centerIn: parent
            width: 560
            height: Math.min(parent.height - 80, col.implicitHeight + 50)

            Flickable {
                anchors.fill: parent; anchors.margins: 22
                contentHeight: col.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: 8

                    Text { text: "Audio"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 6; font.weight: Font.Bold }
                    Text {
                        visible: root.viaEq; Layout.fillWidth: true; wrapMode: Text.WordWrap
                        text: "Sound is going through the equalizer. Picking a different output here bypasses it."
                        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    }

                    Section { text: "OUTPUT" }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: root.sinks
                            Rectangle {
                                id: chipS
                                required property var modelData
                                readonly property bool sel: root.defSink === modelData
                                height: 30; width: tS.implicitWidth + 24; radius: 15
                                color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, 0.7)
                                Text { id: tS; anchors.centerIn: parent; text: root.label(chipS.modelData); color: chipS.sel ? Theme.textOnPrimary : Theme.text
                                       font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = chipS.modelData }
                            }
                        }
                    }
                    VolRow { visible: !!root.defSink?.audio; node: root.defSink ?? null; title: "Master volume" }

                    Section { text: "INPUT" }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: root.sources
                            Rectangle {
                                id: chipI
                                required property var modelData
                                readonly property bool sel: root.defSource === modelData
                                height: 30; width: tI.implicitWidth + 24; radius: 15
                                color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, 0.7)
                                Text { id: tI; anchors.centerIn: parent; text: root.label(chipI.modelData); color: chipI.sel ? Theme.textOnPrimary : Theme.text
                                       font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSource = chipI.modelData }
                            }
                        }
                    }
                    Text { visible: root.sources.length === 0; text: "No microphone found"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                    VolRow { visible: !!root.defSource?.audio; node: root.defSource ?? null; title: "Microphone" }

                    Section { text: "APPS" }
                    Text { visible: root.playing.length === 0 && root.recording.length === 0; text: "Nothing is playing"
                           color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                    Repeater { model: root.playing;   VolRow { required property var modelData; node: modelData; title: root.appLabel(modelData) } }
                    Repeater { model: root.recording; VolRow { required property var modelData; node: modelData; title: "󰍬 " + root.appLabel(modelData) } }
                }
            }
        }
    }
}
