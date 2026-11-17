import Quickshell
import Quickshell.Services.Polkit
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Polkit authentication agent (GUI admin prompts, `pkexec`, etc.).
Scope {
    id: root

    PolkitAgent { id: agent }
    readonly property AuthFlow flow: agent.flow

    function cancel() { if (flow) flow.cancelAuthenticationRequest(); }
    function submit() {
        if (!flow || !flow.isResponseRequired) return;
        flow.submit(pass.text);
        pass.text = "";
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() { shake.restart(); }
    }

    Overlay {
        id: win
        name: "polkit"
        open: agent.isActive
        onCloseRequested: root.cancel()
        onVisibleChanged: if (visible) { pass.text = ""; pass.forceActiveFocus(); }

        // dim the screen behind
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.background, 0.35) }

        GlassPanel {
            id: panel
            anchors.centerIn: parent
            width: 420
            height: col.implicitHeight + 40

            transform: Translate { id: offset }
            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: offset; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: offset; property: "x"; to: 10; duration: 80 }
                NumberAnimation { target: offset; property: "x"; to: 0; duration: 50 }
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 14

                RowLayout {
                    spacing: 14
                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: 22
                        color: Theme.primaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            color: Theme.textOnPrimaryContainer
                            font.family: Theme.font
                            font.pixelSize: 20
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Authentication required"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Font.Bold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.flow?.message ?? ""
                            wrapMode: Text.Wrap
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 22
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
                    border.width: pass.activeFocus ? 2 : 0
                    border.color: root.flow?.supplementaryIsError ? Theme.error : Theme.primary

                    TextInput {
                        id: pass
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        enabled: root.flow?.isResponseRequired ?? false
                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.cancel()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !pass.text
                            text: root.flow?.inputPrompt?.replace(/:\s*$/, "") || "Password"
                            color: Theme.outline
                            font: pass.font
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.flow?.supplementaryMessage ?? ""
                    wrapMode: Text.Wrap
                    color: root.flow?.supplementaryIsError ? Theme.error : Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10

                    component DialogButton: Rectangle {
                        id: b
                        property string label
                        property bool primary
                        signal clicked()
                        implicitWidth: bt.implicitWidth + 36
                        implicitHeight: 36
                        radius: 18
                        color: primary ? (bm.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
                                       : Theme.alpha(Theme.surfaceContainerHigh, bm.containsMouse ? 0.9 : 0.6)
                        Text {
                            id: bt
                            anchors.centerIn: parent
                            text: b.label
                            color: b.primary ? Theme.textOnPrimary : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: bm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: b.clicked()
                        }
                    }

                    DialogButton { label: "Cancel"; onClicked: root.cancel() }
                    DialogButton { label: "Authenticate"; primary: true; onClicked: root.submit() }
                }
            }
        }
    }
}
