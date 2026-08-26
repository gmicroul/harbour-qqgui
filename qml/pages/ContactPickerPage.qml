import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    // injected by the pushing page
    property var groups: []
    property var friends: []
    property string search: ""

    signal accepted(bool isGroup, string id, string name)

    function match(name, id) {
        if (search.length === 0)
            return true
        var s = search.toLowerCase()
        return String(name).toLowerCase().indexOf(s) >= 0
                || String(id).indexOf(s) >= 0
    }

    function buildModel() {
        listModel.clear()
        var i, g, f
        for (i in groups) {
            g = groups[i]
            if (match(g.group_name !== undefined ? g.group_name : "", g.group_id))
                listModel.append({
                    type: "群",
                    id: String(g.group_id),
                    name: g.group_name ? g.group_name : String(g.group_id)
                })
        }
        for (i in friends) {
            f = friends[i]
            var fname = f.remark && f.remark.length > 0 ? f.remark : f.nickname
            if (match(fname, f.user_id))
                listModel.append({
                    type: "好友",
                    id: String(f.user_id),
                    name: fname ? fname : String(f.user_id)
                })
        }
    }

    onSearchChanged: buildModel()
    onGroupsChanged: buildModel()
    onFriendsChanged: buildModel()
    Component.onCompleted: buildModel()

    Row {
        id: topBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 0

        PageHeader {
            width: parent.width - refreshButton.width
            title: qsTr("Pick target")
        }

        IconButton {
            id: refreshButton
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "image://theme/icon-m-refresh"
            onClicked: page.buildModel()
        }
    }

    SearchField {
        id: searchField
        anchors {
            top: topBar.bottom
            left: parent.left
            right: parent.right
        }
        placeholderText: qsTr("Search name or id")
        onTextChanged: page.search = text
    }

    SilicaListView {
        id: listView
        anchors {
            top: searchField.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        model: ListModel { id: listModel }

        VerticalScrollDecorator {}

        delegate: ListItem {
            id: row
            contentHeight: Theme.itemSizeMedium

            Label {
                x: Theme.horizontalPageMargin
                y: Theme.paddingSmall
                width: parent.width - 2 * Theme.horizontalPageMargin - typeTag.width - Theme.paddingMedium
                text: model.name
                color: row.highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: typeTag
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.type
                color: model.type === "群" ? Theme.highlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Label {
                x: Theme.horizontalPageMargin
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                width: parent.width - 2 * Theme.horizontalPageMargin - typeTag.width - Theme.paddingMedium
                text: model.id
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                truncationMode: TruncationMode.Fade
            }

            onClicked: {
                page.accepted(model.type === "群", model.id, model.name)
                pageStack.pop()
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No matches")
            hintText: qsTr("Load contacts after connecting")
        }
    }
}
