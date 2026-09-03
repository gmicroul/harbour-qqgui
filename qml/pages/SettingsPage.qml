import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property var ob: null
    property var hub: null

    GlassBackground { anchors.fill: parent }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + 40

        Column {
            id: column
            width: parent.width
            spacing: 0

            // header bar
            Rectangle {
                width: parent.width; height: 72
                color: Qt.rgba(0.09,0.11,0.22,0.52)
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                Row {
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingSmall; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.paddingSmall
                    IconButton { icon.source: "image://theme/icon-m-back"; icon.color: "white"; onClicked: pageStack.pop() }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Settings"); color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
            }

            Item { width: 1; height: Theme.paddingLarge }

            // Connection 卡片
            GlassSection { title: qsTr("Connection (OneBot)") }
            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                height: connCol.height + 28
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }
                Column {
                    id: connCol
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 4
                    Item { width: 1; height: 6 }
                    Label { width: parent.width; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.42); text: qsTr("Fill these to attach a NapCat running on this device or anywhere on the network.") }
                    TextField { id: wsField; width: parent.width; label: qsTr("WebSocket URL"); placeholderText: "ws://127.0.0.1:3001"; text: ob ? ob.getSetting("connection/wsUrl","ws://127.0.0.1:3001") : ""; inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly; color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28); labelVisible: true }
                    TextField { id: httpField; width: parent.width; label: qsTr("HTTP API URL"); placeholderText: "http://127.0.0.1:3000"; text: ob ? ob.getSetting("connection/httpBase","http://127.0.0.1:3000") : ""; inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly; color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28) }
                    TextField { id: tokenField; width: parent.width; label: qsTr("access_token"); placeholderText: qsTr("empty = no auth"); text: ob ? ob.getSetting("connection/token", "") : ""; color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28) }
                    Item { width: 1; height: 8 }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: saveBtn1.width + 32; height: 38; radius: 19
                        gradient: Gradient { GradientStop { position: 0.0; color: "#7c8bff" } GradientStop { position: 1.0; color: "#a56bff" } }
                        border.color: Qt.rgba(1,1,1,0.18); border.width: 1
                        Label { id: saveBtn1; anchors.centerIn: parent; text: qsTr("Save & reconnect"); color: "white"; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: { if (!ob) return; ob.setSetting("connection/wsUrl", wsField.text.trim()); ob.setSetting("connection/httpBase", httpField.text.trim()); ob.setSetting("connection/token", tokenField.text.trim()); if (hub) hub.reconnectBridge(); savedLabel.show(qsTr("saved & reconnecting")) } }
                    }
                    Item { width: 1; height: 6 }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                height: webuiCol.height + 28
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }
                Column {
                    id: webuiCol
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 4
                    Item { width: 1; height: 6 }
                    Label { text: qsTr("Login helper (WebUI)"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }
                    TextField { id: webuiBaseField; width: parent.width; label: qsTr("WebUI base URL"); placeholderText: "http://127.0.0.1:6099"; text: ob ? ob.getSetting("login/webuiBase","http://127.0.0.1:6099") : ""; inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly; color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28) }
                    TextField { id: webuiTokenField; width: parent.width; label: qsTr("WebUI token"); text: ob ? ob.getSetting("login/webuiToken","32140848d004") : ""; color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28) }
                    Item { width: 1; height: 8 }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 160; height: 36; radius: 18
                        color: Qt.rgba(1,1,1,0.09); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
                        Label { anchors.centerIn: parent; text: qsTr("Save login settings"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; onClicked: { if (!ob) return; ob.setSetting("login/webuiBase", webuiBaseField.text.trim()); ob.setSetting("login/webuiToken", webuiTokenField.text.trim()); savedLabel.show(qsTr("saved")) } }
                    }
                    Item { width: 1; height: 6 }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                height: msgCol.height + 28
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }
                Column {
                    id: msgCol
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 2
                    Item { width: 1; height: 6 }
                    Label { text: qsTr("Messages"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }
                    TextSwitch {
                        id: autoImages; width: parent.width
                        text: qsTr("Auto-load image thumbnails"); description: qsTr("off shows [图片] placeholder only")
                        checked: ob && ob.getSetting("msg/autoImages", "true") === "true"
                        onCheckedChanged: if (ob) ob.setSetting("msg/autoImages", checked ? "true" : "false")
                    }
                    TextField {
                        id: historyField; width: parent.width; label: qsTr("history lines on chat open"); text: ob ? ob.getSetting("msg/historyCount", "30") : "30"
                        inputMethodHints: Qt.ImhDigitsOnly; validator: IntValidator { bottom: 0; top: 99 }
                        color: "white"; placeholderColor: Qt.rgba(1,1,1,0.28)
                        EnterKey.enabled: text.length > 0
                        EnterKey.onClicked: { if (ob) ob.setSetting("msg/historyCount", text.length > 0 ? text : "30"); focus = false }
                    }
                    Item { width: 1; height: 6 }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 168; height: 36; radius: 18
                        color: Qt.rgba(1,1,1,0.09); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
                        Label { anchors.centerIn: parent; text: qsTr("Save message settings"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; onClicked: { if (!ob) return; ob.setSetting("msg/historyCount", historyField.text.length > 0 ? historyField.text : "30"); savedLabel.show(qsTr("saved")) } }
                    }
                    Item { width: 1; height: 6 }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.06)
                border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                height: aboutCol.height + 24
                Column {
                    id: aboutCol
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 10
                    Item { width: 1; height: 4 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("About"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 160; height: 36; radius: 18
                        color: Qt.rgba(1,1,1,0.09); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
                        Label { anchors.centerIn: parent; text: qsTr("Usage guide / FAQ"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; onClicked: pageStack.push(Qt.resolvedUrl("InfoPage.qml")) }
                    }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.32); text: "harbour-qqcat · OneBot11" }
                    Item { width: 1; height: 4 }
                }
            }

            Item { width: 1; height: 40 }
        }

        Label {
            id: savedLabel
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 24
            color: "white"
            font.pixelSize: Theme.fontSizeSmall
            opacity: toastTimer.running ? 1 : 0
            Behavior on opacity { FadeAnimation {} }
            text: ""
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 24; height: parent.height + 12; radius: 14
                color: Qt.rgba(0.48,0.56,1.0,0.22)
                border.color: Qt.rgba(0.66,0.73,1.0,0.28); border.width: 1
                z: -1
                visible: toastTimer.running
            }
            function show(msg) { text = msg; toastTimer.restart() }
        }
        Timer { id: toastTimer; interval: 1800 }
    }
}
