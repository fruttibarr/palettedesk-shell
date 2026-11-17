pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The "current" media player: whichever is playing, else the first one.
Singleton {
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
}
