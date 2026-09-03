import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: tile
    width: 180
    height: 110
    property string vidUrl: ""
    property string vidFile: ""
    property var pageRef
    function saveVideo() {
        pageRef.resolveVideo(vidFile, vidUrl, function(localPath, saved) {
            if (saved) pageRef.appendMsg("sys", "", "视频已保存: 视频/qqcat/" + localPath)
            else pageRef.appendMsg("sys", "", "视频获取失败")
        })
    }
    Rectangle {
        anchors.fill: parent; radius: 14
        color: Qt.rgba(0,0,0,0.32)
        border.color: Qt.rgba(1,1,1,0.12); border.width: 1
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.12) }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 38; height: 38; radius: 19
        color: Qt.rgba(1,1,1,0.14)
        border.color: Qt.rgba(1,1,1,0.18); border.width: 1
        Label { anchors.centerIn: parent; font.pixelSize: 18; color: "white"; text: "▶" }
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.52); text: qsTr("tap to save video")
    }
    MouseArea { anchors.fill: parent; onClicked: tile.saveVideo() }
}
