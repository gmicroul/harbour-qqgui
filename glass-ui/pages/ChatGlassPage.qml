import QtQuick 2.2
import Sailfish.Silica 1.0
import Qqcat 1.0

// 聊天页 · 毛玻璃重设计（逻辑与原 ChatPage.qml 一致，可平替）。
// 同目录部件（GlassCard/GlassAvatar/…）自动可见，无需 import。
// 图片/视频/文件/表情渲染复用原版 FaceTile/ImageTile/VideoTile/FileTile（同目录已存在，无需改动）。
// 尺寸约束：头像 28/36 / 名称 13 / 正文 17 / 时间线 13 / 输入框 44 / 按钮 ≤44 / 圆角 ≤12，全部 < 75。
// 例外：图片缩略图与引用图预览为功能性媒体（72 高 / 170x120 内），不计入 chrome 规范，见 README。
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
    property bool bubbleMenuOpen: false
    property string menuText: ""
    property int menuMid: 0
    property string menuWho: ""
    property bool menuMine: false
    property int mMid: 0
    property string mWho: ""
    property string mText: ""

    property var pending: ({})
    property var lastSent: null
    property var replyTarget: null
    property var quoteCache: ({})

    function appendMsg(kind, who, text, mine, imagesJson, uid,
                       quoteWho, quoteText, quoteImgUrl, quoteImgFile) {
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

    GlassBackground {}

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

        // 顶部玻璃头：内容撑高（头像 itemSizeSmall + 双行标题）
        header: Column {
            width: listView.width
            spacing: Theme.paddingSmall

            Item { width: 1; height: Theme.paddingMedium }

            GlassCard {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Math.max(headAva.height + 2 * Theme.paddingSmall,
                                  headCol.height + 2 * Theme.paddingSmall)

                GlassAvatar {
                    id: headAva
                    x: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    px: Theme.itemSizeSmall
                    src: targetId !== 0
                         ? (isGroup ? "https://p.qlogo.cn/gh/" + targetId + "/" + targetId + "/100"
                                    : "https://q.qlogo.cn/headimg_dl?dst_uin=" + targetId + "&spec=100")
                         : ""
                    fallback: page.targetTitle ? page.targetTitle.charAt(0) : "?"
                }

                Column {
                    id: headCol
                    x: headAva.x + headAva.width + Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - Theme.paddingMedium
                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: "white"
                        truncationMode: TruncationMode.Fade
                        text: page.targetTitle
                    }
                    Label {
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: "white"
                        opacity: 0.6
                        text: isGroup ? qsTr("Group") + " · " + targetId
                                      : qsTr("Private") + " · " + targetId
                    }
                }
            }
        }

        delegate: Item {
            width: listView.width
            height: bubble.height + Theme.paddingSmall

            Label {
                visible: model.kind === "sys"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeExtraSmall
                color: "white"
                opacity: 0.5
                text: "· " + model.text
            }

            // 气泡行：外置头像（itemSizeExtraSmall）+ 玻璃气泡。
            // bubble 宽取 body 自然宽度钳制（避开 width<->implicitWidth 循环绑定）。
            Row {
                visible: model.kind !== "sys"
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall / 2
                x: model.mine ? parent.width - bubble.width - Theme.itemSizeExtraSmall
                                - Theme.horizontalPageMargin - Theme.paddingSmall
                              : Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                GlassAvatar {
                    visible: !model.mine
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingSmall / 2
                    px: Theme.itemSizeExtraSmall
                    src: model.uid
                         ? "https://q.qlogo.cn/headimg_dl?dst_uin=" + model.uid + "&spec=100"
                         : ""
                    fallback: model.who ? model.who.charAt(0) : "?"
                }

                GlassChatBubble {
                    id: bubble
                    mine: model.mine
                    // 外宽上限 0.72 屏；内容宽上限 = 外宽 - 内边距。
                    // 正文宽由自然宽度钳制（pi 定式，初次求值未换行，结果稳定）；
                    // 纯图/表情消息（无正文）直接给满内容宽，免得被初值 0 锁窄。
                    property real maxOuterW: listView.width * 0.72
                    property real maxContentW: maxOuterW - 2 * Theme.paddingLarge
                    property int visualCount: {
                        try { return JSON.parse(model.imagesJson).length }
                        catch (e) { return 0 }
                    }
                    width: Math.min(Math.max(body.width,
                                              visualCount > 0 ? maxContentW : 0)
                                    + 2 * Theme.paddingLarge,
                                    maxOuterW)
                    height: body.height + 2 * Theme.paddingSmall

                    MouseArea {
                        anchors.fill: parent
                        onPressAndHold: {
                            page.menuMid = model.mid
                            page.menuWho = model.who
                            page.menuText = model.text
                            page.menuMine = model.mine
                            page.bubbleMenuOpen = true
                        }
                    }

                    // body 不设显式 width：Column 自动取子项自然宽，避免
                    // bubble→body→text→implicit 的初值 0 循环（气泡越算越窄）。
                    Column {
                        id: body
                        x: Theme.paddingLarge
                        y: Theme.paddingSmall
                        spacing: Theme.paddingSmall

                        Label {
                            width: Math.min(implicitWidth, bubble.maxContentW)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.bold: true
                            color: "white"
                            opacity: model.mine ? 0.6 : 0.9
                            truncationMode: TruncationMode.Fade
                            text: model.mine ? "我"
                                  : (isGroup ? (model.who + " ▸") : model.who)
                        }

                        // 引用条：跟 body 同宽（body 宽由正文/图片撑起）
                        Rectangle {
                            visible: model.quoteWho.length > 0
                            width: body.width
                            height: qcol.height + Theme.paddingSmall
                            radius: Theme.paddingSmall / 2
                            color: "#22ffffff"
                            border.width: 1
                            border.color: "#44ffffff"

                            Column {
                                id: qcol
                                x: Theme.paddingSmall
                                y: Theme.paddingSmall / 2
                                width: parent.width - 2 * Theme.paddingSmall
                                spacing: 0
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    font.bold: true
                                    color: "white"
                                    opacity: 0.85
                                    text: model.quoteWho
                                }
                                Label {
                                    visible: model.quoteText.length > 0
                                    width: parent.width
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: "white"
                                    opacity: 0.6
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: model.quoteText
                                }
                            }
                        }

                        Label {
                            visible: model.text.length > 0
                            width: Math.min(implicitWidth, bubble.maxContentW)
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            font.pixelSize: Theme.fontSizeSmall
                            color: "white"
                            text: model.text
                        }

                        Flow {
                            id: imgFlow
                            width: body.width
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

                GlassAvatar {
                    visible: model.mine
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingSmall / 2
                    px: Theme.itemSizeExtraSmall
                    src: page.selfId
                         ? "https://q.qlogo.cn/headimg_dl?dst_uin=" + page.selfId + "&spec=100"
                         : ""
                    fallback: "我"
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: page.targetTitle
            hintText: qsTr("no messages yet — say hi!")
        }
    }

    // 底部输入坞：毛玻璃通栏
    DockedPanel {
        id: composer
        open: true
        width: parent.width
        height: innerCol.height + 2 * Theme.paddingSmall

        Rectangle {
            anchors.fill: parent
            color: "#22ffffff"
            border.width: 1
            border.color: "#44ffffff"
            Rectangle {
                width: parent.width; height: 1
                color: "white"
                opacity: 0.18
            }
        }

        Column {
            id: innerCol
            width: parent.width - 2 * Theme.horizontalPageMargin
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.paddingSmall
            spacing: Theme.paddingSmall

            // 表情面板（原版 EmojiPanel，选中直接追加到输入框）
            EmojiPanel {
                visible: emojiOpen
                width: parent.width
                onEmojiPicked: inputField.text = inputField.text + emo
            }

            // 长按操作条
            GlassCard {
                visible: bubbleMenuOpen
                width: parent.width
                height: menuRow.height + 2 * Theme.paddingSmall
                Row {
                    id: menuRow
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    Button {
                        width: (parent.width - 2 * parent.spacing) / 3
                        text: qsTr("Copy")
                        onClicked: {
                            ob.copyText(page.menuText)
                            page.bubbleMenuOpen = false
                        }
                    }
                    Button {
                        visible: page.menuMid > 0
                        width: (parent.width - 2 * parent.spacing) / 3
                        text: qsTr("Reply")
                        onClicked: {
                            page.replyTo(page.menuMid, page.menuWho, page.menuText)
                            page.bubbleMenuOpen = false
                        }
                    }
                    Button {
                        visible: isGroup && !page.menuMine
                                 && page.menuWho.length > 0
                        width: (parent.width - 2 * parent.spacing) / 3
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
                    width: Math.max(3, Theme.paddingSmall / 4)
                    height: replyCol.height
                    radius: width / 2
                    color: "#7f5af0"
                }
                Column {
                    id: replyCol
                    width: parent.width - cancelBox.width - 2 * parent.spacing
                    Label {
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: "white"
                        opacity: 0.85
                        text: replyTarget ? qsTr("reply to ") + replyTarget.who : ""
                    }
                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeTiny
                        color: "white"
                        opacity: 0.6
                        truncationMode: TruncationMode.Fade
                        text: replyTarget ? replyTarget.snippet : ""
                    }
                }
                Rectangle {
                    id: cancelBox
                    width: Theme.itemSizeExtraSmall
                    height: width
                    radius: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#22ffffff"
                    border.width: 1
                    border.color: "#44ffffff"
                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        opacity: 0.7
                        text: "✕"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: replyTarget = null
                    }
                }
            }

            Row {
                id: sendRow
                width: parent.width
                spacing: Theme.paddingSmall

                Rectangle {
                    width: Theme.itemSizeSmall
                    height: width
                    radius: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    color: emojiOpen ? "#555af0ff" : "#22ffffff"
                    border.width: 1
                    border.color: "#44ffffff"
                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeMedium
                        color: "white"
                        opacity: 0.9
                        text: "☺"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { emojiOpen = !emojiOpen; plusOpen = false }
                    }
                }

                Rectangle {
                    width: Theme.itemSizeSmall
                    height: width
                    radius: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    color: plusOpen ? "#555af0ff" : "#22ffffff"
                    border.width: 1
                    border.color: "#44ffffff"
                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeLarge
                        color: "white"
                        opacity: 0.9
                        text: "+"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { plusOpen = !plusOpen; emojiOpen = false }
                    }
                }

                GlassCard {
                    id: inputCard
                    width: parent.width - 2 * Theme.itemSizeSmall - sendButton.width
                            - 3 * parent.spacing
                    height: Math.min(Math.max(inputField.implicitHeight + Theme.paddingSmall,
                                              Theme.itemSizeSmall),
                                     3 * Theme.itemSizeSmall)
                    radius: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    TextArea {
                        id: inputField
                        anchors.fill: parent
                        anchors.leftMargin: Theme.paddingSmall
                        anchors.rightMargin: Theme.paddingSmall
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                        color: "white"
                        placeholderColor: "#80ffffff"
                        placeholderText: qsTr("message")
                        EnterKey.enabled: text.trim().length > 0
                        EnterKey.onClicked: sendButton.doSend()
                    }
                }

                Button {
                    id: sendButton
                    width: Theme.itemSizeLarge
                    anchors.verticalCenter: parent.verticalCenter
                    text: "➤"
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

    Component.onCompleted: { }
}
