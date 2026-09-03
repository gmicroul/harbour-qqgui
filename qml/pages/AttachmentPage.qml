import QtQuick 2.2
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1

Page {
    id: page

    allowedOrientations: Orientation.All

    // injected by ChatPage
    property var ob: null
    property var hub: null
    property int targetId: 0
    property bool isGroup: true

    property string currentDir: "/home/defaultuser/Pictures"
    property string startDir: ""

    Component.onCompleted: if (startDir.length > 0)
        currentDir = startDir

    function isImage(name) {
        var e = name.toLowerCase()
        return e.indexOf(".jpg") >= 0 || e.indexOf(".jpeg") >= 0
                || e.indexOf(".png") >= 0 || e.indexOf(".gif") >= 0
                || e.indexOf(".webp") >= 0 || e.indexOf(".bmp") >= 0
    }

    function sendEntry(filePath, name) {
        var img = isImage(name)
        var sz = ob.fileSize(filePath)
        if (sz <= 0) {
            note(qsTr("cannot read file")); return
        }
        if (sz > 25 * 1024 * 1024) {
            note(qsTr("file too large (>25MB)")); return
        }
        busy = true
        if (img) {
            var b64 = ob.fileToBase64(filePath)
            var segs = [{ type: "image",
                          data: { file: "base64://" + b64 } }]
            var act = isGroup ? "send_group_msg" : "send_private_msg"
            var prm = isGroup
                    ? JSON.stringify({ group_id: targetId, message: segs })
                    : JSON.stringify({ user_id: targetId, message: segs })
            pend[ob.sendAction(act, prm)] = function(ok) {
                busy = false
                note(ok ? qsTr("image sent ✓") : qsTr("send failed ✗"))
                if (ok && hub)
                    hub.touchConv(isGroup ? "群" + targetId : "私聊" + targetId,
                                  "我", "[图片]")
            }
        } else {
            var act2 = isGroup ? "upload_group_file" : "upload_private_file"
            var prm2 = isGroup
                    ? JSON.stringify({ group_id: targetId, file: filePath,
                                       name: name })
                    : JSON.stringify({ user_id: targetId, file: filePath,
                                        name: name })
            pend[ob.sendAction(act2, prm2)] = function(ok) {
                busy = false
                note(ok ? qsTr("file uploaded ✓")
                        : qsTr("upload failed ✗"))
            }
        }
    }

    function note(msg) { statusLabel.text = msg; statusTimer.restart() }

    property bool busy: false
    property var pend: ({})

    Connections {
        target: ob
        onActionReply: {
            if (page.pend[echo] !== undefined) {
                var cb = page.pend[echo]
                delete page.pend[echo]
                cb(ok, dataJson)
            }
        }
    }

    Timer { id: statusTimer; interval: 2200 }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("up one level")
                onClicked: {
                    var parts = currentDir.split("/")
                    parts.pop()
                    currentDir = parts.join("/") || "/"
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Send attachment") }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall

                Repeater {
                    model: [ "Pictures", "Downloads", "Videos",
                             "Documents", "Music" ]
                    delegate: Button {
                        text: modelData
                        onClicked: page.currentDir =
                            "/home/defaultuser/" + modelData
                    }
                }
            }

            Label {
                id: statusLabel
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: page.busy ? qsTr("sending…") : ""
            }

            SilicaListView {
                width: parent.width
                height: page.height - 480 > 300 ? page.height - 480 : 300
                clip: true

                model: FolderListModel {
                    id: folderModel
                    folder: "file://" + page.currentDir
                    showDirs: true
                    showDotAndDotDot: false
                    nameFilters: []
                }

                delegate: ListItem {
                    id: row
                    contentHeight: Theme.itemSizeSmall

                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 2 * Theme.horizontalPageMargin
                               - sizeLabel.width - Theme.paddingLarge
                        text: fileName
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                        color: row.highlighted ? Theme.highlightColor
                                               : Theme.primaryColor
                    }

                    Label {
                        id: sizeLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: fileIsDir ? qsTr("dir")
                                        : Math.round(fileSize / 1024) + "K"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }

                    onClicked: {
                        if (fileIsDir)
                            page.currentDir = filePath
                        else
                            page.sendEntry(filePath, fileName)
                    }
                }

                VerticalScrollDecorator {}
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
