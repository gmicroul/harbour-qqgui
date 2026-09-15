import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0
import org.nemomobile.notifications 1.0
import "../js/pinyin.js" as PinYin

// 会话列表 · 毛玻璃重设计（逻辑与原 ConversationsPage.qml 一致，可平替）。
// 同目录部件（GlassCard/GlassAvatar/…）自动可见，无需 import。
// 尺寸约束：行高 68 / 头像 48 / 标题 23 / 名称 21 / 预览 15 / 时间 13 / 徽标 20x11，全部 < 75。
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
        if (q.length === 0)
            return true
        return r.name.toLowerCase().indexOf(q) >= 0
                || (r.nick || "").toLowerCase().indexOf(q) >= 0
                || r.key.indexOf(searchText) >= 0
    }

    function rebuildView() {
        cList.clear()
        var act = []
        var g = []
        var f = []
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i]
            if (!matchesFilter(r))
                continue
            if (r.time !== "")
                act.push(r)
            else if (r.key.charAt(0) === "群")
                g.push(r)
            else
                f.push(r)
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

    function touchConv(key, who, text, mine) {
        if (!mine) {
            msgNotify.previewSummary = nameFor(key, who)
            msgNotify.previewBody = text && text.length > 0 ? text : "[新消息]"
            msgNotify.publish()
        }
        var hm = Qt.formatDateTime(new Date(), "HH:mm")
        var i = findRow(key)
        if (i < 0) {
            var pre0 = text && text.length > 0 ? text : "[消息]"
            if (key.charAt(0) === "群")
                pre0 = who + ": " + pre0
            rows.push({ key: key, name: nameFor(key, who),
                        preview: pre0,
                        time: hm, unread: 1,
                        ts: Date.now(), nick: who || "" })
            rebuildView()
            return
        }
        rows[i].ts = Date.now()
        rows[i].time = hm
        if (text && text.length > 0) {
            var prefix = ""
            if (key.charAt(0) === "群" && !mine)
                prefix = who + ": "
            else if (mine)
                prefix = "我: "
            rows[i].preview = prefix + text
        }
        rows[i].unread++
        rebuildView()
    }

    function markRead(key) {
        var i = findRow(key)
        if (i >= 0 && rows[i].unread !== 0) {
            rows[i].unread = 0
            rebuildView()
        }
    }

    function nameFor(key, fallback) {
        var num = key.replace(/[^0-9]/g, "")
        if (key.charAt(0) === "群")
            return groupNames[num] ? groupNames[num] : (fallback || key)
        return friendNames[num] ? friendNames[num] : (fallback || key)
    }

    function openConv(key) {
        var i = findRow(key)
        if (i < 0)
            return
        rows[i].unread = 0
        rebuildView()
        // 玻璃版聊天页：优先用 ChatGlassPage，同目录试用时存在即用，否则回退原版
        var pg = pageStack.push(Qt.resolvedUrl("ChatGlassPage.qml"), {
            ob: ob,
            hub: page,
            targetKey: key,
            targetId: parseInt(key.replace(/[^0-9]/g, "")),
            isGroup: key.charAt(0) === "群",
            targetTitle: rows[i].name,
            selfId: selfId
        })
        if (pg && pg.loadHistory)
            pg.loadHistory()
    }

    function openConvByKey(key) {
        if (findRow(key) < 0) {
            rows.push({ key: key, name: nameFor(key, ""),
                        preview: "", time: "", unread: 0, ts: 0,
                        nick: "" })
            rebuildView()
        }
        openConv(key)
    }

    function reconnectBridge() {
        ob.url = ob.getSetting("connection/wsUrl",
                               "ws://127.0.0.1:3001").toString()
        ob.close()
        ob.open()
    }

    function loadContacts() {
        var e1 = ob.sendAction("get_group_list", "{}")
        pend[e1] = function(ok, d) {
            if (!ok) return
            var a = JSON.parse(d)
            for (var i in a)
                groupNames[String(a[i].group_id)] =
                        a[i].group_name || String(a[i].group_id)
            groupsDone = true
            tryPopulate()
        }
        var e2 = ob.sendAction("get_friend_list", "{}")
        pend[e2] = function(ok, d) {
            if (!ok) return
            var a = JSON.parse(d)
            for (var i in a) {
                var n = (a[i].remark && a[i].remark.length)
                        ? a[i].remark : a[i].nickname
                friendNames[String(a[i].user_id)] = n || String(a[i].user_id)
            }
            friendsDone = true
            tryPopulate()
        }
    }

    function tryPopulate() {
        if (contactsLoaded || !groupsDone || !friendsDone)
            return
        contactsLoaded = true
        var gk = Object.keys(groupNames)
        for (var i in gk) {
            var k = "群" + gk[i]
            if (findRow(k) < 0)
                rows.push({ key: k, name: groupNames[gk[i]],
                            preview: "", time: "", unread: 0, ts: 0,
                            nick: "" })
        }
        var fk = Object.keys(friendNames)
        for (var j in fk) {
            var kf = "私聊" + fk[j]
            if (findRow(kf) < 0)
                rows.push({ key: kf, name: friendNames[fk[j]],
                            preview: "", time: "", unread: 0, ts: 0,
                            nick: friendNames[fk[j]] })
        }
        rebuildView()
    }

    function refreshNames() {
        for (var i = 0; i < rows.length; i++) {
            rows[i].name = nameFor(rows[i].key, rows[i].name)
        }
        rebuildView()
    }

    function groupNamesToArray() {
        var a = []
        for (var k in groupNames)
            a.push({ group_id: k, group_name: groupNames[k] })
        return a
    }

    function friendNamesToArray() {
        var a = []
        for (var k in friendNames)
            a.push({ user_id: k, remark: "", nickname: friendNames[k] })
        return a
    }

    Notification {
        id: msgNotify
        category: "x-nemo.messaging.im"
        previewSummary: ""
        previewBody: ""
    }

    OneBotBridge {
        id: ob
        url: "ws://127.0.0.1:3001"
        onConnectedChanged: {
            if (connected) {
                var e = ob.sendAction("get_login_info", "{}")
                pend[e] = function(ok, d) {
                    if (ok) {
                        var u = JSON.parse(d)
                        selfId = u.user_id
                        loginLabel = u.nickname + " (" + u.user_id + ")"
                    }
                    loadContacts()
                }
            } else {
                loginLabel = ""
            }
        }
        Component.onCompleted: open()
    }

    Timer {
        interval: 5000
        running: !ob.connected
        repeat: true
        onTriggered: ob.open()
    }

    Connections {
        target: ob
        onActionReply: {
            if (page.pend[echo] !== undefined) {
                var cb = page.pend[echo]
                delete page.pend[echo]
                cb(ok, dataJson)
            }
        }
        onEventReceived: {
            var pk
            try { pk = JSON.parse(packet) } catch (e) { return }
            var txt = pk.text
            try {
                var imgs = JSON.parse(pk.imagesJson)
                if (imgs.length > 0 && (!txt || txt.length === 0)) {
                    txt = "[图片]"
                    for (var ii in imgs)
                        if (imgs[ii].isFile) { txt = "[文件]"; break }
                }
            } catch (e) {}
            touchConv(pk.where, pk.who, txt,
                      parseInt(pk.uid) === selfId)
        }
    }

    // —— 毛玻璃底板 ——
    GlassBackground {}

    Column {
        id: topBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: Theme.paddingSmall

        Item { width: 1; height: Theme.paddingLarge }

        // 标题栏：内容撑高（标题 Large + 状态 Small），按钮盒 itemSizeExtraSmall
        Row {
            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            height: Math.max(iconBox.height, titleCol.height)
            spacing: Theme.paddingSmall

            Column {
                id: titleCol
                width: parent.width - 2 * iconBox.width - 2 * parent.spacing
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    color: "white"
                    text: qsTr("QQ Chats")
                }
                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall
                    Rectangle {
                        id: statusDot
                        width: Math.max(8, Theme.fontSizeTiny * 0.4)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: ob.connected ? "#4ade80" : "#f87171"
                    }
                    Label {
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        opacity: 0.6
                        truncationMode: TruncationMode.Fade
                        width: parent.width - statusDot.width - parent.spacing
                        text: ob.connected
                              ? (loginLabel.length > 0 ? loginLabel : qsTr("connected"))
                              : qsTr("connecting to NapCat…")
                    }
                }
            }

            Rectangle {
                id: iconBox
                width: Theme.itemSizeExtraSmall
                height: width
                radius: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                color: "#22ffffff"
                border.width: 1; border.color: "#44ffffff"
                Label {
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeMedium
                    color: "white"
                    opacity: 0.85
                    text: "⚙"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(Qt.resolvedUrl("SettingsGlassPage.qml"),
                                              { ob: ob, hub: page })
                }
            }

            Rectangle {
                width: Theme.itemSizeExtraSmall
                height: width
                radius: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                color: "#22ffffff"
                border.width: 1; border.color: "#44ffffff"
                Label {
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeMedium
                    color: "white"
                    opacity: 0.85
                    text: "↻"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: page.loadContacts()
                }
            }
        }

        // 筛选胶囊（Theme 度量，见 GlassTabBar）
        GlassTabBar {
            x: Theme.horizontalPageMargin
            current: page.kindFilter
            onPicked: { page.kindFilter = v; page.rebuildView() }
        }

        // 搜索：卡片贴合 SearchField 内容高度
        GlassCard {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: searchField.height
            SearchField {
                id: searchField
                anchors.fill: parent
                anchors.leftMargin: Theme.paddingSmall
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeSmall
                color: "white"
                placeholderColor: "#80ffffff"
                placeholderText: qsTr("search friends and groups")
                onTextChanged: {
                    page.searchText = text
                    page.rebuildView()
                }
            }
        }

        Item { width: 1; height: Theme.paddingSmall }
    }

    SilicaListView {
        id: listView
        anchors { top: topBar.bottom; left: parent.left;
                  right: parent.right; bottom: parent.bottom }
        anchors.topMargin: Theme.paddingSmall
        model: ListModel { id: cList }
        VerticalScrollDecorator {}

        delegate: ListItem {
            id: row
            // 行高取 Theme.itemSizeMedium（与原版一致，随屏缩放）
            contentHeight: Theme.itemSizeMedium

            // 整行玻璃悬浮：左右页边距，上下各半个 paddingSmall 间隙
            GlassCard {
                x: Theme.horizontalPageMargin
                y: Theme.paddingSmall / 2
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height - Theme.paddingSmall
                radius: Theme.paddingSmall
            }

            GlassAvatar {
                id: ava
                x: Theme.horizontalPageMargin + Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                px: Theme.itemSizeSmall * 0.85
                src: {
                    var num = model.key.replace(/[^0-9]/g, "")
                    if (!num) return ""
                    if (model.key.charAt(0) === "群")
                        return "https://p.qlogo.cn/gh/" + num + "/" + num + "/100"
                    return "https://q.qlogo.cn/headimg_dl?dst_uin=" + num + "&spec=100"
                }
                fallback: model.name ? model.name.charAt(0) : "?"
            }

            Label {
                id: nameLabel
                x: ava.x + ava.width + Theme.paddingMedium
                y: Theme.paddingSmall
                width: parent.width - x - Theme.horizontalPageMargin
                       - timeLabel.width - Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                font.bold: model.unread > 0
                color: "white"
                opacity: model.unread > 0 ? 1.0 : 0.9
                truncationMode: TruncationMode.Fade
                text: model.name
            }

            Label {
                id: timeLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingSmall
                y: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "white"
                opacity: 0.5
                text: model.time
            }

            GlassBadge {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingSmall
                anchors.top: timeLabel.bottom
                anchors.topMargin: Theme.paddingSmall / 2
                count: model.unread
            }

            Label {
                x: ava.x + ava.width + Theme.paddingMedium
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                width: parent.width - x - Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "white"
                opacity: 0.6
                truncationMode: TruncationMode.Fade
                text: model.preview
            }

            onClicked: page.openConv(model.key)
        }

        ViewPlaceholder {
            enabled: cList.count === 0
            text: searchText.length > 0
                  ? qsTr("no matches") : qsTr("loading contacts…")
            hintText: ob.connected ? "" : qsTr("connecting to NapCat…")
        }
    }
}
