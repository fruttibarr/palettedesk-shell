import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// 32-band equalizer.  SUPER+SHIFT+A  /  qs ipc call equalizer toggle
// Drag or scroll a band; double-click resets it to 0 dB.
// Below: preamp / auto headroom, high-pass, low-pass and the volume limiter.
Scope {
    id: root

    IpcHandler {
        target: "equalizer"
        function toggle(): void { Globals.equalizerOpen = !Globals.equalizerOpen }
        function preset(name: string): void { Eq.applyPreset(name); }
        function enable(on: bool): void { Eq.setEnabled(on); }
        // 0 Hz turns the filter off
        function highpass(hz: real): void { Eq.setHighPass(hz > 0, hz); }
        function lowpass(hz: real): void { Eq.setLowPass(hz > 0, hz); }
        // ceiling in dB (0 = only catch clipping, down to -20)
        function limit(db: real): void { Eq.setLimit(db); }
        function headroom(auto: bool): void { Eq.setAutoHeadroom(auto); }
        function status(): string {
            return `enabled=${Eq.enabled} preset=${Eq.preset} preamp=${Eq.preamp.toFixed(1)}dB`
                + ` (${Eq.autoHeadroom ? "auto" : "manual"}, peak +${Eq.peakDb.toFixed(1)}dB)`
                + ` highpass=${Eq.hpOn ? Eq.hpFreq + "Hz" : "off"} lowpass=${Eq.lpOn ? Eq.lpFreq + "Hz" : "off"}`
                + ` limit=${Eq.limitDb.toFixed(1)}dB (${Eq.realLimiter ? "lookahead limiter" : "hard clip"})`
                + ` filter=${Eq.available ? "running" : "missing"}`;
        }
    }

    component Pill: Rectangle {
        id: pill
        property string text
        property bool selected
        signal clicked()
        implicitWidth: pillText.implicitWidth + 26
        implicitHeight: 30
        radius: 15
        color: selected ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, pillMouse.containsMouse ? 0.9 : 0.6)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.text
            color: pill.selected ? Theme.textOnPrimary : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: pill.selected ? Font.Bold : Font.Normal
        }
        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    Overlay {
        name: "equalizer"
        open: Globals.equalizerOpen
        onCloseRequested: Globals.equalizerOpen = false

        GlassPanel {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 1000)
            height: 490

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Header: title, on/off, presets
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰺢  Equalizer"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.Bold
                    }

                    // on/off switch
                    Rectangle {
                        implicitWidth: 46
                        implicitHeight: 26
                        radius: 13
                        color: Eq.enabled ? Theme.primary : Theme.alpha(Theme.outline, 0.4)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: Eq.enabled ? parent.width - width - 3 : 3
                            color: Eq.enabled ? Theme.textOnPrimary : Theme.text
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Eq.setEnabled(!Eq.enabled)
                        }
                    }

                    Text {
                        visible: !Eq.available
                        text: "filter not running"
                        color: Theme.error
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: Eq.presetNames
                        Pill {
                            required property string modelData
                            text: modelData
                            selected: Eq.preset === modelData
                            onClicked: Eq.applyPreset(modelData)
                        }
                    }
                    Pill {
                        visible: Eq.preset === "Custom"
                        text: "Custom"
                        selected: true
                    }
                }

                // Graph with 32 draggable bands
                Item {
                    id: graph
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    opacity: Eq.enabled ? 1 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    readonly property real labelW: 34
                    readonly property real plotW: width - labelW
                    readonly property real plotH: height - 22
                    readonly property real colW: plotW / Eq.bands
                    function yFor(db) { return (Eq.maxDb - db) / (2 * Eq.maxDb) * plotH; }
                    function xFor(i) { return labelW + colW * (i + 0.5); }

                    // dB grid
                    Repeater {
                        model: [12, 6, 0, -6, -12]
                        Item {
                            required property int modelData
                            y: graph.yFor(modelData)
                            width: graph.width
                            Rectangle {
                                x: graph.labelW
                                width: graph.plotW
                                height: 1
                                color: Theme.alpha(modelData === 0 ? Theme.primary : Theme.outlineVariant, modelData === 0 ? 0.5 : 0.35)
                            }
                            Text {
                                anchors.verticalCenter: parent.top
                                width: graph.labelW - 8
                                horizontalAlignment: Text.AlignRight
                                text: (modelData > 0 ? "+" : "") + modelData
                                color: Theme.outline
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }

                    // filled curve
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillGradient: LinearGradient {
                                x1: 0; y1: 0; x2: 0; y2: graph.plotH
                                GradientStop { position: 0; color: Theme.alpha(Theme.primary, 0.35) }
                                GradientStop { position: 1; color: Theme.alpha(Theme.tertiary, 0.05) }
                            }
                            PathPolyline {
                                path: [Qt.point(graph.xFor(0), graph.yFor(0))]
                                    .concat(Eq.gains.map((g, i) => Qt.point(graph.xFor(i), graph.yFor(g))))
                                    .concat([Qt.point(graph.xFor(Eq.bands - 1), graph.yFor(0))])
                            }
                        }
                        ShapePath {
                            strokeWidth: 2.5
                            strokeColor: Theme.primary
                            fillColor: "transparent"
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline {
                                path: Eq.gains.map((g, i) => Qt.point(graph.xFor(i), graph.yFor(g)))
                            }
                        }
                    }

                    // actual combined response (bands overlap + high/low-pass)
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: Theme.alpha(Theme.tertiary, 0.9)
                            fillColor: "transparent"
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline {
                                path: Eq.curve.map((db, i) => Qt.point(
                                    graph.xFor((Eq.bands - 1) * i / (Eq.curvePoints - 1)),
                                    graph.yFor(Math.max(-Eq.maxDb, Math.min(Eq.maxDb, db)))))
                            }
                        }
                    }

                    // band columns
                    Repeater {
                        model: Eq.bands

                        Item {
                            id: band
                            required property int index
                            readonly property real gain: Eq.gains[index]
                            x: graph.labelW + graph.colW * index
                            width: graph.colW
                            height: graph.height

                            Rectangle {   // track
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 3
                                height: graph.plotH
                                radius: 1.5
                                color: Theme.alpha(Theme.outlineVariant, bandMouse.containsMouse ? 0.8 : 0.35)
                            }
                            Rectangle {   // knob
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: graph.yFor(band.gain) - height / 2
                                width: bandMouse.containsMouse || bandMouse.pressed ? 14 : 10
                                height: width
                                radius: width / 2
                                color: Theme.primary
                                border.width: 2
                                border.color: Theme.surface
                                Behavior on width { NumberAnimation { duration: 100 } }
                            }
                            Text {   // value while hovering
                                visible: bandMouse.containsMouse || bandMouse.pressed
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Math.max(0, graph.yFor(band.gain) - 26)
                                text: (band.gain > 0 ? "+" : "") + band.gain.toFixed(1)
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                                font.weight: Font.Bold
                            }
                            Text {   // frequency label every 4th band + last
                                visible: band.index % 4 === 0 || band.index === Eq.bands - 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                text: Eq.label(Eq.freqs[band.index])
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }

                            MouseArea {
                                id: bandMouse
                                width: parent.width
                                height: graph.plotH
                                hoverEnabled: true
                                cursorShape: Qt.SizeVerCursor
                                function setFromY(y) { Eq.setGain(band.index, Eq.maxDb - y / graph.plotH * 2 * Eq.maxDb); }
                                onPressed: e => setFromY(e.y)
                                onPositionChanged: e => { if (pressed) setFromY(e.y); }
                                onDoubleClicked: Eq.setGain(band.index, 0)
                                onWheel: e => Eq.setGain(band.index, band.gain + (e.angleDelta.y > 0 ? 0.5 : -0.5))
                            }
                        }
                    }
                }

                // Footer 1: preamp / headroom + reset
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Preamp"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    EqSlider {
                        Layout.preferredWidth: 220
                        frac: (Eq.preamp - Eq.preampMin) / (Eq.preampMax - Eq.preampMin)
                        accent: Eq.clipping ? Theme.error : Theme.tertiary
                        onMoved: f => Eq.setPreamp(Eq.preampMin + f * (Eq.preampMax - Eq.preampMin))
                        onStepped: d => Eq.setPreamp(Eq.preamp + 0.5 * d)
                    }
                    Text {
                        Layout.preferredWidth: 62
                        text: (Eq.preamp > 0 ? "+" : "") + Eq.preamp.toFixed(1) + " dB"
                        color: Eq.clipping ? Theme.error : Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Pill {
                        text: "󰁪  Auto headroom"
                        selected: Eq.autoHeadroom
                        onClicked: Eq.setAutoHeadroom(!Eq.autoHeadroom)
                    }
                    Text {
                        visible: Eq.clipping
                        text: "boosts exceed headroom by " + (Eq.preamp + Eq.peakDb).toFixed(1) + " dB"
                        color: Theme.error
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: !Eq.clipping
                        text: "Tip: double-click a band to reset it"
                        color: Theme.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Pill {
                        text: "󰑓  Reset"
                        onClicked: Eq.applyPreset("Flat")
                    }
                }

                // Footer 2: high-pass, low-pass, volume limiter
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Pill {
                        text: "High-pass"
                        selected: Eq.hpOn
                        onClicked: Eq.setHighPass(!Eq.hpOn, 0)
                    }
                    EqSlider {
                        Layout.fillWidth: true
                        dim: !Eq.hpOn
                        frac: Math.log(Eq.hpFreq / Eq.hpMin) / Math.log(Eq.hpMax / Eq.hpMin)
                        onMoved: f => Eq.setHighPass(true, Eq.hpMin * Math.pow(Eq.hpMax / Eq.hpMin, f))
                        onStepped: d => Eq.setHighPass(true, Eq.hpFreq * Math.pow(1.06, d))
                    }
                    Text {
                        Layout.preferredWidth: 54
                        text: Eq.hpOn ? Eq.label(Eq.hpFreq) + " Hz" : "off"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }

                    Pill {
                        Layout.leftMargin: 8
                        text: "Low-pass"
                        selected: Eq.lpOn
                        onClicked: Eq.setLowPass(!Eq.lpOn, 0)
                    }
                    EqSlider {
                        Layout.fillWidth: true
                        dim: !Eq.lpOn
                        frac: Math.log(Eq.lpFreq / Eq.lpMin) / Math.log(Eq.lpMax / Eq.lpMin)
                        onMoved: f => Eq.setLowPass(true, Eq.lpMin * Math.pow(Eq.lpMax / Eq.lpMin, f))
                        onStepped: d => Eq.setLowPass(true, Eq.lpFreq * Math.pow(1.06, d))
                    }
                    Text {
                        Layout.preferredWidth: 54
                        text: Eq.lpOn ? Eq.label(Eq.lpFreq) + " Hz" : "off"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }

                    Text {
                        Layout.leftMargin: 8
                        text: Eq.realLimiter ? "󰕾  Volume limit" : "󰕾  Volume limit (hard clip)"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    EqSlider {
                        Layout.fillWidth: true
                        dim: Eq.limitDb >= 0
                        frac: (Eq.limitDb - Eq.limitMin) / -Eq.limitMin
                        accent: Theme.primary
                        onMoved: f => Eq.setLimit(Eq.limitMin - f * Eq.limitMin)
                        onStepped: d => Eq.setLimit(Eq.limitDb + 0.5 * d)
                    }
                    Text {
                        Layout.preferredWidth: 54
                        text: Eq.limitDb >= 0 ? "0 dB" : Eq.limitDb.toFixed(1) + " dB"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }
        }
    }
}
