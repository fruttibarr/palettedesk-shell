import qs.services
import QtQuick
import QtQuick.Layouts

// Card grouping related settings under a small heading.
// Look: uiCardStyle (filled | outlined | flat | stripe | glass), uiCardRadius, uiSectionTitle (caps | plain | line), uiDensity.
Rectangle {
    id: sec
    property string title
    readonly property bool isSettingSection: true
    default property alias content: col.data
    readonly property string look: Settings.s.uiCardStyle
    readonly property string dens: Settings.s.uiDensity
    readonly property int pad: dens === "compact" ? 12 : dens === "roomy" ? 24 : 18
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + pad * 2
    radius: Settings.s.uiCardRadius
    color: look === "flat" || look === "outlined" ? "transparent" : Theme.alpha(Theme.surfaceContainerHigh, look === "glass" ? 0.22 : 0.4)
    border.width: look === "flat" ? 0 : 1
    border.color: look === "outlined" ? Theme.alpha(Theme.outline, 0.4) : Theme.alpha(Theme.primary, look === "glass" ? 0.22 : 0.08)

    Rectangle {   // glass: soft sheen from the top
        visible: sec.look === "glass"
        anchors { fill: parent; margins: 1 }
        radius: sec.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.text, 0.07) }
            GradientStop { position: 0.6; color: "transparent" }
        }
    }
    Rectangle {   // stripe: accent bar on the left edge
        visible: sec.look === "stripe"
        x: 0; y: sec.radius * 0.6
        width: 4; height: sec.height - sec.radius * 1.2
        radius: 2
        color: Theme.primary
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: sec.pad }
        anchors.leftMargin: sec.pad + (sec.look === "stripe" ? 4 : 0)
        spacing: sec.dens === "compact" ? 10 : sec.dens === "roomy" ? 22 : 16

        RowLayout {
            Layout.fillWidth: true
            visible: sec.title !== ""
            spacing: 10
            Text {
                text: Settings.s.uiSectionTitle === "caps" || Settings.s.uiSectionTitle === "line" ? sec.title.toUpperCase() : sec.title
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: Settings.s.uiSectionTitle === "plain" ? Theme.fontSize + 1 : Theme.fontSize - 3
                font.weight: Font.Bold
                font.letterSpacing: Settings.s.uiSectionTitle === "plain" ? 0 : 1.2
            }
            Rectangle {
                visible: Settings.s.uiSectionTitle === "line"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 1
                color: Theme.alpha(Theme.primary, 0.3)
            }
        }
    }
}
