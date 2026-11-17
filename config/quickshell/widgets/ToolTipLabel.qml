import qs.services
import QtQuick

// Tooltip bubble above its parent
Rectangle {
    id: tt
    property bool shown: false
    property string text
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.top
    anchors.bottomMargin: 8
    width: ttText.implicitWidth + 18
    height: 26
    radius: 9
    z: 100
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.alpha(Theme.primary, 0.35)
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.85
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    Text {
        id: ttText
        anchors.centerIn: parent
        text: tt.text
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }
}
