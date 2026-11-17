//@ pragma IconTheme Qogir-Dark
import Quickshell
import qs.bar
import qs.popups
import qs.system
import QtQuick

ShellRoot {
    // One wallpaper + one bar per monitor
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                id: perScreen
                required property ShellScreen modelData
                Wallpaper { screen: perScreen.modelData }
                Bar { screen: perScreen.modelData }
            }
        }
    }

    Launcher {}
    WallpaperPicker {}
    ControlCenter {}
    NotificationPopups {}
    PolkitDialog {}
    Lock {}
    Idle {}
    Ipc {}
    AlbumWall {}
    PowerMenu {}
    Osd {}
    Equalizer {}
    Mixer {}
    NightLight {}
    Clipboard {}
    SettingsPanel {}
    TermDrawPreview {}
    LyricsViewer {}
}
