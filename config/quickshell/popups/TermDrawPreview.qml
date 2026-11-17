import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import QtQuick
import QtQuick.Layouts

// Live preview of the terminal being drawn, above all windows.
Scope {
    IpcHandler {
        target: "termdraw"
        function arm(): void { TermDraw.arm(); }
        function superClick(): void { TermDraw.superClick(); }
        function cancel(): void { TermDraw.cancel(); }
        // scripted drag for testing:  test 200 150 700 420  then  finish
        function test(x: int, y: int, w: int, h: int): void {
            TermDraw.begin(Quickshell.screens[0], x, y, false);
            TermDraw.update(x + w, y + h);
        }
        function finish(): void { TermDraw.finish(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            readonly property bool mine: TermDraw.screen === modelData
            readonly property bool catching: TermDraw.armed || (TermDraw.viaOverlay && TermDraw.active)
            readonly property bool drawingHere: TermDraw.active && mine

            visible: catching || drawingHere || preview.opacity > 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-termdraw"
            WlrLayershell.keyboardFocus: TermDraw.armed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            // click-through while the desktop (wallpaper layer) owns the drag
            property Region clickThrough: Region {}
            mask: catching ? null : clickThrough

            // keybind mode: dim + hint, catch the drag here
            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.background, 0.25)
                opacity: TermDraw.armed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.12
                visible: TermDraw.armed
                width: hint.implicitWidth + 36
                height: 40
                radius: 20
                color: Theme.alpha(Theme.surface, Theme.panelOpacity + 0.2)
                border.width: 1
                border.color: Theme.alpha(Theme.primary, 0.35)
                Text {
                    id: hint
                    anchors.centerIn: parent
                    text: "󰆍  Drag to draw a terminal   ·   Esc to cancel"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: win.catching
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.CrossCursor
                onPressed: e => {
                    if (e.button === Qt.RightButton) { TermDraw.cancel(); return; }
                    TermDraw.begin(win.modelData, e.x, e.y, true);
                }
                onPositionChanged: e => TermDraw.update(e.x, e.y)
                onReleased: e => { if (e.button === Qt.LeftButton) TermDraw.finish(); }
            }

            Item {
                focus: TermDraw.armed
                Keys.onEscapePressed: TermDraw.cancel()
            }

            // ---- the preview ----
            Item {
                id: preview
                x: TermDraw.rx
                y: TermDraw.ry
                width: TermDraw.rw
                height: TermDraw.rh
                opacity: win.drawingHere ? 1 : 0
                scale: win.drawingHere ? 1 : 1.04
                Behavior on opacity { NumberAnimation { duration: win.drawingHere ? 120 : 260; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                readonly property bool ok: TermDraw.bigEnough
                readonly property color accent: ok ? Theme.primary : Theme.error

                // terminal body, styled like the real thing
                Rectangle {
                    anchors.fill: parent
                    radius: Settings.s.rounding
                    color: Theme.alpha(Theme.surface, Settings.s.terminalOpacity)
                    border.width: Math.max(2, Settings.s.borderSize)
                    border.color: preview.accent
                    clip: true

                    // fake prompt with blinking cursor
                    Row {
                        x: 14
                        y: 14
                        spacing: 0
                        visible: preview.height > 50
                        Text { text: " ~ "; color: Theme.tertiary; font.family: Theme.font; font.pixelSize: 13 }
                        Text { text: "❯ "; color: Theme.primary; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                        Rectangle {
                            width: 8; height: 16
                            color: Theme.text
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: preview.visible
                                NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    // faint grid lines hint at the terminal's character cells
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        opacity: 0.06
                        Repeater {
                            model: Math.floor(preview.height / 20)
                            Rectangle {
                                required property int index
                                y: 40 + index * 20
                                width: parent.width
                                height: 1
                                color: Theme.text
                            }
                        }
                    }
                }

                // size label
                Rectangle {
                    anchors.centerIn: parent
                    visible: preview.width > 90 && preview.height > 40
                    width: sizeText.implicitWidth + 24
                    height: 30
                    radius: 15
                    color: preview.accent
                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: preview.ok
                            ? `${Math.round(TermDraw.rw)} × ${Math.round(TermDraw.rh)}`
                            : "too small"
                        color: Theme.background
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
