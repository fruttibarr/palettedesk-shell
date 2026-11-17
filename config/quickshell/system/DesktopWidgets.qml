import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.widgets
import qs.widgets.desk
import QtQuick
import QtQuick.Layouts

// Desktop widgets: clock, calendar, media, stats, weather, notes, lyrics and command output placed on the wallpaper.
// Each widget is its own small layer window (Bottom layer: above the wallpaper, below every window), so clicks anywhere
// else go straight to the desktop. Edit mode (`qs ipc call desktop edit`) puts a full-screen overlay on top where
// widgets can be dragged, scaled and removed. Config: Settings "desktopWidgets" (Settings > Desktop widgets).
Scope {
    id: root
    readonly property var widgets: Settings.s.desktopWidgets ?? []
    readonly property bool editing: Globals.deskEdit
    property var sizes: ({})            // uid -> Qt.size(px) of the widget as it is on screen
    // stable list of ids: delegates are only rebuilt when a widget is added or removed, not on every drag step
    property var uidList: []
    function syncUids() { const n = widgets.map(w => w.uid); if (JSON.stringify(n) !== JSON.stringify(uidList)) uidList = n; }
    onWidgetsChanged: syncUids()
    Component.onCompleted: syncUids()

    readonly property var types: [
        { id: "clock", name: "Clock", icon: "󰥔" }, { id: "calendar", name: "Calendar", icon: "󰃭" }, { id: "media", name: "Now playing", icon: "󰎆" },
        { id: "system", name: "CPU & RAM", icon: "󰍛" }, { id: "weather", name: "Weather", icon: "󰖐" }, { id: "notes", name: "Note", icon: "󰎞" },
        { id: "lyrics", name: "Lyrics", icon: "󰎈" }, { id: "command", name: "Command output", icon: "󰆍" },
    ]
    function typeName(id) { return (types.find(t => t.id === id) ?? { name: id }).name; }
    function cfgOf(uid) { return widgets.find(w => w.uid === uid) ?? ({}); }
    function save(arr) { Settings.set("desktopWidgets", arr); }
    function patch(uid, change) { save(widgets.map(w => w.uid === uid ? Object.assign({}, w, change) : w)); }
    function patchOpts(uid, change) { patch(uid, { opts: Object.assign({}, cfgOf(uid).opts ?? {}, change) }); }
    function remove(uid) { save(widgets.filter(w => w.uid !== uid)); }
    function add(type, screenName) {
        const n = widgets.length;
        const plain = ["clock", "lyrics", "command"].includes(type);
        const opts = type === "clock" ? { h24: true, seconds: false, date: true, size: 72 } : type === "command" ? { command: "date", interval: 5, size: 18 } : {};
        const w = { uid: "w" + Date.now().toString(36), type: type, monitor: screenName ?? "", x: 0.06 + 0.07 * (n % 6), y: 0.14 + 0.09 * (n % 6),
                    scale: 1, opacity: 1, style: plain ? "plain" : "glass", opts: opts };
        save(widgets.concat([w]));
        return w.uid;
    }
    function setSize(uid, w, h) {
        const o = sizes[uid];
        if (o && o.width === w && o.height === h) return;
        const s = Object.assign({}, sizes); s[uid] = Qt.size(w, h); sizes = s;
    }

    IpcHandler {
        target: "desktop"
        function edit(): void { Globals.deskEdit = !Globals.deskEdit; }
        function add(type: string): string { return root.types.some(t => t.id === type) ? root.add(type, Quickshell.screens[0]?.name) : "unknown type; use " + root.types.map(t => t.id).join(", "); }
        function list(): string { return root.widgets.map(w => w.uid + "  " + w.type + "  (" + w.x.toFixed(2) + ", " + w.y.toFixed(2) + ") x" + w.scale).join("\n") || "no widgets"; }
        function clear(): void { root.save([]); }
    }

    // ---------------------------------------------------------------- one widget
    component DeskWindow: PanelWindow {
        id: win
        required property string uid
        required property ShellScreen scr
        readonly property var cfg: root.cfgOf(uid)
        readonly property real sc: cfg.scale ?? 1
        readonly property string look: cfg.style ?? "glass"
        readonly property real pad: look === "plain" ? 0 : 16

        screen: scr
        visible: !!cfg.type && (!cfg.monitor || cfg.monitor === scr.name)
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "rice-deskwidget"
        WlrLayershell.keyboardFocus: cfg.type === "notes" && !root.editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true }
        margins { left: Math.round((cfg.x ?? 0) * scr.width); top: Math.round((cfg.y ?? 0) * scr.height) }
        implicitWidth: Math.max(1, Math.ceil(bg.width * sc))
        implicitHeight: Math.max(1, Math.ceil(bg.height * sc))
        color: "transparent"
        onImplicitWidthChanged: root.setSize(uid, implicitWidth, implicitHeight)
        onImplicitHeightChanged: root.setSize(uid, implicitWidth, implicitHeight)
        Component.onCompleted: root.setSize(uid, implicitWidth, implicitHeight)

        Component { id: cClock; ClockW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cCalendar; CalendarW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cMedia; MediaW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cSystem; SystemW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cWeather; WeatherW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cNotes; NotesW { opts: win.cfg.opts ?? ({}); uid: win.uid } }
        Component { id: cLyrics; LyricsW { opts: win.cfg.opts ?? ({}) } }
        Component { id: cCommand; CommandW { opts: win.cfg.opts ?? ({}) } }
        readonly property var comps: ({ clock: cClock, calendar: cCalendar, media: cMedia, system: cSystem, weather: cWeather, notes: cNotes, lyrics: cLyrics, command: cCommand })

        Rectangle {
            id: bg
            width: body.implicitWidth + win.pad * 2
            height: body.implicitHeight + win.pad * 2
            scale: win.sc
            transformOrigin: Item.TopLeft
            opacity: win.cfg.opacity ?? 1
            radius: 18
            color: win.look === "glass" ? Theme.alpha(Theme.surface, 0.55) : "transparent"
            border.width: win.look === "plain" ? 0 : 1
            border.color: win.look === "outline" ? Theme.alpha(Theme.primary, 0.7) : Theme.alpha(Theme.primary, 0.18)
            Loader { id: body; x: win.pad; y: win.pad; sourceComponent: win.comps[win.cfg.type] ?? null }
        }
    }

    // ---------------------------------------------------------------- edit mode
    component EditLayer: PanelWindow {
        id: ed
        required property ShellScreen scr
        screen: scr
        visible: root.editing
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rice-deskedit"
        WlrLayershell.keyboardFocus: root.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Globals.deskEdit = false
            Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.background, 0.4) }

            Repeater {
                model: root.uidList
                Rectangle {
                    id: fr
                    required property string modelData
                    readonly property var cfg: root.cfgOf(modelData)
                    readonly property size sz: root.sizes[modelData] ?? Qt.size(120, 60)
                    visible: !!cfg.type && (!cfg.monitor || cfg.monitor === ed.scr.name)
                    x: Math.round((cfg.x ?? 0) * scope.width); y: Math.round((cfg.y ?? 0) * scope.height)
                    width: sz.width; height: sz.height
                    radius: 10
                    color: Theme.alpha(Theme.primary, 0.1)
                    border.width: 2; border.color: Theme.primary

                    Rectangle {
                        anchors { left: parent.left; bottom: parent.top; bottomMargin: 4 }
                        height: 22; width: tag.implicitWidth + 14; radius: 11; color: Theme.primary
                        Text { id: tag; anchors.centerIn: parent; text: root.typeName(fr.cfg.type); color: Theme.textOnPrimary; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                    }
                    MouseArea {
                        id: mv
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        property point from; property real sx; property real sy
                        onPressed: m => { from = mapToItem(null, m.x, m.y); sx = fr.x; sy = fr.y; }
                        onPositionChanged: m => {
                            if (!pressed) return;
                            const p = mapToItem(null, m.x, m.y);
                            let nx = sx + p.x - from.x, ny = sy + p.y - from.y;
                            const snap = 14, w = fr.width, h = fr.height;
                            const near = (v, t) => Math.abs(v - t) < snap;
                            if (near(nx, 0)) nx = 0; else if (near(nx + w, scope.width)) nx = scope.width - w; else if (near(nx + w / 2, scope.width / 2)) nx = scope.width / 2 - w / 2;
                            if (near(ny, 0)) ny = 0; else if (near(ny + h, scope.height)) ny = scope.height - h; else if (near(ny + h / 2, scope.height / 2)) ny = scope.height / 2 - h / 2;
                            nx = Math.max(0, Math.min(scope.width - w, nx)); ny = Math.max(0, Math.min(scope.height - h, ny));
                            root.patch(fr.modelData, { x: nx / scope.width, y: ny / scope.height });
                        }
                    }
                    Rectangle {   // remove
                        anchors { right: parent.right; top: parent.top; margins: -9 }
                        width: 20; height: 20; radius: 10; color: Theme.error
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.surface; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.remove(fr.modelData) }
                    }
                    Rectangle {   // scale handle
                        anchors { right: parent.right; bottom: parent.bottom; margins: -9 }
                        width: 20; height: 20; radius: 10; color: Theme.primary; border.width: 2; border.color: Theme.surface
                        Text { anchors.centerIn: parent; text: "⇲"; color: Theme.textOnPrimary; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.SizeFDiagCursor
                            property point from; property real w0; property real s0
                            onPressed: m => { from = mapToItem(null, m.x, m.y); w0 = fr.width; s0 = fr.cfg.scale ?? 1; }
                            onPositionChanged: m => {
                                if (!pressed) return;
                                const p = mapToItem(null, m.x, m.y);
                                const s = Math.max(0.4, Math.min(4, s0 * (w0 + p.x - from.x) / w0));
                                root.patch(fr.modelData, { scale: Math.round(s * 100) / 100 });
                            }
                        }
                    }
                }
            }

            // toolbar
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 64 }
                width: tools.implicitWidth + 28; height: 52; radius: 26
                color: Theme.alpha(Theme.surfaceContainerHigh, 0.92)
                border.width: 1; border.color: Theme.alpha(Theme.primary, 0.35)
                Row {
                    id: tools
                    anchors.centerIn: parent
                    spacing: 8
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Add:"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                    Repeater {
                        model: root.types
                        Rectangle {
                            required property var modelData
                            height: 32; width: tl.implicitWidth + 22; radius: 16
                            color: tm.containsMouse ? Theme.primary : Theme.alpha(Theme.surface, 0.7)
                            Text { id: tl; anchors.centerIn: parent; text: parent.modelData.icon + "  " + parent.modelData.name; color: tm.containsMouse ? Theme.textOnPrimary : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.add(parent.modelData.id, ed.scr.name) }
                        }
                    }
                    Rectangle {
                        height: 32; width: dl.implicitWidth + 26; radius: 16; color: Theme.primary
                        Text { id: dl; anchors.centerIn: parent; text: "Done"; color: Theme.textOnPrimary; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Globals.deskEdit = false }
                    }
                }
            }
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 124 }
                text: "Drag to move · corner handle to resize · ✕ to remove · Esc when done"
                color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: ps
            required property ShellScreen modelData
            Variants {
                model: root.uidList
                delegate: DeskWindow { required property string modelData; uid: modelData; scr: ps.modelData }
            }
            EditLayer { scr: ps.modelData }
        }
    }
}
