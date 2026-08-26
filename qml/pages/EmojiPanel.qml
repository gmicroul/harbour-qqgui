import QtQuick 2.2
import Sailfish.Silica 1.0

// small emoji picker docked above the message input
Column {
    id: panel

    signal emojiPicked(string emo)

    width: parent ? parent.width - Theme.horizontalPageMargin * 2 : 480
    height: grid.height + Theme.paddingSmall
    spacing: 0

    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.15)
        radius: Theme.paddingSmall
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: 8
        spacing: Theme.paddingMedium

        Repeater {
            model: [ "😂","🤣","😍","😭","😎","🤔","😡","🙏",
                     "👍","👎","👏","💪","🎉","🎂","🌹","❤️",
                     "💔","🚀","🐶","🐱","🍺","☕","🍉","⭐" ]

            delegate: Label {
                text: modelData
                font.pixelSize: Theme.fontSizeLarge

                MouseArea {
                    anchors.fill: parent
                    onClicked: panel.emojiPicked(modelData)
                }
            }
        }
    }
}
