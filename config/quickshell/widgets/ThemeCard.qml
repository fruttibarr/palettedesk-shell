import Quickshell
import Quickshell.Widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// One theme: wallpaper thumbnail with a tiny sketch of its bar and window layout on top
Rectangle {
    id: tc
    required property var modelData
    readonly property var p: modelData
    readonly property bool active: Presets.activeName === p.name
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 10
    implicitHeight: tcCol.implicitHeight + 16
    radius: 14
    color: Theme.alpha(Theme.surfaceContainerHigh, tcMouse.containsMouse ? 0.85 : 0.5)
    border.width: active ? 2 : 1
    border.color: active ? Theme.primary : Theme.alpha(Theme.primary, tcMouse.containsMouse ? 0.45 : 0.1)
    scale: tcMouse.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 140 } }
    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    MouseArea {
        id: tcMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Presets.apply(tc.p)
    }

    ColumnLayout {
        id: tcCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        spacing: 8

        ClippingRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * 0.56)
            radius: 9
            color: Theme.surfaceContainer

            Image {
                id: tcThumb
                property bool thumbFailed: false
                anchors.fill: parent
                source: "file://" + (thumbFailed ? (tc.p.still || tc.p.wallpaper) : Presets.thumbDir + Qt.md5(tc.p.wallpaper) + ".jpg")
                sourceSize.width: 400
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                onStatusChanged: if (status === Image.Error && !thumbFailed) thumbFailed = true
            }
            Text {
                anchors.centerIn: parent
                visible: tcThumb.status !== Image.Ready
                text: "󰋩"
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: 26
            }

            // ---- sketch of the layout ----
            Item {
                id: mock
                anchors.fill: parent
                readonly property var v: tc.p.values
                readonly property bool atBottom: v.barPosition === "bottom"
                readonly property bool attached: v.barStyle === "attached"
                readonly property bool islands: v.barStyle === "islands"
                readonly property int barH: 9
                readonly property int barM: attached ? 0 : 4
                readonly property real chipR: v.chipShape === "pill" ? barH / 2 : v.chipShape === "rounded" ? 2.5 : 0
                readonly property int gap: Math.round(v.gapsOut / 2.5)
                readonly property int inner: Math.round(v.gapsIn / 2.5) * 2
                readonly property color ink: tc.p.colors[1] ?? "#ffffff"
                readonly property bool light: (v.colorMode ?? "dark") === "light"
                readonly property string effect: v.chipEffect ?? "none"
                readonly property string edge: v.barEdge ?? "none"
                readonly property color glass: light ? Qt.rgba(0.95, 0.94, 0.92, 0.3 + 0.6 * v.barOpacity) : Qt.rgba(0.04, 0.04, 0.06, 0.3 + 0.6 * v.barOpacity)
                readonly property var zones: [v.barLayout.left ?? [], v.barLayout.center ?? [], v.barLayout.right ?? []]

                Item {
                    id: mockBar
                    x: mock.barM
                    y: mock.atBottom ? parent.height - height - mock.barM : mock.barM
                    width: parent.width - mock.barM * 2
                    height: mock.barH
                    Rectangle {
                        anchors.fill: parent
                        visible: !mock.islands
                        radius: mock.attached ? 0 : Math.min(mock.barH / 2, mock.v.shellRadius / 2.5)
                        color: mock.glass
                        border.width: mock.v.barBorder && !mock.attached ? 1 : 0
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                    }
                    Rectangle {   // accent edge (barEdge)
                        visible: mock.edge !== "none"
                        anchors { left: parent.left; right: parent.right; leftMargin: mock.attached ? 0 : 3; rightMargin: mock.attached ? 0 : 3 }
                        y: mock.atBottom ? 0 : parent.height - height
                        height: Math.max(1, Math.round((mock.v.barEdgeWidth ?? 2) / 1.5))
                        color: mock.ink
                    }
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            readonly property int n: mock.zones[index].length
                            visible: n > 0
                            width: 8 + n * 9
                            height: mock.islands ? mock.barH : mock.barH - 4
                            radius: mock.islands ? mock.chipR : Math.min(height / 2, mock.chipR)
                            y: (mock.barH - height) / 2
                            x: index === 0 ? (mock.islands ? 0 : 3) : index === 1 ? (mockBar.width - width) / 2 : mockBar.width - width - (mock.islands ? 0 : 3)
                            color: mock.islands ? mock.glass : mock.v.chipStyle === "filled" ? Qt.rgba(1, 1, 1, 0.28) : "transparent"
                            border.width: mock.islands || mock.v.chipStyle !== "filled" ? 1 : 0
                            border.color: mock.effect === "neon" || mock.effect === "bracket" ? mock.ink : Qt.rgba(1, 1, 1, mock.v.chipStyle === "flat" && !mock.islands ? 0.3 : 0.45)
                            Rectangle {   // neon halo / underline effects
                                visible: mock.effect === "neon" || mock.effect === "underline"
                                anchors.fill: mock.effect === "neon" ? parent : undefined
                                anchors.margins: -1
                                x: 2; width: parent.width - 4; height: 1; y: parent.height - 2
                                radius: parent.radius
                                color: mock.effect === "neon" ? "transparent" : mock.ink
                                border.width: mock.effect === "neon" ? 1 : 0
                                border.color: Qt.alpha(mock.ink, 0.5)
                            }
                        }
                    }
                }

                Item {
                    id: mockArea
                    readonly property int reserved: mock.barM + mock.barH + mock.gap
                    x: mock.gap
                    width: parent.width - mock.gap * 2
                    y: mock.atBottom ? mock.gap : reserved
                    height: parent.height - reserved - mock.gap
                    readonly property var wins: {
                        const W = width, H = height, g = mock.inner;
                        if (mock.v.layout === "scrolling") {
                            const c = Math.round(W * 0.46);
                            return [[0, 0, c, H], [c + g, 0, c, H], [2 * (c + g), 0, c, H]];
                        }
                        const m = Math.round(W * (mock.v.layout === "master" ? 0.62 : 0.5));
                        return [[0, 0, m - g / 2, H], [m + g / 2, 0, W - m - g / 2, (H - g) / 2], [m + g / 2, (H + g) / 2, W - m - g / 2, (H - g) / 2]];
                    }
                    Repeater {
                        model: mockArea.wins
                        Rectangle {
                            required property var modelData
                            required property int index
                            x: modelData[0]; y: modelData[1]; width: modelData[2]; height: modelData[3]
                            radius: mock.v.rounding / 2.5
                            color: Qt.rgba(0.05, 0.05, 0.07, 0.25 + 0.5 * mock.v.terminalOpacity)
                            opacity: index > 0 && mock.v.dimInactive ? 0.75 : 1
                            border.width: Math.max(1, Math.round(mock.v.borderSize / 1.5))
                            border.color: index === 0 ? mock.ink : Qt.rgba(1, 1, 1, 0.22)
                            Rectangle {   // glow around the focused window
                                visible: index === 0 && (mock.v.glowEnabled ?? false)
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: parent.radius + 2
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.alpha(mock.ink, 0.35)
                            }
                        }
                    }
                }
            }

            Rectangle {   // "new" tag
                visible: !!tc.p.isNew
                anchors { top: parent.top; left: parent.left; leftMargin: 6; topMargin: mock.atBottom ? 6 : 18 }
                width: newLbl.implicitWidth + 10; height: 15; radius: 8
                color: Theme.alpha(Theme.tertiary, 0.92)
                Text { id: newLbl; anchors.centerIn: parent; text: "NEW"; color: Theme.surface; font.family: Theme.font; font.pixelSize: 9; font.weight: Font.Bold }
            }
            Rectangle {
                visible: tc.active
                anchors { top: parent.top; right: parent.right; rightMargin: 6; topMargin: mock.atBottom ? 6 : 18 }
                width: activeLbl.implicitWidth + 14
                height: 18
                radius: 9
                color: Theme.primary
                Text {
                    id: activeLbl
                    anchors.centerIn: parent
                    text: "󰄬 Active"
                    color: Theme.textOnPrimary
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 4
                    font.weight: Font.Bold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 2
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: (tc.p.icon ? tc.p.icon + "  " : tc.p.auto ? "󰕌  " : "󰋑  ") + tc.p.name
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }
            Row {
                spacing: -3
                Repeater {
                    model: tc.p.colors ?? []
                    Rectangle {
                        required property string modelData
                        width: 13; height: 13; radius: 7
                        color: modelData
                        border.width: 1
                        border.color: Theme.alpha(Theme.surface, 0.9)
                    }
                }
            }
            Rectangle {   // delete (your own themes only)
                visible: !tc.p.builtin
                implicitWidth: 22; implicitHeight: 22; radius: 11
                color: Theme.alpha(Theme.error, delMouse.containsMouse ? 0.3 : 0)
                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: delMouse.containsMouse ? Theme.error : Theme.outline
                    font.family: Theme.font
                    font.pixelSize: 12
                }
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Presets.remove(tc.p.name)
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 2
            text: tc.p.builtin ? tc.p.description
                : tc.p.auto ? "Saved automatically before you switched themes"
                : tc.p.wallpaper.split("/").pop()
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
        }
    }
}
