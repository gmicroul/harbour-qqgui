import QtQuick 2.2
import Sailfish.Silica 1.0

// one picture tile inside a chat bubble; tap opens the full-size viewer
Item {
    id: tile

    width: 260
    height: 200

    property string imgUrl: ""
    property string imgFile: ""
    property string localUrl: ""
    property var pageRef

    function openFull() {
        if (localUrl.length > 0) {
            pageRef.pushViewer(localUrl)
            return
        }
        pageRef.resolveImage(imgFile, imgUrl, function(src) {
            if (src.length === 0)
                pageRef.appendMsg("sys", "", "图片加载失败")
            else
                pageRef.pushViewer(src)
        })
    }

    function loadLocal() {
        pageRef.resolveImage(imgFile, "", function(src) {
            if (src.indexOf("file://") === 0) {
                tile.localUrl = src
                thumb.source = src
            }
        })
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: "#202020"
    }

    Image {
        id: thumb
        anchors.centerIn: parent
        width: 250
        height: 190
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        source: imgUrl
        onStatusChanged: {
            if (status === Image.Error && tile.localUrl.length === 0)
                tile.loadLocal()
        }
    }

    BusyIndicator {
        visible: thumb.status === Image.Loading
        running: visible
        anchors.centerIn: parent
        size: BusyIndicatorSize.Small
    }

    MouseArea {
        anchors.fill: parent
        onClicked: tile.openFull()
    }
}
