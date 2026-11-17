import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.widgets
import QtQuick

// Scroll to change volume (icon pops on change). Clicks pass through.
Item {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property int pct: Math.round((sink?.audio?.volume ?? 0) * 100)

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    PwObjectTracker { objects: [root.sink] }
    onPctChanged: label.bump()
    onMutedChanged: label.bump()

    IconLabel {
        id: label
        icon: root.muted ? "󰝟" : root.pct > 60 ? "󰕾" : root.pct > 25 ? "󰖀" : "󰕿"
        label: Settings.s.statusPercent ? root.pct + "%" : ""
        iconColor: root.muted ? (Settings.s.statusStateColors ? Theme.error : Theme.outline) : Theme.primary
        labelColor: root.muted ? Theme.outline : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: e => {
            if (!root.sink?.audio) return;
            const step = e.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
