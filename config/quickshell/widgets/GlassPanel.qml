import qs.services
import QtQuick

// Translucent wallpaper-tinted panel (Hyprland blurs behind it).
Rectangle {
    radius: Theme.radius + 6
    color: Theme.alpha(Theme.surface, Theme.panelOpacity)
    border.width: 1
    border.color: Theme.alpha(Theme.primary, 0.35)
    Behavior on color { ColorAnimation { duration: 400 } }

    MouseArea { anchors.fill: parent }  // clicks inside don't close the overlay
}
