import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import qs.services
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts

// Lock screen.  qs ipc call lock lock      (SUPER+L)
//               qs ipc call lock testLock  (auto-unlocks after 15 s)
//
// RECOVERY if the lock screen ever crashes ("lockscreen died" red screen):
//   Ctrl+Alt+F2, log in, then:
//     hyprctl --instance 0 dispatch "hl.dsp.exit()"        (ends the session)
//   or restart the shell so it can take the lock again
//   (misc.allow_session_lock_restore is enabled in hyprland.lua):
//     WAYLAND_DISPLAY=wayland-1 qs -d && qs ipc call lock lock
Scope {
    id: root
    property bool testMode: false
    property bool busy: false
    property string error: ""
    property string pending: ""
    signal failed()

    function lock() {
        if (sessionLock.locked) return;
        error = "";
        sessionLock.locked = true;
        Globals.locked = true;
    }

    // Set Globals.locked ourselves instead of relying on WlSessionLock's change handler: that handler did not
    // reliably clear the flag after an unlock, so the shell kept believing it was locked. Wallpaper animation,
    // the OSD and the audio visualizer all pause while Globals.locked is true, so they stayed frozen until the
    // shell was restarted.
    function unlock() {
        sessionLock.locked = false;
        Globals.locked = false;
    }

    function tryUnlock(password) {
        if (busy || password === "") return;
        pending = password;
        busy = true;
        error = "";
        pam.start();
    }

    Connections {
        target: Globals
        function onLockRequested() { root.lock(); }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function testLock(): void { root.testMode = true; root.lock(); }
        function isLocked(): bool { return sessionLock.locked; }
    }

    PamContext {
        id: pam
        config: "login"
        onResponseRequiredChanged: if (responseRequired) { respond(root.pending); root.pending = ""; }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.error = "Wrong password";
                root.failed();
            }
        }
        onError: {
            root.busy = false;
            root.error = "Authentication error";
            root.failed();
        }
    }

    Timer {
        running: root.testMode && sessionLock.locked
        interval: 15000
        onTriggered: { root.unlock(); root.testMode = false; }
    }

    WlSessionLock {
        id: sessionLock
        onLockedChanged: Globals.locked = locked

        WlSessionLockSurface {
            id: surf
            color: Theme.background

            Image {
                id: wp
                anchors.fill: parent
                source: Theme.wallpaperStill ? "file://" + Theme.wallpaperStill : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(surf.width * (surf.Window.window?.devicePixelRatio ?? 1), surf.height * (surf.Window.window?.devicePixelRatio ?? 1))
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wp
                blurEnabled: Settings.s.lockBlur
                blur: 1.0
                blurMax: 64
                brightness: -Settings.s.lockDim
                saturation: 0.1
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.background, 0.1) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.background, 0.55) }
                }
            }

            SystemClock { id: clock; precision: SystemClock.Seconds }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.22
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, (Settings.s.clock24h ? "HH:mm" : "h:mm") + (Settings.s.lockSeconds ? ":ss" : "") + (Settings.s.clock24h ? "" : " AP"))
                    color: Theme.primary
                    font.family: Theme.font
                    font.pixelSize: 110
                    font.weight: Font.Bold
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Settings.s.lockShowDate
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.22
                spacing: 12

                Rectangle {
                    id: pill
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 340
                    implicitHeight: 54
                    radius: 27
                    color: Theme.alpha(Theme.surface, 0.6)
                    border.width: 2
                    border.color: root.error ? Theme.error : input.activeFocus ? Theme.primary : Theme.alpha(Theme.primary, 0.35)

                    transform: Translate { id: shiftX }
                    SequentialAnimation {
                        id: shake
                        loops: 2
                        NumberAnimation { target: shiftX; property: "x"; to: -12; duration: 50 }
                        NumberAnimation { target: shiftX; property: "x"; to: 12; duration: 80 }
                        NumberAnimation { target: shiftX; property: "x"; to: 0; duration: 50 }
                    }
                    Connections {
                        target: root
                        function onFailed() { input.text = ""; shake.restart(); }
                    }

                    Text {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.busy ? "󰔟" : "󰌾"
                        color: root.error ? Theme.error : Theme.primary
                        font.family: Theme.font
                        font.pixelSize: 18
                    }

                    TextInput {
                        id: input
                        anchors.left: lockIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 16
                        focus: true
                        enabled: !root.busy
                        Component.onCompleted: forceActiveFocus()
                        onTextChanged: if (text) root.error = ""
                        Keys.onReturnPressed: root.tryUnlock(text)
                        Keys.onEnterPressed: root.tryUnlock(text)
                        Keys.onEscapePressed: text = ""

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !input.text
                            text: root.testMode ? "Test lock — unlocks in 15 s" : "Enter password"
                            color: Theme.outline
                            font: input.font
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.error
                    visible: root.error !== ""
                    color: Theme.error
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
