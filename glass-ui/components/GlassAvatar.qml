import QtQuick 2.2
import Sailfish.Silica 1.0

// 圆形头像。调用方传 Theme 尺寸：列表 itemSizeSmall*0.85 / 页头 itemSizeSmall / 气泡 itemSizeExtraSmall。
// 边框取 pi 玻璃边框 #44ffffff；fallback 首字白色（pi 文字色）。
Item {
    id: root

    property int px: Theme.itemSizeSmall
    property string src: ""
    property string fallback: "?"

    width: px
    height: px

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#22ffffff"
        border.width: 1
        border.color: "#44ffffff"
        clip: true

        Image {
            id: img
            anchors.fill: parent
            source: root.src
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: status === Image.Ready
        }

        Label {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            // 字阶随档位自动缩放：头像越大字越大（≥Tiny 起步）
            font.pixelSize: Math.max(Theme.fontSizeTiny, root.px * 0.42)
            font.bold: true
            color: "white"
            text: root.fallback && root.fallback.length > 0 ? root.fallback.charAt(0) : "?"
        }
    }
}
