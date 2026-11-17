import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.services
import QtQuick

// Idle chain: dim (4 min) -> lock (5 min) -> screen off (6 min)
// -> suspend (15 min, on battery only). "Keep awake" in the control
// center blocks all of it.
Scope {
    id: root
    property real savedBrightness: -1

    // Times in seconds, from Settings (minutes; 0 = never)
    readonly property int dimAfter: Settings.s.dimAfter * 60
    readonly property int lockAfter: Settings.s.lockAfter * 60
    readonly property int screenOffAfter: Settings.s.screenOffAfter * 60
    readonly property int suspendAfter: Settings.s.suspendAfter * 60

    // Idle inhibitor needs a surface: a 1px invisible layer while keep-awake is on.
    PanelWindow {
        id: inhibitSurface
        visible: Globals.keepAwake
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-inhibitor"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true }
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
    }

    IdleInhibitor {
        window: inhibitSurface
        enabled: Globals.keepAwake
    }

    IdleMonitor {
        timeout: root.dimAfter
        enabled: root.dimAfter > 0
        onIsIdleChanged: {
            if (!Brightness.available) return;
            if (isIdle) {
                root.savedBrightness = Brightness.value;
                Brightness.set(Math.min(Brightness.value, 0.3));
            } else if (root.savedBrightness >= 0) {
                Brightness.set(root.savedBrightness);
                root.savedBrightness = -1;
            }
        }
    }

    IdleMonitor {
        timeout: root.lockAfter
        enabled: root.lockAfter > 0
        onIsIdleChanged: if (isIdle) Globals.lockRequested()
    }

    IdleMonitor {
        timeout: root.screenOffAfter
        enabled: root.screenOffAfter > 0
        onIsIdleChanged: Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.dpms({ action = '${isIdle ? "off" : "on"}' })`])
    }

    IdleMonitor {
        timeout: root.suspendAfter
        enabled: root.suspendAfter > 0 && (UPower.onBattery || !Settings.s.suspendOnBatteryOnly)
        onIsIdleChanged: if (isIdle) Globals.suspend()
    }
}
