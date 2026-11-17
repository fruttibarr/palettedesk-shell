import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes

// App launcher.  qs ipc call launcher toggle   (SUPER+Space / SUPER+D / SUPER+R)
//
//   empty query  -> frequent apps + animated grid, filter with category chips (Tab)
//   typing       -> ranked list with fuzzy matching and app actions
//   =2+2*3       -> calculator (Enter copies the result)
//   >command     -> run a shell command in a terminal
//   ?words       -> web search
Scope {
    id: root
    property bool open: false
    property string query: ""
    property string category: "all"
    property int openSerial: 0          // bumps on every open, replays entrance animations
    property bool launching: false

    readonly property var cfg: Settings.s
    readonly property string q: query.trim()
    readonly property string mode: cfg.launcherCalc && (q.startsWith("=") || isMath(q)) ? "calc"
                                 : cfg.launcherRun && q.startsWith(">") ? "cmd"
                                 : cfg.launcherWeb && q.startsWith("?") ? "web"
                                 : q !== "" ? "search" : "browse"
    // browsing as a grid, or as the same list used for search results
    readonly property bool gridBrowse: mode === "browse" && cfg.launcherDefaultView === "grid"
    readonly property bool stagger: cfg.launcherStagger
    // Docked: slides up out of the bottom edge (not with a bottom bar - the setting is greyed out then)
    readonly property bool docked: cfg.launcherPosition === "bottom" && cfg.barPosition !== "bottom"

    readonly property var webEngines: ({
        "duckduckgo": "https://duckduckgo.com/?q=", "google": "https://www.google.com/search?q=",
        "brave": "https://search.brave.com/search?q=", "startpage": "https://www.startpage.com/do/search?q=",
        "bing": "https://www.bing.com/search?q=", "kagi": "https://kagi.com/search?q="
    })
    readonly property var hiddenList: (cfg.launcherHidden ?? "").split(",").map(x => x.trim().toLowerCase()).filter(x => x)
    function isHidden(a) { return hiddenList.includes(a.name.toLowerCase()) || hiddenList.includes(String(a.id).toLowerCase()); }
    function hideApp(a) {
        const list = (cfg.launcherHidden ?? "").split(",").map(x => x.trim()).filter(x => x);
        if (!list.includes(a.name)) list.push(a.name);
        Settings.set("launcherHidden", list.join(", "));
    }

    // ---------- data ----------
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay && !isHidden(a))
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var categories: [
        { id: "all",      label: "All",      icon: "󰀻", cats: [] },
        { id: "dev",      label: "Develop",  icon: "󰅩", cats: ["Development", "IDE", "TextEditor"] },
        { id: "net",      label: "Internet", icon: "󰖟", cats: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging"] },
        { id: "media",    label: "Media",    icon: "󰎆", cats: ["AudioVideo", "Audio", "Video", "Music", "Player"] },
        { id: "gfx",      label: "Graphics", icon: "󰏘", cats: ["Graphics", "Photography", "2DGraphics", "3DGraphics"] },
        { id: "office",   label: "Office",   icon: "󰈙", cats: ["Office", "Viewer", "Documentation", "Education"] },
        { id: "game",     label: "Games",    icon: "󰊴", cats: ["Game"] },
        { id: "system",   label: "System",   icon: "󰒓", cats: ["System", "Settings", "Utility", "Monitor", "TerminalEmulator", "FileManager"] },
    ]
    function inCategory(a, c) {
        if (c.id === "all") return true;
        const ac = a.categories ?? [];
        return c.cats.some(x => ac.includes(x));
    }
    // only show chips that have something in them
    readonly property var usedCategories: categories.filter(c => c.id === "all" || apps.some(a => inCategory(a, c)))
    readonly property var browseApps: {
        const c = categories.find(x => x.id === category) ?? categories[0];
        return apps.filter(a => inCategory(a, c));
    }

    // launch counts (for "Frequent" and ranking)
    function countOf(a) { return (store.counts ?? {})[a.id] ?? 0; }
    readonly property var frequent: apps.filter(a => countOf(a) > 0)
        .sort((a, b) => countOf(b) - countOf(a)).slice(0, Math.max(1, cfg.launcherFrequentCount))

    // ---------- search ----------
    function isMath(s) { return /^[\d\s.()+\-*/%^]+$/.test(s) && /\d/.test(s) && /[+\-*/%^]/.test(s.replace(/^-/, "")); }
    function calc(s) {
        const expr = s.replace(/^=/, "").replace(/,/g, ".").replace(/\^/g, "**");
        if (!/^[\d\s.()+\-*/%]*$/.test(expr) || expr.trim() === "") return null;
        try {
            const v = Function('"use strict"; return (' + expr + ')')();
            if (typeof v !== "number" || !isFinite(v)) return null;
            return String(Number(v.toPrecision(12)));
        } catch (e) { return null; }
    }

    function subseq(t, s) {
        let i = 0;
        for (let j = 0; j < s.length && i < t.length; j++) if (s[j] === t[i]) i++;
        return i === t.length;
    }
    function scoreApp(a, t) {
        const n = a.name.toLowerCase();
        let s = -1;
        if (n === t) s = 120;
        else if (n.startsWith(t)) s = 100;
        else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(t))) s = 85;
        else if (n.includes(t)) s = 70;
        else {
            const extra = [a.genericName, a.comment, (a.keywords ?? []).join(" "), a.id].join(" ").toLowerCase();
            if (extra.split(/[\s\-_.;,]+/).some(w => w.startsWith(t))) s = 50;
            else if (extra.includes(t)) s = 35;
            else if (t.length >= 2 && subseq(t, n)) s = 25;
        }
        if (s < 0) return -1;
        return s + (cfg.launcherRankByUsage ? Math.min(25, Math.log2(1 + countOf(a)) * 6) : 0);
    }

    readonly property var results: {
        const out = [];
        if (mode === "calc") {
            const v = calc(q);
            out.push({ type: "calc", title: v === null ? "…" : v, sub: v === null ? "Keep typing an expression" : q.replace(/^=/, "").trim() + "  ·  Enter to copy", glyph: "󰃬", value: v });
            return out;
        }
        if (mode === "cmd") {
            const cmd = q.slice(1).trim();
            out.push({ type: "cmd", title: cmd || "Type a command", sub: "Run in a terminal", glyph: "", value: cmd });
            return out;
        }
        if (mode === "web") {
            const w = q.slice(1).trim();
            out.push({ type: "web", title: w || "Type to search the web", sub: "Search the web", glyph: "󰖟", value: w });
            return out;
        }
        if (mode === "browse") {
            if (cfg.launcherDefaultView === "grid") return out;
            for (const a of browseApps) out.push({ type: "app", app: a, title: a.name, sub: a.comment || a.genericName || "", glyph: "" });
            return out;
        }
        const t = q.toLowerCase();
        const scored = apps.map(a => ({ a, s: scoreApp(a, t) })).filter(x => x.s >= 0)
                           .sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name));
        for (const x of scored.slice(0, Math.max(5, cfg.launcherMaxResults)))
            out.push({ type: "app", app: x.a, title: x.a.name, sub: x.a.comment || x.a.genericName || "", glyph: "" });
        if (cfg.launcherWeb) out.push({ type: "web", title: q, sub: "Search the web", glyph: "󰖟", value: q });
        return out;
    }

    function highlight(text) {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const t = q.toLowerCase();
        const i = text.toLowerCase().indexOf(t);
        if (!t || i < 0) return esc(text);
        return esc(text.slice(0, i)) + `<font color="${Theme.primary}"><b>` + esc(text.slice(i, i + t.length)) + "</b></font>" + esc(text.slice(i + t.length));
    }

    // ---------- actions ----------
    function bump(a) {
        const c = Object.assign({}, store.counts ?? {});
        c[a.id] = (c[a.id] ?? 0) + 1;
        store.counts = c;
        storeFile.writeAdapter();
    }
    function launchApp(a) {
        if (!a || launching) return;
        bump(a);
        a.execute();
        finish();
    }
    function activate(r) {
        if (!r || launching) return;
        if (r.type === "app") return launchApp(r.app);
        if (r.type === "calc") {
            if (r.value === null) return;
            Quickshell.execDetached(["wl-copy", r.value]);
        } else if (r.type === "cmd") {
            if (!r.value) return;
            const term = (cfg.launcherTerminal || "kitty --hold").trim().split(/\s+/);
            Quickshell.execDetached([...term, "sh", "-c", r.value]);
        } else if (r.type === "web") {
            if (!r.value) return;
            Quickshell.execDetached(["xdg-open", (webEngines[cfg.launcherWebEngine] ?? webEngines.duckduckgo) + encodeURIComponent(r.value)]);
        }
        finish();
    }
    // let the launch "pop" play, then close
    function finish() {
        if (!cfg.launcherLaunchAnim) { open = false; return; }
        launching = true; closeTimer.restart();
    }
    Timer { id: closeTimer; interval: 170; onTriggered: { root.open = false; root.launching = false; } }

    function cycleCategory(dir) {
        const ids = usedCategories.map(c => c.id);
        const i = ids.indexOf(category);
        category = ids[(i + dir + ids.length) % ids.length];
    }

    onOpenChanged: if (open) { openSerial++; query = ""; category = "all"; launching = false; }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function resetUsage(): void { store.counts = ({}); storeFile.writeAdapter(); }
        function search(text: string): void { root.open = true; search.text = text; search.cursorPosition = text.length; }
    }

    FileView {
        id: storeFile
        path: Quickshell.env("HOME") + "/.local/state/rice/launcher.json"
        onLoadFailed: writeAdapter()
        JsonAdapter {
            id: store
            property var counts: ({})
        }
    }

    // ---------- window ----------
    Overlay {
        id: win
        name: "launcher"
        open: root.open
        onCloseRequested: root.open = false
        origin: Qt.point(panel.x + panel.width / 2, panel.y + 40)
        zoom: !root.docked
        slideMode: root.docked
        slideOutMs: 340
        animScale: Theme.animLauncher

        onVisibleChanged: if (visible) {
            search.text = "";
            grid.currentIndex = 0;
            list.currentIndex = 0;
            search.forceActiveFocus();
        }

        GlassPanel {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            // height that's on screen; when docked the panel extends `sink` px below the
            // screen so its bottom corners and border are hidden and it sits flush
            readonly property real visH: Math.min(parent.height * (root.cfg.launcherPosition === "center" ? 0.9 : 0.8), root.cfg.launcherHeight)
            readonly property real sink: root.docked ? radius + 4 : 0
            // docked slide: 0 = fully up, visH + extra = hidden below the edge
            property real slide: root.docked && !root.open ? visH + 30 : 0
            // open: soft start, long glide that settles gently (no snap); close: eases in, then drops away
            Behavior on slide {
                enabled: root.docked
                NumberAnimation {
                    duration: (root.open ? 620 : 340) * Theme.animLauncher
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.open ? [0.22, 0.75, 0.22, 1, 1, 1] : [0.45, 0, 0.75, 0.3, 1, 1]
                }
            }
            // docked: contents fade + rise in just behind the panel, and fade out first on close
            property real contentIn: !root.docked || root.open ? 1 : 0
            Behavior on contentIn {
                enabled: root.docked
                SequentialAnimation {
                    PauseAnimation { duration: (root.open ? 160 : 0) * Theme.animLauncher }
                    NumberAnimation {
                        duration: (root.open ? 420 : 160) * Theme.animLauncher
                        easing.type: root.open ? Easing.OutCubic : Easing.InQuad
                    }
                }
            }
            y: root.docked ? parent.height - visH + slide
             : root.cfg.launcherPosition === "center" ? (parent.height - height) / 2 : parent.height * 0.14
            width: Math.min(parent.width - 60, root.cfg.launcherWidth)
            height: visH + sink
            border.width: root.docked ? 0 : 1           // docked: outline drawn by dockEdge instead
            clip: false

            // launch pop: the whole panel swells and fades
            scale: root.launching ? 1.03 : 1
            opacity: root.launching ? 0 : 1
            Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.InCubic } }

            // soft glow under the panel
            RectangularShadow {
                anchors.fill: parent
                z: -1
                radius: parent.radius
                blur: 40
                spread: 0
                offset.y: root.docked ? -6 : 14
                color: Theme.alpha("#000000", 0.45)
            }

            // ---- docked: concave "flares" into the screen edge + one continuous outline ----
            Item {
                id: dockEdge
                visible: root.docked
                readonly property real r: root.cfg.launcherDockFlares ? Math.min(28, panel.radius + 8) : 0
                readonly property real rad: panel.radius
                readonly property real w: panel.width
                readonly property real h: panel.visH
                readonly property color fill: panel.color
                readonly property color line: Theme.alpha(Theme.primary, 0.35)
                x: 0; y: 0; width: w; height: h

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    // left flare
                    ShapePath {
                        strokeWidth: -1
                        fillColor: dockEdge.r > 0 ? dockEdge.fill : "transparent"
                        startX: 0; startY: dockEdge.h - dockEdge.r
                        PathLine { x: 0; y: dockEdge.h }
                        PathLine { x: -dockEdge.r; y: dockEdge.h }
                        PathArc { x: 0; y: dockEdge.h - dockEdge.r; radiusX: dockEdge.r; radiusY: dockEdge.r; direction: PathArc.Counterclockwise }
                    }
                    // right flare
                    ShapePath {
                        strokeWidth: -1
                        fillColor: dockEdge.r > 0 ? dockEdge.fill : "transparent"
                        startX: dockEdge.w; startY: dockEdge.h - dockEdge.r
                        PathLine { x: dockEdge.w; y: dockEdge.h }
                        PathLine { x: dockEdge.w + dockEdge.r; y: dockEdge.h }
                        PathArc { x: dockEdge.w; y: dockEdge.h - dockEdge.r; radiusX: dockEdge.r; radiusY: dockEdge.r; direction: PathArc.Clockwise }
                    }
                    // outline: flare -> up the side -> rounded top -> down -> flare
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: dockEdge.line
                        fillColor: "transparent"
                        startX: -dockEdge.r; startY: dockEdge.h
                        PathArc { x: 0; y: dockEdge.h - dockEdge.r; radiusX: Math.max(0.01, dockEdge.r); radiusY: Math.max(0.01, dockEdge.r); direction: PathArc.Counterclockwise }
                        PathLine { x: 0; y: dockEdge.rad }
                        PathArc { x: dockEdge.rad; y: 0; radiusX: dockEdge.rad; radiusY: dockEdge.rad }
                        PathLine { x: dockEdge.w - dockEdge.rad; y: 0 }
                        PathArc { x: dockEdge.w; y: dockEdge.rad; radiusX: dockEdge.rad; radiusY: dockEdge.rad }
                        PathLine { x: dockEdge.w; y: dockEdge.h - dockEdge.r }
                        PathArc { x: dockEdge.w + dockEdge.r; y: dockEdge.h; radiusX: Math.max(0.01, dockEdge.r); radiusY: Math.max(0.01, dockEdge.r); direction: PathArc.Counterclockwise }
                    }
                }
            }

            // ---- drifting wallpaper-colored light behind the glass ----
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 1
                visible: root.cfg.launcherOrbs
                radius: parent.radius - 1
                color: "transparent"

                Item {
                    id: orbs
                    anchors.fill: parent
                    visible: false
                    Rectangle {
                        id: orbA
                        width: 340; height: 340; radius: 170
                        color: Theme.alpha(Theme.primary, 0.55)
                        x: -80; y: -120
                    }
                    Rectangle {
                        id: orbB
                        width: 300; height: 300; radius: 150
                        color: Theme.alpha(Theme.tertiary, 0.45)
                        x: parent.width - 220; y: parent.height - 200
                    }
                    Rectangle {
                        id: orbC
                        width: 220; height: 220; radius: 110
                        color: Theme.alpha(Theme.secondary, 0.35)
                        x: parent.width * 0.45; y: -60
                    }
                }
                MultiEffect {
                    anchors.fill: orbs
                    source: orbs
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    opacity: root.cfg.launcherOrbStrength
                }
                // slow drift, only while visible
                ParallelAnimation {
                    running: win.visible && root.cfg.launcherOrbs
                    loops: Animation.Infinite
                    SequentialAnimation {
                        NumberAnimation { target: orbA; property: "x"; to: 160; duration: 9000; easing.type: Easing.InOutSine }
                        NumberAnimation { target: orbA; property: "x"; to: -80; duration: 9000; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        NumberAnimation { target: orbA; property: "y"; to: 20; duration: 7000; easing.type: Easing.InOutSine }
                        NumberAnimation { target: orbA; property: "y"; to: -120; duration: 7000; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        NumberAnimation { target: orbB; property: "x"; to: panel.width - 420; duration: 11000; easing.type: Easing.InOutSine }
                        NumberAnimation { target: orbB; property: "x"; to: panel.width - 220; duration: 11000; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        NumberAnimation { target: orbC; property: "y"; to: panel.height * 0.5; duration: 13000; easing.type: Easing.InOutSine }
                        NumberAnimation { target: orbC; property: "y"; to: -60; duration: 13000; easing.type: Easing.InOutSine }
                    }
                }
                // glass highlight along the top edge
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 90
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.alpha("#ffffff", 0.06) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                anchors.bottomMargin: 18 + panel.sink
                spacing: 14
                opacity: panel.contentIn
                transform: Translate { y: (1 - panel.contentIn) * 22 }

                // ---------- search ----------
                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 26
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.75)
                    border.width: 2
                    border.color: Theme.alpha(Theme.primary, 0.25 + glowPulse.value * 0.45)

                    QtObject { id: glowPulse; property real value: 0 }
                    SequentialAnimation {
                        running: win.visible && root.cfg.launcherPulse
                        loops: Animation.Infinite
                        onStopped: glowPulse.value = 0.4
                        NumberAnimation { target: glowPulse; property: "value"; to: 1; duration: 1600; easing.type: Easing.InOutSine }
                        NumberAnimation { target: glowPulse; property: "value"; to: 0; duration: 1600; easing.type: Easing.InOutSine }
                    }

                    // mode icon: morphs when you switch to calc / run / web
                    Rectangle {
                        id: modeBadge
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 18
                        color: root.mode === "browse" || root.mode === "search" ? "transparent" : Theme.primary
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text {
                            id: modeIcon
                            anchors.centerIn: parent
                            readonly property string glyph: root.mode === "calc" ? "󰃬" : root.mode === "cmd" ? "" : root.mode === "web" ? "󰖟" : "󰍉"
                            text: glyph
                            color: root.mode === "browse" || root.mode === "search" ? Theme.primary : Theme.textOnPrimary
                            font.family: Theme.font
                            font.pixelSize: 18
                            onGlyphChanged: spin.restart()
                            SequentialAnimation {
                                id: spin
                                ParallelAnimation {
                                    NumberAnimation { target: modeIcon; property: "rotation"; from: -90; to: 0; duration: 380; easing.type: Easing.OutBack }
                                    NumberAnimation { target: modeIcon; property: "scale"; from: 0.4; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                                }
                            }
                        }
                    }

                    TextInput {
                        id: search
                        anchors.left: modeBadge.right
                        anchors.right: countChip.left
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.textOnPrimary
                        font.family: Theme.font
                        font.pixelSize: 17
                        clip: true
                        onTextChanged: { root.query = text; list.currentIndex = 0; }

                        // rotating hints
                        Text {
                            id: hint
                            property int n: 0
                            readonly property var hints: ["Search apps…"].concat(root.cfg.launcherCalc ? ["Try  =12*7  for a quick sum"] : [],
                                root.cfg.launcherRun ? ["Try  >htop  to run a command"] : [], root.cfg.launcherWeb ? ["Try  ?weather  to search the web"] : [],
                                root.cfg.launcherShowCategories ? ["Tab switches categories"] : [], ["Right-click an app to hide it"])
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !search.text
                            text: root.cfg.launcherHints ? hints[n % hints.length] : "Search apps…"
                            color: Theme.outline
                            font: search.font
                            Timer {
                                running: win.visible && !search.text && root.cfg.launcherHints
                                interval: 3200
                                repeat: true
                                onTriggered: hintSwap.restart()
                            }
                            SequentialAnimation {
                                id: hintSwap
                                ParallelAnimation {
                                    NumberAnimation { target: hint; property: "opacity"; to: 0; duration: 180 }
                                    NumberAnimation { target: hint; property: "anchors.verticalCenterOffset"; to: -6; duration: 180 }
                                }
                                ScriptAction { script: { hint.n++; hint.anchors.verticalCenterOffset = 6; } }
                                ParallelAnimation {
                                    NumberAnimation { target: hint; property: "opacity"; to: 1; duration: 240 }
                                    NumberAnimation { target: hint; property: "anchors.verticalCenterOffset"; to: 0; duration: 300; easing.type: Easing.OutBack }
                                }
                            }
                        }

                        Keys.onPressed: e => {
                            const browsing = root.gridBrowse;
                            const ctrl = e.modifiers & Qt.ControlModifier;
                            if (e.key === Qt.Key_Escape) {
                                if (search.text) search.text = ""; else root.open = false;
                            } else if (e.key === Qt.Key_Tab && root.cfg.launcherShowCategories) root.cycleCategory(1);
                            else if (e.key === Qt.Key_Backtab && root.cfg.launcherShowCategories) root.cycleCategory(-1);
                            else if ((e.modifiers & Qt.AltModifier) && e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.launchApp(root.frequent[e.key - Qt.Key_1]);
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                if (browsing) root.launchApp(root.browseApps[grid.currentIndex]);
                                else root.activate(root.results[list.currentIndex]);
                            } else if (browsing) {
                                if (e.key === Qt.Key_Down || (e.key === Qt.Key_N && ctrl)) grid.moveCurrentIndexDown();
                                else if (e.key === Qt.Key_Up || (e.key === Qt.Key_P && ctrl)) grid.moveCurrentIndexUp();
                                else if (e.key === Qt.Key_Right) grid.moveCurrentIndexRight();
                                else if (e.key === Qt.Key_Left) grid.moveCurrentIndexLeft();
                                else return;
                            } else {
                                if (e.key === Qt.Key_Down || (e.key === Qt.Key_N && ctrl)) list.incrementCurrentIndex();
                                else if (e.key === Qt.Key_Up || (e.key === Qt.Key_P && ctrl)) list.decrementCurrentIndex();
                                else return;
                            }
                            e.accepted = true;
                        }
                    }

                    Rectangle {
                        id: countChip
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property int count: root.mode === "browse" ? root.browseApps.length : root.results.filter(r => r.type === "app").length
                        visible: root.cfg.launcherShowCount && (root.mode === "browse" || root.mode === "search")
                        width: countText.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: Theme.alpha(Theme.primary, 0.15)
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: countChip.count + (countChip.count === 1 ? " app" : " apps")
                            color: Theme.primary
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.DemiBold
                        }
                    }
                }

                // ---------- browse view ----------
                ColumnLayout {
                    id: browseView
                    Layout.fillWidth: true
                    Layout.fillHeight: root.gridBrowse
                    spacing: 12
                    visible: opacity > 0
                    opacity: root.mode === "browse" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    // category chips with a sliding pill
                    Item {
                        Layout.fillWidth: true
                        visible: root.cfg.launcherShowCategories
                        implicitHeight: 32
                        Rectangle {
                            id: chipPill
                            readonly property Item target: chipRow.children[Math.max(0, root.usedCategories.findIndex(c => c.id === root.category))] ?? null
                            x: target ? target.x : 0
                            width: target ? target.width : 0
                            height: 32
                            radius: 16
                            color: Theme.primary
                            Behavior on x { SpringAnimation { spring: 4; damping: 0.32 } }
                            Behavior on width { SpringAnimation { spring: 4; damping: 0.32 } }
                        }
                        Row {
                            id: chipRow
                            spacing: 4
                            Repeater {
                                model: root.usedCategories
                                Item {
                                    id: chip
                                    required property var modelData
                                    readonly property bool active: root.category === modelData.id
                                    width: chipLabel.implicitWidth + 26
                                    height: 32
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: Theme.primary
                                        opacity: chipMouse.containsMouse && !chip.active ? 0.12 : 0
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }
                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        text: chip.modelData.icon + "  " + chip.modelData.label
                                        color: chip.active ? Theme.textOnPrimary : Theme.subtext
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                        font.weight: chip.active ? Font.Bold : Font.Normal
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                    MouseArea {
                                        id: chipMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.category = chip.modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // frequent apps
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.cfg.launcherShowFrequent && root.frequent.length > 0 && root.category === "all"
                        spacing: 8
                        Text {
                            text: "FREQUENT"
                            color: Theme.primary
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                            font.weight: Font.Bold
                            font.letterSpacing: 1.4
                        }
                        Row {
                            spacing: 8
                            Repeater {
                                model: root.frequent
                                Rectangle {
                                    id: fav
                                    required property var modelData
                                    required property int index
                                    width: 52; height: 52; radius: 16
                                    color: Theme.alpha(Theme.surfaceContainerHigh, favMouse.containsMouse ? 0.95 : 0.55)
                                    border.width: favMouse.containsMouse ? 2 : 0
                                    border.color: Theme.primary
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    // pop in one after another
                                    opacity: 0
                                    scale: 0.6
                                    Connections {
                                        target: root
                                        function onOpenSerialChanged() { favIn.restart(); }
                                    }
                                    Component.onCompleted: favIn.restart()
                                    SequentialAnimation {
                                        id: favIn
                                        ScriptAction { script: { fav.opacity = 0; fav.scale = 0.6; } }
                                        PauseAnimation { duration: 60 + fav.index * 45 }
                                        ParallelAnimation {
                                            NumberAnimation { target: fav; property: "opacity"; to: 1; duration: 220 }
                                            NumberAnimation { target: fav; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 2 }
                                        }
                                    }

                                    AppIcon {
                                        anchors.centerIn: parent
                                        size: 32
                                        entry: fav.modelData
                                        scale: favMouse.containsMouse ? 1.15 : 1
                                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                                    }
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: -3
                                        width: 18; height: 18; radius: 9
                                        color: Theme.surfaceContainerHigh
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.primary, 0.4)
                                        Text {
                                            anchors.centerIn: parent
                                            text: fav.index + 1
                                            color: Theme.primary
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }
                                    MouseArea {
                                        id: favMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: e => e.button === Qt.RightButton ? root.hideApp(fav.modelData) : root.launchApp(fav.modelData)
                                    }
                                    ToolTipLabel { shown: favMouse.containsMouse; text: fav.modelData.name + "  ·  Alt+" + (fav.index + 1) }
                                }
                            }
                        }
                    }

                    // all apps grid
                    GridView {
                        id: grid
                        visible: root.gridBrowse
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.browseApps
                        readonly property int iconSize: root.cfg.launcherIconSize
                        readonly property int cols: Math.max(3, Math.floor(width / (iconSize + 66)))
                        cellWidth: Math.floor(width / cols)
                        cellHeight: iconSize + 62
                        boundsBehavior: Flickable.StopAtBounds
                        highlightFollowsCurrentItem: false
                        keyNavigationWraps: true
                        onModelChanged: currentIndex = 0
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                        // springy selection
                        Rectangle {
                            id: gridHl
                            z: -1
                            readonly property Item cur: grid.currentItem
                            visible: cur !== null
                            x: cur ? cur.x + 4 : 0
                            y: cur ? cur.y + 2 : 0
                            width: grid.cellWidth - 8
                            height: grid.cellHeight - 4
                            radius: 18
                            color: Theme.alpha(Theme.primary, 0.18)
                            border.width: 1
                            border.color: Theme.alpha(Theme.primary, 0.6)
                            parent: grid.contentItem
                            Behavior on x { SpringAnimation { spring: 5; damping: 0.34 } }
                            Behavior on y { SpringAnimation { spring: 5; damping: 0.34 } }
                        }

                        delegate: Item {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property bool current: GridView.isCurrentItem
                            width: grid.cellWidth
                            height: grid.cellHeight

                            // staggered entrance: rise + fade, row by row
                            opacity: 0
                            transform: Translate { id: tileShift; y: 18 }
                            Connections {
                                target: root
                                function onOpenSerialChanged() { tileIn.restart(); }
                            }
                            Component.onCompleted: tileIn.restart()
                            SequentialAnimation {
                                id: tileIn
                                ScriptAction { script: { tile.opacity = 0; tileShift.y = 18; } }
                                PauseAnimation { duration: root.stagger ? Math.min(tile.index, 30) * 16 : 0 }
                                ParallelAnimation {
                                    NumberAnimation { target: tile; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: tileShift; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                AppIcon {
                                    id: tileIcon
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    size: grid.iconSize
                                    entry: tile.modelData
                                    scale: root.launching && tile.current ? 1.5 : tile.current ? 1.12 : tileMouse.containsMouse ? 1.06 : 1
                                    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 2.4 } }
                                }
                                Text {
                                    width: grid.cellWidth - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: tile.modelData.name
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    color: tile.current ? Theme.text : Theme.subtext
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                    font.weight: tile.current ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: grid.currentIndex = tile.index
                                onClicked: e => e.button === Qt.RightButton ? root.hideApp(tile.modelData) : root.launchApp(tile.modelData)
                            }
                        }
                    }
                }

                // ---------- search results ----------
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: opacity > 0
                    opacity: !root.gridBrowse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    clip: true
                    spacing: 4
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    Rectangle {
                        id: listHl
                        parent: list.contentItem
                        z: -1
                        readonly property Item cur: list.currentItem
                        visible: cur !== null
                        x: 0
                        y: cur ? cur.y : 0
                        width: list.width
                        height: cur ? cur.height : 0
                        radius: 16
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.alpha(Theme.primary, 0.32) }
                            GradientStop { position: 1; color: Theme.alpha(Theme.primary, 0.1) }
                        }
                        border.width: 1
                        border.color: Theme.alpha(Theme.primary, 0.55)
                        Behavior on y { SpringAnimation { spring: 5; damping: 0.34 } }
                        Behavior on height { NumberAnimation { duration: 160 } }
                        // accent bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4; height: parent.height * 0.45; radius: 2
                            color: Theme.primary
                        }
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        readonly property var actions: modelData.type === "app" && root.cfg.launcherShowActions ? (modelData.app.actions ?? []) : []
                        width: list.width
                        height: row.current && actions.length > 0 ? 88 : 60
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        opacity: 0
                        transform: Translate { id: rowShift; x: -16 }
                        Component.onCompleted: rowIn.start()
                        SequentialAnimation {
                            id: rowIn
                            PauseAnimation { duration: root.stagger ? Math.min(row.index, 10) * 22 : 0 }
                            ParallelAnimation {
                                NumberAnimation { target: row; property: "opacity"; to: 1; duration: 200 }
                                NumberAnimation { target: rowShift; property: "x"; to: 0; duration: 340; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: list.currentIndex = row.index
                            onClicked: e => {
                                if (e.button === Qt.RightButton) { if (row.modelData.type === "app") root.hideApp(row.modelData.app); }
                                else root.activate(row.modelData);
                            }
                        }

                        Item {
                            id: rowIcon
                            x: 18
                            y: 12
                            width: 36; height: 36
                            scale: root.launching && row.current ? 1.5 : row.current ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.4 } }
                            AppIcon {
                                anchors.centerIn: parent
                                visible: row.modelData.type === "app"
                                size: 36
                                entry: row.modelData.app ?? null
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: row.modelData.type !== "app"
                                radius: 12
                                color: Theme.alpha(Theme.primary, row.current ? 0.9 : 0.2)
                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.glyph
                                    color: row.current ? Theme.textOnPrimary : Theme.primary
                                    font.family: Theme.font
                                    font.pixelSize: 18
                                }
                            }
                        }

                        Column {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 14
                            anchors.right: enterHint.left
                            anchors.rightMargin: 10
                            y: 11
                            spacing: 2
                            Text {
                                width: parent.width
                                textFormat: Text.StyledText
                                text: row.modelData.type === "app" ? root.highlight(row.modelData.title) : row.modelData.title
                                elide: Text.ElideRight
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: row.modelData.type === "calc" ? Theme.fontSize + 5 : Theme.fontSize + 1
                                font.weight: row.current || row.modelData.type === "calc" ? Font.DemiBold : Font.Normal
                            }
                            Text {
                                width: parent.width
                                visible: text !== "" && (root.cfg.launcherShowDesc || row.modelData.type !== "app")
                                text: row.modelData.sub
                                elide: Text.ElideRight
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        // desktop actions (New Window, Private Window, …) for the selected app
                        Row {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 14
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            spacing: 6
                            visible: opacity > 0
                            opacity: row.current && row.actions.length > 0 ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            Repeater {
                                model: row.actions.slice(0, 4)
                                Rectangle {
                                    id: act
                                    required property var modelData
                                    width: actText.implicitWidth + 20
                                    height: 24
                                    radius: 12
                                    color: Theme.alpha(Theme.surfaceContainerHigh, actMouse.containsMouse ? 1 : 0.7)
                                    border.width: actMouse.containsMouse ? 1 : 0
                                    border.color: Theme.primary
                                    Text {
                                        id: actText
                                        anchors.centerIn: parent
                                        text: act.modelData.name
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                    MouseArea {
                                        id: actMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.bump(row.modelData.app); act.modelData.execute(); root.finish(); }
                                    }
                                }
                            }
                        }

                        Text {
                            id: enterHint
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            y: 20
                            text: "󰌑"
                            color: Theme.primary
                            opacity: row.current ? 1 : 0
                            font.family: Theme.font
                            font.pixelSize: 15
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // ---------- footer ----------
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.cfg.launcherShowFooter
                    spacing: 14
                    Repeater {
                        model: [["↵", "open"], ["Tab", "category", root.cfg.launcherShowCategories], ["=", "calc", root.cfg.launcherCalc],
                                [">", "run", root.cfg.launcherRun], ["?", "web", root.cfg.launcherWeb], ["Esc", "close"]].filter(k => k[2] !== false)
                        Row {
                            required property var modelData
                            spacing: 6
                            Rectangle {
                                width: keyText.implicitWidth + 12
                                height: 20
                                radius: 6
                                color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
                                border.width: 1
                                border.color: Theme.alpha(Theme.outline, 0.3)
                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: parent.parent.modelData[0]
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 4
                                    font.bold: true
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData[1]
                                color: Theme.outline
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
