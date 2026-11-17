import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// PaletteDesk login screen. Colours and the blurred wallpaper come from theme.conf(.user), which
// `palettedesk sddm sync` keeps up to date through a small privileged helper.
Rectangle {
    id: root
    width: 1280; height: 720
    readonly property color surface: config.surface || "#141318"
    readonly property color fg: config.onSurface || "#e6e1e9"
    readonly property color primary: config.primary || "#cbbeff"
    readonly property color fgOnPrimary: config.onPrimary || "#32275f"
    readonly property color container: config.container || "#211f25"
    color: surface

    Image {
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: root.surface; opacity: 0.55 }

    property string message: ""
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    Connections {
        target: sddm
        function onLoginFailed() { root.message = "Wrong password"; pw.text = ""; pw.forceActiveFocus(); }
        function onLoginSucceeded() { root.message = ""; }
    }

    Text {
        id: clock
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
        color: root.fg; font.pixelSize: 84; font.weight: Font.Light
        text: Qt.formatTime(new Date(), "hh:mm")
        Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm") }
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: clock.bottom }
        color: root.primary; font.pixelSize: 20
        text: Qt.formatDate(new Date(), "dddd, d MMMM")
    }

    Rectangle {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        width: 360; height: 220; radius: 20
        color: Qt.rgba(root.container.r, root.container.g, root.container.b, 0.85)
        border.width: 1; border.color: Qt.rgba(root.primary.r, root.primary.g, root.primary.b, 0.5)
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 12
            TextField {
                id: user
                Layout.fillWidth: true
                text: userModel.lastUser
                placeholderText: "User"
                placeholderTextColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)
                color: root.fg
                background: Rectangle { radius: 10; color: Qt.rgba(1, 1, 1, 0.06); border.width: user.activeFocus ? 2 : 0; border.color: root.primary }
                KeyNavigation.tab: pw
            }
            TextField {
                id: pw
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)
                color: root.fg
                focus: true
                background: Rectangle { radius: 10; color: Qt.rgba(1, 1, 1, 0.06); border.width: pw.activeFocus ? 2 : 0; border.color: root.primary }
                Keys.onReturnPressed: sddm.login(user.text, pw.text, root.sessionIndex)
                Keys.onEnterPressed: sddm.login(user.text, pw.text, root.sessionIndex)
            }
            Text { Layout.fillWidth: true; color: "#ffb4ab"; text: root.message; visible: root.message !== ""; horizontalAlignment: Text.AlignHCenter }
            Button {
                Layout.fillWidth: true
                text: "Log in"
                onClicked: sddm.login(user.text, pw.text, root.sessionIndex)
                contentItem: Text { text: parent.text; color: root.fgOnPrimary; horizontalAlignment: Text.AlignHCenter; font.weight: Font.Bold }
                background: Rectangle { radius: 10; color: root.primary }
            }
        }
    }

    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
        spacing: 12
        Button { text: "Reboot"; visible: sddm.canReboot; onClicked: sddm.reboot() }
        Button { text: "Power off"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }
    Component.onCompleted: pw.forceActiveFocus()
}
