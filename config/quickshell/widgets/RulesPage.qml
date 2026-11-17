import Quickshell
import Quickshell.Hyprland
import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Window rules: per-app window rules, workspace rules and startup commands.
// Stored as JSON arrays in the windowRules / workspaceRules / autostart settings (see Settings.rulesLua()).
ColumnLayout {
    id: page
    spacing: 16

    function parse(key) { try { const v = JSON.parse(Settings.s[key] || "[]"); return Array.isArray(v) ? v : []; } catch (e) { return []; } }
    function save(key, arr) { Settings.set(key, JSON.stringify(arr)); }
    function patch(key, index, change) { const a = parse(key); a[index] = Object.assign({}, a[index], change); save(key, a); }
    function remove(key, index) { const a = parse(key); a.splice(index, 1); save(key, a); }
    function add(key, item) { save(key, parse(key).concat([item])); }

    readonly property var openClasses: {
        const seen = new Set();
        for (const t of Hyprland.toplevels.values) { const c = t.lastIpcObject?.class; if (c) seen.add(c); }
        return Array.from(seen).sort();
    }

    component Btn: Rectangle {
        property string label: ""
        property bool danger: false
        signal clicked()
        height: 28; width: bt.implicitWidth + 22; radius: 14
        color: bm.containsMouse ? (danger ? Theme.error : Theme.primary) : Theme.alpha(Theme.surfaceContainerHigh, 0.8)
        Text { id: bt; anchors.centerIn: parent; text: parent.label; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
               color: bm.containsMouse ? Theme.textOnPrimary : Theme.text }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
    component Field: ColumnLayout {
        property string caption: ""
        property alias text: tf.text
        property string placeholder: ""
        signal submitted(string value)
        spacing: 2
        Text { text: parent.caption; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
        Rectangle {
            Layout.preferredWidth: 150; Layout.preferredHeight: 28; radius: 8
            color: Theme.alpha(Theme.surface, 0.6); border.width: tf.activeFocus ? 1 : 0; border.color: Theme.primary
            TextInput {
                id: tf; anchors.fill: parent; anchors.margins: 6; clip: true; verticalAlignment: TextInput.AlignVCenter
                color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; selectByMouse: true
                onAccepted: { parent.parent.submitted(text); focus = false; }
                onActiveFocusChanged: if (!activeFocus) parent.parent.submitted(text)
                Text { visible: !tf.text && !tf.activeFocus; text: parent.parent.parent.placeholder; color: Theme.alpha(Theme.subtext, 0.6)
                       font: tf.font; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
    component Flag: RowLayout {
        property string label: ""
        property bool on: false
        signal toggled(bool value)
        spacing: 6
        Rectangle { width: 18; height: 18; radius: 5; color: parent.on ? Theme.primary : Theme.alpha(Theme.surface, 0.7)
            Text { anchors.centerIn: parent; visible: parent.parent.on; text: "✓"; color: Theme.textOnPrimary; font.pixelSize: 12 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.toggled(!parent.parent.on) } }
        Text { text: parent.label; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
    }
    component Card: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true; implicitHeight: inner.implicitHeight + 24; radius: 12
        color: Theme.alpha(Theme.surfaceContainerHigh, 0.5)
        ColumnLayout { id: inner; anchors.fill: parent; anchors.margins: 12; spacing: 8 }
    }
    component Head: ColumnLayout {
        property string title: ""
        property string note: ""
        spacing: 2
        Text { text: parent.title; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 3; font.weight: Font.Bold }
        Text { visible: parent.note !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: parent.note; color: Theme.subtext
               font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
    }

    Text { text: "Window rules"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize + 8; font.weight: Font.Bold }
    Text {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: "Make specific apps float, stay pinned, open on a workspace and more. Press Enter in a field to apply it."
        color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
    }

    // ---------------------------------------------------------------- window rules
    Head { title: "Per-app rules"; note: "Match by app class (a regular expression, e.g. ^firefox$) and optionally by title." }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Text { text: "Add a rule for an open app:"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; height: 28; verticalAlignment: Text.AlignVCenter }
        Repeater { model: page.openClasses; Btn { required property string modelData; label: modelData
                   onClicked: page.add("windowRules", { enabled: true, class: "^" + modelData + "$", float: true }) } }
        Btn { label: "+ Blank rule"; onClicked: page.add("windowRules", { enabled: true, class: "", float: true }) }
    }
    Text { visible: page.parse("windowRules").length === 0; text: "No rules yet."; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
    Repeater {
        model: page.parse("windowRules")
        Card {
            id: rc
            required property var modelData
            required property int index
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Flag { label: "On"; on: rc.modelData.enabled !== false; onToggled: v => page.patch("windowRules", rc.index, { enabled: v }) }
                Field { caption: "App class"; text: rc.modelData.class ?? ""; placeholder: "^firefox$"; onSubmitted: v => { if (v !== (rc.modelData.class ?? "")) page.patch("windowRules", rc.index, { class: v }); } }
                Field { caption: "Title (optional)"; text: rc.modelData.title ?? ""; placeholder: "Picture-in-Picture"; onSubmitted: v => { if (v !== (rc.modelData.title ?? "")) page.patch("windowRules", rc.index, { title: v }); } }
                Item { Layout.fillWidth: true }
                Btn { label: "Delete"; danger: true; onClicked: page.remove("windowRules", rc.index) }
            }
            Flow {
                Layout.fillWidth: true; spacing: 14
                Flag { label: "Float"; on: !!rc.modelData.float; onToggled: v => page.patch("windowRules", rc.index, { float: v }) }
                Flag { label: "Pin"; on: !!rc.modelData.pin; onToggled: v => page.patch("windowRules", rc.index, { pin: v }) }
                Flag { label: "No blur"; on: !!rc.modelData.noBlur; onToggled: v => page.patch("windowRules", rc.index, { noBlur: v }) }
                Flag { label: "Don't focus on open"; on: !!rc.modelData.noInitialFocus; onToggled: v => page.patch("windowRules", rc.index, { noInitialFocus: v }) }
            }
            Flow {
                Layout.fillWidth: true; spacing: 12
                Field { caption: "Open on workspace"; text: rc.modelData.workspace ?? ""; placeholder: "3"; onSubmitted: v => { if (v !== (rc.modelData.workspace ?? "")) page.patch("windowRules", rc.index, { workspace: v }); } }
                Field { caption: "Opacity (active inactive)"; text: rc.modelData.opacity ?? ""; placeholder: "0.9 0.8"; onSubmitted: v => { if (v !== (rc.modelData.opacity ?? "")) page.patch("windowRules", rc.index, { opacity: v }); } }
                Field { caption: "Size (width height)"; text: rc.modelData.size ?? ""; placeholder: "900 600"; onSubmitted: v => { if (v !== (rc.modelData.size ?? "")) page.patch("windowRules", rc.index, { size: v }); } }
            }
        }
    }

    // ---------------------------------------------------------------- workspace rules
    Head { title: "Workspace rules"; note: "Keep a workspace on a particular monitor, or make it the default or persistent (shown even when empty)." }
    Btn { label: "+ Add workspace rule"; onClicked: page.add("workspaceRules", { workspace: "1", monitor: "" }) }
    Repeater {
        model: page.parse("workspaceRules")
        Card {
            id: wc
            required property var modelData
            required property int index
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Field { caption: "Workspace"; text: wc.modelData.workspace ?? ""; placeholder: "1"; onSubmitted: v => { if (v !== (wc.modelData.workspace ?? "")) page.patch("workspaceRules", wc.index, { workspace: v }); } }
                Field { caption: "Monitor"; text: wc.modelData.monitor ?? ""; placeholder: Quickshell.screens[0]?.name ?? "eDP-1"; onSubmitted: v => { if (v !== (wc.modelData.monitor ?? "")) page.patch("workspaceRules", wc.index, { monitor: v }); } }
                Flag { label: "Default"; on: !!wc.modelData.default; onToggled: v => page.patch("workspaceRules", wc.index, { default: v }) }
                Flag { label: "Persistent"; on: !!wc.modelData.persistent; onToggled: v => page.patch("workspaceRules", wc.index, { persistent: v }) }
                Item { Layout.fillWidth: true }
                Btn { label: "Delete"; danger: true; onClicked: page.remove("workspaceRules", wc.index) }
            }
        }
    }

    // ---------------------------------------------------------------- autostart
    Head { title: "Autostart"; note: "Commands that run once when Hyprland starts (not when you change a setting). Applies from your next login." }
    Btn { label: "+ Add command"; onClicked: page.add("autostart", "") }
    Repeater {
        model: page.parse("autostart")
        Card {
            id: ac
            required property var modelData
            required property int index
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Field { Layout.fillWidth: true; caption: "Command"; text: String(ac.modelData); placeholder: "firefox"
                        onSubmitted: v => { const a = page.parse("autostart"); if (v !== a[ac.index]) { a[ac.index] = v; page.save("autostart", a); } } }
                Btn { label: "Delete"; danger: true; onClicked: page.remove("autostart", ac.index) }
            }
        }
    }
}
