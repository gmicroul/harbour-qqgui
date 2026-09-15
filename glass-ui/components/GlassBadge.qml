import QtQuick 2.2
import Sailfish.Silica 1.0

// 未读徽标：粉 #ff6a88（取 pi 光斑粉，与紫底最配），内容撑起 pill，字 Tiny 加粗白字。
// count<=0 自动隐藏；>99 显示 99+。
Item {
    id: root

    property int count: 0

    visible: count > 0
    width: Math.max(height, txt.width + Theme.paddingLarge)
    height: txt.height + Theme.paddingSmall

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#ff6a88"
        border.width: 1
        border.color: "#88ffffff"

        Label {
            id: txt
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeTiny
            font.bold: true
            color: "white"
            text: root.count > 99 ? "99+" : root.count
        }
    }
}
