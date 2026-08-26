import QtQuick 2.2
import Sailfish.Silica 1.0

// one video attachment inside a chat bubble; tap saves it into
// ~/Videos/qqcat/ where the media library picks it up
Item {
    id: tile

    width: 260
    height: 120

    property string vidUrl: ""
    property string vidFile: ""
    property var pageRef

    function saveVideo() {
        pageRef.resolveVideo(vidFile, vidUrl, function(localPath, saved) {
            if (saved)
                pageRef.appendMsg("sys", "",
                                  "视频已保存: 视频/qqcat/" + localPath)
            else
                pageRef.appendMsg("sys", "", "视频获取失败")
        })
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: "#202020"
    }

    Label {
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.primaryColor
        text: "▶"
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: qsTr("tap to save video")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: tile.saveVideo()
    }
}
