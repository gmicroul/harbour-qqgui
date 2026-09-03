import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: root
    property string title: ""
    default property alias content: col.data
    width: parent ? parent.width : 400
    spacing: 0

    Label {
        visible: title.length > 0
        x: Theme.horizontalPageMargin
        width: parent.width - 2*Theme.horizontalPageMargin
        text: title
        color: Qt.rgba(1,1,1,0.52)
        font.pixelSize: Theme.fontSizeExtraSmall
        font.letterSpacing: 1.1
        font.capitalization: Font.AllUppercase
        bottomPadding: Theme.paddingSmall
    }

    Rectangle {
        width: parent.width - Theme.horizontalPageMargin*2
        x: Theme.horizontalPageMargin
        radius: 20
        color: Qt.rgba(1,1,1,0.07)
        border.color: Qt.rgba(1,1,1,0.13)
        border.width: 1
        height: col.height + Theme.paddingLarge*1.2

        // top highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: parent.radius
            color: Qt.rgba(1,1,1,0.13)
        }

        Column {
            id: col
            width: parent.width - Theme.paddingLarge*2
            anchors.centerIn: parent
            spacing: Theme.paddingSmall
        }
    }
}
