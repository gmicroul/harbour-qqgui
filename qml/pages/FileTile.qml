import QtQuick 2.2
import Sailfish.Silica 1.0

// one file attachment inside a chat bubble; tap downloads it into
// ~/Downloads/qqcat/ via NapCat's get_file cache
Item {
    id: tile

    width: parent && parent.width > 50 ? parent.width : 300
    height: Theme.itemSizeSmall

    property string fname: ""
    property string fid: ""
    property string furl: ""
    property string gid: ""
    property string busid: ""
    property var pageRef

    function saveFile() {
        pageRef.resolveFile(fid, furl, gid, busid, function(localPath, saved) {
            pageRef.appendMsg("sys", "",
                              saved ? "文件已保存: Downloads/qqcat/"
                                      + localPath : "文件下载失败")
        })
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.25)
    }

    Label {
        id: icon
        x: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeMedium
        text: "📄"
    }

    Label {
        anchors.left: icon.right
        anchors.leftMargin: Theme.paddingSmall
        anchors.right: hint.left
        anchors.rightMargin: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        text: tile.fname
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: hint
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeTiny
        color: Theme.secondaryColor
        text: qsTr("tap to save")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: tile.saveFile()
    }
}
