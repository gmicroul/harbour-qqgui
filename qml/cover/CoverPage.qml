import QtQuick 2.2
import Sailfish.Silica 1.0

CoverBackground {
    // side-view mascot centered; one-line title pinned to the bottom edge
    Image {
        source: Qt.resolvedUrl("../images/cemian.png")
        visible: status === Image.Ready

        opacity: 0.35
        fillMode: Image.PreserveAspectFit
        smooth: true
        anchors.centerIn: parent
    }

    Row {
        spacing: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge

        Label { text: "QQ" }
        Label { text: qsTr("Bridge"); color: Theme.secondaryColor }
    }
}
