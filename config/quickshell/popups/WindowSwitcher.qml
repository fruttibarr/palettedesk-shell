import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Alt-Tab window switcher (most recently used first) and a workspace overview.
//   qs ipc call switcher next | prev | commit | cancel        (ALT+Tab, ALT+SHIFT+Tab)
//   qs ipc call overview toggle                                (SUPER+Tab)
// Keys while the switcher is open: Tab / arrows move, Enter or releasing Alt switches, Esc cancels.
Scope {
    id: root

    // ---- most-recently-used order ----
    property var history: []          // window addresses, newest first
    function addr(t) { return String(t?.address ?? "").replace(/^0x/, ""); }
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const a = root.addr(Hyprland.activeToplevel);
            if (a) root.history = [a].concat(root.history.filter(x => x !== a)).slice(0, 60);
        }
    }
    function windows() {
        const rank = t => { const i = history.indexOf(addr(t)); return i < 0 ? 1000 : i; };
        return Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id > 0 && (t.title || t.lastIpcObject?.class))
                                        .sort((a, b) => rank(a) - rank(b));
    }
    function appClass(t) { return t?.lastIpcObject?.class ?? ""; }
    function iconFor(t) {
        const c = appClass(t); if (!c) return "";
        const e = DesktopEntries.byId(c) ?? DesktopEntries.byId(c.toLowerCase());
        return Quickshell.iconPath(e?.icon ?? c.toLowerCase(), true);
    }
    function focusWindow(t) {
        if (!t) return;
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${root.addr(t)}" })`);
    }

    // ---- switcher state ----
    property var list: []
    property int index: 0
    function open(step) {
        if (!Globals.switcherOpen) {
            list = windows();
            if (list.length === 0) return;
            index = list.length > 1 ? (step > 0 ? 1 : list.length - 1) : 0;
            Globals.popupFrom(Hyprland.focusedMonitor?.name);
            Globals.switcherOpen = true;
        } else if (list.length > 0) index = (index + step + list.length) % list.length;
    }
    // Closing the switcher gives keyboard focus back to the previously active window; if we focus the chosen window at
    // the same moment, that handover can win. So close first, then focus a moment later.
    Timer { id: focusLater; interval: 120; property var target: null; onTriggered: root.focusWindow(target) }
    function commit() {
        if (!Globals.switcherOpen) return;
        focusLater.target = list[index];
        Globals.switcherOpen = false;
        focusLater.restart();
    }
    function cancel() { Globals.switcherOpen = false; }

    IpcHandler {
        target: "switcher"
        function next(): void { root.open(1); }
        function prev(): void { root.open(-1); }
        function commit(): void { root.commit(); }
        function cancel(): void { root.cancel(); }
        function status(): string { return Globals.switcherOpen ? "open " + (root.index + 1) + "/" + root.list.length : "closed (" + root.windows().length + " windows)"; }
    }

    Overlay {
        name: "switcher"
        open: Globals.switcherOpen
        onCloseRequested: root.cancel()
        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Tab) root.open((e.modifiers & Qt.ShiftModifier) ? -1 : 1);
                else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left || e.key === Qt.Key_Up) root.open(-1);
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) root.open(1);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.commit();
                else if (e.key === Qt.Key_Escape) root.cancel();
                else return;
                e.accepted = true;
            }
            Keys.onReleased: e => { if (e.key === Qt.Key_Alt && !e.isAutoRepeat) { root.commit(); e.accepted = true; } }

            GlassPanel {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, strip.implicitWidth + 44)
                height: 190
                Row {
                    id: strip
                    anchors.centerIn: parent
                    spacing: 10
                    Repeater {
                        model: root.list
                        Rectangle {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool sel: root.index === index
                            width: 150; height: 140; radius: 14
                            color: sel ? Theme.alpha(Theme.primary, 0.35) : Theme.alpha(Theme.surfaceContainerHigh, 0.5)
                            border.width: sel ? 2 : 0; border.color: Theme.primary
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 6
                                IconImage { Layout.alignment: Qt.AlignHCenter; implicitSize: 56; source: root.iconFor(card.modelData); visible: source != "" }
                                Text { visible: root.iconFor(card.modelData) === ""; Layout.alignment: Qt.AlignHCenter; text: "󰖲"; color: Theme.primary
                                       font.family: Theme.font; font.pixelSize: 48 }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: card.modelData.title || root.appClass(card.modelData)
                                       color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "workspace " + (card.modelData.workspace?.id ?? "?")
                                       color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.index = card.index; root.commit(); } }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- overview
    IpcHandler {
        target: "overview"
        function toggle(): void { Globals.popupFrom(Hyprland.focusedMonitor?.name); Globals.overviewOpen = !Globals.overviewOpen; }
    }
    readonly property var workspaceIds: {
        const ids = new Set();
        for (const w of Hyprland.workspaces.values) if (w.id > 0 && w.id < 100 && (w.toplevels.values.length > 0 || w.active)) ids.add(w.id);
        return Array.from(ids).sort((a, b) => a - b);
    }
    function wsWindows(id) { return Hyprland.toplevels.values.filter(t => t.workspace?.id === id); }

    Overlay {
        name: "overview"
        open: Globals.overviewOpen
        onCloseRequested: Globals.overviewOpen = false
        GlassPanel {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1100)
            height: Math.min(parent.height - 80, ovCol.implicitHeight + 50)
            Flickable {
                anchors.fill: parent; anchors.margins: 22
                contentHeight: ovCol.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: ovCol
                    width: parent.width; spacing: 12
                    Text { text: "Workspaces"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 6; font.weight: Font.Bold }
                    GridLayout {
                        id: wsGrid
                        Layout.fillWidth: true; columns: 3; rowSpacing: 12; columnSpacing: 12
                        Repeater {
                            model: root.workspaceIds
                            Rectangle {
                                id: wc
                                required property int modelData
                                readonly property var wins: root.wsWindows(modelData)
                                readonly property bool current: Hyprland.monitors.values.some(m => m.activeWorkspace?.id === modelData)
                                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop
                                implicitHeight: col.implicitHeight + 24; radius: 14
                                color: Theme.alpha(Theme.surfaceContainerHigh, current ? 0.8 : 0.5)
                                border.width: current ? 2 : 0; border.color: Theme.primary
                                ColumnLayout {
                                    id: col; anchors.fill: parent; anchors.margins: 12; spacing: 6
                                    Text { text: "Workspace " + wc.modelData; color: wc.current ? Theme.primary : Theme.text; font.family: Theme.font
                                           font.pixelSize: Theme.fontSize; font.weight: Font.Bold }
                                    Text { visible: wc.wins.length === 0; text: "empty"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                    Repeater {
                                        model: wc.wins
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true; spacing: 8
                                            IconImage { implicitSize: 20; source: root.iconFor(modelData); visible: source != "" }
                                            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.title || root.appClass(modelData)
                                                   color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                        onClicked: { Globals.overviewOpen = false; root.focusWindow(modelData); } }
                                        }
                                    }
                                }
                                MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.PointingHandCursor
                                            onClicked: { Globals.overviewOpen = false; Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wc.modelData} })`); } }
                            }
                        }
                    }
                }
            }
        }
    }
}
