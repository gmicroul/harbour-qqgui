import QtQuick 2.2
import Sailfish.Silica 1.0

// 设计 token：对齐 harbour-pi（深紫底 + 三色光斑 + #22ffffff 玻璃）。
// 字号/尺寸全部取 Theme（随设备 dpi 缩放），不再写裸 px。
// 全屏背景光斑沿用 pi 固定值（底板豁免，见 README）。
QtObject {
    id: theme

    // —— pi 底色 ——
    readonly property color bgTop: "#0f0c29"
    readonly property color bgMid: "#302b63"
    readonly property color bgBottom: "#24243e"
    readonly property color blobPurple: "#7f5af0"   // 0.55
    readonly property color blobPink: "#ff6a88"     // 0.45
    readonly property color blobBlue: "#2cb4ff"     // 0.35
    readonly property color shadeBottom: "#66000000"

    // —— pi 玻璃 ——
    readonly property color tint: "#22ffffff"
    readonly property color border: "#44ffffff"
    readonly property color activeTint: "#555af0ff"
    readonly property color bubbleMine: "#885af0ff"
    readonly property color bubbleMineBorder: "#aaf0f0ff"
    readonly property color bubbleOther: "#33ffffff"
    readonly property color bubbleOtherBorder: "#55ffffff"
    readonly property color okGreen: "#4ade80"
    readonly property color errRed: "#f87171"

    // —— pi 文字（深底上只用白，不跟随系统 ambience）——
    readonly property color textPrimary: "white"        // 标题/正文
    readonly property color textSecondary: "#99ffffff"  // 预览/副标题/说明 (white 0.6)
    readonly property color textFaint: "#80ffffff"      // 时间/占位 (white 0.5)
    readonly property color accentPurple: "#7f5af0"     // 引用条/选中点缀
    readonly property color accentPink: "#ff6a88"       // 徽标/节标题色条

    // —— 尺寸（Theme 语义，随屏缩放；与原版 qqcat 页同口径）——
    // 头像三档：列表 itemSizeSmall*0.85（与原版一致）/ 页头 itemSizeSmall / 气泡 itemSizeExtraSmall
    readonly property int avatarList: Theme.itemSizeSmall * 0.85
    readonly property int avatarHeader: Theme.itemSizeSmall
    readonly property int avatarBubble: Theme.itemSizeExtraSmall
    // 行与栏：行 itemSizeMedium（与原版一致）；顶栏/输入内容撑高；胶囊 itemSizeExtraSmall
    readonly property int rowHeight: Theme.itemSizeMedium
    readonly property int tabHeight: Theme.itemSizeExtraSmall
    readonly property int iconBox: Theme.itemSizeExtraSmall
    readonly property int sendWidth: Theme.itemSizeLarge

    // —— 圆角（Theme 语义）——
    readonly property int radiusPanel: Theme.paddingSmall
    readonly property int radiusBubble: Theme.paddingSmall
    readonly property int radiusField: Theme.paddingSmall

    // —— 字阶（Theme 语义，禁止裸 px）——
    // 标题 Large / 名称 Medium / 正文 Small / 次级 ExtraSmall / 微 Tiny
    readonly property int fontTitle: Theme.fontSizeLarge
    readonly property int fontName: Theme.fontSizeMedium
    readonly property int fontBody: Theme.fontSizeSmall
    readonly property int fontPreview: Theme.fontSizeExtraSmall
    readonly property int fontMeta: Theme.fontSizeExtraSmall
    readonly property int fontTiny: Theme.fontSizeTiny

    // —— 间距（Theme 语义）——
    readonly property int padS: Theme.paddingSmall
    readonly property int padM: Theme.paddingMedium
    readonly property int padL: Theme.paddingLarge
}
