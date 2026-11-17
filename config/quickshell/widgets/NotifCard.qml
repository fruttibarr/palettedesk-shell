import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import QtQuick
import QtQuick.Layouts

// One notification. `popup: true` = on-screen toast (auto-expires, pauses
// on hover); false = entry in the control center history.
Rectangle {
    id: card
    property Notification notif
    property bool popup: true
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string icon: notif ? Notifs.iconFor(notif) : ""
    readonly property var buttons: notif ? notif.actions.filter(a => a.identifier !== "default") : []
    signal expired()

    implicitHeight: layout.implicitHeight + 24
    radius: Settings.s.notifRadius
    readonly property string accentMode: Settings.s.notifAccent   // left | top | none
    color: popup ? Theme.alpha(Theme.surface, Math.min(1, Theme.panelOpacity + 0.2)) : Theme.alpha(Theme.surfaceContainerHigh, hover.hovered ? 0.8 : 0.55)
    border.width: popup || critical ? 1 : 0
    border.color: critical ? Theme.error : Theme.alpha(Theme.primary, 0.35)

    HoverHandler { id: hover }

    Timer {
        running: card.popup && Notifs.timeoutFor(card.notif) > 0 && !hover.hovered
        interval: Notifs.timeoutFor(card.notif)
        onTriggered: card.expired()
    }

    // Click = run default action (if any) and dismiss
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const def = card.notif.actions.find(a => a.identifier === "default");
            if (def) def.invoke();
            card.notif.dismiss();
        }
    }

    // Accent stripe
    Rectangle {
        visible: card.accentMode !== "none"
        readonly property bool onTop: card.accentMode === "top"
        x: onTop ? card.radius * 0.7 : 10
        y: onTop ? 0 : 12
        width: onTop ? card.width - card.radius * 1.4 : 3
        height: onTop ? 3 : card.height - 24
        radius: 2
        color: card.critical ? Theme.error : Theme.primary
    }

    // time-left bar (notifProgress), popups only
    Rectangle {
        id: prog
        visible: Settings.s.notifProgress && card.popup && Notifs.timeoutFor(card.notif) > 0
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: card.radius * 0.6; bottomMargin: 0 }
        height: 3
        radius: 2
        color: Theme.alpha(card.critical ? Theme.error : Theme.primary, 0.7)
        readonly property real full: card.width - card.radius * 1.2
        width: full
        NumberAnimation on width {
            id: progAnim
            running: prog.visible && !hover.hovered
            from: prog.full; to: 0
            duration: Math.max(1, Notifs.timeoutFor(card.notif))
        }
    }

    RowLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12; leftMargin: card.accentMode === "left" ? 22 : 14; topMargin: card.accentMode === "top" ? 14 : 12 }
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            visible: card.icon !== ""
            implicitWidth: 40
            implicitHeight: 40
            radius: 10
            color: Theme.alpha(Theme.primaryContainer, 0.8)
            Image {
                anchors.fill: parent
                source: card.icon
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(80, 80)
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notif?.appName || "Notification"
                    elide: Text.ElideRight
                    color: card.critical ? Theme.error : Theme.primary
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "󰅖"
                    color: closeMouse.containsMouse ? Theme.text : Theme.outline
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notif.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.notif?.summary ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 2
                elide: Text.ElideRight
                color: Theme.subtext
                linkColor: Theme.tertiary
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: card.buttons.length > 0
                spacing: 6
                Repeater {
                    model: card.buttons
                    Rectangle {
                        id: actBtn
                        required property NotificationAction modelData
                        implicitWidth: actText.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: actMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.primaryContainer, 0.85)
                        Text {
                            id: actText
                            anchors.centerIn: parent
                            text: actBtn.modelData.text
                            color: actMouse.containsMouse ? Theme.textOnPrimary : Theme.textOnPrimaryContainer
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actBtn.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
