import QtQuick 2.2
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow {
    initialPage: Component { LoginPage {} }

    cover: Component { CoverPage {} }
}
