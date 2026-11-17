import qs.services
import QtQuick

// On/off switch.
Rectangle {
    id: t
    property bool checked
    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? Theme.primary : Theme.alpha(Theme.outline, mouse.containsMouse ? 0.5 : 0.35)
    Behavior on color { ColorAnimation { duration: 180 } }

    Rectangle {
        width: 20; height: 20; radius: 10
        y: 3
        x: t.checked ? t.width - width - 3 : 3
        color: t.checked ? Theme.textOnPrimary : Theme.text
        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled(!t.checked)
    }
}
