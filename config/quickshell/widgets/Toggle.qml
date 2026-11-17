import qs.services
import QtQuick

// On/off switch. Look from the uiToggleStyle setting: pill | square | ios | dot.
Rectangle {
    id: t
    property bool checked
    signal toggled(bool value)

    readonly property string style: Settings.s.uiToggleStyle
    readonly property bool dot: style === "dot"
    readonly property bool ios: style === "ios"
    readonly property int pad: dot ? 0 : ios ? 2 : 3
    readonly property int knob: dot ? 20 : ios ? 27 : 20

    implicitWidth: dot ? 40 : ios ? 52 : 46
    implicitHeight: dot ? 16 : ios ? 31 : 26
    radius: style === "square" ? 6 : height / 2
    color: checked ? (ios ? Theme.secondary : Theme.primary) : Theme.alpha(Theme.outline, mouse.containsMouse ? 0.5 : 0.35)
    border.width: dot ? 0 : style === "square" ? 1 : 0
    border.color: checked ? Theme.primary : Theme.alpha(Theme.outline, 0.6)
    Behavior on color { ColorAnimation { duration: 180 } }

    Rectangle {
        id: knobRect
        width: t.knob + (mouse.pressed && !t.dot ? 3 : 0); height: t.knob
        radius: t.style === "square" ? 4 : t.knob / 2
        anchors.verticalCenter: parent.verticalCenter
        x: t.checked ? t.width - width - t.pad : t.pad
        color: t.dot ? (t.checked ? Theme.primary : Theme.text) : t.checked ? (t.ios ? "white" : Theme.textOnPrimary) : (t.ios ? "white" : Theme.text)
        border.width: t.dot ? 3 : 0
        border.color: t.dot ? Theme.surface : "transparent"
        Behavior on x { NumberAnimation { duration: 260 * Theme.anim; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on width { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled(!t.checked)
    }
}
