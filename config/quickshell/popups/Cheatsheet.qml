import Quickshell
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Keybind cheatsheet: every shortcut with the combo you actually have set (Settings > Keybinds).
// SUPER + /   or   qs ipc call cheatsheet toggle      Type to filter, Esc closes.
Scope {
    id: root
    property bool open: false
    property string query: ""

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.open = !root.open; }
        function show(): void { root.open = true; }
        function hide(): void { root.open = false; }
    }

    readonly property var pretty: ({ SLASH: "/", COMMA: ",", PERIOD: ".", SEMICOLON: ";", APOSTROPHE: "'", MINUS: "-", EQUAL: "=", BACKSLASH: "\\", GRAVE: "`",
                                     BRACKETLEFT: "[", BRACKETRIGHT: "]", RETURN: "Enter", PRINT: "PrtSc" })

    // [{ group, items: [{ label, keys: ["SUPER", "Q"] }] }] with the current combos, filtered by the search text
    readonly property var groups: {
        const q = query.trim().toLowerCase();
        const order = [], map = {};
        const add = (g, label, combo) => {
            if (!combo) return;
            if (q && !(label.toLowerCase().includes(q) || combo.toLowerCase().includes(q) || g.toLowerCase().includes(q))) return;
            if (!map[g]) { map[g] = []; order.push(g); }
            map[g].push({ label, keys: combo.split("+").map(k => k.trim()).filter(k => k).map(k => pretty[k.toUpperCase()] ?? k) });
        };
        for (const a of Settings.bindActions) add(a.group, a.label, Settings.bindFor(a.id));
        add("Workspaces", "Go to workspace 1–10", "SUPER + 1…0");
        add("Workspaces", "Move window to workspace 1–10", "SUPER + SHIFT + 1…0");
        add("Mouse", "Move window", "SUPER + left drag");
        add("Mouse", "Resize window", "SUPER + right drag");
        add("Mouse", "Cycle workspaces", "SUPER + scroll");
        return order.map(g => ({ group: g, items: map[g] }));
    }

    Overlay {
        name: "cheatsheet"
        open: root.open
        onCloseRequested: root.open = false
        onVisibleChanged: if (visible) { search.text = ""; search.forceActiveFocus(); }

        GlassPanel {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1180)
            height: Math.min(parent.height - 100, 720)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text { text: "󰌌  Keyboard shortcuts"; color: Theme.primary; font.family: Theme.font; font.pixelSize: Theme.fontSize + 4; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: 260
                        implicitHeight: 36
                        radius: 18
                        color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
                        TextInput {
                            id: search
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            clip: true
                            onTextChanged: root.query = text
                            Keys.onEscapePressed: root.open = false
                            Text { visible: !search.text; text: "Filter…"; color: Theme.outline; font: search.font; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: cols.height
                    boundsBehavior: Flickable.StopAtBounds

                    // masonry: groups dealt into columns, shortest column first
                    readonly property int nCols: Math.max(1, Math.min(4, Math.floor(width / 270)))
                    readonly property var columns: {
                        const cs = [];
                        const heights = [];
                        for (let i = 0; i < nCols; i++) { cs.push([]); heights.push(0); }
                        for (const g of root.groups) {
                            let m = 0;
                            for (let i = 1; i < nCols; i++) if (heights[i] < heights[m]) m = i;
                            cs[m].push(g);
                            heights[m] += g.items.length + 2.2;
                        }
                        return cs;
                    }

                    Row {
                        id: cols
                        width: flick.width
                        spacing: 16
                        Repeater {
                            model: flick.columns
                            Column {
                                id: col
                                required property var modelData
                                width: (flick.width - 16 * (flick.nCols - 1)) / flick.nCols
                                spacing: 14
                                Repeater {
                                    model: col.modelData
                                    Column {
                                        id: grp
                                        required property var modelData
                                        width: col.width
                                        spacing: 5
                                        Text { text: grp.modelData.group; color: Theme.primary; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; font.bold: true; font.capitalization: Font.AllUppercase; font.letterSpacing: 1 }
                                        Repeater {
                                            model: grp.modelData.items
                                            RowLayout {
                                                id: item
                                                required property var modelData
                                                width: grp.width
                                                spacing: 8
                                                Text { Layout.fillWidth: true; text: item.modelData.label; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                                Row {
                                                    spacing: 3
                                                    Repeater {
                                                        model: item.modelData.keys
                                                        Rectangle {
                                                            required property string modelData
                                                            width: kt.implicitWidth + 12; height: 20; radius: 6
                                                            color: Theme.alpha(Theme.surfaceContainerHigh, 0.9)
                                                            border.width: 1; border.color: Theme.alpha(Theme.primary, 0.3)
                                                            Text { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Text {
                    visible: root.groups.length === 0
                    text: "No shortcuts match."
                    color: Theme.outline
                    font.family: Theme.font
                }
                Text {
                    text: "Change any of these in Settings › Keybinds.   Esc to close."
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }
}
