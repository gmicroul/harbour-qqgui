import QtQuick 2.2
import Sailfish.Silica 1.0

// 毛玻璃卡片：harbour-pi GlassPanel 配色（tint #22ffffff + 边框 #44ffffff + 顶光）。
// 用法：GlassCard { width: ...; height: ...; <children> }，圆角取 Theme.paddingSmall。
// 可选 tint 属性覆盖（选中态传 "#555af0ff"）。
Rectangle {
    id: root

    property color tint: "#22ffffff"

    radius: Theme.paddingSmall
    color: tint
    border.width: 1
    border.color: "#44ffffff"

    // 顶部高光线（pi: 白，opacity 0.18）
    Rectangle {
        x: Theme.paddingLarge
        y: 0
        width: parent.width - 2 * Theme.paddingLarge
        height: 1
        radius: Theme.paddingSmall
        color: "white"
        opacity: 0.18
    }
}
