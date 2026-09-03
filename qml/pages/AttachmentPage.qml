import QtQuick 2.2
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property var ob: null
    property var hub: null
    property int targetId: 0
    property bool isGroup: true
    property string currentDir: "/home/defaultuser/Pictures"
    property string startDir: ""
    Component.onCompleted: if (startDir.length > 0) currentDir = startDir
    function isImage(name) {
        var e = name.toLowerCase()
        return e.indexOf(".jpg") >= 0 || e.indexOf(".jpeg") >= 0 || e.indexOf(".png") >= 0 || e.indexOf(".gif") >= 0 || e.indexOf(".webp") >= 0 || e.indexOf(".bmp") >= 0
    }
    function sendEntry(filePath, name) {
        var img = isImage(name); var sz = ob.fileSize(filePath)
        if (sz <= 0) { note(qsTr("cannot read file")); return }
        if (sz > 25 * 1024 * 1024) { note(qsTr("file too large (>25MB)")); return }
        busy = true
        if (img) {
            var b64 = ob.fileToBase64(filePath); var segs = [{ type: "image", data: { file: "base64://" + b64 } }]
            var act = isGroup ? "send_group_msg" : "send_private_msg"
            var prm = isGroup ? JSON.stringify({ group_id: targetId, message: segs }) : JSON.stringify({ user_id: targetId, message: segs })
            pend[ob.sendAction(act, prm)] = function(ok) { busy = false; note(ok ? qsTr("image sent ✓") : qsTr("send failed ✗")); if (ok && hub) hub.touchConv(isGroup ? "群" + targetId : "私聊" + targetId, "我", "[图片]") }
        } else {
            var act2 = isGroup ? "upload_group_file" : "upload_private_file"
            var prm2 = isGroup ? JSON.stringify({ group_id: targetId, file: filePath, name: name }) : JSON.stringify({ user_id: targetId, file: filePath, name: name })
            pend[ob.sendAction(act2, prm2)] = function(ok) { busy = false; note(ok ? qsTr("file uploaded ✓") : qsTr("upload failed ✗")) }
        }
    }
    function note(msg) { statusLabel.text = msg; statusTimer.restart() }
    property bool busy: false
    property var pend: ({})
    Connections { target: ob; onActionReply: { if (page.pend[echo] !== undefined) { var cb = page.pend[echo]; delete page.pend[echo]; cb(ok, dataJson) } } }
    Timer { id: statusTimer; interval: 2200 }
    GlassBackground { anchors.fill: parent }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem { text: qsTr("up one level"); onClicked: { var parts = currentDir.split("/"); parts.pop(); currentDir = parts.join("/") || "/" } }
        }

        Column {
            id: column
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width; height: 72
                color: Qt.rgba(0.09,0.11,0.22,0.52)
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                Row {
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingSmall; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.paddingSmall
                    IconButton { icon.source: "image://theme/icon-m-back"; icon.color: "white"; onClicked: pageStack.pop() }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Send attachment"); color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeTiny
                color: Qt.rgba(1,1,1,0.42)
                text: currentDir
            }

            Item { width: 1; height: Theme.paddingSmall }

            // 快捷目录 pills
            Item {
                width: parent.width
                height: 36
                SilicaFlickable {
                    anchors.fill: parent
                    contentWidth: pillRow.width + 2*Theme.horizontalPageMargin
                    flickableDirection: Flickable.HorizontalFlick
                    Row {
                        id: pillRow
                        x: Theme.horizontalPageMargin
                        spacing: 8
                        Repeater {
                            model: [ "Pictures", "Downloads", "Videos", "Documents", "Music" ]
                            delegate: Rectangle {
                                height: 32; radius: 16
                                width: pillT.width + 22
                                color: currentDir.indexOf(modelData) >= 0 ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                                border.color: currentDir.indexOf(modelData) >= 0 ? Qt.rgba(0.66,0.73,1.0,0.32) : Qt.rgba(1,1,1,0.11)
                                border.width: 1
                                Label { id: pillT; anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: Theme.fontSizeExtraSmall }
                                MouseArea { anchors.fill: parent; onClicked: page.currentDir = "/home/defaultuser/" + modelData }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2*Theme.horizontalPageMargin
                height: 28
                radius: 14
                visible: statusLabel.text.length > 0
                color: page.busy ? Qt.rgba(0.48,0.56,1.0,0.18) : Qt.rgba(0.30,0.85,0.52,0.14)
                border.color: page.busy ? Qt.rgba(0.66,0.73,1.0,0.28) : Qt.rgba(0.30,0.85,0.52,0.22)
                border.width: 1
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    BusyIndicator { visible: page.busy; running: visible; size: BusyIndicatorSize.Small; anchors.verticalCenter: parent.verticalCenter }
                    Label { id: statusLabel; anchors.verticalCenter: parent.verticalCenter; color: "white"; font.pixelSize: Theme.fontSizeExtraSmall; text: page.busy ? qsTr("sending…") : "" }
                }
            }

            Item { width: 1; height: Theme.paddingSmall }

            // 文件列表 — 毛玻璃卡片容器
            Rectangle {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                radius: 18
                color: Qt.rgba(1,1,1,0.06)
                border.color: Qt.rgba(1,1,1,0.11); border.width: 1
                height: Math.max(320, Math.min(folderModel.count * 54 + 16, page.height * 0.62))

                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.12) }

                SilicaListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: FolderListModel { id: folderModel; folder: "file://" + page.currentDir; showDirs: true; showDotAndDotDot: false; nameFilters: [] }
                    spacing: 6
                    delegate: Rectangle {
                        id: row
                        width: parent.width
                        height: 48
                        radius: 12
                        color: rowMouse.pressed ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.07)
                        border.color: fileIsDir ? Qt.rgba(0.66,0.73,1.0,0.18) : Qt.rgba(1,1,1,0.09)
                        border.width: 1
                        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.10) }
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: fileIsDir ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                                border.color: fileIsDir ? Qt.rgba(0.66,0.73,1.0,0.28) : Qt.rgba(1,1,1,0.11); border.width: 1
                                Label { anchors.centerIn: parent; text: fileIsDir ? "📁" : "📄"; font.pixelSize: Theme.fontSizeSmall }
                            }
                            Label {
                                width: row.width - 90 - sizeLabel.width
                                anchors.verticalCenter: parent.verticalCenter
                                text: fileName; font.pixelSize: Theme.fontSizeSmall; color: "white"; truncationMode: TruncationMode.Fade
                            }
                        }
                        Label {
                            id: sizeLabel
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            text: fileIsDir ? qsTr("dir") : Math.round(fileSize / 1024) + "K"
                            color: fileIsDir ? "#9aa3ff" : Qt.rgba(1,1,1,0.42); font.pixelSize: Theme.fontSizeTiny
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            onClicked: { if (fileIsDir) page.currentDir = filePath; else page.sendEntry(filePath, fileName) }
                        }
                    }
                    VerticalScrollDecorator {}
                    ViewPlaceholder { enabled: folderModel.count === 0; text: qsTr("empty folder") }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }
}
