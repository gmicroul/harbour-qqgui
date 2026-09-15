import QtQuick 2.2
import Sailfish.Silica 1.0

// 聊天气泡：harbour-pi 配色，圆角 16。
// 我方 #885af0ff + 边框 #aaf0f0ff；对方 #33ffffff + 边框 #55ffffff。宽度由调用方约束。
Rectangle {
    id: root

    property bool mine: false

    radius: Theme.paddingSmall
    border.width: 1
    color: mine ? "#885af0ff" : "#33ffffff"
    border.color: mine ? "#aaf0f0ff" : "#55ffffff"
}
