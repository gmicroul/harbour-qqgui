# glass-ui · 毛玻璃重设计（不覆盖源码）

> 新建目录 `glass-ui/`，原 `qml/` / `src/` 一个字节都没动。
> 试用脚本只向 `qml/pages/` **新增** `*Glass*.qml` 文件，用完可一键删除。

## 文件地图

```
glass-ui/
  README.md                  本说明
  try-glass.sh               安全试用：复制新文件到 qml/pages（不覆盖），并去掉扁平目录多余的 import
  restore-glass.sh           一键清理试用文件
  flatten-glass.sh           遗留脚本（当前打包已不需要：玻璃页源码不再含 `import "../components"` 行，直接扁平安装）
  theme/GlassTheme.qml       设计 token：尺寸/圆角/字号/玻璃配色（全部 Theme 语义，随屏缩放）
  components/
    GlassBackground.qml      全屏底板：深色渐变 + 3 块相对尺寸色光（无固定 px，供玻璃透出）
    GlassCard.qml            毛玻璃卡片：半透明渐变 + 1px 亮边 + 顶部 1px 高光，圆角 14
    GlassAvatar.qml          圆形头像，档位 48/36/28/24（默认 48）
    GlassBadge.qml           未读徽标，高 20 / 字 11，>99 显示 99+
    GlassTabBar.qml          胶囊筛选条，高 itemSizeExtraSmall / 字 Small（All/Groups/Friends）
    GlassChatBubble.qml      聊天气泡，圆角 paddingSmall，我方蓝玻璃 / 对方白玻璃
    GlassSectionTitle.qml    小节标题，色条 + ExtraSmall 字（Theme 度量）
  pages/
    ConversationsGlassPage.qml  会话列表（逻辑与原版一致，行高 itemSizeMedium，头像 itemSizeSmall*0.85）
    ChatGlassPage.qml           聊天（逻辑与原版一致，头像 itemSizeExtraSmall/itemSizeSmall，正文 Small）
    LoginGlassPage.qml          登录（逻辑与原版一致，二维码见例外说明）
    SettingsGlassPage.qml       设置（逻辑与原版一致，按钮原生高度）
  js/pinyin.js               原样拷贝的拼音表，仅为让 glass-ui 内相对 import 可用
```

## 毛玻璃怎么做（Sailfish 无系统模糊时的模拟）

1. **底板先有东西可透**：`GlassBackground` 放深色渐变 + 蓝/紫/青三块大色光。
2. **卡片半透明渐变**：顶 `rgba(1,1,1,0.14)` → 底 `rgba(1,1,1,0.06)`，我方气泡用蓝色同透明度。
3. **1px 亮边 + 顶部 1px 高光线**：这是“玻璃边缘反光”，便宜但效果明显。
4. **圆角取 `Theme.paddingSmall`**：卡片/气泡/输入框/胶囊统一家族感，随屏缩放。
5. **零外部依赖**：纯 `QtQuick 2.2 + Silica 1.0`，没引 GraphicalEffects，设备上不会缺库。

## 布局 / 字体 / 头像

> 教训：早期玻璃版用裸 px（68/48/23/21/17/15/13…）在高 dpi 真机上又小又挤。
> 现全部改 Theme 语义（与原版同口径），卡片只换皮、不改骨。

| 位置 | 原版 | 玻璃版 | 说明 |
|---|---|---|---|
| 会话行高 | `Theme.itemSizeMedium` | 同左 | 玻璃卡内嵌，行高一致 |
| 会话头像 | 方形 `itemSizeSmall*0.85` | 同尺寸**圆形** + 首字兜底 | 群/私聊同一直链规则 |
| 会话标题/预览/时间 | Medium/ExtraSmall | Medium/ExtraSmall（白 0.9/0.6/0.5） | 三级阶梯，预览截断 Fade |
| 未读 | 大圆 `fontSize*1.6` | 内容撑起 pill + Tiny | 右上贴时间下方，不抢标题 |
| 顶栏 | PageHeader + 裸 IconButton | 玻璃头（内容撑高）：Large 粗标题 + Small 状态 + 在线圆点 + `itemSizeExtraSmall` 按钮盒 | 状态（在线/连接中）收进标题下 |
| 筛选 | 裸 Label 行 | `itemSizeExtraSmall` 胶囊（选中紫玻璃 `#555af0ff`） | 点击区域更大 |
| 搜索 | 全宽 SearchField | 玻璃卡贴合 SearchField 高（字 Small） | 与列表卡片同语言 |
| 聊天头 | 56 头像 + 大标题 | 玻璃卡（内容撑高）：`itemSizeSmall` 头像 + Medium 标题 + ExtraSmall 副标题 | 进群一眼确认 ID |
| 聊天气泡 | 方角半透明块，头像只在气泡内 24 | **头像外置** `itemSizeExtraSmall`（对方左/我方右）+ 玻璃泡 + ExtraSmall 昵称 + Small 正文 | 气泡宽取 `body.implicitWidth` 钳制（无循环绑定），长按仍出 Copy/Reply |
| 引用条 | 灰底大块 | `#22ffffff` + Tiny/ExtraSmall 两行，最多 2 行省略 | 信息降噪 |
| 输入坞 | DockedPanel 裸排 | 玻璃通栏（pi 配色）：`itemSizeSmall` 表情/+ 钮 + 自适应输入卡（字 Small，最高 3×）+ `itemSizeLarge` 发送 | 高度全由内容撑起 |
| 设置 | 裸表单 | **分组玻璃卡**：节标题 + 卡内输入字 Small + 原生按钮 | 一节一卡，扫读更快 |
| 登录 | 白卡 380 + 大按钮 | **玻璃外卡 + 白内芯**（二维码随屏宽，原生按钮） | 扫码路径不变 |

