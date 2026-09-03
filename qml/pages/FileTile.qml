import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: tile
    width: parent && parent.width > 50 ? parent.width : 300
    height: 48
    property string fname: ""
    property string fid: ""
    property string furl: ""
    property string gid: ""
    property string busid: ""
    property var pageRef
    function saveFile() {
        pageRef.resolveFile(fid, furl, gid, busid, function(localPath, saved) {
            pageRef.appendMsg("sys", "", saved ? "文件已保存: Downloads/qqcat/" + localPath : "文件下载失败")
        })
    }
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(1,1,1,0.08)
        border.color: Qt.rgba(1,1,1,0.12)
        border.width: 1
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.12) }
    }
    Rectangle {
        x: 8; anchors.verticalCenter: parent.verticalCenter
        width: 32; height: 32; radius: 8
        color: Qt.rgba(0.48,0.56,1.0,0.22)
        border.color: Qt.rgba(0.66,0.73,1.0,0.28); border.width: 1
        Label { anchors.centerIn: parent; font.pixelSize: Theme.fontSizeSmall; text: "📄" }
    }
    Label {
        anchors.left: parent.left; anchors.leftMargin: 48
        anchors.right: hint.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: tile.fname; font.pixelSize: Theme.fontSizeExtraSmall; color: "white"; truncationMode: TruncationMode.Fade
    }
    Label {
        id: hint; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeTiny; color: Qt.rgba(1,1,1,0.42); text: qsTr("tap to save")
    }
    MouseArea { anchors.fill: parent; onClicked: tile.saveFile() }
}
