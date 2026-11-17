import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Power menu.  SUPER+SHIFT+E  /  qs ipc call power toggle
// Arrows + Enter, or click. Log out / reboot / shut down need a second press.
Scope {
    id: root
    property int index: 0
    property int armed: -1

    readonly property var actions: [
        { icon: "󰌾", name: "Lock",      confirm: false, run: () => Globals.lockRequested() },
        { icon: "󰍃", name: "Log out",   confirm: true,  run: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]) },
        { icon: "󰤄", name: "Suspend",   confirm: false, run: () => Globals.suspend() },
        { icon: "󰜉", name: "Reboot",    confirm: true,  run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { icon: "󰐥", name: "Shut down", confirm: true,  run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
    ]

    function close() { Globals.powerMenuOpen = false; }
    function activate(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) { armed = i; index = i; return; }
        close();
        a.run();
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Globals.powerMenuOpen = !Globals.powerMenuOpen }
    }

    Overlay {
        name: "power"
        open: Globals.powerMenuOpen
        onCloseRequested: root.close()
        onVisibleChanged: if (visible) { root.index = 0; root.armed = -1; keys.forceActiveFocus(); }

        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.background, 0.35) }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Left) { root.index = (root.index + 4) % 5; root.armed = -1; }
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { root.index = (root.index + 1) % 5; root.armed = -1; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.activate(root.index);
                else if (e.key === Qt.Key_Escape) root.close();
                else return;
                e.accepted = true;
            }
        }

        GlassPanel {
            anchors.centerIn: parent
            width: row.implicitWidth + 40
            height: row.implicitHeight + 70

            RowLayout {
                id: row
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: btn
                        required property var modelData
                        required property int index
                        readonly property bool current: root.index === index
                        readonly property bool isArmed: root.armed === index
                        implicitWidth: 110
                        implicitHeight: 110
                        radius: 22
                        color: isArmed ? Theme.error
                             : current ? Theme.primary
                             : Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        scale: current ? 1.05 : 1
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.modelData.icon
                                color: btn.isArmed ? Theme.background : btn.current ? Theme.textOnPrimary : Theme.primary
                                font.family: Theme.font
                                font.pixelSize: 34
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: btn.modelData.name
                                color: btn.isArmed ? Theme.background : btn.current ? Theme.textOnPrimary : Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: if (root.index !== btn.index) { root.index = btn.index; root.armed = -1; }
                            onClicked: root.activate(btn.index)
                        }
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.armed >= 0 ? `Press again to ${root.actions[root.armed].name.toLowerCase()}`
                                      : "←/→ to choose · Enter to select · Esc to cancel"
                color: root.armed >= 0 ? Theme.error : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
