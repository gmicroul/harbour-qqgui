import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.Portrait
    property string webuiToken: ""
    property string webuiBase: "http://127.0.0.1:6099"
    property string credential: ""
    property string qrData: ""
    property int remaining: 60
    property string lastError: ""
    property bool loggedIn: false
    property bool authFailed: false
    property var pending: ({})

    function act(action, paramsJson, cb) {
        var e = ob.sendAction(action, paramsJson)
        if (!e || e.length === 0) { cb(false, ""); return }
        pending[e] = cb
    }
    function startLogin() {
        statusLabel.text = qsTr("connecting to NapCat…")
        var hash = ob.sha256Hex(webuiToken + ".napcat")
        credential = ""
        webui("/auth/login", { hash: hash, totpCode: "" }, function(d) {
            if (!d || d.code !== 0) { authFailed = true; statusLabel.text = qsTr("WebUI auth failed"); return }
            authFailed = false; credential = d.data.Credential; pollStatus()
        })
    }
    function pollStatus() {
        if (loggedIn) return
        webui("/QQLogin/CheckLoginStatus", {}, function(d) {
            if (!d || d.code !== 0) { statusLabel.text = qsTr("waiting for NapCat…"); return }
            lastError = d.data.loginError ? d.data.loginError : ""
            if (d.data.isLogin) { loggedIn = true; statusLabel.text = qsTr("login ok, starting bridge…"); waitTimer.start(); return }
            statusLabel.text = qsTr("scan with mobile QQ")
            setQrUrl(d.data.qrcodeurl)
        })
    }
    function webui(path, body, cb) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", webuiBase + "/api" + path)
        xhr.setRequestHeader("Content-Type", "application/json")
        if (credential.length > 0) xhr.setRequestHeader("Authorization", "Bearer " + credential)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var parsed = null; try { parsed = JSON.parse(xhr.responseText) } catch (e) {}
            if (parsed && parsed.code === -1 && credential.length > 0 && path !== "/auth/login") { credential = ""; startLogin(); return }
            cb(parsed)
        }
        xhr.send(body ? JSON.stringify(body) : "{}")
    }
    function setQrUrl(url) {
        if (!url || url.length === 0) return
        if (url === currentQrUrl) return
        currentQrUrl = url
        var png = ob.qrDataUrl(url)
        if (png.length > 0) { qrData = png; remaining = 60 }
    }
    function refreshQr() { webui("/QQLogin/RefreshQRcode", {}, function(d) { currentQrUrl = ""; pollStatus() }) }
    function regenerateQr() {
        statusLabel.text = qsTr("restarting NapCat for a fresh QR…")
        currentQrUrl = ""; qrData = ""; credential = ""
        webui("/QQLogin/RestartNapCat", {}, function(d) { })
        fossilTimer.start()
    }

    Timer { id: fossilTimer; interval: 20000; onTriggered: page.startLogin() }
    property string currentQrUrl: ""
    OneBotBridge { id: ob }
    Connections { target: ob; onActionReply: { if (page.pending[echo] !== undefined) { var cb = page.pending[echo]; delete page.pending[echo]; cb(ok, dataJson) } } }
    Timer { interval: 2500; running: !loggedIn && credential.length > 0; repeat: true; onTriggered: pollStatus() }
    Timer { interval: 1000; running: qrData.length > 0 && !loggedIn; repeat: true; onTriggered: { remaining--; if (remaining <= 0) refreshQr() } }
    Timer { id: waitTimer; interval: 1500; repeat: true; property int tries: 0; onTriggered: { tries++; if (tries > 20) { stop(); return } page.act("get_login_info", "{}", function(ok) { if (ok) pageStack.replace(Qt.resolvedUrl("ConversationsPage.qml")) }) } }

    GlassBackground { anchors.fill: parent }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + 40

        PullDownMenu {
            MenuItem { text: qsTr("Enter anyway"); onClicked: pageStack.replace(Qt.resolvedUrl("ConversationsPage.qml")) }
            MenuItem { text: qsTr("Regenerate QR (restart NapCat)"); onClicked: page.regenerateQr() }
        }

        Column {
            id: column
            width: parent.width
            spacing: 0

            // 顶部标题 — 毛玻璃 bar
            Rectangle {
                width: parent.width
                height: 72
                color: Qt.rgba(0.09,0.11,0.22,0.38)
                border.color: Qt.rgba(1,1,1,0.09)
                border.width: 1
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "QQ Bridge"; color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true; font.letterSpacing: 0.6 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Sailfish · OneBot"; color: Qt.rgba(1,1,1,0.42); font.pixelSize: Theme.fontSizeTiny; font.letterSpacing: 1.2 }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
            }

            Item { width: 1; height: Theme.paddingLarge }

            // 状态胶囊
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: statusLabel.width + 32
                height: 28
                radius: 14
                color: loggedIn ? Qt.rgba(0.30,0.85,0.52,0.18) : Qt.rgba(1,1,1,0.08)
                border.color: loggedIn ? Qt.rgba(0.30,0.85,0.52,0.32) : Qt.rgba(1,1,1,0.11)
                border.width: 1
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle { width: 7; height: 7; radius: 4; anchors.verticalCenter: parent.verticalCenter; color: loggedIn ? "#4ade80" : credential.length>0 ? "#fbbf24" : "#94a3b8"; opacity: 0.95 }
                    Label { id: statusLabel; font.pixelSize: Theme.fontSizeExtraSmall; color: loggedIn ? "#a7f3d0" : Qt.rgba(1,1,1,0.78); text: qsTr("starting…") }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            // 二维码卡片 — 大毛玻璃卡
            Rectangle {
                id: qrCard
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(page.width - 32, 360)
                height: width + 22
                radius: 28
                color: Qt.rgba(1,1,1,0.08)
                border.color: Qt.rgba(1,1,1,0.14)
                border.width: 1

                // 内高光
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.18) }
                // 阴影
                Rectangle { anchors.fill: parent; anchors.topMargin: 4; radius: parent.radius; color: Qt.rgba(0,0,0,0.18); z: -1 }

                Rectangle {
                    id: qrInner
                    anchors.centerIn: parent
                    width: parent.width - 28
                    height: width
                    radius: 20
                    color: "white"
                    border.color: Qt.rgba(1,1,1,0.6)
                    border.width: 1

                    Image {
                        id: qrImage
                        anchors.centerIn: parent
                        width: parent.width - 20
                        height: width
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                        source: page.qrData
                        visible: page.qrData.length > 0 && !page.loggedIn
                    }
                    BusyIndicator {
                        visible: qrImage.status !== Image.Ready && !page.loggedIn && page.credential.length > 0
                        running: visible; anchors.centerIn: parent; size: BusyIndicatorSize.Large
                    }
                    // 已登录遮罩
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        color: Qt.rgba(0.45,0.52,1.0,0.82)
                        visible: page.loggedIn
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "✓"; color: "white"; font.pixelSize: 42; font.bold: true }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; color: "white"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; text: qsTr("logged in") }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(1,1,1,0.78); font.pixelSize: Theme.fontSizeTiny; text: qsTr("entering…") }
                        }
                    }
                    // 过期遮罩
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        color: Qt.rgba(0,0,0,0.58)
                        visible: !page.loggedIn && page.remaining <= 0 && page.qrData.length > 0
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Label { anchors.horizontalCenter: parent.horizontalCenter; color: "white"; font.pixelSize: Theme.fontSizeMedium; font.bold: true; text: qsTr("QR expired") }
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 88; height: 28; radius: 14; color: "white"
                                Label { anchors.centerIn: parent; text: qsTr("tap to refresh"); color: "#1a1d2e"; font.pixelSize: Theme.fontSizeTiny; font.bold: true }
                            }
                        }
                    }
                    MouseArea { anchors.fill: parent; enabled: !page.loggedIn && page.credential.length > 0; onClicked: page.refreshQr() }
                }

                // 底部圆点进度
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    spacing: 4
                    visible: page.qrData.length > 0 && !page.loggedIn
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: index < Math.ceil(page.remaining/15) ? "white" : Qt.rgba(1,1,1,0.22)
                            opacity: index < Math.ceil(page.remaining/15) ? 0.92 : 0.55
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            // 进度条 — 毛玻璃轨道
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: qrCard.width
                height: 22
                visible: page.qrData.length > 0 && !page.loggedIn
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 6; radius: 3
                    color: Qt.rgba(1,1,1,0.10)
                    border.color: Qt.rgba(1,1,1,0.08)
                    border.width: 1
                    Rectangle {
                        width: parent.width * Math.max(page.remaining,0)/60
                        height: parent.height; radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#7c8bff" }
                            GradientStop { position: 1.0; color: "#a56bff" }
                        }
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
                Label {
                    anchors.top: parent.top; anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.42)
                    text: qsTr("expires in") + " " + Math.max(page.remaining,0) + "s"
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                visible: !page.loggedIn
                Rectangle {
                    width: 120; height: 38; radius: 19
                    color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
                    Label { anchors.centerIn: parent; text: qsTr("Refresh QR"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                    MouseArea { anchors.fill: parent; enabled: !page.loggedIn && page.credential.length > 0; onClicked: page.refreshQr() }
                }
                Rectangle {
                    visible: page.authFailed
                    width: 110; height: 38; radius: 19
                    color: Qt.rgba(0.48,0.56,1.0,0.18); border.color: Qt.rgba(0.66,0.73,1.0,0.28); border.width: 1
                    Label { anchors.centerIn: parent; text: qsTr("Reconnect"); color: "white"; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: page.startLogin() }
                }
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: page.authFailed ? Qt.rgba(1,0.55,0.55,0.9) : Qt.rgba(1,1,1,0.38)
                visible: page.authFailed || page.lastError.length > 0
                text: page.authFailed ? qsTr("cannot reach NapCat WebUI, check container") : page.lastError
            }

            Item { width: 1; height: Theme.paddingLarge }

            // 底部小提示
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeTiny
                color: Qt.rgba(1,1,1,0.28)
                text: "NapCat WebUI  ·  Scan with QQ"
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }

    Component.onCompleted: {
        webuiToken = ob.getSetting("login/webuiToken", "")
        webuiBase = ob.getSetting("login/webuiBase", "http://127.0.0.1:6099")
        startLogin()
    }
}
