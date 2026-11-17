import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// Desktop wallpaper: images, GIFs and videos, with workspace parallax
// (the wallpaper slides a little as you move between workspaces) and a
// zoom-settle crossfade when it changes.
PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.background

    // ---- parallax ----
    readonly property var monitor: Hyprland.monitorFor(win.screen)
    readonly property int wsActive: monitor?.activeWorkspace?.id ?? 1
    readonly property int wsSpan: {
        let n = Settings.s.wsCount;
        for (const w of Hyprland.workspaces.values)
            if (w.id > n && w.id < 100 && w.toplevels.values.length > 0) n = w.id;
        return Math.max(n, wsActive > 0 && wsActive < 100 ? wsActive : 1);
    }
    readonly property real extra: Settings.s.parallaxEnabled ? Settings.s.parallaxStrength : 0
    readonly property real ratio: wsSpan > 1 && wsActive > 0 && wsActive < 100 ? (wsActive - 1) / (wsSpan - 1) : 0

    // ---- when animation should play ----
    readonly property bool hasFullscreen: monitor?.activeWorkspace?.lastIpcObject?.hasfullscreen ?? false
    readonly property bool playing: Settings.s.animatedWallpapers
        && !Globals.locked
        && !(Settings.s.pauseOnBattery && UPower.onBattery)
        && !(Settings.s.pauseWhenFullscreen && hasFullscreen)

    // Live state for `qs ipc call shell wallState` (see system/Ipc.qml): why is the wallpaper (not) animating?
    function state() {
        return {
            screen: win.screen?.name ?? "?", playing: playing, hasFullscreen: hasFullscreen,
            animatedSetting: Settings.s.animatedWallpapers, pauseWhenFullscreen: Settings.s.pauseWhenFullscreen,
            locked: Globals.locked, kind: front?.kind ?? "", file: (front?.path ?? "").split("/").pop(), ready: front?.ready ?? false
        };
    }

    Item {
        id: scene
        height: parent.height
        width: parent.width * (1 + win.extra)
        x: -win.ratio * (width - win.width)
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        // wallpaper effects (Wallpaper & Colors → Effects). Only rendered offscreen while one is switched on.
        readonly property var cfg: Settings.s
        readonly property bool tinted: cfg.wallTintAmount > 0.001 && /^#[0-9a-fA-F]{6}$/.test(cfg.wallTint)
        layer.enabled: cfg.wallBlur > 0.001 || Math.abs(cfg.wallBrightness) > 0.001 || Math.abs(cfg.wallSaturation) > 0.001 || Math.abs(cfg.wallContrast) > 0.001 || tinted
        layer.effect: MultiEffect {
            blurEnabled: scene.cfg.wallBlur > 0.001
            blurMax: 64
            blur: scene.cfg.wallBlur
            brightness: scene.cfg.wallBrightness
            saturation: scene.cfg.wallSaturation
            contrast: scene.cfg.wallContrast
            colorization: scene.tinted ? scene.cfg.wallTintAmount : 0
            colorizationColor: scene.tinted ? scene.cfg.wallTint : "white"
        }

        WallLayer { id: layerA; anchors.fill: parent; playing: win.playing && win.front === layerA; still: Theme.wallpaperStill }
        WallLayer { id: layerB; anchors.fill: parent; playing: win.playing && win.front === layerB; still: Theme.wallpaperStill; opacity: 0 }
    }

    // vignette and grain sit over the wallpaper but under the album visualizer
    Shape {
        anchors.fill: parent
        visible: Settings.s.wallVignette > 0.001
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: win.width / 2; centerY: win.height / 2
                centerRadius: Math.hypot(win.width, win.height) * 0.55
                focalX: centerX; focalY: centerY
                GradientStop { position: 0.45; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Math.min(1, Settings.s.wallVignette)) }
            }
            startX: 0; startY: 0
            PathLine { x: win.width; y: 0 }
            PathLine { x: win.width; y: win.height }
            PathLine { x: 0; y: win.height }
            PathLine { x: 0; y: 0 }
        }
    }
    Image {
        anchors.fill: parent
        visible: Settings.s.wallGrain > 0.001
        source: Qt.resolvedUrl("widgets/grain.png")
        fillMode: Image.Tile
        opacity: Settings.s.wallGrain * 0.18
    }

    // ---- crossfade between layers ----
    property var front: layerA
    property var incoming: null
    readonly property string target: Theme.wallpaperFor(win.screen?.name ?? "")

    onTargetChanged: swap()
    Component.onCompleted: { layerA.path = target; Globals.wallWindows = Globals.wallWindows.concat([win]); }
    Component.onDestruction: Globals.wallWindows = Globals.wallWindows.filter(w => w !== win)

    function swap() {
        if (!target || target === front.path) return;
        const back = front === layerA ? layerB : layerA;
        back.opacity = 0;
        back.path = target;
        incoming = back;
        if (back.ready) reveal();
    }
    Connections {
        target: win.incoming
        function onReadyChanged() { if (win.incoming?.ready) win.reveal(); }
    }
    function reveal() {
        const old = front;
        const next = incoming;
        incoming = null;
        next.z = 1; old.z = 0;
        front = next;
        fadeIn.target = next;
        settle.target = next;
        fadeIn.restart(); settle.restart();
        cleanup.old = old;
        cleanup.restart();
    }
    NumberAnimation { id: fadeIn; property: "opacity"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
    NumberAnimation { id: settle; property: "scale"; from: 1.08; to: 1; duration: 1400; easing.type: Easing.OutQuint }
    Timer {
        id: cleanup
        property var old
        interval: 1000
        onTriggered: if (old && old !== win.front) old.path = ""   // stop the old video/GIF
    }

    // audio visualizer, only while an album cover is the wallpaper (widgets/AlbumViz.qml)
    AlbumViz { anchors.fill: parent }

    // SUPER + left-drag on empty desktop -> draw a terminal (see services/TermDraw.qml).
    MouseArea {
        anchors.fill: parent
        enabled: Settings.s.drawTerminal
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: e => {
            if (e.button === Qt.RightButton) { if (TermDraw.active) TermDraw.cancel(); else e.accepted = false; return; }
            TermDraw.desktopPress(win.screen, e.x, e.y, (e.modifiers & Qt.MetaModifier) !== 0);
        }
        onPositionChanged: e => TermDraw.desktopMove(e.x, e.y)
        onReleased: e => { if (e.button === Qt.LeftButton) TermDraw.desktopRelease(); }
        onCanceled: { if (!TermDraw.viaOverlay) TermDraw.cancel(); }
    }
}
