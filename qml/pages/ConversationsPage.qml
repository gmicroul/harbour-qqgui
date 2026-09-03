import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0
import org.nemomobile.notifications 1.0
import "../js/pinyin.js" as PinYin

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
    // source of truth for roster rows
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
        // 横幅通知：别人的消息才提醒
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
        console.log("[OPEN]", key)
        var i = findRow(key)
        if (i < 0)
            return
        rows[i].unread = 0
        rebuildView()
        var pg = pageStack.push(Qt.resolvedUrl("ChatPage.qml"), {
            ob: ob,
            hub: page,
            targetKey: key,
            targetId: parseInt(key.replace(/[^0-9]/g, "")),
            isGroup: key.charAt(0) === "群",
            targetTitle: rows[i].name,
            selfId: selfId
        })
        if (pg)
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

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: {
            var out = "== roster dump ==\n"
            for (var i = 0; i < cList.count && i < 15; i++) {
                var r = cList.get(i)
                out += i + "| " + r.name + " | " + r.preview
                       + " | u" + r.unread + " | " + r.time + "\n"
            }
            ob.writeFile("/tmp/qqcat_roster.txt", out)
        }
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

    Column {
        id: topBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Row {
            width: parent.width

            PageHeader {
                width: parent.width - settingsBtn.width - refreshBtn.width
                title: qsTr("QQ Chats")
            }

            IconButton {
                id: settingsBtn
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-about"
                onClicked: pageStack.push(Qt.resolvedUrl(
                    "SettingsPage.qml"), { ob: ob, hub: page })
            }

            IconButton {
                id: refreshBtn
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-refresh"
                onClicked: page.loadContacts()
            }
        }

        Label {
            x: Theme.horizontalPageMargin
            font.pixelSize: Theme.fontSizeExtraSmall
            color: ob.connected ? Theme.highlightColor : Theme.secondaryColor
            text: ob.connected
                  ? (loginLabel.length > 0 ? loginLabel : qsTr("connected"))
                  : qsTr("connecting to NapCat…")
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingLarge

            Repeater {
                model: [ { t: qsTr("All"), v: "" },
                         { t: qsTr("Groups"), v: "群" },
                         { t: qsTr("Friends"), v: "私聊" } ]

                delegate: Label {
                    text: modelData.t
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: page.kindFilter === modelData.v
                    color: page.kindFilter === modelData.v
                           ? Theme.highlightColor : Theme.secondaryColor

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            page.kindFilter = modelData.v
                            page.rebuildView()
                        }
                    }
                }
            }
        }

        SearchField {
            width: parent.width
            placeholderText: qsTr("search friends and groups")
            onTextChanged: {
                page.searchText = text
                page.rebuildView()
            }
        }
    }

    SilicaListView {
        id: listView
        anchors {
            top: topBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        model: ListModel { id: cList }

        VerticalScrollDecorator {}

        delegate: ListItem {
            id: row
            contentHeight: Theme.itemSizeMedium

            Rectangle {
                id: avatar
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.itemSizeSmall * 0.85
                height: width
                radius: Theme.paddingSmall
                clip: true
                color: Theme.rgba(Theme.highlightColor, 0.12)
                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: {
                        var num = model.key.replace(/[^0-9]/g, "")
                        if (!num) return ""
                        if (model.key.charAt(0) === "群") return "https://p.qlogo.cn/gh/" + num + "/" + num + "/100"
                        return "https://q.qlogo.cn/headimg_dl?dst_uin=" + num + "&spec=100"
                    }
                    asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop; smooth: true
                    visible: status === Image.Ready
                }
                Label {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: model.name ? model.name.charAt(0) : "?"
                    color: row.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                }
            }

            Label {
                x: avatar.x + avatar.width + Theme.paddingMedium
                y: Theme.paddingSmall
                width: parent.width - x - timeLabel.width - badge.width - Theme.paddingSmall
                text: model.name
                color: row.highlighted || model.unread > 0
                       ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: timeLabel
                anchors.right: badge.left
                anchors.rightMargin: Theme.paddingMedium
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                text: model.time
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Rectangle {
                id: badge
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                width: Math.max(Theme.fontSizeExtraSmall * 1.6,
                                unreadText.width + Theme.paddingSmall)
                height: width
                radius: width / 2
                visible: model.unread > 0
                color: Theme.rgba(Theme.highlightColor, 0.4)

                Label {
                    id: unreadText
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.primaryColor
                    text: model.unread > 99 ? "99+" : model.unread
                }
            }

            Label {
                x: avatar.x + avatar.width + Theme.paddingMedium
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                width: parent.width - x - Theme.horizontalPageMargin
                text: model.preview
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                truncationMode: TruncationMode.Fade
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
