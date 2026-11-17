import Quickshell
import Quickshell.Io
import qs.services
import QtQuick

// Sticky note, saved to ~/.config/rice/notes-<uid>.txt. Click it and type (the window takes keyboard focus on demand).
Item {
    id: w
    property var opts: ({})
    property string uid: "default"
    implicitWidth: 260
    implicitHeight: 200
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/rice/notes-" + w.uid + ".txt"
        onLoaded: edit.text = text()
    }
    Timer { id: saveT; interval: 600; onTriggered: file.setText(edit.text) }
    TextEdit {
        id: edit
        anchors.fill: parent
        wrapMode: TextEdit.Wrap
        color: Theme.text
        selectionColor: Theme.primary
        font.family: Theme.font; font.pixelSize: Theme.fontSize
        onTextChanged: if (activeFocus) saveT.restart()
        Text { visible: !edit.text && !edit.activeFocus; text: "Click to write a note…"; color: Theme.outline; font: edit.font }
    }
}
