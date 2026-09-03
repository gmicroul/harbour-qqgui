import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: flow.height + Theme.paddingLarge * 2

        Column {
            id: flow
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Usage guide") }

            SectionHeader { text: qsTr("How it works") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                text: "手机App(本应用)\n" +
                      "   ⇅ OneBot11 协议\n" +
                      "   · WebSocket 收消息\n" +
                      "   · HTTP API 发消息/查数据\n" +
                      "NapCat(QQ客户端本体, 可在本机容器/电脑/服务器)\n" +
                      "   ⇅ QQ协议\n" +
                      "腾讯服务器"
            }

            SectionHeader { text: qsTr("First-time setup") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "1. 在任一机器安装 NapCat 并登录一个用作机器人的QQ号\n" +
                      "2. NapCat 的 OneBot 配置里开启:\n" +
                      "    · 正向WebSocket(如 ws://0.0.0.0:3001)\n" +
                      "    · HTTP服务(如 0.0.0.0:3000)\n" +
                      "    · 建议设置 access_token 鉴权\n" +
                      "3. 本应用 设置→连接 填入对应地址与令牌 → 保存并重连\n" +
                      "4. 登录页扫码完成机器人账号登录\n" +
                      "5. 花名册点选会话即可收发"
            }

            SectionHeader { text: qsTr("FAQ") }

            InfoBlock {
                q: qsTr("Q: 重启后为什么要点重新连接/扫码?")
                a: "NapCat 重启后本地会话常被风控判定失效, 快速登录被拒,\n只能重新扫码。登录页会自动出新码, 扫一次即可。"
            }
            InfoBlock {
                q: qsTr("Q: 手机QQ和机器人同时在线吗?")
                a: "手机QQ与机器人是『手机端+电脑端』可共存;\n但 niri 图形版 QQ 与机器人同属电脑端, 会互踢。"
            }
            InfoBlock {
                q: qsTr("Q: 连不上怎么办?")
                a: "依次检查:\n1) NapCat 是否在线(WebUI能打开)\n" +
                   "2) 地址端口是否可达\n3) access_token 是否一致\n4) WS 与 HTTP 两个地址都要填"
            }
            InfoBlock {
                q: qsTr("Q: 图片打不开?")
                a: "缩略图优先走腾讯图床直链, 失败自动回退到 NapCat 本地缓存。\n远程模式下缓存不在本机, 请确认图床链接可用。"
            }

            SectionHeader { text: qsTr("About") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "harbour-qqcat — Sailfish OS OneBot11 客户端\n" +
                      "QR: nayuki/qrcodegen (MIT) · 拼音表: sxei/pinyinjs (MIT)\n" +
                      "后端: NapCat (OneBot11 实现)"
            }
        }
    }
}
