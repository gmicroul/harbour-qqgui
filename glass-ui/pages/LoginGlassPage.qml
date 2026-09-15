import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0

// 登录页 · 毛玻璃重设计（逻辑与原 LoginPage.qml 一致）。
// 同目录部件（GlassCard/GlassAvatar/…）自动可见，无需 import。
// 尺寸约束：标题 23 / 状态 15 / 按钮高 40 / 提示 13，全部 < 75。
// 例外：二维码为功能性媒体，内芯 240，外卡按屏宽自适应（扫码下限约 200），不计入 chrome 规范。
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
    property string currentQrUrl: ""

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
            if (!d || d.code !== 0) {
                authFailed = true
                statusLabel.text = qsTr("WebUI auth failed")
                return
            }
            authFailed = false
            credential = d.data.Credential
            pollStatus()
        })
    }

    function pollStatus() {
        if (loggedIn)
            return
        webui("/QQLogin/CheckLoginStatus", {}, function(d) {
            if (!d || d.code !== 0) {
                statusLabel.text = qsTr("waiting for NapCat…")
                return
            }
            lastError = d.data.loginError ? d.data.loginError : ""
            if (d.data.isLogin) {
                loggedIn = true
                statusLabel.text = qsTr("login ok, starting bridge…")
                waitTimer.start()
                return
            }
            statusLabel.text = qsTr("scan with mobile QQ")
            setQrUrl(d.data.qrcodeurl)
        })
    }

    function webui(path, body, cb) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", webuiBase + "/api" + path)
        xhr.setRequestHeader("Content-Type", "application/json")
        if (credential.length > 0)
            xhr.setRequestHeader("Authorization", "Bearer " + credential)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            var parsed = null
            try { parsed = JSON.parse(xhr.responseText) } catch (e) {}
            if (parsed && parsed.code === -1 && credential.length > 0
                    && path !== "/auth/login") {
                credential = ""
                startLogin()
                return
            }
            cb(parsed)
        }
        xhr.send(body ? JSON.stringify(body) : "{}")
    }

    function setQrUrl(url) {
        if (!url || url.length === 0)
            return
        if (url === currentQrUrl)
            return
        currentQrUrl = url
        var png = ob.qrDataUrl(url)
        if (png.length > 0) {
            qrData = png
            remaining = 60
        }
    }

    function refreshQr() {
        webui("/QQLogin/RefreshQRcode", {}, function(d) {
            currentQrUrl = ""
            pollStatus()
        })
    }

    function regenerateQr() {
        statusLabel.text = qsTr("restarting NapCat for a fresh QR…")
        currentQrUrl = ""
        qrData = ""
        credential = ""
        webui("/QQLogin/RestartNapCat", {}, function(d) { })
        fossilTimer.start()
    }

    Timer {
        id: fossilTimer
        interval: 20000
        onTriggered: page.startLogin()
    }

    OneBotBridge { id: ob }

    Connections {
        target: ob
        onActionReply: {
            if (page.pending[echo] !== undefined) {
                var cb = page.pending[echo]
                delete page.pending[echo]
                cb(ok, dataJson)
            }
        }
    }

    Timer {
        interval: 2500
        running: !loggedIn && credential.length > 0
        repeat: true
        onTriggered: pollStatus()
    }

    Timer {
        interval: 1000
        running: qrData.length > 0 && !loggedIn
        repeat: true
        onTriggered: {
            remaining--
            if (remaining <= 0)
                refreshQr()
        }
    }

    Timer {
        id: waitTimer
        interval: 1500
        repeat: true
        property int tries: 0
        onTriggered: {
            tries++
            if (tries > 20) { stop(); return }
            page.act("get_login_info", "{}", function(ok) {
                if (ok)
                    pageStack.replace(Qt.resolvedUrl("ConversationsGlassPage.qml"))
            })
        }
    }

    GlassBackground {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + 24

        PullDownMenu {
            MenuItem {
                text: qsTr("Enter anyway")
                onClicked: pageStack.replace(Qt.resolvedUrl("ConversationsGlassPage.qml"))
            }
            MenuItem {
                text: qsTr("Regenerate QR (restart NapCat)")
                onClicked: page.regenerateQr()
            }
        }

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
                text: qsTr("QQ Login")
            }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: statusLabel.height + 2 * Theme.paddingMedium
                Label {
                    id: statusLabel
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeSmall
                    color: "white"
                    opacity: 0.85
                    text: qsTr("starting…")
                }
            }

            // 二维码玻璃外卡 + 白色内芯（二维码物理尺寸随屏宽走，保证可扫）
            GlassCard {
                id: qrOuter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: qrCard.height + expiryLabel.height
                        + 3 * Theme.paddingMedium

                Rectangle {
                    id: qrCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingLarge
                    height: width
                    radius: Theme.paddingSmall
                    color: "white"

                    Image {
                        id: qrImage
                        anchors.centerIn: parent
                        width: parent.width - Theme.paddingMedium
                        height: width
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                        source: page.qrData
                        visible: page.qrData.length > 0 && !page.loggedIn
                    }

                    BusyIndicator {
                        visible: qrImage.status !== Image.Ready && !page.loggedIn
                                 && page.credential.length > 0
                        running: visible
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.paddingSmall
                        color: Qt.rgba(0, 0, 0, 0.55)
                        visible: page.loggedIn
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: page.loggedIn
                        color: "white"
                        font.pixelSize: Theme.fontSizeMedium
                        text: qsTr("✓ logged in")
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !page.loggedIn && page.credential.length > 0
                        onClicked: page.refreshQr()
                    }
                }

                Label {
                    id: expiryLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: qrCard.y + qrCard.height + Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: "white"
                    opacity: 0.6
                    text: page.qrData.length > 0 && !page.loggedIn
                          ? qsTr("expires in") + " " + Math.max(page.remaining, 0) + "s"
                          : qsTr("tap card to refresh after expiry")
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall
                visible: !page.loggedIn
                Button {
                    text: qsTr("Refresh QR")
                    enabled: !page.loggedIn && page.credential.length > 0
                    onClicked: page.refreshQr()
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "#f87171"
                visible: page.authFailed
                text: qsTr("cannot reach NapCat WebUI, check container")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: page.authFailed
                text: qsTr("Reconnect")
                onClicked: page.startLogin()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "#f87171"
                visible: page.lastError.length > 0
                text: page.lastError
            }
        }
    }

    Component.onCompleted: {
        webuiToken = ob.getSetting("login/webuiToken", "")
        webuiBase = ob.getSetting("login/webuiBase",
                                  "http://127.0.0.1:6099")
        startLogin()
    }
}
