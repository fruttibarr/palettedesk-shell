import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.services
import qs.widgets
import QtQuick

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

    Item {
        id: scene
        height: parent.height
        width: parent.width * (1 + win.extra)
        x: -win.ratio * (width - win.width)
        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        WallLayer { id: layerA; anchors.fill: parent; playing: win.playing && win.front === layerA; still: Theme.wallpaperStill }
        WallLayer { id: layerB; anchors.fill: parent; playing: win.playing && win.front === layerB; still: Theme.wallpaperStill; opacity: 0 }
    }

    // ---- crossfade between layers ----
    property var front: layerA
    property var incoming: null
    readonly property string target: Theme.wallpaper

    onTargetChanged: swap()
    Component.onCompleted: { layerA.path = target; }

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
