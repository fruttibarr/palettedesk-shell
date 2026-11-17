import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// System monitor: live CPU, memory, GPU, network, disks, temperatures and the busiest processes.
// The sampler (scripts/sysmon.py) only runs while this is open.   qs ipc call sysmon toggle
Scope {
    id: root
    property var d: null
    property var cpuHist: []
    property var netHist: []
    property var gpuHist: []

    function push(arr, v) { const a = arr.concat([v]); return a.length > 60 ? a.slice(a.length - 60) : a; }
    function human(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : (b / 1024).toFixed(0) + " KB/s"; }
    function gb(mb) { return (mb / 1024).toFixed(1); }

    Process {
        id: sampler
        running: Globals.sysmonOpen
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/sysmon.py"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    root.d = s;
                    root.cpuHist = root.push(root.cpuHist, s.cpu);
                    root.netHist = root.push(root.netHist, s.net.rx + s.net.tx);
                    if (s.gpu) root.gpuHist = root.push(root.gpuHist, s.gpu.busy);
                } catch (e) {}
            }
        }
    }

    IpcHandler {
        target: "sysmon"
        function toggle(): void { Globals.sysmonOpen = !Globals.sysmonOpen; }
        function status(): string { return root.d ? "cpu " + root.d.cpu + "% mem " + root.d.mem.used + "/" + root.d.mem.total + " MB" : "no data"; }
    }

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
    component Bar: Rectangle {
        property real frac: 0
        property color tint: Theme.primary
        Layout.fillWidth: true; implicitHeight: 8; radius: 4; color: Theme.alpha(Theme.surface, 0.6)
        Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.frac)); height: parent.height; radius: 4
                    color: parent.frac > 0.9 ? Theme.error : parent.tint }
    }
    component Label: Text { color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }

    Overlay {
        name: "sysmon"
        open: Globals.sysmonOpen
        onCloseRequested: Globals.sysmonOpen = false

        GlassPanel {
            anchors.centerIn: parent
            width: 760
            height: Math.min(parent.height - 80, 560)

            Flickable {
                anchors.fill: parent; anchors.margins: 22
                contentHeight: body.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: body
                    width: parent.width; spacing: 10
                    Text { text: "System"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 6; font.weight: Font.Bold }
                    Label { visible: !root.d; text: "Reading…"; color: Theme.subtext }

                    RowLayout {
                        visible: !!root.d; Layout.fillWidth: true; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop; spacing: 10
                            Card {
                                heading: "CPU"
                                RowLayout { Label { text: (root.d?.cpu ?? 0).toFixed(0) + "%"; font.pixelSize: Theme.fontSize + 10; font.weight: Font.Bold; color: Theme.primary }
                                            Item { Layout.fillWidth: true }
                                            Label { text: (root.d?.cores?.length ?? 0) + " cores"; color: Theme.subtext } }
                                Graph { Layout.fillWidth: true; Layout.preferredHeight: 70; values: root.cpuHist; color: Theme.primary }
                                Flow {
                                    Layout.fillWidth: true; spacing: 4
                                    Repeater { model: root.d?.cores ?? []
                                        Rectangle { required property real modelData; width: 14; height: 26; radius: 3; color: Theme.alpha(Theme.surface, 0.6)
                                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height * modelData / 100; radius: 3
                                                        color: modelData > 85 ? Theme.error : Theme.secondary } } }
                                }
                            }
                            Card {
                                heading: "MEMORY"
                                Label { text: root.gb(root.d?.mem.used ?? 0) + " / " + root.gb(root.d?.mem.total ?? 0) + " GB" }
                                Bar { frac: (root.d?.mem.used ?? 0) / Math.max(1, root.d?.mem.total ?? 1) }
                                Label { visible: (root.d?.mem.swap_total ?? 0) > 0; text: "Swap " + root.gb(root.d?.mem.swap_used ?? 0) + " / " + root.gb(root.d?.mem.swap_total ?? 0) + " GB"; color: Theme.subtext }
                            }
                            Card {
                                visible: !!root.d?.gpu; heading: "GPU"
                                Label { text: (root.d?.gpu?.busy ?? 0) + "%   ·   VRAM " + root.gb(root.d?.gpu?.vram_used ?? 0) + " / " + root.gb(root.d?.gpu?.vram_total ?? 0) + " GB" }
                                Graph { Layout.fillWidth: true; Layout.preferredHeight: 50; values: root.gpuHist; color: Theme.tertiary }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop; spacing: 10
                            Card {
                                heading: "NETWORK"
                                Label { text: "↓ " + root.human(root.d?.net.rx ?? 0) + "     ↑ " + root.human(root.d?.net.tx ?? 0) }
                                Graph { Layout.fillWidth: true; Layout.preferredHeight: 50; values: root.netHist
                                        maxValue: Math.max(102400, Math.max.apply(null, root.netHist.concat([1]))); color: Theme.secondary }
                            }
                            Card {
                                visible: (root.d?.temps?.length ?? 0) > 0; heading: "TEMPERATURES"
                                Repeater { model: (root.d?.temps ?? []).slice(0, 5)
                                    RowLayout { required property var modelData; Layout.fillWidth: true
                                        Label { text: modelData.label; color: Theme.subtext; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Label { text: modelData.c.toFixed(0) + "°C"; color: modelData.c > 85 ? Theme.error : Theme.text } } }
                            }
                            Card {
                                heading: "DISKS"
                                Repeater { model: root.d?.disks ?? []
                                    ColumnLayout { required property var modelData; Layout.fillWidth: true; spacing: 3
                                        Label { text: modelData.mount + "   " + modelData.used + " / " + modelData.total + " GB" }
                                        Bar { frac: modelData.used / Math.max(1, modelData.total); tint: Theme.tertiary } } }
                            }
                            Card {
                                heading: "BUSIEST PROCESSES"
                                Repeater { model: root.d?.procs ?? []
                                    RowLayout { required property var modelData; Layout.fillWidth: true
                                        Label { text: modelData.name; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Label { text: modelData.cpu.toFixed(0) + "%"; color: Theme.primary; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                                        Label { text: modelData.mem + " MB"; color: Theme.subtext; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight } } }
                            }
                        }
                    }
                }
            }
        }
    }
}
