import QtQuick 2.2
import Sailfish.Silica 1.0

// 胶囊筛选条：高 itemSizeExtraSmall pill，字 Small（全部 Theme 度量，随屏缩放）。
// 选中态 tint #555af0ff（pi 选中色），未选中 #22ffffff。
// v: ""=全部 "群"=群 "私聊"=好友，与原 ConversationsPage.kindFilter 对齐。
Row {
    id: root

    property string current: ""
    signal picked(string v)

    spacing: Theme.paddingSmall

    Repeater {
        model: [ { t: qsTr("All"), v: "" },
                 { t: qsTr("Groups"), v: "群" },
                 { t: qsTr("Friends"), v: "私聊" } ]

        delegate: Rectangle {
            width: Math.max(Theme.itemSizeMedium, tabLabel.width + 2 * Theme.paddingLarge)
            height: Theme.itemSizeExtraSmall
            radius: height / 2
            color: root.current === modelData.v ? "#555af0ff" : "#22ffffff"
            border.width: 1
            border.color: "#44ffffff"

            Label {
                id: tabLabel
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeSmall
                font.bold: root.current === modelData.v
                color: "white"
                opacity: root.current === modelData.v ? 1.0 : 0.6
                text: modelData.t
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.picked(modelData.v)
            }
        }
    }
}
