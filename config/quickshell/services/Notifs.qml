pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification daemon. `history` = everything not yet dismissed,
// `popups` = what's currently shown on screen.
Singleton {
    id: root

    property bool dnd: false
    property var popups: []
    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length

    function hidePopup(n) {
        popups = popups.filter(x => x !== n);
        if (n && n.transient) n.expire();
    }

    function clearAll() {
        for (const n of [...history]) n.dismiss();
        popups = [];
    }

    // Popup lifetime in ms (critical = never expires)
    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0;
        const t = n.expireTimeout;
        if (!t || t <= 0) return Settings.s.notifTimeout * 1000;
        return t < 100 ? t * 1000 : t;   // accept seconds or ms
    }

    function iconFor(n) {
        const src = n.image || n.appIcon || "";
        if (!src) return "";
        if (src.startsWith("/")) return "file://" + src;
        if (src.includes("://")) return src;
        return Quickshell.iconPath(src, true);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.hidePopup(n));
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return;
            root.popups = [n, ...root.popups].slice(0, Math.max(1, Settings.s.notifMaxPopups));
        }
    }
}
