import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    GlassBackground { anchors.fill: parent }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: flow.height + 40

        Column {
            id: flow
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width; height: 72
                color: Qt.rgba(0.09,0.11,0.22,0.52)
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                Row {
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingSmall; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.paddingSmall
                    IconButton { icon.source: "image://theme/icon-m-back"; icon.color: "white"; onClicked: pageStack.pop() }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Usage guide"); color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
            }

            Item { width: 1; height: Theme.paddingLarge }

            // How it works — glass card
            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                height: howCol.height + 28
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }
                Column {
                    id: howCol
                    width: parent.width - 28
                    anchors.centerIn: parent
                    spacing: 8
                    Item { width: 1; height: 4 }
                    Label { text: qsTr("How it works"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }
                    Label {
                        width: parent.width
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Qt.rgba(1,1,1,0.78)
                        lineHeight: 1.35
                        text: "手机App(本应用)\n   ⇅ OneBot11 协议\n   · WebSocket 收消息\n   · HTTP API 发消息/查数据\nNapCat(QQ客户端本体, 可在本机容器/电脑/服务器)\n   ⇅ QQ协议\n腾讯服务器"
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 20
                color: Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                height: setupCol.height + 28
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }
                Column {
                    id: setupCol
                    width: parent.width - 28
                    anchors.centerIn: parent
                    spacing: 8
                    Item { width: 1; height: 4 }
                    Label { text: qsTr("First-time setup"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }
                    Label {
                        width: parent.width
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Qt.rgba(1,1,1,0.78)
                        lineHeight: 1.4
                        text: "1. 在任一机器安装 NapCat 并登录一个用作机器人的QQ号\n2. NapCat 的 OneBot 配置里开启:\n    · 正向WebSocket(如 ws://0.0.0.0:3001)\n    · HTTP服务(如 0.0.0.0:3000)\n    · 建议设置 access_token 鉴权\n3. 本应用 设置→连接 填入对应地址与令牌 → 保存并重连\n4. 登录页扫码完成机器人账号登录\n5. 花名册点选会话即可收发"
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label { x: Theme.horizontalPageMargin; text: qsTr("FAQ"); color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeExtraSmall; font.letterSpacing: 1.0; font.capitalization: Font.AllUppercase }

            Item { width: 1; height: Theme.paddingSmall }

            Column {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                InfoBlock { q: qsTr("Q: 重启后为什么要点重新连接/扫码?"); a: "NapCat 重启后本地会话常被风控判定失效, 快速登录被拒,\n只能重新扫码。登录页会自动出新码, 扫一次即可。" }
                InfoBlock { q: qsTr("Q: 手机QQ和机器人同时在线吗?"); a: "手机QQ与机器人是『手机端+电脑端』可共存;\n但 niri 图形版 QQ 与机器人同属电脑端, 会互踢。" }
                InfoBlock { q: qsTr("Q: 连不上怎么办?"); a: "依次检查:\n1) NapCat 是否在线(WebUI能打开)\n2) 地址端口是否可达\n3) access_token 是否一致\n4) WS 与 HTTP 两个地址都要填" }
                InfoBlock { q: qsTr("Q: 图片打不开?"); a: "缩略图优先走腾讯图床直链, 失败自动回退到 NapCat 本地缓存。\n远程模式下缓存不在本机, 请确认图床链接可用。" }
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 16
                color: Qt.rgba(1,1,1,0.05)
                border.color: Qt.rgba(1,1,1,0.09); border.width: 1
                height: aboutLabel.height + 20
                Label {
                    id: aboutLabel
                    anchors.centerIn: parent
                    width: parent.width - 24
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Qt.rgba(1,1,1,0.38)
                    lineHeight: 1.4
                    text: "harbour-qqcat — Sailfish OS OneBot11 客户端\nQR: nayuki/qrcodegen (MIT) · 拼音表: sxei/pinyinjs (MIT)\n后端: NapCat (OneBot11 实现)"
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
