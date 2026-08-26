import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0

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
    property int menuMid: 0
    property string menuWho: ""
    property int mMid: 0
    property string mWho: ""
    property string mText: ""

    property var pending: ({})
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
                            rid: s.data && s.data.id ? String(s.data.id) : "" })
            } else if (s.type === "video") {
                imgs.push({ video: true,
                            url: s.data && s.data.url ? s.data.url : "",
                            file: s.data && s.data.file ? s.data.file : "" })
            } else if (s.type === "file") {
                imgs.push({ isFile: true,
                            name: s.data && (s.data.name || s.data.file)
                                  ? (s.data.name || s.data.file) : "file",
                            fid: s.data && s.data.file_id
                                 ? s.data.file_id : "" })
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

    function resolveFile(fid, cb) {
        if (!fid || fid.length === 0) { cb("", false); return }
        var e = ob.sendAction("get_file", JSON.stringify({ file_id: fid }))
        pending[e] = function(ok, data) {
            if (!ok) { cb("", false); return }
            var d = JSON.parse(data)
            var p = d.path || d.file_path || d.file || ""
            if (p.indexOf("/") !== 0) { cb("", false); return }
            var base = p.split("/").pop()
            var dst = "/home/defaultuser/Downloads/qqcat/" + base
            cb(base, ob.copyFile(p, dst))
        }
    }

    function resolveQuote(rowIndex, rid) {
        if (quoteCache[rid] !== undefined) {
            var c = quoteCache[rid]
            setRow(rowIndex, { quoteWho: c.who, quoteText: c.text })
            return
        }
        var e = ob.sendAction("get_msg",
                              JSON.stringify({ message_id: parseInt(rid) }))
        pending[e] = function(ok, data) {
            if (!ok) return
            var d = JSON.parse(data)
            var who = d.sender && d.sender.nickname ? d.sender.nickname : "?"
            var txt = cleanCQ(d.raw_message)
            if (txt.length > 40) txt = txt.substring(0, 40) + "…"
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
            if (qimg) txt = ""
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
                resolveQuote(rowIndex, arr[i].rid)
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
                        rowReplies.push(sp.images[rj].rid)
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
                    resolveQuote(newIdx, rowReplies[qi])
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
                    replyIds.push(imgs[ri].rid)
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
                resolveQuote(newRow, replyIds[qi])
            if (hub)
                hub.markRead(targetKey)
            scrollToBottom()
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        anchors.bottomMargin: composer.height
        model: ListModel { id: listModel }

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Load history")
                onClicked: page.loadHistory()
            }
            MenuItem {
                text: qsTr("Clear view")
                onClicked: listModel.clear()
            }
        }

        header: Column {
            width: listView.width
            PageHeader { title: page.targetTitle }
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
                color: Theme.secondaryColor
                text: "· " + model.text
            }

            Rectangle {
                id: bubble
                visible: model.kind !== "sys"
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                x: model.mine
                   ? parent.width - width - Theme.horizontalPageMargin
                   : Theme.horizontalPageMargin
                width: Math.min(body.width + 2 * Theme.paddingLarge,
                                parent.width * 0.78)
                height: body.height + 2 * Theme.paddingSmall
                radius: Theme.paddingSmall
                color: model.mine
                       ? Theme.rgba(Theme.highlightColor, 0.32)
                       : Theme.rgba(Theme.secondaryColor, 0.13)

                MouseArea {
                    anchors.fill: parent
                    onPressAndHold: {
                        page.menuMid = model.mid
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

                    Label {
                        visible: !model.mine
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        text: isGroup ? (model.who + " ▸") : model.who

                        MouseArea {
                            anchors.fill: parent
                            enabled: isGroup && model.uid > 0
                                     && model.uid !== page.selfId
                            onClicked: page.openPrivate(model.uid)
                        }
                    }

                    Rectangle {
                        visible: model.quoteWho.length > 0
                        width: parent.width
                        height: qcol.height + Theme.paddingSmall
                        radius: 4
                        color: Theme.rgba(Theme.secondaryColor, 0.18)

                        Column {
                            id: qcol
                            x: Theme.paddingSmall
                            y: Theme.paddingSmall
                            spacing: 0

                            Label {
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.highlightColor
                                text: model.quoteWho
                            }

                            // 被引用的图片：图床直链失败自动换本地缓存
                            Image {
                                visible: model.quoteImgUrl.length > 0
                                width: 170
                                height: 120
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                property string localSrc: ""
                source: localSrc.length > 0 ? localSrc
                                            : model.quoteImgUrl
                onStatusChanged: {
                    if (status === Image.Error && !localSrc.length)
                        page.resolveImage(model.quoteImgFile, "",
                                          function(fp) {
                                              if (fp.indexOf("file://") === 0)
                                                  localSrc = fp
                                          })
                }
                            }
                        }
                    }

                    Label {
                        visible: model.text.length > 0
                        width: Math.min(implicitWidth,
                                        listView.width * 0.78
                                        - 2 * Theme.paddingLarge)
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        text: model.text
                    }

                    Flow {
                        id: imgFlow
                        spacing: Theme.paddingSmall

                        Component.onCompleted: {
                            var arr = []
                            try { arr = JSON.parse(model.imagesJson) }
                            catch (e) { arr = [] }
                            for (var i = 0; i < arr.length; i++) {
                                if (arr[i].faceId !== undefined) {
                                    Qt.createComponent("FaceTile.qml")
                                      .createObject(imgFlow, {
                                          faceId: arr[i].faceId
                                      })
                                } else if (arr[i].isFile) {
                                    Qt.createComponent("FileTile.qml")
                                      .createObject(imgFlow, {
                                          fname: arr[i].name,
                                          fid: arr[i].fid,
                                          pageRef: page
                                      })
                                } else if (arr[i].video) {
                                    Qt.createComponent("VideoTile.qml")
                                      .createObject(imgFlow, {
                                          vidUrl: arr[i].url,
                                          vidFile: arr[i].file,
                                          pageRef: page
                                      })
                                } else if (page.autoIm()
                                           && (arr[i].file || arr[i].url)) {
                                    Qt.createComponent("ImageTile.qml")
                                      .createObject(imgFlow, {
                                          imgUrl: arr[i].url,
                                          imgFile: arr[i].file,
                                          pageRef: page
                                      })
                                }
                            }
                        }
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: page.targetTitle
            hintText: qsTr("no messages yet — say hi!")
        }
    }

    DockedPanel {
        id: composer
        open: true
        width: parent.width
        height: innerCol.height + 2 * Theme.paddingMedium

        Column {
            id: innerCol
            width: parent.width - Theme.paddingMedium * 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall

            EmojiPanel {
                id: emojiPanel
                visible: emojiOpen
                width: parent.width
                onEmojiPicked: inputField.text = inputField.text + emo
            }

            // 长按消息后的操作条
            Rectangle {
                visible: bubbleMenuOpen
                width: parent.width
                height: menuRow.height + Theme.paddingSmall * 2
                radius: Theme.paddingSmall
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.25)

                Row {
                    id: menuRow
                    anchors.centerIn: parent
                    spacing: Theme.paddingMedium

                    Button {
                        text: qsTr("Copy")
                        onClicked: {
                            ob.copyText(page.menuText)
                            page.bubbleMenuOpen = false
                        }
                    }
                    Button {
                        visible: page.menuMid > 0
                        text: qsTr("Reply")
                        onClicked: {
                            page.replyTo(page.menuMid,
                                         page.menuWho, page.menuText)
                            page.bubbleMenuOpen = false
                        }
                    }
                    Button {
                        visible: isGroup && !page.menuMine
                                 && page.menuWho.length > 0
                        text: "@" + (page.menuWho || "").substring(0, 6)
                        onClicked: {
                            inputField.text =
                                inputField.text + "@" + page.menuWho + " "
                            inputField.focus = true
                            page.bubbleMenuOpen = false
                        }
                    }
                }
            }

            Row {
                visible: plusOpen
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - parent.spacing) / 2
                    text: qsTr("Image")
                    onClicked: openAttach("/home/defaultuser/Pictures")
                }
                Button {
                    width: (parent.width - parent.spacing) / 2
                    text: qsTr("File")
                    onClicked: openAttach("/home/defaultuser/Downloads")
                }
            }

            Row {
                visible: replyTarget !== null
                width: parent.width
                spacing: Theme.paddingSmall

                Rectangle {
                    width: 4
                    height: replyCol.height
                    color: Theme.highlightColor
                }
                Column {
                    id: replyCol
                    width: parent.width - cancelBtn.width
                           - 4 * Theme.paddingSmall
                    Label {
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        text: replyTarget
                              ? qsTr("reply to ") + replyTarget.who : ""
                    }
                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                        text: replyTarget ? replyTarget.snippet : ""
                    }
                }
                IconButton {
                    id: cancelBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.itemSizeExtraSmall
                    height: width
                    icon.source: "image://theme/icon-m-clear"
                    onClicked: replyTarget = null
                }
            }

            Row {
                id: sendRow
                width: parent.width
                spacing: Theme.paddingSmall

                Rectangle {
                    id: emojiChip
                    width: Theme.itemSizeSmall * 0.85
                    height: Theme.itemSizeSmall * 0.85
                    radius: Theme.paddingSmall
                    color: emojiOpen
                           ? Theme.rgba(Theme.highlightColor, 0.35)
                           : "transparent"

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeMedium
                        text: "😊"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            emojiOpen = !emojiOpen
                            plusOpen = false
                        }
                    }
                }

                Rectangle {
                    id: plusChip
                    width: Theme.itemSizeSmall * 0.85
                    height: Theme.itemSizeSmall * 0.85
                    radius: Theme.paddingSmall
                    color: plusOpen
                           ? Theme.rgba(Theme.highlightColor, 0.35)
                           : "transparent"

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeLarge
                        color: plusOpen ? Theme.highlightColor
                                        : Theme.secondaryColor
                        text: "+"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            plusOpen = !plusOpen
                            emojiOpen = false
                        }
                    }
                }

                TextArea {
                    id: inputField
                    width: parent.width - emojiChip.width - plusChip.width
                           - sendButton.width - 3 * parent.spacing
                    // grows with content: min 1 line, max ~3 lines
                    height: Math.min(Math.max(implicitHeight,
                                              Theme.itemSizeSmall * 0.9),
                                     Theme.itemSizeSmall * 4.5)
                    wrapMode: TextEdit.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    placeholderText: qsTr("message")
                    EnterKey.enabled: text.trim().length > 0
                    EnterKey.onClicked: sendButton.doSend()
                }

                Button {
                    id: sendButton
                    width: Theme.itemSizeSmall * 1.05
                    text: "\u27A4"
                    enabled: inputField.text.trim().length > 0
                    onClicked: doSend()

                    function doSend() {
                        var txt = inputField.text
                        var segs = []
                        if (replyTarget)
                            segs.push({ type: "reply",
                                        data: { id: String(replyTarget.mid) } })
                        segs.push({ type: "text", data: { text: txt } })
                        var params = isGroup
                            ? JSON.stringify({ group_id: targetId,
                                               message: segs })
                            : JSON.stringify({ user_id: targetId,
                                               message: segs })
                        pending[ob.sendAction(
                            isGroup ? "send_group_msg"
                                    : "send_private_msg",
                            params)] = function(ok) {
                            if (ok) {
                                // NapCat 不回显自己发的消息，本地立即渲染
                                lastSent = { text: txt, ts: Date.now() }
                                appendMsg(isGroup ? "群" : "私聊",
                                          "我", txt, true)
                                if (hub)
                                    hub.touchConv(targetKey, "我", txt)
                                replyTarget = null
                                inputField.text = ""
                            } else {
                                appendMsg("sys", "", "发送失败 ✗")
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // push() assigns properties after construction; the real
        // history load is triggered by ConversationsPage.openConv()
    }
}
