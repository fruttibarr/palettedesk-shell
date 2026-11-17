pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.services
import QtQuick

// Automatic profiles (Settings > Automation). A rule = a trigger + what to change while it holds:
//   trigger: { type: "battery"|"fullscreen"|"app"|"time"|"monitor", ... }
//   action:  { theme?: name, settings?: {key: value}, power?: "power-saver"|"balanced"|"performance", dnd?: bool,
//              command?: sh, commandOff?: sh }
// While a rule is active its settings are applied; when it ends the previous values come back, unless you changed
// that setting by hand in the meantime (your change wins). Rules are evaluated in list order, later ones win.
// What was overridden is saved to ~/.local/state/rice/profiles.json so a reload or crash never leaves it stuck.
Singleton {
    id: root
    readonly property string file: Quickshell.env("HOME") + "/.local/state/rice/profiles.json"
    readonly property var rules: Settings.s.autoRules ?? []

    property var simulated: ({})                       // trigger -> bool, set by `qs ipc call profiles simulate`
    property var win: ({ cls: "", fullscreen: false })
    property date now: new Date()
    property var activeIds: []
    // what we overrode: values before (keys), values we set (applied), wallpaper, power profile, dnd
    property var snap: ({ keys: {}, applied: {}, wall: "", appliedWall: "", power: null, appliedPower: null, dnd: null, appliedDnd: null })
    property bool ready: false

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
    function clone(v) { return v === undefined ? undefined : JSON.parse(JSON.stringify(v)); }
    function minutes(hhmm) { const p = String(hhmm ?? "0:0").split(":"); return (parseInt(p[0]) || 0) * 60 + (parseInt(p[1]) || 0); }

    function cond(r) {
        const t = r.trigger ?? {};
        const sim = simulated;
        switch (t.type) {
        case "battery": {
            const on = sim.battery ?? UPower.onBattery;
            const pct = (UPower.displayDevice?.percentage ?? 1) * 100;
            return on && (!(t.below > 0) || pct < t.below);
        }
        case "fullscreen": return sim.fullscreen ?? win.fullscreen;
        case "app": {
            if (sim.app !== undefined) return sim.app;
            try { return !!t.match && new RegExp(t.match, "i").test(win.cls); } catch (e) { return false; }
        }
        case "time": {
            if (sim.time !== undefined) return sim.time;
            const n = now.getHours() * 60 + now.getMinutes(), a = minutes(t.from), b = minutes(t.to);
            return a <= b ? (n >= a && n < b) : (n >= a || n < b);
        }
        case "monitor": return sim.monitor ?? Quickshell.screens.length > (t.count ?? 1);
        }
        return false;
    }

    function evaluate() {
        if (!ready) return;
        const on = rules.filter(r => r.enabled && cond(r));
        const ids = on.map(r => r.id);

        // what the active rules want, later rules overriding earlier ones
        const want = { settings: {}, wall: "", power: null, dnd: null };
        for (const r of on) {
            const a = r.action ?? {};
            if (a.theme) {
                const p = Presets.all.find(x => x.name.toLowerCase() === String(a.theme).toLowerCase());
                if (p) { Object.assign(want.settings, Presets.full(p)); want.wall = p.wallpaper; }
            }
            Object.assign(want.settings, a.settings ?? {});
            if (a.power) want.power = a.power;
            if (a.dnd === true || a.dnd === false) want.dnd = a.dnd;
        }

        const s = clone(snap);
        const set = {}, back = {};
        for (const k in want.settings) {
            if (!(k in Settings.defaults)) continue;
            if (!(k in s.keys)) s.keys[k] = clone(Settings.s[k]);
            if (!(k in s.applied) || !same(s.applied[k], want.settings[k])) set[k] = want.settings[k];
            s.applied[k] = clone(want.settings[k]);
        }
        for (const k in s.keys) {
            if (k in want.settings) continue;
            if (same(Settings.s[k], s.applied[k])) back[k] = s.keys[k];     // untouched by the user: put it back
            delete s.keys[k]; delete s.applied[k];                           // (changed by hand: leave their value)
        }

        // wallpaper only changes through themes
        let wall = "";
        if (want.wall) {
            if (!s.wall) s.wall = Theme.baseWallpaper;
            if (s.appliedWall !== want.wall) wall = want.wall;
            s.appliedWall = want.wall;
        } else if (s.wall) {
            if (s.appliedWall === Theme.baseWallpaper) wall = s.wall;
            s.wall = ""; s.appliedWall = "";
        }

        if (wall) Settings.applyLook(Object.assign({}, back, set), wall);
        else { for (const k in back) Settings.set(k, back[k]); for (const k in set) Settings.set(k, set[k]); }

        // power profile
        if (want.power) {
            const target = ({ "power-saver": PowerProfile.PowerSaver, "balanced": PowerProfile.Balanced, "performance": PowerProfile.Performance })[want.power];
            if (s.power === null) s.power = PowerProfiles.profile;
            if (target !== undefined && s.appliedPower !== target) PowerProfiles.profile = target;
            s.appliedPower = target ?? null;
        } else if (s.power !== null) {
            if (PowerProfiles.profile === s.appliedPower) PowerProfiles.profile = s.power;
            s.power = null; s.appliedPower = null;
        }
        // do not disturb
        if (want.dnd !== null) {
            if (s.dnd === null) s.dnd = Notifs.dnd;
            Notifs.dnd = want.dnd; s.appliedDnd = want.dnd;
        } else if (s.dnd !== null) {
            if (Notifs.dnd === s.appliedDnd) Notifs.dnd = s.dnd;
            s.dnd = null; s.appliedDnd = null;
        }

        // commands run once when a rule switches on / off
        for (const r of rules) {
            const was = activeIds.includes(r.id), is = ids.includes(r.id);
            if (is && !was && r.action?.command) Quickshell.execDetached(["sh", "-c", r.action.command]);
            if (!is && was && r.action?.commandOff) Quickshell.execDetached(["sh", "-c", r.action.commandOff]);
        }

        const changed = !same(s, snap);
        snap = s;
        if (!same(ids, activeIds)) activeIds = ids;
        if (changed) store.setText(JSON.stringify(s));
    }
    Timer { id: evalTimer; interval: 150; onTriggered: root.evaluate() }
    function poke() { evalTimer.restart(); }
    onRulesChanged: { poke(); winTimer.restart(); }
    onSimulatedChanged: poke()
    onWinChanged: poke()
    onNowChanged: poke()

    // load what a previous run overrode, then start (a leftover snapshot is undone by the first evaluate if no rule holds it any more)
    FileView {
        id: store
        path: root.file
        onLoaded: { try { const d = JSON.parse(text()); if (d && d.keys) root.snap = Object.assign(root.snap, d); } catch (e) {} startTimer.start(); }
        onLoadFailed: startTimer.start()
    }
    Timer { id: startTimer; interval: 1500; onTriggered: { root.ready = true; root.evaluate(); } }

    // clock (time rules)
    Timer { interval: 30000; repeat: true; running: root.rules.some(r => r.enabled && r.trigger?.type === "time"); onTriggered: root.now = new Date() }

    Connections { target: UPower; function onOnBatteryChanged() { root.poke(); } }
    Connections { target: UPower.displayDevice; function onPercentageChanged() { root.poke(); } }
    Connections { target: Quickshell; function onScreensChanged() { root.poke(); } }

    // focused window class + fullscreen state
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (["activewindow", "activewindowv2", "fullscreen", "workspace", "focusedmon", "closewindow"].includes(e.name)) winTimer.restart();
        }
    }
    Timer { id: winTimer; interval: 120; onTriggered: if (root.rules.some(r => r.enabled && (r.trigger?.type === "app" || r.trigger?.type === "fullscreen"))) winProc.running = true }
    Process {
        id: winProc
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                let w = { cls: "", fullscreen: false };
                try { const j = JSON.parse(text); w = { cls: j.class ?? "", fullscreen: j.fullscreen === true || Number(j.fullscreen) > 0 }; } catch (e) {}
                if (!root.same(w, root.win)) root.win = w;
            }
        }
    }
    function setEnabled(id, on) {
        Settings.set("autoRules", rules.map(r => r.id === id ? Object.assign({}, r, { enabled: on }) : r));
    }

    IpcHandler {
        target: "profiles"
        function list(): string { return root.rules.map(r => (root.activeIds.includes(r.id) ? "● " : r.enabled ? "○ " : "  ") + r.id + "  " + r.name).join("\n") || "no rules"; }
        function active(): string { return root.activeIds.join(" ") || "none"; }
        function enable(id: string): void { root.setEnabled(id, true); }
        function disable(id: string): void { root.setEnabled(id, false); }
        // qs ipc call profiles simulate battery on|off|clear   (battery | fullscreen | app | time | monitor)
        function simulate(trigger: string, state: string): string {
            const o = Object.assign({}, root.simulated);
            if (state === "clear") delete o[trigger]; else o[trigger] = state === "on";
            root.simulated = o;
            return trigger + " = " + (state === "clear" ? "real" : state);
        }
        function snapshot(): string { return JSON.stringify(root.snap); }
    }
}
