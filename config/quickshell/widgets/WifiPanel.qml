import Quickshell
import Quickshell.Networking
import qs.services
import QtQuick
import QtQuick.Layouts

// Wi-Fi network list for the control center: scan, connect (with password),
// disconnect, forget.
ColumnLayout {
    id: root
    property bool active: false             // scan only while shown
    readonly property var dev: NetStatus.wifiDevice
    property var pskTarget: null            // network whose password field is open
    spacing: 6

    // keep the scanner on while the panel is visible
    Binding {
        when: root.active && root.dev !== null && Networking.wifiEnabled
        target: root.dev
        property: "scannerEnabled"
        value: true
        restoreMode: Binding.RestoreBindingOrValue
    }
    onActiveChanged: if (!active) pskTarget = null

    function secured(n) {
        if (!n) return false;
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe
            && n.security !== WifiSecurityType.Unknown;
    }
    function strengthOf(n) {
        const s = n?.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }
    function signalIcon(n) {
        const s = strengthOf(n);
        return s > 0.75 ? "󰤨" : s > 0.5 ? "󰤥" : s > 0.25 ? "󰤢" : "󰤟";
    }

    // header
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Text {
            text: "Wi-Fi"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Bold
        }
        Text {
            visible: root.active && root.dev?.scannerEnabled && Networking.wifiEnabled
            text: "scanning…"
            color: Theme.outline
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
        Item { Layout.fillWidth: true }
        Toggle {
            checked: Networking.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    Text {
        visible: !Networking.wifiEnabled || root.dev === null || list.count === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.dev === null ? "No Wi-Fi adapter"
            : !Networking.wifiEnabled ? (Networking.wifiHardwareEnabled ? "Wi-Fi is off" : "Wi-Fi is blocked (airplane mode / hardware switch)")
            : "Looking for networks…"
        color: Theme.outline
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        wrapMode: Text.WordWrap
    }

    ListView {
        id: list
        visible: Networking.wifiEnabled && count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: (root.dev && Networking.wifiEnabled)
                ? [...root.dev.networks.values]
                    .filter(n => n.name)
                    .sort((a, b) => (b.connected - a.connected)
                                 || (b.known - a.known)
                                 // bucket strength so rows don't jump around constantly
                                 || (Math.round(root.strengthOf(b) * 4) - Math.round(root.strengthOf(a) * 4))
                                 || a.name.localeCompare(b.name))
                : []
        }

        delegate: DeviceRow {
            id: netRow
            required property var modelData
            readonly property var net: modelData
            readonly property bool askPsk: root.pskTarget === net
            property string failText: ""

            width: ListView.view.width
            icon: root.signalIcon(net)
            title: net?.name + (root.secured(net) ? "  󰌾" : "")
            current: net?.connected ?? false
            busy: net?.stateChanging ?? false
            error: failText !== ""
            subtitle: failText !== "" ? failText
                : net?.state === ConnectionState.Connecting ? "Connecting…"
                : net?.state === ConnectionState.Disconnecting ? "Disconnecting…"
                : net?.connected ? "Connected"
                : net?.known ? "Saved"
                : root.secured(net) ? "" : "Open"
            actions: net?.connected ? [{ icon: "󰖪", tip: "Disconnect" }, { icon: "󰆴", tip: "Forget", danger: true }]
                   : net?.known ? [{ icon: "󰆴", tip: "Forget", danger: true }]
                   : []

            onClicked: {
                failText = "";
                if (net?.connected || net?.stateChanging) return;
                if (net?.known || !root.secured(net)) {
                    root.pskTarget = null;
                    net.connect();
                } else {
                    root.pskTarget = askPsk ? null : net;
                }
            }
            onActionClicked: i => {
                const a = actions[i];
                if (a.tip === "Disconnect") net.disconnect();
                else if (a.tip === "Forget") net.forget();
            }

            Connections {
                target: netRow.net
                function onConnectionFailed(reason) {
                    netRow.failText = reason === ConnectionFailReason.NoSecrets ? "Wrong password"
                        : reason === ConnectionFailReason.WifiAuthTimeout ? "Authentication timed out"
                        : reason === ConnectionFailReason.WifiNetworkLost ? "Network lost"
                        : "Couldn't connect";
                    // a saved network with a bad password: ask for a new one
                    if (reason === ConnectionFailReason.NoSecrets && root.secured(netRow.net))
                        root.pskTarget = netRow.net;
                }
                function onConnectedChanged() { if (netRow.net?.connected) netRow.failText = ""; }
            }

            // password field
            RowLayout {
                visible: netRow.askPsk
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 6

                function submit() {
                    if (!psk.text) return;
                    netRow.failText = "";
                    netRow.net.connectWithPsk(psk.text);
                    psk.text = "";
                    root.pskTarget = null;
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 17
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.9)
                    border.width: psk.activeFocus ? 2 : 1
                    border.color: psk.activeFocus ? Theme.primary : Theme.alpha(Theme.outline, 0.4)

                    TextInput {
                        id: psk
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 34
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: showPsk.checked ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        clip: true
                        Keys.onReturnPressed: parent.parent.submit()
                        Keys.onEnterPressed: parent.parent.submit()
                        Keys.onEscapePressed: root.pskTarget = null
                        Component.onCompleted: if (netRow.askPsk) forceActiveFocus()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !psk.text
                            text: "Password"
                            color: Theme.outline
                            font: psk.font
                        }
                    }
                    Text {
                        id: showPsk
                        property bool checked: false
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: checked ? "󰈈" : "󰈉"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showPsk.checked = !showPsk.checked
                        }
                    }
                }
                Rectangle {
                    implicitWidth: 70
                    implicitHeight: 34
                    radius: 17
                    opacity: psk.text ? 1 : 0.5
                    color: goMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.primary, 0.8)
                    Text {
                        anchors.centerIn: parent
                        text: "Join"
                        color: Theme.textOnPrimary
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: goMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.submit()
                    }
                }
            }
            onAskPskChanged: if (askPsk) psk.forceActiveFocus()
        }
    }
}
