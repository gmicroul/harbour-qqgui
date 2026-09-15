import QtQuick 2.2
import Sailfish.Silica 1.0

// 设置页 · 毛玻璃重设计（逻辑与原 SettingsPage.qml 一致）。
// 同目录部件（GlassCard/GlassAvatar/…）自动可见，无需 import。
// 度量全部取 Theme（字号/边距/控件高），随屏缩放；按钮用原生高度。
Page {
    id: page

    allowedOrientations: Orientation.All

    property var ob: null
    property var hub: null

    GlassBackground {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: "white"
                text: qsTr("Settings")
            }

            GlassSectionTitle { x: Theme.horizontalPageMargin; text: qsTr("Connection (OneBot)") }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: connCol.height + 2 * Theme.paddingMedium
                Column {
                    id: connCol
                    x: Theme.paddingMedium
                    y: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    Label {
                        width: parent.width
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: "white"
                        opacity: 0.6
                        text: qsTr("Fill these to attach a NapCat running on this device or anywhere on the network.")
                    }
                    TextField {
                        id: wsField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
                        label: qsTr("WebSocket URL")
                        placeholderText: "ws://127.0.0.1:3001"
                        text: ob ? ob.getSetting("connection/wsUrl",
                                                 "ws://127.0.0.1:3001") : ""
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
                    }
                    TextField {
                        id: httpField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
                        label: qsTr("HTTP API URL")
                        placeholderText: "http://127.0.0.1:3000"
                        text: ob ? ob.getSetting("connection/httpBase",
                                                 "http://127.0.0.1:3000") : ""
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
                    }
                    TextField {
                        id: tokenField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
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
                }
            }

            GlassSectionTitle { x: Theme.horizontalPageMargin; text: qsTr("Login helper (WebUI)") }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: webCol.height + 2 * Theme.paddingMedium
                Column {
                    id: webCol
                    x: Theme.paddingMedium
                    y: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    TextField {
                        id: webuiBaseField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
                        label: qsTr("WebUI base URL")
                        placeholderText: "http://127.0.0.1:6099"
                        text: ob ? ob.getSetting("login/webuiBase",
                                                 "http://127.0.0.1:6099") : ""
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
                    }
                    TextField {
                        id: webuiTokenField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
                        label: qsTr("WebUI token")
                        text: ob ? ob.getSetting("login/webuiToken", "") : ""
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
                }
            }

            GlassSectionTitle { x: Theme.horizontalPageMargin; text: qsTr("Messages") }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: msgCol.height + 2 * Theme.paddingMedium
                Column {
                    id: msgCol
                    x: Theme.paddingMedium
                    y: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        Column {
                            width: parent.width - autoImages.width - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                width: parent.width
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                font.pixelSize: Theme.fontSizeSmall
                                color: "white"
                                text: qsTr("Auto-load image thumbnails")
                            }
                            Label {
                                width: parent.width
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: "white"
                                opacity: 0.6
                                text: qsTr("off shows [图片] placeholder only")
                            }
                        }
                        Switch {
                            id: autoImages
                            anchors.verticalCenter: parent.verticalCenter
                            checked: ob && ob.getSetting("msg/autoImages", "true") === "true"
                            onCheckedChanged: if (ob)
                                                  ob.setSetting("msg/autoImages",
                                                                checked ? "true" : "false")
                        }
                    }
                    TextField {
                        id: historyField
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
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
                }
            }

            GlassSectionTitle { x: Theme.horizontalPageMargin; text: qsTr("About") }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: aboutCol.height + 2 * Theme.paddingMedium
                Column {
                    id: aboutCol
                    x: Theme.paddingMedium
                    y: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Usage guide / FAQ")
                        onClicked: pageStack.push(Qt.resolvedUrl("InfoGlassPage.qml"))
                    }
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "white"
                opacity: 0.5
                text: "harbour-qqcat · OneBot11 · glass-ui"
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
            anchors.bottomMargin: Theme.paddingMedium
            color: "#4ade80"
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
