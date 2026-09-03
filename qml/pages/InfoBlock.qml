import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: block

    property string q: ""
    property string a: ""

    width: parent.width
    spacing: Theme.paddingSmall

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        text: block.q
    }

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.primaryColor
        text: block.a
    }
}
