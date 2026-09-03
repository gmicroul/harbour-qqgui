import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0
import org.nemomobile.notifications 1.0
import "../js/pinyin.js" as PinYin
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string loginLabel: ""
    property var pend: ({})
    property var groupNames: ({})
    property var friendNames: ({})
    property int selfId: 0
    property bool groupsDone: false
    property bool friendsDone: false
    property bool contactsLoaded: false
    property string searchText: ""
    property string kindFilter: ""
    property var rows: []

    function findRow(key) {
        for (var i = 0; i < rows.length; i++)
            if (rows[i].key === key)
                return i
        return -1
    }
    function matchesFilter(r) {
        if (kindFilter.length > 0 && r.key.indexOf(kindFilter) !== 0)
            return false
        var q = searchText.toLowerCase()
        if (q.length === 0) return true
        return r.name.toLowerCase().indexOf(q) >= 0
                || (r.nick || "").toLowerCase().indexOf(q) >= 0
                || r.key.indexOf(searchText) >= 0
    }
    function rebuildView() {
        cList.clear()
        var act = [], g = [], f = []
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i]
            if (!matchesFilter(r)) continue
            if (r.time !== "") act.push(r)
            else if (r.key.charAt(0) === "群") g.push(r)
            else f.push(r)
        }
        act.sort(function(a, b) { return b.ts - a.ts })
        g.sort(function(a, b) { return PinYin.cmp(a.name, b.name) })
        f.sort(function(a, b) { return PinYin.cmp(a.name, b.name) })
        var all = act.concat(g, f)
        for (var j in all)
            cList.append({ key: all[j].key, name: all[j].name,
                           preview: all[j].preview, time: all[j].time,
                           unread: all[j].unread })
    }
    function oneLine(s) { return s ? String(s).replace(/[\r\n]+/g, " ") : s }
    function touchConv(key, who, text, mine) {
        text = oneLine(text)
        if (!mine) {
            msgNotify.previewSummary = nameFor(key, who)
            msgNotify.previewBody = text && text.length > 0 ? text : "[新消息]"
            msgNotify.publish()
        }
        var hm = Qt.formatDateTime(new Date(), "HH:mm")
        var i = findRow(key)
        if (i < 0) {
            var pre0 = text && text.length > 0 ? text : "[消息]"
            if (key.charAt(0) === "群") pre0 = who + ": " + pre0
            rows.push({ key: key, name: nameFor(key, who), preview: pre0, time: hm, unread: 1, ts: Date.now(), nick: who || "" })
            rebuildView(); return
        }
        rows[i].ts = Date.now(); rows[i].time = hm
        if (text && text.length > 0) {
            var prefix = ""
            if (key.charAt(0) === "群" && !mine) prefix = who + ": "
            else if (mine) prefix = "我: "
            rows[i].preview = prefix + text
        }
        rows[i].unread++
        rebuildView()
    }
    function markRead(key) {
        var i = findRow(key)
        if (i >= 0 && rows[i].unread !== 0) { rows[i].unread = 0; rebuildView() }
    }
    function nameFor(key, fallback) {
        var num = key.replace(/[^0-9]/g, "")
        if (key.charAt(0) === "群") return groupNames[num] ? groupNames[num] : (fallback || key)
        return friendNames[num] ? friendNames[num] : (fallback || key)
    }
    function openConv(key) {
        var i = findRow(key); if (i < 0) return
        rows[i].unread = 0; rebuildView()
        var pg = pageStack.push(Qt.resolvedUrl("ChatPage.qml"), {
            ob: ob, hub: page, targetKey: key,
            targetId: parseInt(key.replace(/[^0-9]/g, "")),
            isGroup: key.charAt(0) === "群",
            targetTitle: rows[i].name, selfId: selfId })
        if (pg) pg.loadHistory()
    }
    function openConvByKey(key) {
        if (findRow(key) < 0) {
            rows.push({ key: key, name: nameFor(key, ""), preview: "", time: "", unread: 0, ts: 0, nick: "" })
            rebuildView()
        }
        openConv(key)
    }
    function reconnectBridge() {
        ob.url = ob.getSetting("connection/wsUrl","ws://127.0.0.1:3001").toString()
        ob.close(); ob.open()
    }
    function loadContacts() {
        var e1 = ob.sendAction("get_group_list", "{}")
        pend[e1] = function(ok, d) {
            if (!ok) return
            var a = JSON.parse(d)
            for (var i in a) groupNames[String(a[i].group_id)] = a[i].group_name || String(a[i].group_id)
            groupsDone = true; tryPopulate()
        }
        var e2 = ob.sendAction("get_friend_list", "{}")
        pend[e2] = function(ok, d) {
            if (!ok) return
            var a = JSON.parse(d)
            for (var i in a) {
                var n = (a[i].remark && a[i].remark.length) ? a[i].remark : a[i].nickname
                friendNames[String(a[i].user_id)] = n || String(a[i].user_id)
            }
            friendsDone = true; tryPopulate()
        }
    }
    function tryPopulate() {
        if (contactsLoaded || !groupsDone || !friendsDone) return
        contactsLoaded = true
        var gk = Object.keys(groupNames)
        for (var i in gk) {
            var k = "群" + gk[i]
            if (findRow(k) < 0) rows.push({ key: k, name: groupNames[gk[i]], preview: "", time: "", unread: 0, ts: 0, nick: "" })
        }
        var fk = Object.keys(friendNames)
        for (var j in fk) {
            var kf = "私聊" + fk[j]
            if (findRow(kf) < 0) rows.push({ key: kf, name: friendNames[fk[j]], preview: "", time: "", unread: 0, ts: 0, nick: friendNames[fk[j]] })
        }
        rebuildView()
    }
    function refreshNames() {
        for (var i = 0; i < rows.length; i++) rows[i].name = nameFor(rows[i].key, rows[i].name)
        rebuildView()
    }
    function groupNamesToArray() {
        var a = []; for (var k in groupNames) a.push({ group_id: k, group_name: groupNames[k] }); return a
    }
    function friendNamesToArray() {
        var a = []; for (var k in friendNames) a.push({ user_id: k, remark: "", nickname: friendNames[k] }); return a
    }

    Notification { id: msgNotify; category: "x-nemo.messaging.im"; previewSummary: ""; previewBody: "" }
    Timer {
        interval: 4000; running: true; repeat: true
        onTriggered: {
            var out = "== roster dump ==\n"
            for (var i = 0; i < cList.count && i < 15; i++) {
                var r = cList.get(i)
                out += i + "| " + r.name + " | " + r.preview + " | u" + r.unread + " | " + r.time + "\n"
            }
            ob.writeFile("/tmp/qqcat_roster.txt", out)
        }
    }
    OneBotBridge {
        id: ob; url: "ws://127.0.0.1:3001"
        onConnectedChanged: {
            if (connected) {
                var e = ob.sendAction("get_login_info", "{}")
                pend[e] = function(ok, d) {
                    if (ok) { var u = JSON.parse(d); selfId = u.user_id; loginLabel = u.nickname + " (" + u.user_id + ")" }
                    loadContacts()
                }
            } else loginLabel = ""
        }
        Component.onCompleted: open()
    }
    Timer { interval: 5000; running: !ob.connected; repeat: true; onTriggered: ob.open() }
    Connections {
        target: ob
        onActionReply: { if (page.pend[echo] !== undefined) { var cb = page.pend[echo]; delete page.pend[echo]; cb(ok, dataJson) } }
        onEventReceived: {
            var pk; try { pk = JSON.parse(packet) } catch (e) { return }
            var txt = pk.text
            try { var imgs = JSON.parse(pk.imagesJson); if (imgs.length > 0 && (!txt || txt.length === 0)) { txt = "[图片]"; for (var ii in imgs) if (imgs[ii].isFile) { txt = "[文件]"; break } } } catch (e) {}
            touchConv(pk.where, pk.who, txt, parseInt(pk.uid) === selfId)
        }
    }

    // ===== Glass UI =====
    GlassBackground { anchors.fill: parent }

    Column {
        id: topBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 0

            // Sailfish 风格顶栏 — 玻璃底 + 原生大触控按钮，标题靠左
            Rectangle {
                width: parent.width
                height: 88 + Theme.paddingMedium
                color: Qt.rgba(0.09,0.11,0.22,0.42)
                border.color: Qt.rgba(1,1,1,0.10)
                border.width: 1
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }
                Column {
                    anchors.left: parent.left
                    anchors.right: actions.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.rightMargin: Theme.paddingSmall
                    spacing: 2
                    Row {
                        spacing: 8
                        Label { text: "QQ"; font.pixelSize: Theme.fontSizeLarge; font.bold: true; color: "white"; font.letterSpacing: 0.5 }
                        Label { text: "· Bridge"; anchors.baseline: parent.children[0].baseline; font.pixelSize: Theme.fontSizeSmall; color: Qt.rgba(1,1,1,0.55) }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: ob.connected ? "#4ade80" : "#f87171"; border.color: Qt.rgba(1,1,1,0.5); border.width: 1; opacity: ob.connected ? 1 : 0.85 }
                    }
                    Label { width: parent.width; font.pixelSize: Theme.fontSizeExtraSmall; color: ob.connected ? Qt.rgba(1,1,1,0.72) : Qt.rgba(1,1,1,0.42); truncationMode: TruncationMode.Fade; text: ob.connected ? (loginLabel.length > 0 ? loginLabel : qsTr("connected")) : qsTr("connecting to NapCat…") }
                }
                Row {
                    id: actions
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingMedium
                    Rectangle {
                        id: refreshBtn
                        width: 64; height: 64; radius: 32
                        color: refreshMouse.pressed ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.16)
                        border.color: Qt.rgba(1,1,1,0.24); border.width: 1.2
                        Image { anchors.centerIn: parent; width: 32; height: 32; source: "image://theme/icon-m-refresh"; smooth: true }
                        MouseArea { id: refreshMouse; anchors.fill: parent; onClicked: page.loadContacts() }
                    }
                    Rectangle {
                        id: settingsBtn
                        width: 64; height: 64; radius: 32
                        color: settingsMouse.pressed ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.16)
                        border.color: Qt.rgba(1,1,1,0.24); border.width: 1.2
                        Image { anchors.centerIn: parent; width: 32; height: 32; source: "image://theme/icon-m-developer-mode"; smooth: true }
                        MouseArea { id: settingsMouse; anchors.fill: parent; onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), { ob: ob, hub: page }) }
                    }
                }
            }

            // 筛选 pills — 毛玻璃胶囊
            Item { width: 1; height: Theme.paddingMedium }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                Repeater {
                    model: [ { t: qsTr("All"), v: "" }, { t: qsTr("Groups"), v: "群" }, { t: qsTr("Friends"), v: "私聊" } ]
                    delegate: Item {
                        width: bgRect.width; height: bgRect.height
                        Rectangle {
                            id: bgRect
                            width: pillLabel.implicitWidth + Theme.paddingLarge*1.8
                            height: 30; radius: 15
                            color: page.kindFilter === modelData.v ? Qt.rgba(0.55,0.62,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                            border.color: page.kindFilter === modelData.v ? Qt.rgba(0.66,0.73,1.0,0.38) : Qt.rgba(1,1,1,0.11)
                            border.width: 1
                            Label {
                                id: pillLabel
                                anchors.centerIn: parent
                                text: modelData.t
                                font.pixelSize: Theme.fontSizeExtraSmall
                                font.bold: page.kindFilter === modelData.v
                                color: page.kindFilter === modelData.v ? "white" : Qt.rgba(1,1,1,0.62)
                            }
                        }
                        MouseArea {
                            anchors.fill: bgRect
                            onClicked: { page.kindFilter = modelData.v; page.rebuildView() }
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            // 搜索框 — 毛玻璃 (保留 Sailfish SearchField 以保证对齐)
            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: searchField.height
                radius: 14
                color: Qt.rgba(1,1,1,0.08)
                border.color: Qt.rgba(1,1,1,0.13)
                border.width: 1
                clip: true
                SearchField {
                    id: searchField
                    width: parent.width
                    placeholderText: qsTr("search friends and groups")
                    placeholderColor: Qt.rgba(1,1,1,0.38)
                    color: "white"
                    font.pixelSize: Theme.fontSizeSmall
                    background: null
                    // 让内部 TextField 透明，露出毛玻璃底
                    onTextChanged: { page.searchText = text; page.rebuildView() }
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                }
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        // 会话列表 — 毛玻璃卡片
        SilicaListView {
            id: listView
            anchors { top: topBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            clip: true
            model: ListModel { id: cList }
            spacing: Theme.paddingSmall
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingLarge

            VerticalScrollDecorator {}

            delegate: Item {
                width: listView.width
                height: 78

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: parent.width - 2*Theme.horizontalPageMargin
                    height: 72
                    radius: 18
                    color: rowMouse.pressed ? Qt.rgba(1,1,1,0.13) : Qt.rgba(1,1,1,0.07)
                    border.color: model.unread > 0 ? Qt.rgba(0.66,0.73,1.0,0.28) : Qt.rgba(1,1,1,0.11)
                    border.width: 1

                    // 顶部高光
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        radius: parent.radius
                        color: Qt.rgba(1,1,1,0.14)
                    }

                    // 未读时左侧光柱
                    Rectangle {
                        visible: model.unread > 0
                        width: 3
                        height: 28
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#7c8bff"
                        opacity: 0.95
                    }

                    // 头像 — 真实 QQ 头像 + 首字兜底
                    Rectangle {
                        id: avatar
                        x: 12
                        y: 12
                        width: 48; height: 48; radius: 14
                        color: Qt.rgba(1,1,1,0.08)
                        border.color: Qt.rgba(1,1,1,0.18)
                        border.width: 1
                        clip: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: model.key.charAt(0) === "群" ? "#6d6bff" : "#3ec6ff" }
                            GradientStop { position: 1.0; color: model.key.charAt(0) === "群" ? "#a56bff" : "#7c8bff" }
                        }
                        opacity: 0.92
                        Label {
                            id: avatarFallback
                            anchors.centerIn: parent
                            text: model.name ? model.name.charAt(0) : "?"
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            visible: avatarImg.status !== Image.Ready
                        }
                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            source: {
                                var num = model.key.replace(/[^0-9]/g, "")
                                if (!num) return ""
                                if (model.key.charAt(0) === "群") return "https://p.qlogo.cn/gh/" + num + "/" + num + "/100"
                                return "https://q.qlogo.cn/headimg_dl?dst_uin=" + num + "&spec=100"
                            }
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                        }
                    }

                    Label {
                        x: avatar.x + avatar.width + Theme.paddingMedium
                        y: 14
                        width: parent.width - x - timeLabel.width - badge.width - Theme.paddingMedium*2 - 8
                        text: model.name
                        color: model.unread > 0 ? "white" : Qt.rgba(1,1,1,0.92)
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: model.unread > 0
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        id: timeLabel
                        anchors.right: badge.left
                        anchors.rightMargin: Theme.paddingSmall
                        y: 16
                        text: model.time
                        color: model.unread > 0 ? Qt.rgba(0.68,0.75,1.0,1) : Qt.rgba(1,1,1,0.38)
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: model.unread > 0
                    }

                    Rectangle {
                        id: badge
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        y: 14
                        width: Math.max(22, unreadText.width + 10)
                        height: 20
                        radius: 10
                        visible: model.unread > 0
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#7c8bff" }
                            GradientStop { position: 1.0; color: "#a56bff" }
                        }
                        border.color: Qt.rgba(1,1,1,0.18)
                        border.width: 1
                        Label {
                            id: unreadText
                            anchors.centerIn: parent
                            font.pixelSize: Theme.fontSizeTiny
                            font.bold: true
                            color: "white"
                            text: model.unread > 99 ? "99+" : model.unread
                        }
                    }

                    Label {
                        x: avatar.x + avatar.width + Theme.paddingMedium
                        y: 38
                        width: parent.width - x - Theme.paddingLarge - 12
                        text: model.preview
                        color: Qt.rgba(1,1,1,0.52)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        maximumLineCount: 1
                        truncationMode: TruncationMode.Fade
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        onClicked: page.openConv(model.key)
                    }
                }
            }

            ViewPlaceholder {
                enabled: cList.count === 0
                text: searchText.length > 0 ? qsTr("no matches") : qsTr("loading contacts…")
                hintText: ob.connected ? "" : qsTr("connecting to NapCat…")
            }
        }
}
