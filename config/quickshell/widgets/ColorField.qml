import qs.services
import QtQuick
import QtQuick.Layouts

// Hex color field with a swatch that opens an inline picker (saturation/value square + hue bar).
// `value` is "#rrggbb" (or "" when allowEmpty). Emits picked() when a color is committed:
// on mouse release, on Enter in the hex box, or on Clear. Dragging only previews inside the picker,
// so a drag doesn't re-theme the whole shell on every frame.
ColumnLayout {
    id: cf
    property string value
    property string placeholder: "#rrggbb"
    property bool allowEmpty: false
    signal picked(string hex)

    spacing: 8
    property bool open: false
    property real hue: 0
    property real sat: 0
    property real val: 1
    readonly property bool valid: Theme.validHex(value)
    readonly property color current: Qt.hsva(hue, sat, val, 1)

    function sync() {   // load value into the hsv state (never while dragging)
        if (!Theme.validHex(value)) return;
        const c = Qt.color(value.trim());
        hue = c.hsvHue < 0 ? hue : c.hsvHue;   // greys have no hue: keep the last one
        sat = c.hsvSaturation; val = c.hsvValue;
    }
    function hex() {
        const c = current, h = n => ("0" + Math.round(n * 255).toString(16)).slice(-2);
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }
    onValueChanged: if (!dragging) sync()
    Component.onCompleted: sync()
    property bool dragging: false
    function commit() { dragging = false; picked(hex()); }

    RowLayout {
        spacing: 8
        Rectangle {
            id: swatch
            width: 34; height: 34; radius: 10
            color: cf.valid ? cf.value : "transparent"
            border.width: cf.open ? 2 : 1
            border.color: cf.open ? Theme.primary : Theme.outline
            Text {
                anchors.centerIn: parent
                visible: !cf.valid
                text: "󰏘"; color: Theme.outline
                font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cf.open = !cf.open }
        }
        SettingText {
            implicitWidth: 130
            text: cf.value; placeholder: cf.placeholder
            onSubmitted: t => {
                const v = t.trim().toLowerCase();
                if (Theme.validHex(v) || (cf.allowEmpty && v === "")) cf.picked(v);
            }
        }
        Text {
            visible: cf.allowEmpty && cf.value !== ""
            text: "Clear"; color: Theme.primary
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: cf.picked("") }
        }
    }

    Item {
        visible: cf.open
        implicitWidth: 240; implicitHeight: 190
        Layout.preferredWidth: 240; Layout.preferredHeight: visible ? 190 : 0

        Rectangle {   // saturation / value square
            id: sv
            x: 0; y: 0; width: 240; height: 150; radius: 8; clip: true
            color: Qt.hsva(cf.hue, 1, 1, 1)
            Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ffffff" } GradientStop { position: 1; color: "#00ffffff" } } }
            Rectangle { anchors.fill: parent; gradient: Gradient {
                GradientStop { position: 0; color: "#00000000" } GradientStop { position: 1; color: "#000000" } } }
            Rectangle {
                x: cf.sat * sv.width - 8; y: (1 - cf.val) * sv.height - 8; width: 16; height: 16; radius: 8
                color: cf.current; border.width: 2; border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                function set(m) { cf.sat = Math.max(0, Math.min(1, m.x / width)); cf.val = 1 - Math.max(0, Math.min(1, m.y / height)); }
                onPressed: m => { cf.dragging = true; set(m); }
                onPositionChanged: m => set(m)
                onReleased: cf.commit()
            }
        }
        Rectangle {   // hue bar
            id: hb
            x: 0; y: 160; width: 240; height: 20; radius: 10
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.000; color: "#ff0000" } GradientStop { position: 0.167; color: "#ffff00" }
                GradientStop { position: 0.333; color: "#00ff00" } GradientStop { position: 0.500; color: "#00ffff" }
                GradientStop { position: 0.667; color: "#0000ff" } GradientStop { position: 0.833; color: "#ff00ff" }
                GradientStop { position: 1.000; color: "#ff0000" } }
            Rectangle {
                x: cf.hue * (hb.width - 8) ; y: -2; width: 8; height: 24; radius: 4
                color: Qt.hsva(cf.hue, 1, 1, 1); border.width: 2; border.color: "white"
            }
            MouseArea {
                anchors.fill: parent
                function set(m) { cf.hue = Math.max(0, Math.min(1, (m.x - 4) / (width - 8))); }
                onPressed: m => { cf.dragging = true; set(m); }
                onPositionChanged: m => set(m)
                onReleased: cf.commit()
            }
        }
    }
}
