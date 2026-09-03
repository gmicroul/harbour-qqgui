import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All
    property var groups: []
    property var friends: []
    property string search: ""
    signal accepted(bool isGroup, string id, string name)
    function match(name, id) {
        if (search.length === 0) return true
        var s = search.toLowerCase()
        return String(name).toLowerCase().indexOf(s) >= 0 || String(id).indexOf(s) >= 0
    }
    function buildModel() {
        listModel.clear()
        for (var i in groups) {
            var g = groups[i]
            if (match(g.group_name !== undefined ? g.group_name : "", g.group_id))
                listModel.append({ type: "群", id: String(g.group_id), name: g.group_name ? g.group_name : String(g.group_id) })
        }
        for (var j in friends) {
            var f = friends[j]
            var fname = f.remark && f.remark.length > 0 ? f.remark : f.nickname
            if (match(fname, f.user_id))
                listModel.append({ type: "好友", id: String(f.user_id), name: fname ? fname : String(f.user_id) })
        }
    }
    onSearchChanged: buildModel()
    onGroupsChanged: buildModel()
    onFriendsChanged: buildModel()
    Component.onCompleted: buildModel()

    GlassBackground { anchors.fill: parent }

    Rectangle {
        id: topBar
        width: parent.width; height: 72
        color: Qt.rgba(0.09,0.11,0.22,0.52)
        border.color: Qt.rgba(1,1,1,0.10); border.width: 1
        Row {
            anchors.left: parent.left; anchors.leftMargin: Theme.paddingSmall; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.paddingSmall
            IconButton { icon.source: "image://theme/icon-m-back"; icon.color: "white"; onClicked: pageStack.pop() }
            Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Pick target"); color: "white"; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin; anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36; radius: 18; color: Qt.rgba(1,1,1,0.10); border.color: Qt.rgba(1,1,1,0.14); border.width: 1
            IconButton { anchors.centerIn: parent; width: 36; height: 36; icon.source: "image://theme/icon-m-refresh"; icon.color: "white"; onClicked: page.buildModel() }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
    }

    Rectangle {
        id: searchBox
        anchors.top: topBar.bottom; anchors.topMargin: Theme.paddingMedium
        x: Theme.horizontalPageMargin
        width: parent.width - 2*Theme.horizontalPageMargin
        height: 44; radius: 14
        color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.13); border.width: 1
        Row {
            anchors.fill: parent; anchors.leftMargin: Theme.paddingMedium; anchors.rightMargin: Theme.paddingMedium; spacing: Theme.paddingSmall
            Label { anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: Qt.rgba(1,1,1,0.42); font.pixelSize: Theme.fontSizeMedium }
            TextField {
                id: searchField
                width: parent.width - 28; anchors.verticalCenter: parent.verticalCenter
                placeholderText: qsTr("Search name or id"); placeholderColor: Qt.rgba(1,1,1,0.38); color: "white"; font.pixelSize: Theme.fontSizeSmall; background: null
                onTextChanged: page.search = text
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.top: searchBox.bottom; anchors.topMargin: Theme.paddingSmall
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        model: ListModel { id: listModel }
        spacing: Theme.paddingSmall
        topMargin: Theme.paddingSmall
        clip: false
        VerticalScrollDecorator {}
        delegate: Item {
            width: listView.width; height: 72
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 2*Theme.horizontalPageMargin
                height: 64; radius: 16
                color: rowMouse.pressed ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.11); border.width: 1
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.12) }
                Rectangle {
                    x: 10; anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42; radius: 12
                    clip: true
                    color: Qt.rgba(1,1,1,0.08)
                    border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: model.type === "群" ? "#6d6bff" : "#3ec6ff" }
                        GradientStop { position: 1.0; color: model.type === "群" ? "#a56bff" : "#7c8bff" }
                    }
                    Label { anchors.centerIn: parent; text: model.name ? model.name.charAt(0) : "?"; color: "white"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; visible: avatarImg.status !== Image.Ready }
                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: model.type === "群" ? "https://p.qlogo.cn/gh/" + model.id + "/" + model.id + "/100" : "https://q.qlogo.cn/headimg_dl?dst_uin=" + model.id + "&spec=100"
                        asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop; smooth: true; visible: status === Image.Ready
                    }
                }
                Label {
                    x: 62; y: 12
                    width: parent.width - 62 - typeTag.width - 20
                    text: model.name; color: "white"; font.pixelSize: Theme.fontSizeSmall; truncationMode: TruncationMode.Fade
                }
                Label {
                    x: 62; y: 34
                    width: parent.width - 62 - typeTag.width - 20
                    text: model.id; color: Qt.rgba(1,1,1,0.42); font.pixelSize: Theme.fontSizeTiny; truncationMode: TruncationMode.Fade
                }
                Rectangle {
                    id: typeTag
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 22; radius: 11
                    color: model.type === "群" ? Qt.rgba(0.48,0.56,1.0,0.22) : Qt.rgba(1,1,1,0.08)
                    border.color: model.type === "群" ? Qt.rgba(0.66,0.73,1.0,0.28) : Qt.rgba(1,1,1,0.11); border.width: 1
                    Label { anchors.centerIn: parent; text: model.type; color: model.type === "群" ? "#9aa3ff" : Qt.rgba(1,1,1,0.62); font.pixelSize: Theme.fontSizeTiny; font.bold: true }
                }
                MouseArea { id: rowMouse; anchors.fill: parent; onClicked: { page.accepted(model.type === "群", model.id, model.name); pageStack.pop() } }
            }
        }
        ViewPlaceholder { enabled: listModel.count === 0; text: qsTr("No matches"); hintText: qsTr("Load contacts after connecting") }
    }
}
