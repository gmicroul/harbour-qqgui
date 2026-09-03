import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: tile
    width: 180
    height: 140
    property string imgUrl: ""
    property string imgFile: ""
    property string localUrl: ""
    property var pageRef

    function openFull() {
        if (localUrl.length > 0) { pageRef.pushViewer(localUrl); return }
        pageRef.resolveImage(imgFile, imgUrl, function(src) {
            if (src.length === 0) pageRef.appendMsg("sys", "", "图片加载失败")
            else pageRef.pushViewer(src)
        })
    }
    function loadLocal() {
        pageRef.resolveImage(imgFile, "", function(src) {
            if (src.indexOf("file://") === 0) { tile.localUrl = src; thumb.source = src }
        })
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(0,0,0,0.28)
        border.color: Qt.rgba(1,1,1,0.14)
        border.width: 1
    }
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        radius: parent.radius
        color: Qt.rgba(1,1,1,0.12)
    }
    Image {
        id: thumb
        anchors.centerIn: parent
        width: parent.width - 8
        height: parent.height - 8
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: imgUrl
        onStatusChanged: { if (status === Image.Error && tile.localUrl.length === 0) tile.loadLocal() }
    }
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "transparent"
        border.color: Qt.rgba(1,1,1,0.08)
        border.width: 1
    }
    BusyIndicator { visible: thumb.status === Image.Loading; running: visible; anchors.centerIn: parent; size: BusyIndicatorSize.Small }
    MouseArea { anchors.fill: parent; onClicked: tile.openFull() }
}
