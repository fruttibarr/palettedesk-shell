import qs.services
import QtQuick

// Nerd-font icon + text. Call bump() to make the icon pop.
Row {
    id: root
    property string icon
    property string label
    property color iconColor: Theme.primary
    property color labelColor: Theme.text
    property alias iconItem: iconText
    spacing: 6

    function bump() { pop.restart(); }

    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.iconColor
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        Behavior on color { ColorAnimation { duration: 300 } }

        SequentialAnimation {
            id: pop
            NumberAnimation { target: iconText; property: "scale"; to: 1.3; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: iconText; property: "scale"; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.label !== ""
        text: root.label
        color: root.labelColor
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.features: { "tnum": 1 }   // fixed-width digits: numbers don't jitter
    }
}
