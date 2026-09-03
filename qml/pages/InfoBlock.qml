import QtQuick 2.2
import Sailfish.Silica 1.0

Rectangle {
    id: block
    property string q: ""
    property string a: ""
    width: parent.width
    height: col.height + 20
    radius: 16
    color: Qt.rgba(1,1,1,0.07)
    border.color: Qt.rgba(1,1,1,0.11)
    border.width: 1
    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.12) }

    Column {
        id: col
        width: parent.width - 20
        anchors.centerIn: parent
        spacing: 6
        Item { width: 1; height: 2 }
        Label {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: "#9aa3ff"
            text: block.q
        }
        Label {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Qt.rgba(1,1,1,0.68)
            lineHeight: 1.35
            text: block.a
        }
        Item { width: 1; height: 2 }
    }
}
