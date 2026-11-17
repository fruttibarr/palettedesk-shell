import Quickshell
import Quickshell.Io
import qs.services
import QtQuick
import QtQuick.Layouts

// Settings > Bar > Custom modules: make your own bar chips from a shell command.
// Modules are stored in Settings "customModules"; place them with the layout editor like any other module.
SettingSection {
    id: sec
    title: "Custom modules"

    property var draft: null            // module being edited (a copy), null = just the list
    property bool isNew: false
    property string testOut: ""
    readonly property var list: Settings.s.customModules ?? []

    readonly property var templates: [
        { name: "Battery %", icon: "󰁹", command: "cat /sys/class/power_supply/BAT*/capacity | head -1 | sed 's/$/%/'", mode: "interval", interval: 30 },
        { name: "Updates", icon: "󰚰", command: "checkupdates 2>/dev/null | wc -l", mode: "interval", interval: 1800, onClick: "kitty -e sudo pacman -Syu" },
        { name: "Local IP", icon: "󰩟", command: "ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+'", mode: "interval", interval: 60 },
        { name: "GPU temp", icon: "󰢮", command: "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | sed 's/$/°C/'", mode: "interval", interval: 5 },
        { name: "Now playing", icon: "󰎆", command: "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null", mode: "interval", interval: 3, onClick: "playerctl play-pause", onScrollUp: "playerctl next", onScrollDown: "playerctl previous" },
        { name: "Tokyo time", icon: "󰥔", command: "TZ=Asia/Tokyo date +%H:%M", mode: "interval", interval: 20 },
        { name: "Seconds (test)", icon: "󱎫", command: "date +%S", mode: "interval", interval: 1 },
    ]

    function blank() {
        return { id: "custom:" + Date.now().toString(36), name: "My module", icon: "󰣇", command: "", mode: "interval", interval: 5,
                 json: false, onClick: "", onRightClick: "", onMiddleClick: "", onScrollUp: "", onScrollDown: "",
                 tint: "primary", maxWidth: 220, hideWhenEmpty: false };
    }
    function startNew(tpl) { draft = Object.assign(blank(), tpl ?? {}); isNew = true; testOut = ""; }
    function startEdit(m) { draft = Object.assign(blank(), m); isNew = false; testOut = ""; }
    function patch(key, v) { const d = Object.assign({}, draft); d[key] = v; draft = d; }
    function save() {
        const arr = list.filter(m => m.id !== draft.id);
        if (isNew) arr.push(draft); else arr.splice(Math.max(0, list.findIndex(m => m.id === draft.id)), 0, draft);
        Settings.set("customModules", arr);
        draft = null;
    }
    function remove(id) {
        Settings.set("customModules", list.filter(m => m.id !== id));
        // take it out of the bar layout too
        const L = Settings.s.barLayout ?? {};
        Settings.set("barLayout", { left: (L.left ?? []).filter(x => x !== id), center: (L.center ?? []).filter(x => x !== id), right: (L.right ?? []).filter(x => x !== id) });
        if (draft && draft.id === id) draft = null;
    }

    component TextBtn: Rectangle {
        id: tb
        property string label
        property bool primary: false
        property bool danger: false
        signal clicked()
        implicitWidth: tbText.implicitWidth + 28
        implicitHeight: 30
        radius: 15
        color: primary ? (tbMouse.containsMouse ? Theme.alpha(Theme.primary, 0.9) : Theme.primary)
             : Theme.alpha(danger ? Theme.error : Theme.surfaceContainerHigh, tbMouse.containsMouse ? 0.95 : 0.6)
        Text {
            id: tbText
            anchors.centerIn: parent
            text: tb.label
            color: tb.primary ? Theme.textOnPrimary : tb.danger ? Theme.error : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
        MouseArea { id: tbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tb.clicked() }
    }

    Text {
        Layout.fillWidth: true
        text: "Show anything in the bar: run a shell command every few seconds (or keep it running) and display its output. Place the module with the layout editor above."
        wrapMode: Text.Wrap
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }

    // ---- existing modules ----
    Repeater {
        model: sec.list
        RowLayout {
            id: mrow
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: mrow.modelData.icon || "󰘳"; color: Theme.primary; font.family: Theme.font; font.pixelSize: 16 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: mrow.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight; Layout.fillWidth: true }
                Text {
                    text: (CustomModules.values[mrow.modelData.id]?.text ?? "…") + "   ·   " + mrow.modelData.command
                    color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            TextBtn { label: "Edit"; onClicked: sec.startEdit(mrow.modelData) }
            TextBtn { label: "Delete"; danger: true; onClicked: sec.remove(mrow.modelData.id) }
        }
    }
    Text {
        visible: sec.list.length === 0 && sec.draft === null
        text: "No custom modules yet."
        color: Theme.outline
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }

    // ---- add ----
    RowLayout {
        visible: sec.draft === null
        Layout.fillWidth: true
        spacing: 8
        TextBtn { label: "󰐕  New module"; primary: true; onClicked: sec.startNew(null) }
    }
    Text {
        visible: sec.draft === null
        text: "Or start from a template:"
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }
    Flow {
        visible: sec.draft === null
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: sec.templates
            TextBtn { required property var modelData; label: modelData.icon + "  " + modelData.name; onClicked: sec.startNew(modelData) }
        }
    }

    // ---- form ----
    ColumnLayout {
        visible: sec.draft !== null
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: sec.isNew ? "New module" : "Edit module"
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
        SettingRow {
            label: "Name"; description: "Shown in the layout editor"
            SettingText { text: sec.draft?.name ?? ""; onSubmitted: t => sec.patch("name", t) }
        }
        SettingRow {
            label: "Icon"; description: "A Nerd Font glyph or emoji (optional)"
            SettingText { implicitWidth: 120; text: sec.draft?.icon ?? ""; onSubmitted: t => sec.patch("icon", t) }
        }
        SettingRow { label: "Command"; description: "Run with sh -c. The last line it prints is shown." }
        SettingText { Layout.fillWidth: true; placeholder: "e.g. date +%H:%M"; text: sec.draft?.command ?? ""; onSubmitted: t => sec.patch("command", t) }
        SettingRow { label: "Runs" }
        Segmented {
            current: sec.draft?.mode ?? "interval"
            onPicked: v => sec.patch("mode", v)
            options: [{ label: "Every few seconds", value: "interval" }, { label: "Live stream (every line updates)", value: "stream" }]
        }
        SettingRow {
            visible: (sec.draft?.mode ?? "interval") === "interval"
            label: "Interval"
            ValueSlider { from: 1; to: 300; stepSize: 1; suffix: " s"; value: sec.draft?.interval ?? 5; onMoved: v => sec.patch("interval", v) }
        }
        SettingRow {
            label: "Output is JSON"; description: "Lines like {\"text\":\"5\",\"icon\":\"󰁹\",\"tint\":\"error\"}"
            Toggle { checked: sec.draft?.json ?? false; onToggled: v => sec.patch("json", v) }
        }
        SettingRow { label: "Color"; description: "Of the icon" }
        Segmented {
            current: sec.draft?.tint ?? "primary"
            onPicked: v => sec.patch("tint", v)
            options: [{ label: "Primary", value: "primary" }, { label: "Secondary", value: "secondary" }, { label: "Tertiary", value: "tertiary" },
                      { label: "Red", value: "error" }, { label: "Text", value: "none" }]
        }
        SettingRow {
            label: "Max width"; description: "Longer text is cut off with …"
            ValueSlider { from: 40; to: 600; stepSize: 10; suffix: " px"; value: sec.draft?.maxWidth ?? 220; onMoved: v => sec.patch("maxWidth", v) }
        }
        SettingRow {
            label: "Hide when empty"
            Toggle { checked: sec.draft?.hideWhenEmpty ?? false; onToggled: v => sec.patch("hideWhenEmpty", v) }
        }

        Text { text: "Actions (shell commands, all optional)"; color: Theme.subtext; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
        Repeater {
            model: [{ k: "onClick", l: "Left click" }, { k: "onRightClick", l: "Right click" }, { k: "onMiddleClick", l: "Middle click" },
                    { k: "onScrollUp", l: "Scroll up" }, { k: "onScrollDown", l: "Scroll down" }]
            RowLayout {
                id: arow
                required property var modelData
                Layout.fillWidth: true
                spacing: 12
                Text { Layout.preferredWidth: 90; text: arow.modelData.l; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                SettingText {
                    Layout.fillWidth: true
                    placeholder: "command"
                    text: sec.draft ? (sec.draft[arow.modelData.k] ?? "") : ""
                    onSubmitted: t => sec.patch(arow.modelData.k, t)
                }
            }
        }

        // test output
        Rectangle {
            Layout.fillWidth: true
            visible: sec.testOut !== ""
            implicitHeight: outText.implicitHeight + 16
            radius: 10
            color: Theme.alpha(Theme.surfaceContainerHigh, 0.7)
            Text {
                id: outText
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                text: sec.testOut
                wrapMode: Text.WrapAnywhere
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
        RowLayout {
            spacing: 8
            TextBtn { label: "󰐊  Test command"; onClicked: { sec.testOut = "running…"; test.running = false; test.running = true; testKill.restart(); } }
            TextBtn { label: isNewLabel; primary: true; readonly property string isNewLabel: sec.isNew ? "Add module" : "Save"; onClicked: sec.save() }
            TextBtn { label: "Cancel"; onClicked: sec.draft = null }
        }
    }

    Process {
        id: test
        command: ["sh", "-c", sec.draft?.command ?? "true"]
        stdout: StdioCollector {
            onStreamFinished: sec.testOut = text.trim() === "" ? "(no output)" : text.trim().split("\n").slice(-4).join("\n")
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") sec.testOut = (sec.testOut === "running…" ? "" : sec.testOut + "\n") + "stderr: " + text.trim().split("\n")[0]
        }
    }
    // streaming commands never finish: stop the test after 4 s
    Timer { id: testKill; interval: 4000; onTriggered: if (test.running) { test.running = false; if (sec.testOut === "running…") sec.testOut = "(still running after 4 s; fine for a stream)"; } }
}