## 度量规范：Theme 语义，禁止裸 px

字号/行高/头像/图标/按钮/圆角/间距全部取 `Theme.*`
（`fontSizeLarge/Medium/Small/ExtraSmall/Tiny`、`itemSizeSmall/Medium/Large/ExtraSmall`、
`paddingSmall/Medium/Large`、`horizontalPageMargin`），卡片高度一律由内容撑起。
裸 px 只允许：`border.width: 1`、1px 高光线、 spacer `Item { width: 1; … }`。

**例外（功能性媒体）：**

- 二维码内芯：随屏宽（`parent.width - 边距`），保证物理尺寸可扫。
- 聊天图片缩略图 / 引用图预览 / 视频文件块：沿用原版媒体尺寸（`ImageTile 260x200` 等在原文件里），玻璃版未改，确保可看可点。
- `GlassBackground` 三块色光：照搬 pi 固定值（底板豁免）。
- `SilicaListView` / `Page` 全屏锚定：无固定 px。

审计方法：`rg -n "pixelSize: [0-9]|width: [0-9]|height: [0-9]|px: [0-9]|radius: [0-9]" glass-ui --glob "*.qml"`，
应只剩 border/hairline/spacer 行。

## 安全试用（不覆盖源码）

```bash
./glass-ui/try-glass.sh      # 新增文件到 qml/pages，自动去掉扁平多余 import
git status --porcelain        # 应只看到新增的 *Glass*.qml，无修改（M）项
# 预览：临时把 qml/harbour-qqcat.qml 的 initialPage 换成 ConversationsGlassPage {}
# 看完后：
git checkout -- qml/harbour-qqcat.qml
./glass-ui/restore-glass.sh   # 删掉试用文件
```

聊天页的图片/表情/视频/文件渲染复用原版
`FaceTile / ImageTile / VideoTile / FileTile`（试用目录里本来就有，无需复制）。
`ChatGlassPage` 的 `openConv` 指向 `ChatGlassPage`，`LoginGlassPage` 登录成功跳
`ConversationsGlassPage`，玻璃页之间已闭环；回退原版只需进原入口即可。

## 独立打包：harbour-qqgui（与 qqcat 共存）

玻璃版以新包名 `harbour-qqgui`（显示名 QQ Glass）发布，二进制 / QML / 图标路径全独立：

| 新文件 | 说明 |
|---|---|
| `harbour-qqgui.pro` | `TARGET=harbour-qqgui`；C++ 复用 `onebotbridge/qrcodegen`；玻璃页（源码已无 `../components` import，直接同目录解析）扁平装进 `qml/pages` |
| `src/main_qqgui.cpp` | 应用名 `harbour-qqgui`，入口 `qml/harbour-qqgui.qml`（其余同原 main） |
| `qml/harbour-qqgui.qml` | 首屏 `LoginGlassPage`，cover 复用 |
| `harbour-qqgui.desktop` | `Exec=/usr/bin/harbour-qqgui`，`Icon=harbour-qqgui` |
| `icons/86x86/harbour-qqgui.png` | 暂复用 qqcat 图标占位，欢迎替换 |
| `rpm/harbour-qqgui.spec` | `Version 1.0.0-Release 1`；`%build` 必须显式 `qmake harbour-qqgui.pro`（裸 `qmake` 会选中 qqcat） |
| `install-qqgui.sh` | 本机开发部署（影子构建 + `make install INSTALL_ROOT` staging 后拷入 `/`） |

```bash
# 验证构建（源码树外影子构建，树内零污染）
mkdir -p /tmp/opencode/qqgui-build && cd /tmp/opencode/qqgui-build
qmake /path/to/harbour-qqgui.pro CONFIG+=release && make -j4
make install INSTALL_ROOT=/tmp/opencode/qqgui-root   # 扁平页无 import "../components"，8 处跨页引用全闭合

# 打 RPM（SDK/OBS 内）
rpmbuild -bb rpm/harbour-qqgui.spec
./install-qqgui.sh   # 本机直装调试
```
