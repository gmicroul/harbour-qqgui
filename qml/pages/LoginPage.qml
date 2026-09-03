import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0

Page {
    id: page

    allowedOrientations: Orientation.Portrait

    // NapCat WebUI token (see /opt/QQ/resources/app/config/webui.json)
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
        if (!e || e.length === 0) {
            cb(false, "")
            return
        }
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
            console.log("[LOGIN] poll isLogin=", d.data.isLogin)
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
            // credential invalidated (e.g. NapCat restarted): re-auth once
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
            currentQrUrl = ""          // force redraw on next poll
            pollStatus()
        })
    }

    // kicked sessions freeze the served QR into a stale "fossil" code
    // that always scans as expired; only bouncing NapCat regenerates it
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

    property string currentQrUrl: ""

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

    Timer {   // QR status polling
        interval: 2500
        running: !loggedIn && credential.length > 0
        repeat: true
        onTriggered: pollStatus()
    }

    Timer {   // expiry countdown; auto refresh at zero
        interval: 1000
        running: qrData.length > 0 && !loggedIn
        repeat: true
        onTriggered: {
            remaining--
            if (remaining <= 0)
                refreshQr()
        }
    }

    Timer {   // wait for OneBot ports to come up after login
        id: waitTimer
        interval: 1500
        repeat: true
        property int tries: 0
        onTriggered: {
            tries++
            if (tries > 20) {
                stop()
                return
            }
            page.act("get_login_info", "{}", function(ok) {
                if (ok)
                    pageStack.replace(Qt.resolvedUrl(
                        "ConversationsPage.qml"))
            })
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Enter anyway")
                onClicked: pageStack.replace(Qt.resolvedUrl(
                    "ConversationsPage.qml"))
            }
            MenuItem {
                text: qsTr("Regenerate QR (restart NapCat)")
                onClicked: page.regenerateQr()
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("QQ Login") }

            Label {
                id: statusLabel
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: qsTr("starting…")
            }

            Item { width: 1; height: Theme.paddingMedium }

            // QR code card
            Rectangle {
                id: qrCard
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(page.width - 4 * Theme.horizontalPageMargin,
                                380)
                height: width
                radius: Theme.paddingMedium
                color: "white"

                Image {
                    id: qrImage
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingLarge
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
                    size: BusyIndicatorSize.Large
                }

                // darkened overlay once logged in
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.55)
                    visible: page.loggedIn
                }

                Label {
                    anchors.centerIn: parent
                    visible: page.loggedIn
                    color: "white"
                    font.pixelSize: Theme.fontSizeLarge
                    text: qsTr("✓ logged in")
                }

                // expired overlay: tap anywhere on the card to refresh
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.6)
                    visible: !page.loggedIn && page.remaining <= 0
                             && page.qrData.length > 0
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingSmall
                    visible: !page.loggedIn && page.remaining <= 0
                             && page.qrData.length > 0

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "white"
                        font.pixelSize: Theme.fontSizeMedium
                        text: qsTr("QR expired")
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: qsTr("tap to refresh")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !page.loggedIn && page.credential.length > 0
                    onClicked: page.refreshQr()
                }
            }

            ProgressBar {
                anchors.horizontalCenter: parent.horizontalCenter
                width: qrCard.width
                minimumValue: 0
                maximumValue: 60
                value: Math.max(page.remaining, 0)
                visible: page.qrData.length > 0 && !page.loggedIn
                label: qsTr("expires in") + " " + Math.max(page.remaining, 0)                       + "s"
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
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
                color: Theme.secondaryColor
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
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
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
