import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property alias source: image.source
    GlassBackground { anchors.fill: parent }

    Rectangle {
        width: parent.width; height: 56
        color: Qt.rgba(0.09,0.11,0.22,0.42)
        border.color: Qt.rgba(1,1,1,0.09); border.width: 1
        IconButton { anchors.left: parent.left; anchors.leftMargin: Theme.paddingSmall; anchors.verticalCenter: parent.verticalCenter; icon.source: "image://theme/icon-m-back"; icon.color: "white"; onClicked: pageStack.pop() }
        Label { anchors.centerIn: parent; text: qsTr("Image"); color: "white"; font.pixelSize: Theme.fontSizeSmall }
    }

    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: 56
        contentHeight: height
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 24
            height: parent.height * 0.82
            radius: 22
            color: Qt.rgba(1,1,1,0.07)
            border.color: Qt.rgba(1,1,1,0.13); border.width: 1
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.14) }
            Image {
                id: image
                anchors.centerIn: parent
                width: parent.width - 12
                height: parent.height - 12
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
            BusyIndicator { visible: image.status === Image.Loading; running: visible; anchors.centerIn: parent; size: BusyIndicatorSize.Large }
            Label { visible: image.status === Image.Error; anchors.centerIn: parent; color: Qt.rgba(1,1,1,0.52); font.pixelSize: Theme.fontSizeSmall; text: qsTr("image unavailable") }
        }
    }
}
