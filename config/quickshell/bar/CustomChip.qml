import Quickshell
import qs.services
import qs.widgets
import QtQuick

// A bar module defined by the user (see services/CustomModules.qml).
// Left click / right click / middle click / scroll run the commands set in the editor.
Chip {
    id: chip
    property string moduleId
    readonly property var cfg: CustomModules.config(moduleId) ?? ({})
    readonly property var val: CustomModules.values[moduleId] ?? ({})
    readonly property string iconText: val.icon ?? cfg.icon ?? ""
    readonly property string label: val.text ?? ""
    readonly property string tintName: val.tint ?? cfg.tint ?? "primary"
    readonly property color tintColor: ({ primary: Theme.primary, secondary: Theme.secondary, tertiary: Theme.tertiary, error: Theme.error })[tintName] ?? Theme.text

    spacing: 6
    clickable: !!(cfg.onClick || cfg.onRightClick || cfg.onMiddleClick)
    acceptedButtons: Qt.AllButtons
    wheelEnabled: !!(cfg.onScrollUp || cfg.onScrollDown)
    onButtonClicked: b => {
        const cmd = b === Qt.LeftButton ? cfg.onClick : b === Qt.RightButton ? cfg.onRightClick : b === Qt.MiddleButton ? cfg.onMiddleClick : "";
        if (cmd) { CustomModules.run(cmd); refreshSoon.restart(); }
    }
    onWheeled: d => {
        const cmd = d > 0 ? cfg.onScrollUp : cfg.onScrollDown;
        if (cmd) { CustomModules.run(cmd); refreshSoon.restart(); }
    }
    Timer { id: refreshSoon; interval: 400; onTriggered: CustomModules.refresh(chip.moduleId) }

    Text {
        visible: chip.iconText !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: chip.iconText
        color: chip.tintColor
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
    }
    Text {
        id: lbl
        visible: chip.label !== ""
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, chip.cfg.maxWidth ?? 220)
        text: chip.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
