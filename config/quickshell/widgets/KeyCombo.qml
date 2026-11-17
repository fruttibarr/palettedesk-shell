import qs.services
import QtQuick
import QtQuick.Layouts

// Shows a key combo as keycaps; click to record a new one.
// Hyprland grabs SUPER combos before apps see them, so modifiers are toggles
// while recording and only the plain key needs pressing.
RowLayout {
    id: kc
    property string combo            // "SUPER + SHIFT + Q", "" = disabled
    property string defaultCombo
    property bool recording: false
    property var mods: []            // while recording
    signal picked(string combo)
    spacing: 6

    readonly property var modOrder: ["SUPER", "CTRL", "ALT", "SHIFT"]
    readonly property var parts: combo ? combo.split("+").map(s => s.trim()).filter(s => s) : []

    function pretty(p) {
        const m = { SUPER: "󰘳 Super", SHIFT: "⇧ Shift", CTRL: "Ctrl", ALT: "Alt", RETURN: "Enter", SPACE: "Space",
                    COMMA: ",", PERIOD: ".", SLASH: "/", SEMICOLON: ";", APOSTROPHE: "'", MINUS: "-", EQUAL: "=",
                    BACKSLASH: "\\", GRAVE: "`", BRACKETLEFT: "[", BRACKETRIGHT: "]",
                    LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓", PRINT: "PrtSc", ESCAPE: "Esc" };
        return m[p.toUpperCase()] ?? (p.length === 1 ? p.toUpperCase() : p);
    }

    function startRecording() {
        mods = parts.slice(0, -1).map(p => p.toUpperCase()).filter(p => modOrder.includes(p));
        if (!combo) mods = ["SUPER"];
        recording = true;
        catcher.forceActiveFocus();
    }
    function toggleMod(m) {
        mods = mods.includes(m) ? mods.filter(x => x !== m) : mods.concat([m]);
        catcher.forceActiveFocus();
    }

    // Qt key -> Hyprland (xkb) key name. Shifted symbols map back to their base key.
    function keyName(e) {
        const k = e.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1);
        const map = {};
        map[Qt.Key_Return] = "RETURN"; map[Qt.Key_Enter] = "RETURN"; map[Qt.Key_Space] = "SPACE";
        map[Qt.Key_Tab] = "TAB"; map[Qt.Key_Backtab] = "TAB"; map[Qt.Key_Backspace] = "BACKSPACE";
        map[Qt.Key_Delete] = "DELETE"; map[Qt.Key_Insert] = "INSERT"; map[Qt.Key_Home] = "HOME"; map[Qt.Key_End] = "END";
        map[Qt.Key_PageUp] = "Prior"; map[Qt.Key_PageDown] = "Next";
        map[Qt.Key_Left] = "left"; map[Qt.Key_Right] = "right"; map[Qt.Key_Up] = "up"; map[Qt.Key_Down] = "down";
        map[Qt.Key_Print] = "Print";
        map[Qt.Key_Comma] = "COMMA"; map[Qt.Key_Less] = "COMMA";
        map[Qt.Key_Period] = "PERIOD"; map[Qt.Key_Greater] = "PERIOD";
        map[Qt.Key_Slash] = "SLASH"; map[Qt.Key_Question] = "SLASH";
        map[Qt.Key_Semicolon] = "SEMICOLON"; map[Qt.Key_Colon] = "SEMICOLON";
        map[Qt.Key_Apostrophe] = "APOSTROPHE"; map[Qt.Key_QuoteDbl] = "APOSTROPHE";
        map[Qt.Key_Minus] = "MINUS"; map[Qt.Key_Underscore] = "MINUS";
        map[Qt.Key_Equal] = "EQUAL"; map[Qt.Key_Plus] = "EQUAL";
        map[Qt.Key_Backslash] = "BACKSLASH"; map[Qt.Key_Bar] = "BACKSLASH";
        map[Qt.Key_QuoteLeft] = "grave"; map[Qt.Key_AsciiTilde] = "grave";
        map[Qt.Key_BracketLeft] = "bracketleft"; map[Qt.Key_BraceLeft] = "bracketleft";
        map[Qt.Key_BracketRight] = "bracketright"; map[Qt.Key_BraceRight] = "bracketright";
        map[Qt.Key_Exclam] = "1"; map[Qt.Key_At] = "2"; map[Qt.Key_NumberSign] = "3"; map[Qt.Key_Dollar] = "4";
        map[Qt.Key_Percent] = "5"; map[Qt.Key_AsciiCircum] = "6"; map[Qt.Key_Ampersand] = "7";
        map[Qt.Key_Asterisk] = "8"; map[Qt.Key_ParenLeft] = "9"; map[Qt.Key_ParenRight] = "0";
        return map[k] ?? "";
    }

    component Cap: Rectangle {
        id: cap
        property string text
        property bool active: true
        property bool clickable: false
        signal clicked()
        implicitWidth: Math.max(28, capText.implicitWidth + 16)
        implicitHeight: 28
        radius: 7
        color: active ? Theme.alpha(Theme.primary, capMouse.containsMouse && clickable ? 0.3 : 0.18)
                      : Theme.alpha(Theme.surfaceContainerHigh, capMouse.containsMouse ? 0.95 : 0.6)
        border.width: 1
        border.color: active ? Theme.alpha(Theme.primary, 0.5) : Theme.alpha(Theme.outline, 0.3)
        Text {
            id: capText
            anchors.centerIn: parent
            text: cap.text
            color: cap.active ? Theme.primary : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: capMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: cap.clickable
            cursorShape: Qt.PointingHandCursor
            onClicked: cap.clicked()
        }
    }

    // ---- idle: keycaps, click to edit ----
    Rectangle {
        visible: !kc.recording
        implicitWidth: idleRow.implicitWidth + 12
        implicitHeight: 36
        radius: 10
        color: Theme.alpha(Theme.surfaceContainerHigh, idleMouse.containsMouse ? 0.95 : 0.0)
        border.width: idleMouse.containsMouse ? 1 : 0
        border.color: Theme.alpha(Theme.primary, 0.4)
        Row {
            id: idleRow
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: kc.parts
                Cap { required property string modelData; text: kc.pretty(modelData) }
            }
            Text {
                visible: kc.parts.length === 0
                anchors.verticalCenter: parent.verticalCenter
                text: "Disabled"
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                font.italic: true
            }
        }
        MouseArea {
            id: idleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: kc.startRecording()
        }
    }

    // ---- recording: modifier toggles + "press a key" ----
    Row {
        visible: kc.recording
        spacing: 4
        Repeater {
            model: kc.modOrder
            Cap {
                required property string modelData
                text: kc.pretty(modelData)
                active: kc.mods.includes(modelData)
                clickable: true
                onClicked: kc.toggleMod(modelData)
            }
        }
        Rectangle {
            id: catcherBox
            width: 128
            height: 28
            radius: 7
            color: Theme.alpha(Theme.primary, 0.12)
            border.width: 2
            border.color: Theme.primary
            SequentialAnimation on opacity {
                running: kc.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 600 }
                NumberAnimation { to: 1; duration: 600 }
            }
            Text {
                anchors.centerIn: parent
                text: "press a key…"
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
            Item {
                id: catcher
                anchors.fill: parent
                focus: kc.recording
                onActiveFocusChanged: if (!activeFocus && kc.recording) kc.recording = false
                Keys.onPressed: e => {
                    e.accepted = true;
                    if (e.key === Qt.Key_Escape) { kc.recording = false; return; }
                    const name = kc.keyName(e);
                    if (!name) return;                     // a lone modifier, or unknown key
                    let m = kc.mods.slice();
                    if (e.modifiers & Qt.ControlModifier && !m.includes("CTRL")) m.push("CTRL");
                    if (e.modifiers & Qt.AltModifier && !m.includes("ALT")) m.push("ALT");
                    if (e.modifiers & Qt.MetaModifier && !m.includes("SUPER")) m.push("SUPER");
                    if (e.modifiers & Qt.ShiftModifier && !m.includes("SHIFT")) m.push("SHIFT");
                    m = kc.modOrder.filter(x => m.includes(x));
                    kc.recording = false;
                    kc.picked(m.concat([name]).join(" + "));
                }
            }
        }
    }

    // small round icon buttons: cancel / disable / reset
    component IconBtn: Rectangle {
        id: ib
        property string icon
        property string tip
        signal clicked()
        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: Theme.alpha(Theme.surfaceContainerHigh, ibMouse.containsMouse ? 0.95 : 0.6)
        Text { anchors.centerIn: parent; text: ib.icon; color: Theme.primary; font.family: Theme.font; font.pixelSize: 13 }
        MouseArea { id: ibMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
    }
    IconBtn { visible: kc.recording; icon: "󰜺"; onClicked: kc.recording = false }
    IconBtn { visible: kc.recording; icon: "󰂭"; onClicked: { kc.recording = false; kc.picked(""); } }   // disable
    IconBtn {
        visible: !kc.recording && Settings.normCombo(kc.combo) !== Settings.normCombo(kc.defaultCombo)
        icon: "󰑓"
        onClicked: kc.picked(kc.defaultCombo)
    }
}
