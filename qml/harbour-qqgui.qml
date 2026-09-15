import QtQuick 2.2
import Sailfish.Silica 1.0
import "pages"
import "cover"

// harbour-qqgui 入口：毛玻璃版，首屏进玻璃登录页，封面用玻璃专属 CoverGlassPage。
// （对照：qml/harbour-qqcat.qml 首屏是原版 LoginPage + 原版 CoverPage。）
ApplicationWindow {
    initialPage: Component { LoginGlassPage {} }

    cover: Component { CoverGlassPage {} }
}
