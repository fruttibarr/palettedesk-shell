import qs.services
import QtQuick
import QtQuick.Layouts

// Drag-and-drop bar layout editor: a miniature bar (Left | Center | Right) plus a "Not in bar" tray.
// Drag a chip to move it between zones or reorder it; a caret shows where it will land.
// Keyboard: focus a chip (Tab / click) then ←/→ reorder, ↑/↓ change zone, Delete removes it from the bar.
Item {
    id: ed
    property var catalog: []                       // [{ id, icon, name, short }]
    property var layout: ({ left: [], center: [], right: [] })
    signal layoutEdited(var layout)
    signal moduleClicked(string id)

    readonly property var zoneKeys: ["left", "center", "right", "hidden"]
    readonly property var zoneNames: ({ left: "Left", center: "Center", right: "Right", hidden: "Not in bar" })

    // ---- drag state ----
    property string dragId: ""
    property string dropZone: ""
    property int dropIndex: 0
    property point ghostPos: Qt.point(0, 0)
    readonly property bool dragging: dragId !== ""

    function meta(id) { return catalog.find(c => c.id === id) ?? { id: id, icon: "󰘳", name: id, short: id }; }

    // Full zone contents including modules that are hidden (= in no zone).
    function zoneList(z) {
        const L = layout ?? {};
        if (z !== "hidden") return [...(L[z] ?? [])].filter(id => catalog.some(c => c.id === id));
        const used = [...(L.left ?? []), ...(L.center ?? []), ...(L.right ?? [])];
        return catalog.map(c => c.id).filter(id => !used.includes(id));
    }
    function zoneOf(id) {
        for (const z of zoneKeys) if (zoneList(z).includes(id)) return z;
        return "hidden";
    }
    // What a zone shows right now: the real list, with a caret inserted while dragging over it.
    function shownList(z) {
        const base = zoneList(z);
        if (!dragging || dropZone !== z) return base;
        const rest = base.filter(id => id !== dragId);
        const i = Math.max(0, Math.min(rest.length, dropIndex));
        // keep the dragged chip in place (dimmed) so its mouse grab survives; insert the caret before the i-th other chip
        const out = [];
        let k = 0, placed = false;
        for (const id of base) {
            if (id === dragId) { out.push(id); continue; }
            if (k === i && !placed) { out.push("__caret"); placed = true; }
            out.push(id); k++;
        }
        if (!placed) out.push("__caret");
        return out;
    }

    function commit(id, zone, index) {
        const L = { left: zoneList("left"), center: zoneList("center"), right: zoneList("right") };
        for (const z of ["left", "center", "right"]) L[z] = L[z].filter(x => x !== id);
        if (zone !== "hidden") {
            const i = Math.max(0, Math.min(L[zone].length, index));
            L[zone].splice(i, 0, id);
        }
        layoutEdited(L);
    }
    function shift(id, dir) {
        const z = zoneOf(id);
        if (z === "hidden") return;
        const arr = zoneList(z), i = arr.indexOf(id), j = i + dir;
        if (j < 0 || j >= arr.length) return;
        commit(id, z, j);
    }
    function shiftZone(id, dir) {
        const z = zoneOf(id), zi = zoneKeys.indexOf(z) + dir;
        if (zi < 0 || zi >= zoneKeys.length) return;
        commit(id, zoneKeys[zi], 9999);
    }

    // Which zone / slot is under (x, y) in editor coordinates.
    function hitTest(x, y) {
        let best = "", bestD = 1e9;
        for (let n = 0; n < zoneKeys.length; n++) {
            const box = boxFor(n);
            if (!box) continue;
            const p = box.mapToItem(ed, 0, 0);
            const dx = x < p.x ? p.x - x : x > p.x + box.width ? x - p.x - box.width : 0;
            const dy = y < p.y ? p.y - y : y > p.y + box.height ? y - p.y - box.height : 0;
            const d = dx * dx + dy * dy * 4;
            if (d < bestD) { bestD = d; best = zoneKeys[n]; }
        }
        if (best === "") return;
        dropZone = best;
        // slot = number of other chips that sit before the pointer
        const box = boxFor(zoneKeys.indexOf(best));
        const items = box.chipItems();
        let k = 0, slot = 0;
        for (const it of items) {
            if (it.moduleId === dragId || it.moduleId === "__caret") continue;
            const c = it.mapToItem(ed, it.width / 2, it.height / 2);
            const top = it.mapToItem(ed, 0, 0).y, bottom = top + it.height;
            const before = y > bottom || (y >= top && x > c.x);
            if (before) slot = k + 1;
            k++;
        }
        dropIndex = slot;
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right }
        spacing: 10

        // The mini bar: three zones
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                id: zoneBoxes
                model: ["left", "center", "right"]
                delegate: ZoneBox {
                    required property string modelData
                    zone: modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: modelData === "center" ? 2 : 3
                    Layout.alignment: Qt.AlignTop
                }
            }
        }
    }

    // Floating chip following the pointer
    Rectangle {
        id: ghost
        visible: ed.dragging
        z: 100
        x: ed.ghostPos.x - width / 2
        y: ed.ghostPos.y - height / 2
        width: ghostRow.implicitWidth + 20
        height: 28
        radius: 14
        color: Theme.primaryContainer
        border.width: 1
        border.color: Theme.primary
        opacity: 0.92
        Row {
            id: ghostRow
            anchors.centerIn: parent
            spacing: 6
            Text { text: ed.meta(ed.dragId).icon; color: Theme.primary; font.family: Theme.font; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
            Text { text: ed.meta(ed.dragId).short; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------------- parts ----------------
    component ZoneBox: Rectangle {
        id: box
        property string zone
        readonly property bool active: ed.dragging && ed.dropZone === zone
        function chipItems() { const r = []; for (let i = 0; i < rep.count; i++) { const it = rep.itemAt(i); if (it) r.push(it); } return r; }
        implicitHeight: zcol.implicitHeight + 16
        radius: 12
        color: Theme.alpha(Theme.surfaceContainerHigh, active ? 0.75 : 0.35)
        border.width: 1
        border.color: active ? Theme.primary : Theme.alpha(Theme.outline, zone === "hidden" ? 0.5 : 0.3)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            id: zcol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 6
            Text {
                text: ed.zoneNames[box.zone]
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }
            Flow {
                id: flow
                Layout.fillWidth: true
                Layout.minimumHeight: 30
                spacing: 6
                move: Transition { NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic } }
                Repeater {
                    id: rep
                    model: ed.shownList(box.zone)
                    delegate: Item {
                        id: cell
                        required property string modelData
                        readonly property string moduleId: modelData
                        readonly property bool isCaret: modelData === "__caret"
                        readonly property bool isDragged: ed.dragId === modelData
                        width: isCaret ? 3 : chipBody.implicitWidth
                        height: 30
                        activeFocusOnTab: !isCaret
                        Keys.onLeftPressed: ed.shift(modelData, -1)
                        Keys.onRightPressed: ed.shift(modelData, 1)
                        Keys.onUpPressed: ed.shiftZone(modelData, -1)
                        Keys.onDownPressed: ed.shiftZone(modelData, 1)
                        Keys.onDeletePressed: ed.commit(modelData, "hidden", 0)

                        Rectangle {   // insertion caret
                            visible: cell.isCaret
                            anchors.fill: parent
                            radius: 1.5
                            color: Theme.primary
                        }
                        Rectangle {
                            id: chipBody
                            visible: !cell.isCaret
                            implicitWidth: crow.implicitWidth + 20
                            width: implicitWidth
                            height: parent.height
                            radius: 15
                            opacity: cell.isDragged ? 0.3 : 1
                            color: Theme.alpha(box.zone === "hidden" ? Theme.surfaceContainerHigh : Theme.primaryContainer,
                                               chipMouse.containsMouse ? 0.95 : (box.zone === "hidden" ? 0.55 : 0.75))
                            border.width: cell.activeFocus ? 2 : 1
                            border.color: cell.activeFocus ? Theme.primary : Theme.alpha(Theme.primary, box.zone === "hidden" ? 0.1 : 0.3)
                            Row {
                                id: crow
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: ed.meta(cell.modelData).icon; color: box.zone === "hidden" ? Theme.outline : Theme.primary; font.family: Theme.font; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: ed.meta(cell.modelData).short; color: box.zone === "hidden" ? Theme.subtext : Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: ed.dragging && cell.isDragged ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                property point pressAt
                                property bool moved: false
                                onPressed: m => { cell.forceActiveFocus(); pressAt = Qt.point(m.x, m.y); moved = false; }
                                onPositionChanged: m => {
                                    if (!pressed || !(m.buttons & Qt.LeftButton)) return;
                                    const p = mapToItem(ed, m.x, m.y);
                                    if (!moved && Math.hypot(m.x - pressAt.x, m.y - pressAt.y) < 6) return;
                                    moved = true;
                                    ed.dragId = cell.modelData;
                                    ed.ghostPos = p;
                                    ed.hitTest(p.x, p.y);
                                }
                                onReleased: m => {
                                    if (m.button === Qt.RightButton) { ed.commit(cell.modelData, "hidden", 0); return; }
                                    if (moved && ed.dragging) {
                                        const id = ed.dragId, z = ed.dropZone, i = ed.dropIndex;
                                        ed.dragId = ""; ed.dropZone = "";
                                        ed.commit(id, z, i);
                                    } else if (!moved) {
                                        ed.moduleClicked(cell.modelData);
                                    }
                                    moved = false;
                                }
                                onCanceled: { ed.dragId = ""; ed.dropZone = ""; moved = false; }
                            }
                        }
                    }
                }
                Text {
                    visible: rep.count === 0
                    text: box.zone === "hidden" ? "Everything is in the bar" : "Drop modules here"
                    color: Theme.outline
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    height: 30
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // "Not in bar" tray + hint, below the three zones
    Column {
        id: trayCol
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: col.implicitHeight + 10 }
        spacing: 8
        ZoneBox {
            id: trayBox
            width: parent.width
            zone: "hidden"
        }
        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "Drag modules between zones or into “Not in bar”. Click a module to jump to its settings. Keyboard: ←/→ reorder, ↑/↓ change zone, Delete removes. Right-click also removes."
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
    }
    implicitHeight: col.implicitHeight + 10 + trayCol.implicitHeight

    function boxFor(n) { return zoneKeys[n] === "hidden" ? trayBox : zoneBoxes.itemAt(n); }
}
