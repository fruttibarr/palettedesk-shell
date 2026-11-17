import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts

// Wallpaper grid. Toggle with:  qs ipc call wallpaper toggle
// Picking one runs scripts/set-wallpaper.sh, which re-themes everything via matugen.
Scope {
    id: root
    property bool open: false
    property var all: []
    // one record per wallpaper, built once per scan: { p, lp (lowercase), repo, anim }
    property var recs: []
    property string lastScan: ""
    property string typed: ""           // search box text; `query` follows it after a short pause
    property string query: ""
    Timer { id: queryDebounce; interval: 110; onTriggered: root.query = root.typed }
    onTypedChanged: typed === "" ? (queryDebounce.stop(), query = "") : queryDebounce.restart()

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string setter: Quickshell.shellDir + "/scripts/set-wallpaper.sh"
    property string kindFilter: "all"   // all / static / animated
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/rice/thumbs/"
    function isVideo(p) { return /\.(mp4|webm|mkv|mov)$/i.test(p); }
    function isAnimated(p) { return isVideo(p) || /\.gif$/i.test(p); }
    property string repoFilter: ""      // "" = all repos, else the repo folder name
    // Repo folder a wallpaper came from: <dir>/<Owner-repo>/… or <dir>/Animated/<Owner-repo>/…
    function repoOf(p) {
        const parts = p.slice(dir.length + 1).split("/");
        return (parts[0] === "Animated" && parts.length > 2) ? parts[1] : (parts.length > 1 ? parts[0] : "Loose");
    }
    function kindOk(p) { return kindFilter === "all" || (kindFilter === "animated") === isAnimated(p); }
    // [{ name, count }] for the repo chips, respecting the static/animated filter
    readonly property var repos: {
        const counts = {};
        for (const r of recs) if (kindFilter === "all" || (kindFilter === "animated") === r.anim) counts[r.repo] = (counts[r.repo] || 0) + 1;
        return Object.keys(counts).sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
                     .map(n => ({ name: n, count: counts[n] }));
    }
    // ---- smart search ----
    // Index from scripts/index-walls.py: { path: { w, h, l, s, c: {color: %}, a: accent, p: [hex] } }
    property var index: ({})
    property int indexDone: 0
    property int indexTotal: 0
    readonly property bool indexing: indexer.running && indexTotal > 0 && indexDone < indexTotal

    readonly property var colorNames: ["red", "orange", "yellow", "green", "teal", "blue", "purple", "pink", "brown", "black", "gray", "white"]
    readonly property var colorSwatch: ({ red: "#e5484d", orange: "#f76b15", yellow: "#ffd60a", green: "#30a46c", teal: "#12a594",
                                          blue: "#0090ff", purple: "#8e4ec6", pink: "#e93d82", brown: "#a0613c", black: "#111111",
                                          gray: "#8b8d98", white: "#f5f5f5" })
    readonly property var colorAlias: ({ grey: "gray", cyan: "teal", aqua: "teal", turquoise: "teal", violet: "purple",
                                         lavender: "purple", magenta: "purple", navy: "blue", azure: "blue", crimson: "red",
                                         scarlet: "red", gold: "yellow", amber: "orange", lime: "green", mint: "green",
                                         rose: "pink", beige: "brown", tan: "brown" })
    // word -> test on an index entry
    readonly property var moodWords: ({
        dark: e => e.l < 30, night: e => e.l < 30, dim: e => e.l < 30,
        light: e => e.l > 60, bright: e => e.l > 60,
        vibrant: e => e.s >= 35, colorful: e => e.s >= 35, colourful: e => e.s >= 35, saturated: e => e.s >= 35,
        muted: e => e.s < 14, mono: e => e.s < 8, monochrome: e => e.s < 8, grayscale: e => e.s < 8, minimal: e => e.s < 14,
        pastel: e => e.l > 55 && e.s >= 8 && e.s < 40,
        "4k": e => e.w >= 3800, uhd: e => e.w >= 3800,
        "2k": e => e.w >= 2560, qhd: e => e.w >= 2560, "1440p": e => e.w >= 2560,
        hd: e => e.w >= 1920, "1080p": e => e.w >= 1920, sharp: e => e.w >= 1920,
        lowres: e => e.w > 0 && e.w < 1440, small: e => e.w > 0 && e.w < 1000,
        portrait: e => e.h > e.w, vertical: e => e.h > e.w,
        wide: e => e.w / Math.max(1, e.h) > 2, ultrawide: e => e.w / Math.max(1, e.h) > 2
    })
    readonly property var kindWords: ({ gif: p => /\.gif$/i.test(p), video: p => isVideo(p), videos: p => isVideo(p),
                                        animated: p => isAnimated(p), live: p => isAnimated(p), static: p => !isAnimated(p) })
    readonly property var similarWords: ["similar", "like", "matching", "match", "current"]

    function hexRgb(h) {
        h = h.replace("#", "");
        if (h.length === 3) h = h.split("").map(c => c + c).join("");
        const n = parseInt(h, 16);
        return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
    }
    // perceptual-ish RGB distance ("redmean")
    function colorDist(a, b) {
        const r = (a[0] + b[0]) / 2, dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
        return Math.sqrt((2 + r / 256) * dr * dr + 4 * dg * dg + (2 + (255 - r) / 256) * db * db);
    }
    function paletteDist(pa, pb) {
        if (!pa || !pb || !pa.length || !pb.length) return 1e9;
        const A = pa.map(hexRgb), B = pb.map(hexRgb);
        let sum = 0;
        for (const a of A) sum += Math.min(...B.map(b => colorDist(a, b)));
        return sum / A.length;
    }

    // Parse the query into filters; returns { text[], colors[], hex[], tests[], kinds[], similar }
    function parseQuery(q) {
        const out = { text: [], colors: [], hex: [], tests: [], kinds: [], similar: false };
        for (let w of q.toLowerCase().split(/\s+/).filter(x => x)) {
            if (colorAlias[w]) w = colorAlias[w];
            if (colorNames.includes(w)) out.colors.push(w);
            else if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(w)) out.hex.push(hexRgb(w));
            else if (moodWords[w]) out.tests.push(moodWords[w]);
            else if (kindWords[w]) out.kinds.push(kindWords[w]);
            else if (similarWords.includes(w)) out.similar = true;
            else out.text.push(w);
        }
        return out;
    }
    readonly property var parsed: parseQuery(query.trim())
    readonly property bool smartActive: parsed.colors.length || parsed.hex.length || parsed.tests.length || parsed.similar

    readonly property var results: {
        const f = parsed;
        const idx = smartActive ? index : null;      // plain searches don't depend on the index
        const cur = f.similar ? idx[Theme.wallpaper] : null;
        const scored = [];
        const kf = kindFilter, rf = repoFilter;
        for (const r of recs) {
            if (kf !== "all" && (kf === "animated") !== r.anim) continue;
            if (rf && r.repo !== rf) continue;
            const p = r.p, lp = r.lp;
            if (f.text.length && f.text.some(t => !lp.includes(t))) continue;
            if (f.kinds.length && !f.kinds.some(k => k(p))) continue;
            let score = 0;
            if (smartActive) {
                const e = idx[p];
                if (!e || e.bad) continue;
                if (f.tests.some(t => !t(e))) continue;
                let ok = true;
                for (const c of f.colors) {
                    const share = (e.c && e.c[c]) || 0;
                    if (share < 8 && e.a !== c) { ok = false; break; }
                    score += share + (e.a === c ? 30 : 0);
                }
                if (!ok) continue;
                for (const h of f.hex) {
                    const d = Math.min(...(e.p || []).map(x => colorDist(h, hexRgb(x))));
                    if (!(d < 160)) { ok = false; break; }
                    score -= d;
                }
                if (!ok) continue;
                if (f.similar) {
                    if (!cur || p === Theme.wallpaper) continue;
                    score -= paletteDist(cur.p, e.p) + Math.abs(cur.l - e.l) * 2;
                }
            }
            scored.push([p, score]);
        }
        if (f.colors.length || f.hex.length || f.similar) scored.sort((a, b) => b[1] - a[1]);
        const out = scored.map(x => x[0]);
        return f.similar ? out.slice(0, 300) : out;
    }
    // What the grid shows. Only replaced when the list really changed, because a new
    // model array makes the GridView rebuild every tile and reload its image.
    property var shown: []
    function sameList(a, b) {
        if (a === b) return true;
        if (!a || !b || a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
        return true;
    }
    onResultsChanged: if (!sameList(results, shown)) shown = results
    // Toggle a color word in the search box (from the color dots)
    function toggleWord(w) {
        const words = search.text.trim().split(/\s+/).filter(x => x);
        const i = words.indexOf(w);
        if (i >= 0) words.splice(i, 1); else words.push(w);
        search.text = words.join(" ") + (words.length ? " " : "");
        search.forceActiveFocus();
    }
    function cycleRepo(step) {
        const names = [""].concat(repos.map(r => r.name));
        const i = Math.max(0, names.indexOf(repoFilter));
        repoFilter = names[(i + step + names.length) % names.length];
        grid.currentIndex = 0;
    }

    // "" = every monitor; otherwise only that monitor gets the wallpaper (colors stay as they are)
    property string targetMonitor: ""
    readonly property bool multiMonitor: Quickshell.screens.length > 1
    function apply(path) {
        if (!path) return;
        if (multiMonitor && targetMonitor !== "") Quickshell.execDetached([setter, "--monitor", targetMonitor, path]);
        else Quickshell.execDetached([setter, "--all", path]);
        open = false;
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
        function browse(kind: string): void { root.kindFilter = kind; root.open = true; }
        // e.g.  qs ipc call wallpaper search "dark blue 4k"   (returns the match count)
        function search(text: string): void { root.open = true; Qt.callLater(() => search.text = text); }
        function count(): int { return root.shown.length; }
        // qs ipc call wallpaper setFor <monitor|all> <file>
        function setFor(monitor: string, file: string): void { root.targetMonitor = monitor === "all" ? "" : monitor; root.apply(file); }
    }

    Process {
        id: scan
        command: ["find", "-L", root.dir, "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp",
                  "-o", "-iname", "*.gif", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", "-o", "-iname", "*.mkv", "-o", "-iname", "*.mov", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === root.lastScan) return;         // nothing new: keep the grid as is
                const firstScan = root.lastScan === "";
                root.lastScan = text;
                const list = text.split("\n").filter(l => l).sort();
                root.recs = list.map(p => ({ p: p, lp: p.toLowerCase(), repo: root.repoOf(p), anim: root.isAnimated(p) }));
                root.all = list;
                // new files: video thumbnails + colors/thumbnails for the rest
                Quickshell.execDetached([Quickshell.shellDir + "/scripts/make-thumbs.sh"]);
                if (!indexer.running) indexer.running = true;
            }
        }
    }

    FileView {
        id: indexFile
        path: Quickshell.env("HOME") + "/.cache/rice/wallindex.json"
        blockLoading: false
        onLoaded: { try { root.index = JSON.parse(text()); } catch (e) {} }
    }
    // Colors/brightness/size for new wallpapers; incremental, so cheap once done
    Process {
        id: indexer
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/index-walls.py"]
        stdout: SplitParser {
            onRead: line => {
                const m = /^progress (\d+) (\d+)/.exec(line);
                if (m) { root.indexDone = +m[1]; root.indexTotal = +m[2]; }
                else if (line === "saved") root.indexStale = true;
                else if (line === "busy") root.indexStale = true;
            }
        }
        onExited: { root.indexStale = true; if (root.open) indexFile.reload(); }
    }
    // Pick up new index data at most every 20 s, and only while the picker is open
    // (each reload re-parses a few MB of JSON). Reopening always loads the latest.
    property bool indexStale: true
    Timer {
        interval: 20000; repeat: true
        running: root.open && (indexer.running || root.indexStale)
        onTriggered: if (root.indexStale) { root.indexStale = false; indexFile.reload(); }
    }

    Overlay {
        id: win
        name: "wallpaper-picker"
        open: root.open
        onCloseRequested: root.open = false

        onVisibleChanged: if (visible) {
            scan.running = true;
            if (root.indexStale) { root.indexStale = false; indexFile.reload(); }
            search.text = "";
            search.forceActiveFocus();
        }


        GlassPanel {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1000)
            height: Math.min(parent.height - 120, 640)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 10
                    color: Theme.surfaceContainerHigh

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 15
                        onTextChanged: { root.typed = text; grid.currentIndex = 0; }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !search.text
                            text: "󰸉  Search " + root.all.length + " wallpapers: name, blue, dark, pastel, 4k, #ff8800, similar…"
                            color: Theme.outline
                            font: search.font
                        }

                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) root.open = false;
                            else if (e.key === Qt.Key_Right) grid.moveCurrentIndexRight();
                            else if (e.key === Qt.Key_Left) grid.moveCurrentIndexLeft();
                            else if (e.key === Qt.Key_Down) grid.moveCurrentIndexDown();
                            else if (e.key === Qt.Key_Up) grid.moveCurrentIndexUp();
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.apply(root.shown[grid.currentIndex]);
                            else if (e.key === Qt.Key_Tab) root.cycleRepo(1);
                            else if (e.key === Qt.Key_Backtab) root.cycleRepo(-1);
                            else if (e.key === Qt.Key_R && e.modifiers & Qt.ControlModifier)
                                root.apply(root.shown[Math.floor(Math.random() * root.shown.length)]);
                            else return;
                            e.accepted = true;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [{ v: "all", l: "All" }, { v: "static", l: "󰋩  Static" }, { v: "animated", l: "󰕧  Animated" }]
                        Rectangle {
                            id: chipF
                            required property var modelData
                            readonly property bool sel: root.kindFilter === modelData.v
                            implicitWidth: fText.implicitWidth + 24
                            implicitHeight: 28
                            radius: 14
                            color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, fMouse.containsMouse ? 0.95 : 0.6)
                            Text {
                                id: fText
                                anchors.centerIn: parent
                                text: chipF.modelData.l
                                color: chipF.sel ? Theme.textOnPrimary : Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                            MouseArea {
                                id: fMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.kindFilter = chipF.modelData.v; grid.currentIndex = 0; }
                            }
                        }
                    }

                    // which monitor the next pick is for (only with more than one monitor)
                    Repeater {
                        model: root.multiMonitor ? [{ v: "", l: "󰍹  All monitors" }].concat(Quickshell.screens.map(sc => ({ v: sc.name, l: sc.name }))) : []
                        Rectangle {
                            id: chipM
                            required property var modelData
                            readonly property bool sel: root.targetMonitor === modelData.v
                            implicitWidth: mText.implicitWidth + 24
                            implicitHeight: 28
                            radius: 14
                            color: sel ? Theme.secondary : Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                            Text { id: mText; anchors.centerIn: parent; text: chipM.modelData.l
                                   color: chipM.sel ? Theme.surface : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.targetMonitor = chipM.modelData.v }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // indexing status
                    Text {
                        visible: root.indexing
                        text: "󰔟 reading colors " + root.indexDone + "/" + root.indexTotal
                        color: Theme.outline
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 4
                    }

                    // color dots: click to add/remove that color from the search
                    Repeater {
                        model: root.colorNames
                        Rectangle {
                            id: dot
                            required property string modelData
                            readonly property bool sel: root.parsed.colors.includes(modelData)
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: root.colorSwatch[modelData]
                            border.width: sel ? 3 : 1
                            border.color: sel ? Theme.primary : Theme.alpha(Theme.text, dotMouse.containsMouse ? 0.7 : 0.2)
                            scale: dotMouse.containsMouse ? 1.15 : 1
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            MouseArea {
                                id: dotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleWord(dot.modelData)
                            }
                        }
                    }

                    // similar to the current wallpaper
                    Rectangle {
                        id: simChip
                        readonly property bool sel: root.parsed.similar
                        implicitWidth: simText.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, simMouse.containsMouse ? 0.95 : 0.6)
                        Text {
                            id: simText
                            anchors.centerIn: parent
                            text: "󰸌  Similar"
                            color: simChip.sel ? Theme.textOnPrimary : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea {
                            id: simMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWord("similar")
                        }
                    }
                }

                // Repo chips (Tab / Shift+Tab cycles). Scroll with the mouse wheel.
                ListView {
                    id: repoList
                    Layout.fillWidth: true
                    implicitHeight: 28
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: [{ name: "", count: root.all.filter(p => root.kindOk(p)).length }].concat(root.repos)
                    currentIndex: Math.max(0, model.findIndex(r => r.name === root.repoFilter))
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    WheelHandler {
                        onWheel: e => repoList.flick((e.angleDelta.y || e.angleDelta.x) * 12, 0)
                    }
                    delegate: Rectangle {
                        id: chipR
                        required property var modelData
                        readonly property bool sel: root.repoFilter === modelData.name
                        implicitWidth: rText.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: sel ? Theme.primary : Theme.alpha(Theme.surfaceContainerHigh, rMouse.containsMouse ? 0.95 : 0.6)
                        Text {
                            id: rText
                            anchors.centerIn: parent
                            text: (chipR.modelData.name || "󰉋  All repos") + "  " + chipR.modelData.count
                            color: chipR.sel ? Theme.textOnPrimary : Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                        MouseArea {
                            id: rMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.repoFilter = chipR.modelData.name; grid.currentIndex = 0; }
                        }
                    }
                }

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.shown
                    cellWidth: Math.floor(width / 4)
                    cellHeight: cellWidth * 0.62
                    cacheBuffer: 1200      // thumbnails are tiny; pre-load ~2 rows each way for smooth scrolling
                    highlightMoveDuration: 80

                    delegate: Item {
                        id: cell
                        required property string modelData
                        required property int index
                        readonly property bool current: GridView.isCurrentItem
                        readonly property bool isCurrentWallpaper: modelData === Theme.baseWallpaper
                        readonly property bool video: root.isVideo(modelData)
                        // small cached JPEG from index-walls.py / make-thumbs.sh; falls back to the original
                        property bool thumbFailed: false
                        readonly property var entry: root.index[modelData]
                        readonly property bool hasThumb: video || (!thumbFailed && !!entry?.t)
                        readonly property bool animated: root.isAnimated(modelData)
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 10
                            color: Theme.surfaceContainer
                            border.width: cell.current ? 3 : cell.isCurrentWallpaper ? 2 : 0
                            border.color: cell.current ? Theme.primary : Theme.tertiary
                            clip: true

                            Image {
                                id: thumb
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                source: cell.hasThumb ? "file://" + root.thumbDir + Qt.md5(cell.modelData) + ".jpg"
                                                      : "file://" + cell.modelData
                                sourceSize.width: 400
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: !cell.video
                                onStatusChanged: if (status === Image.Error && cell.hasThumb && !cell.video) cell.thumbFailed = true
                            }

                            // video thumbnail still being generated: placeholder + retry
                            Text {
                                anchors.centerIn: parent
                                visible: thumb.status !== Image.Ready
                                text: cell.video ? "󰕧" : "󰋩"
                                color: Theme.outline
                                font.family: Theme.font
                                font.pixelSize: 28
                            }
                            Timer {
                                running: cell.video && thumb.status === Image.Error && root.open
                                interval: 2500
                                repeat: true
                                onTriggered: { const s = thumb.source; thumb.source = ""; thumb.source = s; }
                            }

                            // repo label (only when showing every repo)
                            Rectangle {
                                visible: !root.repoFilter
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.margins: 8
                                width: Math.min(repoLbl.implicitWidth + 12, parent.width - 76)
                                height: 18
                                radius: 9
                                color: Theme.alpha(Theme.surface, 0.75)
                                Text {
                                    id: repoLbl
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: root.repoOf(cell.modelData)
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 5
                                }
                            }

                            // main colors of this wallpaper
                            Row {
                                readonly property var entry: cell.entry
                                visible: !!entry && !!entry.p
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 8
                                spacing: 0
                                Repeater {
                                    model: parent.entry?.p ?? []
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: 12
                                        height: 12
                                        radius: 3
                                        color: modelData
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.surface, 0.8)
                                    }
                                }
                            }

                            // animated badge
                            Rectangle {
                                visible: cell.animated
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: badge.implicitWidth + 12
                                height: 20
                                radius: 10
                                color: Theme.alpha(Theme.surface, 0.8)
                                Text {
                                    id: badge
                                    anchors.centerIn: parent
                                    text: cell.video ? "󰐊 VIDEO" : "󰐊 GIF"
                                    color: Theme.primary
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 4
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: grid.currentIndex = cell.index
                            onClicked: root.apply(cell.modelData)
                        }
                    }
                }
            }
        }
    }
}
