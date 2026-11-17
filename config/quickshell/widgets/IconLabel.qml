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
    property bool showIcon: true
    property alias extra: slot.data     // optional custom glyph (ring / bar) between icon and label
    // barIconColor: accent (as given) / mono / tertiary; error + dimmed state colours are always kept
    readonly property string colorMode: Settings.s.barIconColor
    readonly property bool stateColor: Qt.colorEqual(iconColor, Theme.error) || Qt.colorEqual(iconColor, Theme.outline)
    readonly property color shownIconColor: stateColor || colorMode === "accent" ? iconColor
                                           : colorMode === "mono" ? Theme.text : Theme.tertiary
    spacing: 6

    function bump() { pop.restart(); }

    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcon
        text: root.icon
        color: root.shownIconColor
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2 + Settings.s.barIconSize
        Behavior on color { ColorAnimation { duration: 300 } }

        SequentialAnimation {
            id: pop
            NumberAnimation { target: iconText; property: "scale"; to: 1.3; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: iconText; property: "scale"; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
    }
    Item {
        id: slot
        anchors.verticalCenter: parent.verticalCenter
        visible: { for (let i = 0; i < children.length; i++) if (children[i].visible) return true; return false; }
        implicitWidth: childrenRect.width
        implicitHeight: 0   // children centre on the slot; the row's height comes from the texts (was a binding loop)
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
