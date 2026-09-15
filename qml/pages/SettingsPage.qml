import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    // injected by ConversationsPage
    property var ob: null
    property var hub: null

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Settings") }

            SectionHeader { text: qsTr("Connection (OneBot)") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Fill these to attach a NapCat running on this device or anywhere on the network.")
            }

            TextField {
                id: wsField
                width: parent.width
                label: qsTr("WebSocket URL")
                placeholderText: "ws://127.0.0.1:3001"
                text: ob ? ob.getSetting("connection/wsUrl",
                                         "ws://127.0.0.1:3001") : ""
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
            }

            TextField {
                id: httpField
                width: parent.width
                label: qsTr("HTTP API URL")
                placeholderText: "http://127.0.0.1:3000"
                text: ob ? ob.getSetting("connection/httpBase",
                                         "http://127.0.0.1:3000") : ""
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
            }

            TextField {
                id: tokenField
                width: parent.width
                label: qsTr("access_token")
                placeholderText: qsTr("empty = no auth")
                text: ob ? ob.getSetting("connection/token", "") : ""
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save & reconnect")
                onClicked: {
                    if (!ob)
                        return
                    ob.setSetting("connection/wsUrl", wsField.text.trim())
                    ob.setSetting("connection/httpBase", httpField.text.trim())
                    ob.setSetting("connection/token", tokenField.text.trim())
                    if (hub)
                        hub.reconnectBridge()
                    savedLabel.show(qsTr("saved & reconnecting"))
                }
            }

            SectionHeader { text: qsTr("Login helper (WebUI)") }

            TextField {
                id: webuiBaseField
                width: parent.width
                label: qsTr("WebUI base URL")
                placeholderText: "http://127.0.0.1:6099"
                text: ob ? ob.getSetting("login/webuiBase",
                                         "http://127.0.0.1:6099") : ""
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
            }

            TextField {
                id: webuiTokenField
                width: parent.width
                label: qsTr("WebUI token")
                text: ob ? ob.getSetting("login/webuiToken",
                                         "") : ""
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save login settings")
                onClicked: {
                    if (!ob)
                        return
                    ob.setSetting("login/webuiBase", webuiBaseField.text.trim())
                    ob.setSetting("login/webuiToken", webuiTokenField.text.trim())
                    savedLabel.show(qsTr("saved"))
                }
            }

            SectionHeader { text: qsTr("Messages") }

            TextSwitch {
                id: autoImages
                width: parent.width
                text: qsTr("Auto-load image thumbnails")
                description: qsTr("off shows [图片] placeholder only")
                checked: ob && ob.getSetting("msg/autoImages", "true") === "true"
                onCheckedChanged: if (ob)
                                      ob.setSetting("msg/autoImages",
                                                    checked ? "true" : "false")
            }

            TextField {
                id: historyField
                width: parent.width
                label: qsTr("history lines on chat open")
                text: ob ? ob.getSetting("msg/historyCount", "30") : "30"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0; top: 99 }
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: {
                    if (ob)
                        ob.setSetting("msg/historyCount",
                                      text.length > 0 ? text : "30")
                    focus = false
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save message settings")
                onClicked: {
                    if (!ob)
                        return
                    ob.setSetting("msg/historyCount",
                                  historyField.text.length > 0
                                  ? historyField.text : "30")
                    savedLabel.show(qsTr("saved"))
                }
            }

            SectionHeader { text: qsTr("About") }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Usage guide / FAQ")
                onClicked: pageStack.push(Qt.resolvedUrl("InfoPage.qml"))
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "harbour-qqcat · OneBot11"
            }
        }

        function show(msg) {
            toastLabel.text = msg
            toastTimer.restart()
        }

        Label {
            id: savedLabel
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Theme.paddingLarge
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            opacity: toastTimer.running ? 1 : 0
            Behavior on opacity { FadeAnimation {} }
            text: ""
        }

        Timer {
            id: toastTimer
            interval: 1800
        }
    }
}
