import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
    id: panel
    signal emojiPicked(string emo)
    width: parent ? parent.width : 480
    height: gridBox.height + 16
    spacing: 0

    Rectangle {
        id: gridBox
        width: parent.width
        height: grid.height + 20
        radius: 16
        color: Qt.rgba(1,1,1,0.08)
        border.color: Qt.rgba(1,1,1,0.12)
        border.width: 1
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; radius: parent.radius; color: Qt.rgba(1,1,1,0.13) }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: 8
            spacing: 8
            Repeater {
                model: [ "😂","🤣","😍","😭","😎","🤔","😡","🙏",
                         "👍","👎","👏","💪","🎉","🎂","🌹","❤️",
                         "💔","🚀","🐶","🐱","🍺","☕","🍉","⭐" ]
                delegate: Rectangle {
                    width: 52; height: 52; radius: 14
                    color: emoMouse.pressed ? Qt.rgba(1,1,1,0.14) : "transparent"
                    Label { anchors.centerIn: parent; text: modelData; font.pixelSize: 28 }
                    MouseArea { id: emoMouse; anchors.fill: parent; onClicked: panel.emojiPicked(modelData) }
                }
            }
        }
    }
}
