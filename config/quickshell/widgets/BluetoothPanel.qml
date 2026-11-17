import Quickshell
import Quickshell.Bluetooth
import qs.services
import QtQuick
import QtQuick.Layouts

// Bluetooth device list for the control center: discover, pair, connect,
// disconnect, forget.
ColumnLayout {
    id: root
    property bool active: false              // discover only while shown
    readonly property var adapter: BtStatus.adapter
    readonly property bool btOn: adapter?.enabled ?? false
    property var pendingConnect: []          // devices to connect once pairing finishes
    spacing: 6

    Binding {
        when: root.active && root.btOn
        target: root.adapter
        property: "discovering"
        value: true
        restoreMode: Binding.RestoreBindingOrValue
    }

    function deviceIcon(d) {
        const i = d?.icon || "";
        return i.startsWith("audio-head") ? "󰋋"
             : i.startsWith("audio") ? "󰓃"
             : i === "input-mouse" ? "󰍽"
             : i === "input-keyboard" ? "󰌌"
             : i === "input-gaming" ? "󰊴"
             : i === "input-tablet" ? "󰓶"
             : i.startsWith("phone") ? "󰏲"
             : i === "computer" ? "󰟀"
             : i.startsWith("camera") ? "󰄀"
             : "󰂯";
    }

    // header
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Text {
            text: "Bluetooth"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.Bold
        }
        Text {
            visible: root.adapter?.discovering ?? false
            text: "searching…"
            color: Theme.outline
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
        Item { Layout.fillWidth: true }
        Toggle {
            checked: root.btOn
            onToggled: v => { if (root.adapter) root.adapter.enabled = v; }
        }
    }

    // pairing prompt from the agent (BtStatus): confirm / show / enter a code
    Rectangle {
        id: prompt
        readonly property var p: BtStatus.agentPrompt
        visible: p !== null
        Layout.fillWidth: true
        implicitHeight: promptCol.implicitHeight + 20
        radius: 12
        color: Theme.alpha(Theme.primaryContainer, 0.85)
        border.width: 1
        border.color: Theme.primary

        function send() {
            if (codeIn.text) { BtStatus.agentReply(codeIn.text); codeIn.text = ""; }
        }

        ColumnLayout {
            id: promptCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.textOnPrimaryContainer
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                text: !prompt.p ? ""
                    : prompt.p.kind === "confirm" ? "Does the device show this code?"
                    : prompt.p.kind === "accept" ? "A device wants to pair. Allow it?"
                    : prompt.p.kind === "display" ? "Type this code on the device, then press Enter:"
                    : prompt.p.kind === "pin" ? "Enter the device's PIN (often 0000 or 1234):"
                    : "Enter the passkey shown on the device:"
            }
            Text {
                visible: prompt.p && prompt.p.code !== ""
                Layout.alignment: Qt.AlignHCenter
                text: prompt.p?.code ?? ""
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 10
                font.weight: Font.Bold
                font.letterSpacing: 4
            }
            Rectangle {
                visible: prompt.p && (prompt.p.kind === "pin" || prompt.p.kind === "passkey")
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 17
                color: Theme.alpha(Theme.surfaceContainerHigh, 0.9)
                border.width: codeIn.activeFocus ? 2 : 1
                border.color: codeIn.activeFocus ? Theme.primary : Theme.alpha(Theme.outline, 0.4)
                TextInput {
                    id: codeIn
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    inputMethodHints: Qt.ImhDigitsOnly
                    Keys.onReturnPressed: prompt.send()
                    Keys.onEnterPressed: prompt.send()
                    onVisibleChanged: if (visible) forceActiveFocus()
                }
            }
            RowLayout {
                visible: prompt.p && prompt.p.kind !== "display"
                Layout.alignment: Qt.AlignRight
                spacing: 6
                Repeater {
                    model: [{ label: "Cancel", yes: false }, { label: prompt.p?.kind === "pin" || prompt.p?.kind === "passkey" ? "Pair" : "Yes, pair", yes: true }]
                    Rectangle {
                        id: pbtn
                        required property var modelData
                        implicitWidth: pbtnText.implicitWidth + 28
                        implicitHeight: 32
                        radius: 16
                        color: modelData.yes ? (pbtnMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.primary, 0.85))
                             : pbtnMouse.containsMouse ? Theme.alpha(Theme.outline, 0.35) : Theme.alpha(Theme.outline, 0.2)
                        Text {
                            id: pbtnText
                            anchors.centerIn: parent
                            text: pbtn.modelData.label
                            color: pbtn.modelData.yes ? Theme.textOnPrimary : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: pbtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const k = prompt.p.kind;
                                if (k === "pin" || k === "passkey") {
                                    if (pbtn.modelData.yes) prompt.send();
                                    else BtStatus.agentReply("");   // empty reply rejects
                                } else {
                                    BtStatus.agentReply(pbtn.modelData.yes ? "yes" : "no");
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: !root.btOn || list.count === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: !root.adapter ? "Bluetooth service isn't running"
            : !root.btOn ? "Bluetooth is off"
            : "Looking for devices…"
        color: Theme.outline
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }

    ListView {
        id: list
        visible: root.btOn && count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 280)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: root.btOn
                ? [...root.adapter.devices.values]
                    // hide nameless new devices (just a MAC address)
                    .filter(d => d.paired || (d.deviceName && d.deviceName !== d.address))
                    .sort((a, b) => (b.connected - a.connected)
                                 || (b.paired - a.paired)
                                 || a.name.localeCompare(b.name))
                : []
        }

        delegate: DeviceRow {
            id: devRow
            required property var modelData
            readonly property var dev: modelData
            readonly property bool connecting: dev?.state === BluetoothDeviceState.Connecting
            readonly property bool disconnecting: dev?.state === BluetoothDeviceState.Disconnecting

            width: ListView.view.width
            icon: root.deviceIcon(dev)
            title: dev?.name || dev?.deviceName || dev?.address || ""
            current: dev?.connected ?? false
            busy: (dev?.pairing ?? false) || connecting || disconnecting
            subtitle: dev?.pairing ? "Pairing…"
                : connecting ? "Connecting…"
                : disconnecting ? "Disconnecting…"
                : dev?.connected ? "Connected" + (dev?.batteryAvailable ? "  ·  󰁹 " + Math.round(dev?.battery * 100) + "%" : "")
                : dev?.paired ? "Paired"
                : "Click to pair"
            actions: dev?.connected ? [{ icon: "󰂲", tip: "Disconnect" }, { icon: "󰆴", tip: "Forget", danger: true }]
                   : dev?.paired ? [{ icon: "󰆴", tip: "Forget", danger: true }]
                   : dev?.pairing ? [{ icon: "󰜺", tip: "Cancel" }]
                   : []

            onClicked: {
                if (dev?.connected || busy) return;
                if (dev?.paired) {
                    dev.connect();
                } else {
                    root.pendingConnect = [...root.pendingConnect, dev];
                    dev.pair();
                }
            }
            onActionClicked: i => {
                const a = actions[i];
                if (a.tip === "Disconnect") dev.disconnect();
                else if (a.tip === "Forget") dev.forget();
                else if (a.tip === "Cancel") dev.cancelPair();
            }

            Connections {
                target: devRow.dev
                function onPairedChanged() {
                    const d = devRow.dev;
                    if (!d.paired || !root.pendingConnect.includes(d)) return;
                    root.pendingConnect = root.pendingConnect.filter(x => x !== d);
                    d.trusted = true;
                    if (!d.connected) d.connect();
                }
                function onPairingChanged() {
                    // pairing failed or was cancelled
                    const d = devRow.dev;
                    if (!d.pairing && !d.paired)
                        root.pendingConnect = root.pendingConnect.filter(x => x !== d);
                }
            }
        }
    }
}
