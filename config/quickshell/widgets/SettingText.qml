import qs.services
import QtQuick

// Single-line text field; emits submitted() on Enter or focus loss.
Rectangle {
    id: f
    property string text
    property string placeholder
    signal submitted(string text)

    implicitWidth: 220
    implicitHeight: 34
    radius: 10
    color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.primary : Theme.alpha(Theme.outline, 0.3)

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        text: f.text
        color: Theme.text
        selectionColor: Theme.primary
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        clip: true
        onEditingFinished: if (text !== f.text) f.submitted(text)
        Keys.onEscapePressed: { text = f.text; focus = false; }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text && !input.activeFocus
            text: f.placeholder
            color: Theme.outline
            font: input.font
        }
    }
}
