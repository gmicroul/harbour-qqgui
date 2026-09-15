import QtQuick 2.2
import Sailfish.Silica 1.0

// 小节标题：4px 粉色条（取 pi 光斑粉 #ff6a88）+ ExtraSmall 加粗白字 0.6。
Row {
    id: root

    property string text: ""

    spacing: Theme.paddingSmall

    Rectangle {
        width: Math.max(4, Theme.paddingSmall / 3)
        height: sectionLabel.height
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: "#ff6a88"
    }

    Label {
        id: sectionLabel
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        font.bold: true
        color: "white"
        opacity: 0.6
        text: root.text
    }
}
