import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    property var ob: null
    property var hub: null
    property string targetKey: ""
    property int targetId: 0
    property bool isGroup: true
    property string targetTitle: ""
    property int selfId: 0
    property bool emojiOpen: false
    property bool plusOpen: false
    // 长按气泡后的操作条状态
    property bool bubbleMenuOpen: false
    property string menuText: ""
    property var menuMid: 0
    property bool menuMine: false
    property string menuWho: ""
    property int mMid: 0
    property string mWho: ""
    property string mText: ""

    property var pending: ({})
    property var dlPending: ({})
    property var lastSent: null
    // 当前引用的目标消息 {mid, who, snippet}
    property var replyTarget: null
    // 已解析的引用内容缓存: msg_id -> {who, snippet}
    property var quoteCache: ({})

    function appendMsg(kind, who, text, mine, imagesJson, uid,
                       quoteWho, quoteText, quoteImgUrl, quoteImgFile) {
        // ListModel 角色表由首次 append 锁定，所有字段必须齐备
        listModel.append({ kind: kind, who: who, text: text,
                           mine: mine === true,
                           imagesJson: imagesJson ? imagesJson : "[]",
                           uid: uid || 0, mid: 0,
                           quoteWho: quoteWho || "",
                           quoteText: quoteText || "",
                           quoteImgUrl: quoteImgUrl || "",
                           quoteImgFile: quoteImgFile || "" })
        scrollToBottom()
    }

    function setRow(rowIndex, fields) {
        if (rowIndex < 0 || rowIndex >= listModel.count)
            return
        var r = listModel.get(rowIndex)
        listModel.set(rowIndex, {
            kind: r.kind, who: r.who, text: r.text, mine: r.mine,
            imagesJson: r.imagesJson, uid: r.uid, mid: r.mid,
            quoteWho: fields.quoteWho !== undefined
                      ? fields.quoteWho : r.quoteWho,
            quoteText: fields.quoteText !== undefined
                       ? fields.quoteText : r.quoteText,
            quoteImgUrl: fields.quoteImgUrl !== undefined
                         ? fields.quoteImgUrl : r.quoteImgUrl,
            quoteImgFile: fields.quoteImgFile !== undefined
                          ? fields.quoteImgFile : r.quoteImgFile
        })
    }

    function segSplit(segs) {
        var t = []
        var imgs = []
        for (var i in segs) {
            var s = segs[i]
            if (s.type === "text") {
                t.push(s.data ? s.data.text : "")
            } else if (s.type === "image") {
                imgs.push({ url: s.data && s.data.url ? s.data.url : "",
                            file: s.data && s.data.file ? s.data.file : "" })
            } else if (s.type === "face") {
                imgs.push({ faceId: s.data && s.data.id
                                    ? parseInt(s.data.id) : -1 })
            } else if (s.type === "reply") {
                imgs.push({ isReply: true,
                            rid: s.data && s.data.id ? String(s.data.id) : "",
                            ridText: s.data && s.data.text ? s.data.text : "" })
            } else if (s.type === "video") {
                imgs.push({ video: true,
                            url: s.data && s.data.url ? s.data.url : "",
                            file: s.data && s.data.file ? s.data.file : "" })
            } else if (s.type === "file") {
                imgs.push({ isFile: true,
                            name: s.data && (s.data.name || s.data.file)
                                  ? (s.data.name || s.data.file) : "file",
                            fid: s.data && s.data.file_id
                                 ? s.data.file_id : "",
                            url: s.data && s.data.url ? s.data.url : "" })
            }
        }
        return { text: t.join(" "), images: imgs }
    }

    function cleanCQ(s) {
        if (!s)
            return ""
        return String(s)
            .replace(/\[CQ:reply,[^\]]*\]/g, "[回复]")
            .replace(/\[CQ:at,qq=(\d+)[^\]]*\]/g, "@$1")
            .replace(/\[CQ:image,[^\]]*\]/g, " [图片]")
            .replace(/\[CQ:face,[^\]]*\]/g, "[表情]")
            .replace(/\[CQ:record,[^\]]*\]/g, "[语音]")
            .replace(/\[CQ:video,[^\]]*\]/g, "[视频]")
            .replace(/\[CQ:[^\]]*\]/g, " [附件]")
            .trim()
    }

    function autoIm() {
        return !ob || ob.getSetting("msg/autoImages", "true") === "true"
    }

    function applyImagePolicy(sp) {
        if (autoIm() || sp.images.length === 0)
            return sp
        sp.text = sp.text.length > 0 ? sp.text + " [图片]" : "[图片]"
        sp.images = []
        return sp
    }

    function pushViewer(src) {
        pageStack.push(Qt.resolvedUrl("ImageViewerPage.qml"), { source: src })
    }

    function openPrivate(uidStr) {
        var uid = parseInt(uidStr)
        if (hub)
            hub.openConvByKey("私聊" + uid)
    }

    function replyTo(mid, who, snippet) {
        replyTarget = { mid: mid, who: who,
                        snippet: snippet.length > 24
                                 ? snippet.substring(0, 24) + "…"
                                 : snippet }
    }

    function openAttach(dir) {
        plusOpen = false
        pageStack.push(Qt.resolvedUrl("AttachmentPage.qml"), {
            ob: ob, hub: page,
            targetId: targetId, isGroup: isGroup,
            startDir: dir
        })
    }

    function resolveImage(file, url, cb) {
        if (!file || file.length === 0) {
            cb(url && url.length > 0 ? url : "")
            return
        }
        var e = ob.sendAction("get_image", JSON.stringify({ file: file }))
        pending[e] = function(ok, data) {
            if (!ok) { cb(url && url.length > 0 ? url : ""); return }
            var d = JSON.parse(data)
            var p = d.path || d.file_path || d.file || ""
            if (p.indexOf("/") === 0)
                cb("file://" + p)
            else
                cb(url && url.length > 0 ? url : "")
        }
    }

    function resolveVideo(file, url, cb) {
        var p = (url && url.indexOf("/") === 0) ? url : ""
        if (p.length > 0) {
            var nm = "vid-" + Date.now() + ".mp4"
            var dst = "/home/defaultuser/Videos/qqcat/" + nm
            cb(nm, ob.copyFile(p, dst))
            return
        }
        if (!file || file.length === 0) { cb("", false); return }
        var e = ob.sendAction("get_video", JSON.stringify({ file: file }))
        pending[e] = function(ok, data) {
            if (!ok) { cb("", false); return }
            var d = JSON.parse(data)
            var q = d.path || d.file_path || d.file || ""
            if (q.indexOf("/") !== 0) { cb("", false); return }
            var name = "vid-" + Date.now() + ".mp4"
            cb(name, ob.copyFile(q,
               "/home/defaultuser/Videos/qqcat/" + name))
        }
    }

    function saveDownloaded(url, name, cb) {
        var nm = name && name.length > 0 ? name : "group-file"
        var dst = "/home/defaultuser/Downloads/qqcat/" + nm
        var tok = ob.downloadFile(url, dst)
        dlPending[tok] = cb
    }

    function resolveFile(fid, furl, gid, busid, cb) {
        if (furl && furl.indexOf("http") === 0) {
            saveDownloaded(furl, "", cb)
            return
        }
        if (gid && gid.length > 0) {
            var ga = { group_id: parseInt(gid), file_id: fid }
            if (busid && busid.length > 0) ga.busid = parseInt(busid)
            var e2 = ob.sendAction("get_group_file_url",
                                   JSON.stringify(ga))
            pending[e2] = function(ok, data) {
                if (!ok) { cb("", false); return }
                var d = JSON.parse(data)
                var url = d.url || d.file_url || d.file || ""
                if (url.indexOf("/") !== 0 && url.indexOf("http") !== 0) {
                    cb("", false); return
                }
                if (url.indexOf("http") === 0)
                    saveDownloaded(url, d.file_name || d.name || "", cb)
                else {
                    var base = url.split("/").pop()
                    var dst = "/home/defaultuser/Downloads/qqcat/" + base
                    cb(base, ob.copyFile(url, dst))
                }
            }
            return
        }
        if (!fid || fid.length === 0) { cb("", false); return }
        var e = ob.sendAction("get_file", JSON.stringify({ file: fid }))
        pending[e] = function(ok, data) {
            if (!ok) { cb("", false); return }
            var d = JSON.parse(data)
            var local = d.file || ""
            if (local.indexOf("/") === 0) {
                var base = local.split("/").pop()
                var dst = "/home/defaultuser/Downloads/qqcat/" + base
                cb(base, ob.copyFile(local, dst))
            } else if (d.url && d.url.indexOf("http") === 0) {
                saveDownloaded(d.url, d.file_name || "", cb)
            } else {
                cb("", false)
            }
        }
    }

    function resolveQuote(rowIndex, rid, ridText) {
        if (quoteCache[rid] !== undefined) {
            var c = quoteCache[rid]
            setRow(rowIndex, { quoteWho: c.who, quoteText: c.text,
                               quoteImgUrl: c.imgUrl || "",
                               quoteImgFile: c.imgFile || "" })
            return
        }
        // reply 段自带的预览文字（NapCat 实时附带，不依赖 get_msg）
        var inlineText = ridText && ridText.length > 0 ? ridText : ""
        if (inlineText.length > 40)
            inlineText = inlineText.substring(0, 40) + "…"
        var e = ob.sendAction("get_msg",
                              JSON.stringify({ message_id: parseInt(rid) }))
        pending[e] = function(ok, data) {
            if (!ok) return
            var d = JSON.parse(data)
            var who = d.sender && d.sender.nickname ? d.sender.nickname : "?"
            var txt = inlineText
            if (txt.length === 0) {
                txt = cleanCQ(d.raw_message)
                if (txt.length > 40) txt = txt.substring(0, 40) + "…"
                // 兜底：群消息 raw_message 常为空，从 message 段拼文字
                if (txt.length === 0 && d.message && d.message.length !== undefined) {
                    var parts = []
                    for (var ti in d.message) {
                        if (d.message[ti].type === "text") {
                            var td = d.message[ti].data
                            parts.push(td && td.text ? td.text : "")
                        }
                    }
                    txt = parts.join(" ").trim()
                    if (txt.length > 40) txt = txt.substring(0, 40) + "…"
                }
            }
            // 原消息是图片 → 提取图片段供引用块渲染预览
            var qimg = null
            if (d.message && d.message.length !== undefined) {
                for (var si in d.message) {
                    if (d.message[si].type === "image") {
                        qimg = { url: d.message[si].data.url || "",
                                 file: d.message[si].data.file || "" }
                        break
                    }
                }
            }
            quoteCache[rid] = { who: who, text: txt,
                                imgUrl: qimg ? qimg.url : "",
                                imgFile: qimg ? qimg.file : "" }
            setRow(rowIndex, { quoteWho: who,
                               quoteText: txt,
                               quoteImgUrl: qimg ? qimg.url : "",
                               quoteImgFile: qimg ? qimg.file : "" })
        }
    }

    function resolveRowQuotes(rowIndex, imagesJson) {
        var arr = []
        try { arr = JSON.parse(imagesJson) } catch (e) { return }
        for (var i in arr) {
            if (arr[i].isReply && arr[i].rid.length > 0)
                resolveQuote(rowIndex, arr[i].rid, arr[i].ridText || "")
        }
    }

    function scrollToBottom() {
        if (listModel.count > 0)
            listView.positionViewAtEnd()
    }

    function loadHistory() {
        if (!ob || !targetId || isNaN(targetId))
            return
        var n = parseInt(ob.getSetting("msg/historyCount", "30"))
        if (!(n > 0))
            n = 30
        var params = isGroup ? { group_id: targetId, count: n }
                             : { user_id: targetId, count: n,
                                 message_seq: 0 }
        var action = isGroup ? "get_group_msg_history"
                             : "get_friend_msg_history"
        pending[ob.sendAction(action, JSON.stringify(params))] =
              function(ok, data) {
            if (!ok) {
                appendMsg("sys", "", "拉取历史失败")
                return
            }
            var arr = JSON.parse(data).messages || []
            if (arr.length === 0) {
                appendMsg("sys", "", "没有更早的记录")
                return
            }
            listModel.clear()
            appendMsg("sys", "", "── 最近 " + arr.length + " 条 ──")
            for (var i in arr) {
                var m = arr[i]
                var who = m.sender && m.sender.nickname
                          ? m.sender.nickname : m.user_id
                var mine = m.sender && m.sender.user_id === selfId
                var sp = m.message && m.message.length !== undefined
                         ? segSplit(m.message)
                         : { text: cleanCQ(m.raw_message), images: [] }
                sp = applyImagePolicy(sp)
                var rowReplies = []
                var visImgs2 = []
                for (var rj in sp.images) {
                    if (sp.images[rj].isReply)
                        rowReplies.push({ rid: sp.images[rj].rid,
                                          ridText: sp.images[rj].ridText || "" })
                    else
                        visImgs2.push(sp.images[rj])
                }
                listModel.append({
                    kind: isGroup ? "群" : "私聊",
                    who: mine ? "我" : who,
                    text: sp.text,
                    mine: mine,
                    imagesJson: JSON.stringify(visImgs2),
                    uid: (m.sender && m.sender.user_id) || m.user_id || 0,
                    mid: m.message_id || 0,
                    quoteWho: "", quoteText: "",
                    quoteImgUrl: "", quoteImgFile: ""
                })
                var newIdx = listModel.count - 1
                for (var qi in rowReplies)
                    resolveQuote(newIdx, rowReplies[qi].rid,
                                 rowReplies[qi].ridText || "")
            }
            scrollToBottom()
        }
    }

    Connections {
        target: ob
        onActionReply: {
            if (page.pending[echo] !== undefined) {
                var cb = page.pending[echo]
                delete page.pending[echo]
                cb(ok, dataJson)
            }
        }
        onFileDownloadDone: {
            if (page.dlPending[token] !== undefined) {
                var cb2 = page.dlPending[token]
                delete page.dlPending[token]
                cb2(path, ok)
            }
        }
        onEventReceived: {
            var pk
            try { pk = JSON.parse(packet) } catch (e) { return }
            if (pk.where !== targetKey)
                return
            var imgs = []
            try { imgs = JSON.parse(pk.imagesJson) } catch (e) {}
            // 拆出引用段，其余图片/视频/文件照旧
            var replyIds = []
            var visImgs = []
            for (var ri in imgs) {
                if (imgs[ri].isReply)
                    replyIds.push({ rid: imgs[ri].rid,
                                    ridText: imgs[ri].ridText || "" })
                else
                    visImgs.push(imgs[ri])
            }
            var txt = cleanCQ(pk.text)
            if (!autoIm() && visImgs.length > 0)
                txt = txt.length > 0 ? txt + " [图片]" : "[图片]"
            var mine = parseInt(pk.uid) === selfId
            if (mine && lastSent && lastSent.text === pk.text
                    && Date.now() - lastSent.ts < 5000)
                return
            listModel.append({ kind: isGroup ? "群" : "私聊",
                               who: mine ? "我" : pk.who,
                               text: txt,
                               mine: mine,
                               imagesJson: autoIm()
                                           ? JSON.stringify(visImgs) : "[]",
                               uid: parseInt(pk.uid) || 0,
                               mid: parseInt(pk.mid) || 0,
                               quoteWho: "", quoteText: "",
                               quoteImgUrl: "", quoteImgFile: "" })
            var newRow = listModel.count - 1
            for (var qi in replyIds)
                resolveQuote(newRow, replyIds[qi].rid,
                             replyIds[qi].ridText || "")
            if (hub)
                hub.markRead(targetKey)
            scrollToBottom()
        }
    }

    // ===== Glass UI =====
    GlassBackground { anchors.fill: parent }

    Rectangle {
        id: headerBar
        width: parent.width
        height: 84
        color: Qt.rgba(0.09,0.11,0.22,0.52)
        border.color: Qt.rgba(1,1,1,0.10)
        border.width: 1
        z: 2
        clip: false
        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingSmall
            IconButton {
                icon.source: "image://theme/icon-m-back"
                icon.color: "white"
                onClicked: pageStack.pop()
            }
            Rectangle {
                width: 40; height: 40; radius: 12
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(1,1,1,0.08)
                border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                Image {
                    anchors.fill: parent
                    source: isGroup ? "https://p.qlogo.cn/gh/" + targetId + "/" + targetId + "/100" : "https://q.qlogo.cn/headimg_dl?dst_uin=" + targetId + "&spec=100"
                    asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop; smooth: true
                }
            }
            Column {
                anchors.top: parent.top
                anchors.topMargin: 14
                spacing: 3
                width: page.width - 148
                Label {
                    width: parent.width
                    text: page.targetTitle
                    color: "white"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    truncationMode: TruncationMode.Fade
                    elide: Text.ElideRight
                    lineHeight: 1.1
                }
                Label {
                    width: parent.width
                    text: isGroup ? qsTr("Group") + " · " + targetId : qsTr("Private") + " · " + targetId
                    color: Qt.rgba(1,1,1,0.45)
                    font.pixelSize: Theme.fontSizeTiny
                    truncationMode: TruncationMode.Fade
                    elide: Text.ElideRight
                    lineHeight: 1.0
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPageMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingSmall
            Rectangle {
                width: 56; height: 56; radius: 28
                color: refreshMouse.pressed ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
                border.color: Qt.rgba(1,1,1,0.16)
                border.width: 1
                Image {
                    anchors.centerIn: parent
                    width: 28; height: 28
                    source: "image://theme/icon-m-refresh"
                    smooth: true
                }
                MouseArea { id: refreshMouse; anchors.fill: parent; onClicked: page.loadHistory() }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
    }

    SilicaListView {
        id: listView
        anchors.top: headerBar.bottom
        anchors.bottom: composer.top
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        model: ListModel { id: listModel }
        spacing: Theme.paddingSmall
        topMargin: Theme.paddingMedium
        bottomMargin: Theme.paddingMedium
        VerticalScrollDecorator {}
        PullDownMenu {
            MenuItem { text: qsTr("Load history"); onClicked: page.loadHistory() }
            MenuItem { text: qsTr("Clear view"); onClicked: listModel.clear() }
        }

        delegate: Item {
            width: listView.width
            height: bubble.height + Theme.paddingMedium

            Label {
                visible: model.kind === "sys"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Qt.rgba(1,1,1,0.62)
                text: "· " + model.text
            }

            Rectangle {
                id: bubble
                visible: model.kind !== "sys"
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                x: model.mine ? parent.width - width - 14 : Theme.horizontalPageMargin
                width: Math.min(body.width + 2 * Theme.paddingLarge, parent.width * 0.78)
                height: body.height + 2 * Theme.paddingSmall
                radius: 18
                color: model.mine ? Qt.rgba(0.48,0.56,1.0,0.18) : Qt.rgba(1,1,1,0.08)
                border.color: model.mine ? Qt.rgba(0.66,0.73,1.0,0.32) : Qt.rgba(1,1,1,0.13)
                border.width: 1
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    radius: parent.radius
                    color: Qt.rgba(1,1,1, model.mine ? 0.22 : 0.14)
                }

                MouseArea {
                    anchors.fill: parent
                    onPressAndHold: {
                        page.menuMid = model.mid
                        page.menuMine = model.mine
                        page.menuWho = model.who
                        page.menuText = model.text
                        page.bubbleMenuOpen = true
                    }
                }

                Column {
                    id: body
                    x: Theme.paddingLarge
                    y: Theme.paddingSmall
                    spacing: -Theme.paddingSmall

                    Item { width: 1; height: Theme.paddingSmall / 2 }

                    Row {
                        spacing: 6
                        Rectangle {
                            width: 20; height: 20; radius: 6
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(1,1,1,0.08)
                            border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                            Image {
                                anchors.fill: parent
                                source: {
                                    var u = model.mine ? page.selfId : model.uid
                                    return u ? "https://q.qlogo.cn/headimg_dl?dst_uin=" + u + "&spec=100" : ""
                                }
                                asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop; smooth: true
                            }
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: model.mine ? Qt.rgba(1,1,1,0.92) : Qt.rgba(0.72,0.78,1.0,0.95)
                            font.bold: true
                            text: model.mine ? "我" : (isGroup ? (model.who + " ▸") : model.who)
                            MouseArea {
                                anchors.fill: parent
                                enabled: isGroup && model.uid > 0 && model.uid !== page.selfId
                                onClicked: page.openPrivate(model.uid)
                            }
                        }
                    }

                    Rectangle {
                        id: quoteBlock
                        visible: model.quoteWho.length > 0
                        width: Math.min(listView.width * 0.78 - 2 * Theme.paddingLarge, 240)
                        height: qcol.height + Theme.paddingSmall
                        radius: 10
                        color: Qt.rgba(1,1,1,0.08)
                        border.color: Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Rectangle { width: 3; height: parent.height - 12; x: 6; y: 6; radius: 2; color: model.mine ? Qt.rgba(0.66,0.73,1.0,0.9) : Qt.rgba(1,1,1,0.32) }
                        Column {
                            id: qcol
                            x: Theme.paddingSmall
                            y: Theme.paddingSmall
                            spacing: 2
                            Label { font.pixelSize: Theme.fontSizeTiny; font.bold: true; color: Qt.rgba(0.72,0.78,1.0,1); text: model.quoteWho }
                            Label { visible: model.quoteText.length > 0; width: quoteBlock.width - 2 * Theme.paddingSmall; font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.58); text: model.quoteText; wrapMode: Text.WrapAnywhere; maximumLineCount: 2 }
                            Image {
                                visible: model.quoteImgUrl.length > 0
                                width: 160
                                height: 110
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                property string localSrc: ""
                                source: localSrc.length > 0 ? localSrc : model.quoteImgUrl
                                onStatusChanged: {
                                    if (status === Image.Error && !localSrc.length)
                                        page.resolveImage(model.quoteImgFile, "", function(fp) {
                                            if (fp.indexOf("file://") === 0) localSrc = fp
                                        })
                                }
                            }
                        }
                    }

                    Label {
                        visible: model.text.length > 0
                        width: Math.min(implicitWidth, listView.width * 0.78 - 2 * Theme.paddingLarge)
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        text: model.text
                    }

                    Flow {
                        id: imgFlow
                        spacing: Theme.paddingSmall
                        Component.onCompleted: {
                            var arr = []
                            try { arr = JSON.parse(model.imagesJson) } catch (e) { arr = [] }
                            for (var i = 0; i < arr.length; i++) {
                                if (arr[i].faceId !== undefined) {
                                    Qt.createComponent("FaceTile.qml").createObject(imgFlow, { faceId: arr[i].faceId })
                                } else if (arr[i].isFile) {
                                    Qt.createComponent("FileTile.qml").createObject(imgFlow, { fname: arr[i].name, fid: arr[i].fid, furl: arr[i].url ? arr[i].url : "", gid: arr[i].gid ? arr[i].gid : "", busid: arr[i].busid ? arr[i].busid : "", pageRef: page })
                                } else if (arr[i].video) {
                                    Qt.createComponent("VideoTile.qml").createObject(imgFlow, { vidUrl: arr[i].url, vidFile: arr[i].file, pageRef: page })
                                } else if (page.autoIm() && (arr[i].file || arr[i].url)) {
                                    Qt.createComponent("ImageTile.qml").createObject(imgFlow, { imgUrl: arr[i].url, imgFile: arr[i].file, pageRef: page })
                                }
                            }
                        }
                    }
                }
            }
        }
        ViewPlaceholder { enabled: listModel.count === 0; text: page.targetTitle; hintText: qsTr("no messages yet — say hi!") }
    }

    Rectangle {
        id: composer
        width: parent.width
        height: innerCol.height + 20
        anchors.bottom: parent.bottom
        color: Qt.rgba(0.10,0.12,0.24,0.58)
        border.color: Qt.rgba(1,1,1,0.11)
        border.width: 1
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.10) }

        Column {
            id: innerCol
            width: parent.width - 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            spacing: 8

            EmojiPanel { id: emojiPanel; visible: emojiOpen; width: parent.width; onEmojiPicked: inputField.text = inputField.text + emo }

            Rectangle {
                visible: bubbleMenuOpen
                width: parent.width
                height: menuRow.height + 18
                radius: 16
                color: Qt.rgba(1,1,1,0.09)
                border.color: Qt.rgba(1,1,1,0.14)
                border.width: 1
                Row {
                    id: menuRow
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: (width - 74 -74 -84 -44)/3
                    Rectangle { height: 40; radius: 20; width: 74; color: Qt.rgba(1,1,1,0.10); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
                        Label { anchors.centerIn: parent; text: qsTr("Copy"); font.pixelSize: Theme.fontSizeSmall; color: "white" }
                        MouseArea { anchors.fill: parent; onClicked: { ob.copyText(page.menuText); page.bubbleMenuOpen = false } }
                    }
                    Rectangle { height: 40; radius: 20; width: 74; color: page.menuMid !== 0 ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.05); border.color: page.menuMid !== 0 ? Qt.rgba(0.66,0.73,1.0,0.32) : Qt.rgba(1,1,1,0.08); border.width: 1; opacity: page.menuMid !== 0 ? 1 : 0.35; enabled: page.menuMid !== 0
                        Label { anchors.centerIn: parent; text: qsTr("Reply"); font.pixelSize: Theme.fontSizeSmall; color: "white"; opacity: parent.enabled ? 1 : 0.4 }
                        MouseArea { anchors.fill: parent; enabled: parent.enabled; onClicked: { page.replyTo(page.menuMid, page.menuWho, page.menuText); page.bubbleMenuOpen = false } }
                    }
                    Rectangle { height: 40; radius: 20; width: 84; color: (isGroup && !page.menuMine && page.menuWho.length > 0) ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.05); border.color: (isGroup && !page.menuMine && page.menuWho.length > 0) ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.08); border.width: 1; opacity: (isGroup && !page.menuMine && page.menuWho.length > 0) ? 1 : 0.35; enabled: isGroup && !page.menuMine && page.menuWho.length > 0
                        Label { anchors.centerIn: parent; text: "@" + (page.menuWho || "").substring(0, 6); font.pixelSize: Theme.fontSizeSmall; color: "white"; opacity: parent.enabled ? 1 : 0.4 }
                        MouseArea { anchors.fill: parent; enabled: parent.enabled; onClicked: { inputField.text = inputField.text + "@" + page.menuWho + " "; inputField.focus = true; page.bubbleMenuOpen = false } }
                    }
                    Rectangle { height: 40; radius: 20; width: 44; color: Qt.rgba(1,0.3,0.3,0.16); border.color: Qt.rgba(1,0.4,0.4,0.22); border.width: 1
                        Label { anchors.centerIn: parent; text: "✕"; color: Qt.rgba(1,0.6,0.6,1); font.pixelSize: Theme.fontSizeSmall }
                        MouseArea { anchors.fill: parent; onClicked: page.bubbleMenuOpen = false }
                    }
                }
            }

            Row {
                visible: plusOpen
                width: parent.width
                spacing: 8
                Rectangle { width: (parent.width - 8)/2; height: 38; radius: 12; color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                    Label { anchors.centerIn: parent; text: qsTr("Image"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                    MouseArea { anchors.fill: parent; onClicked: openAttach("/home/defaultuser/Pictures") }
                }
                Rectangle { width: (parent.width - 8)/2; height: 38; radius: 12; color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                    Label { anchors.centerIn: parent; text: qsTr("File"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
                    MouseArea { anchors.fill: parent; onClicked: openAttach("/home/defaultuser/Downloads") }
                }
            }

            Row {
                visible: replyTarget !== null
                width: parent.width
                spacing: 8
                Rectangle { width: 3; height: replyCol.height; radius: 2; color: "#7c8bff" }
                Column {
                    id: replyCol
                    width: parent.width - cancelBtn.width - 16
                    Label { font.pixelSize: Theme.fontSizeExtraSmall; color: "#9aa3ff"; text: replyTarget ? qsTr("reply to ") + replyTarget.who : "" }
                    Label { width: parent.width; font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.52); truncationMode: TruncationMode.Fade; text: replyTarget ? replyTarget.snippet : "" }
                }
                IconButton { id: cancelBtn; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; icon.source: "image://theme/icon-m-clear"; icon.color: "white"; onClicked: replyTarget = null }
            }

            Row {
                id: sendRow
                width: parent.width
                spacing: 8
                Rectangle {
                    id: emojiChip; width: 52; height: 52; radius: 14
                    color: emojiOpen ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                    border.color: emojiOpen ? Qt.rgba(0.66,0.73,1.0,0.32) : Qt.rgba(1,1,1,0.12)
                    border.width: 1
                    Label { anchors.centerIn: parent; font.pixelSize: Theme.fontSizeLarge; text: "😊" }
                    MouseArea { anchors.fill: parent; onClicked: { emojiOpen = !emojiOpen; plusOpen = false } }
                }
                Rectangle {
                    id: plusChip; width: 52; height: 52; radius: 14
                    color: plusOpen ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                    border.color: plusOpen ? Qt.rgba(0.66,0.73,1.0,0.32) : Qt.rgba(1,1,1,0.12)
                    border.width: 1
                    Label { anchors.centerIn: parent; font.pixelSize: 28; color: plusOpen ? "#9aa3ff" : Qt.rgba(1,1,1,0.72); text: "+" }
                    MouseArea { anchors.fill: parent; onClicked: { plusOpen = !plusOpen; emojiOpen = false } }
                }
                TextArea {
                    id: inputField
                    width: parent.width - emojiChip.width - plusChip.width - sendButton.width - 3 * parent.spacing
                    height: Math.min(Math.max(implicitHeight, Theme.itemSizeSmall * 0.85), Theme.itemSizeSmall * 3.2)
                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: Theme.fontSizeSmall
                    color: "white"
                    placeholderText: qsTr("message")
                    placeholderColor: Qt.rgba(1,1,1,0.32)
                    background: Rectangle {
                        radius: 14
                        color: Qt.rgba(1,1,1,0.08)
                        border.color: inputField.activeFocus ? Qt.rgba(0.66,0.73,1.0,0.38) : Qt.rgba(1,1,1,0.12)
                        border.width: 1
                    }
                    EnterKey.enabled: text.trim().length > 0
                    EnterKey.onClicked: sendButton.doSend()
                }
                Rectangle {
                    id: sendButton
                    width: 64; height: 52; radius: 16
                    color: inputField.text.trim().length > 0 ? Qt.rgba(0.48,0.56,1.0,0.92) : Qt.rgba(1,1,1,0.10)
                    border.color: inputField.text.trim().length > 0 ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
                    border.width: 1
                    opacity: inputField.text.trim().length > 0 ? 1 : 0.6
                    Label { anchors.centerIn: parent; text: "➤"; color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
                    MouseArea { anchors.fill: parent; enabled: inputField.text.trim().length > 0; onClicked: sendButton.doSend() }
                    function doSend() {
                        var txt = inputField.text; var segs = []
                        if (replyTarget) segs.push({ type: "reply", data: { id: String(replyTarget.mid) } })
                        segs.push({ type: "text", data: { text: txt } })
                        var params = isGroup ? JSON.stringify({ group_id: targetId, message: segs }) : JSON.stringify({ user_id: targetId, message: segs })
                        pending[ob.sendAction(isGroup ? "send_group_msg" : "send_private_msg", params)] = function(ok) {
                            if (ok) { lastSent = { text: txt, ts: Date.now() }; appendMsg(isGroup ? "群" : "私聊", "我", txt, true); if (hub) hub.touchConv(targetKey, "我", txt); replyTarget = null; inputField.text = "" } else appendMsg("sys", "", "发送失败 ✗")
                        }
                    }
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
