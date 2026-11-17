import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Clipboard history (cliphist).  SUPER+V  /  qs ipc call clipboard toggle
// Enter = copy, Delete = remove entry, Esc = close.
Scope {
    id: root
    property bool open: false
    property var entries: []
    property string query: ""

    readonly property var results: {
        const q = query.trim().toLowerCase();
        return q ? entries.filter(e => e.text.toLowerCase().includes(q)) : entries;
    }

    function parse(line) {
        const tab = line.indexOf("\t");
        const id = line.slice(0, tab);
        const text = line.slice(tab + 1);
        const img = text.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
        return {
            line, id, text,
            isImage: img !== null,
            label: img ? `Image · ${img[2].toUpperCase()} ${img[3]} · ${img[1]}` : text.replace(/\s+/g, " ").trim(),
        };
    }

    function copy(entry) {
        if (!entry) return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line]);
        open = false;
    }

    function remove(entry) {
        if (!entry) return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry.line]);
        entries = entries.filter(e => e !== entry);
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.open = !root.open }
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l.includes("\t")).map(root.parse)
        }
    }

    Overlay {
        name: "clipboard"
        open: root.open
        onCloseRequested: root.open = false
        onVisibleChanged: if (visible) {
            lister.running = true;
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        }

        GlassPanel {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            width: 620
            height: 480

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 22
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)

                    Text {
                        id: clipIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅌"
                        color: Theme.primary
                        font.family: Theme.font
                        font.pixelSize: 17
                    }

                    TextInput {
                        id: search
                        anchors.left: clipIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 15
                        onTextChanged: { root.query = text; list.currentIndex = 0; }

                        Text {
                            visible: !search.text
                            text: root.entries.length ? `Search ${root.entries.length} clipboard entries…` : "Clipboard is empty"
                            color: Theme.outline
                            font: search.font
                        }

                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) root.open = false;
                            else if (e.key === Qt.Key_Down) list.incrementCurrentIndex();
                            else if (e.key === Qt.Key_Up) list.decrementCurrentIndex();
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.copy(root.results[list.currentIndex]);
                            else if (e.key === Qt.Key_Delete) root.remove(root.results[list.currentIndex]);
                            else return;
                            e.accepted = true;
                        }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.results
                    highlightMoveDuration: 100
                    highlight: Rectangle { radius: 12; color: Theme.primary }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        width: list.width
                        height: 42

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12
                            Text {
                                text: row.modelData.isImage ? "󰋩" : "󰦨"
                                color: row.current ? Theme.textOnPrimary : row.modelData.isImage ? Theme.tertiary : Theme.primary
                                font.family: Theme.font
                                font.pixelSize: 15
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.label
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: row.current ? Theme.textOnPrimary : Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.italic: row.modelData.isImage
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: root.copy(row.modelData)
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Enter copy · Del remove · Esc close"
                    color: Theme.outline
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
