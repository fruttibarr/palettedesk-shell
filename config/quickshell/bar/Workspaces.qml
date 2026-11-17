import Quickshell
import Quickshell.Hyprland
import qs.services
import QtQuick

// Workspaces with a "liquid" indicator (leading edge moves first).
// Settings: wsCount, wsStyle (numbers / dots / roman / kanji), wsShowEmpty,
// wsOpacity (chip background, applied in Bar.qml), wsActiveOpacity (the indicator pill).
Item {
    id: root

    readonly property string style: Settings.s.wsStyle
    readonly property int activeId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    readonly property var occupied: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.id < 100 && w.toplevels.values.length > 0)
        .map(w => w.id)
    readonly property var ids: {
        let n = Settings.s.wsCount;
        for (const id of occupied) n = Math.max(n, id);
        if (activeId > 0 && activeId < 100) n = Math.max(n, activeId);
        const list = [];
        for (let i = 1; i <= n; i++)
            if (Settings.s.wsShowEmpty || i === activeId || occupied.includes(i)) list.push(i);
        return list;
    }

    readonly property int cell: style === "dots" ? 16 : 22
    readonly property int gap: style === "dots" ? 6 : 4
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    function label(id) {
        if (style === "dots") return "";
        if (style === "kanji") return kanji[id - 1] ?? String(id);
        if (style === "roman") {
            const r = [["X", 10], ["IX", 9], ["V", 5], ["IV", 4], ["I", 1]];
            let n = id, out = "";
            for (const [s, v] of r) while (n >= v) { out += s; n -= v; }
            return out;
        }
        return String(id);
    }
    function xOf(id) { return Math.max(0, (ids ?? []).indexOf(id)) * (cell + gap); }

    implicitWidth: ids.length * cell + Math.max(0, ids.length - 1) * gap
    implicitHeight: 22

    // indicator edges, animated separately for the stretch effect
    property real edgeL: 0
    property real edgeR: cell
    property int lastId: activeId
    function place(animate) {
        const goingRight = activeId > lastId;
        leftAnim.duration = !animate ? 0 : goingRight ? 420 : 240;
        rightAnim.duration = !animate ? 0 : goingRight ? 240 : 420;
        edgeL = xOf(activeId);
        edgeR = xOf(activeId) + cell;
        lastId = activeId;
    }
    onActiveIdChanged: place(true)
    onIdsChanged: place(true)
    onCellChanged: place(false)
    Component.onCompleted: place(false)
    Behavior on edgeL { NumberAnimation { id: leftAnim; easing.type: Easing.OutCubic } }
    Behavior on edgeR { NumberAnimation { id: rightAnim; easing.type: Easing.OutCubic } }

    Rectangle {
        x: root.edgeL
        width: root.edgeR - root.edgeL
        height: root.style === "dots" ? root.cell : 22
        anchors.verticalCenter: parent.verticalCenter
        radius: Settings.s.chipShape === "square" ? 3 : height / 2
        color: Theme.alpha(Theme.primary, Settings.s.wsActiveOpacity)
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    Repeater {
        model: root.ids

        Item {
            id: cellItem
            required property int modelData
            readonly property int wsId: modelData
            readonly property bool active: root.activeId === wsId
            readonly property bool isOccupied: root.occupied.includes(wsId)

            x: root.xOf(wsId)
            width: root.cell
            height: 22
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Rectangle {   // hover glow
                anchors.centerIn: parent
                width: root.cell; height: root.style === "dots" ? root.cell : 22
                radius: height / 2
                color: Theme.primary
                opacity: mouse.containsMouse && !cellItem.active ? 0.2 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // dots style
            Rectangle {
                visible: root.style === "dots" && !cellItem.active
                anchors.centerIn: parent
                width: 6; height: 6; radius: 3
                color: cellItem.isOccupied ? Theme.textOnPrimaryContainer : "transparent"
                border.width: cellItem.isOccupied ? 0 : 1.2
                border.color: Theme.alpha(Theme.textOnPrimaryContainer, 0.5)
            }

            // text styles
            Text {
                visible: root.style !== "dots"
                anchors.centerIn: parent
                anchors.verticalCenterOffset: cellItem.isOccupied && !cellItem.active ? -1.5 : 0
                text: root.label(cellItem.wsId)
                color: cellItem.active ? (Settings.s.wsActiveOpacity < 0.5 ? Theme.textOnPrimaryContainer : Theme.textOnPrimary)
                     : cellItem.isOccupied ? Theme.textOnPrimaryContainer
                     : Theme.alpha(Theme.textOnPrimaryContainer, 0.4)
                font.family: Theme.font
                font.pixelSize: root.style === "roman" && text.length > 2 ? Theme.fontSize - 5 : Theme.fontSize - 2
                font.weight: cellItem.active ? Font.Black : Font.DemiBold
                scale: cellItem.active ? 1.1 : 1
                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 200 } }
            }
            Rectangle {   // "has windows" dot under numbers
                visible: root.style !== "dots"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: 3; height: 3; radius: 1.5
                color: Theme.textOnPrimaryContainer
                opacity: cellItem.isOccupied && !cellItem.active ? 0.8 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${cellItem.wsId} })`)
            }
        }
    }

    WheelHandler {
        onWheel: e => Hyprland.dispatch(`hl.dsp.focus({ workspace = "e${e.angleDelta.y > 0 ? "-" : "+"}1" })`)
    }
}
