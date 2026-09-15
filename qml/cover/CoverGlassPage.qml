import QtQuick 2.2
import Sailfish.Silica 1.0

// QQ Glass 专属封面：深紫玻璃底 + 新 mascot + 标题（原版 qqcat 继续用 CoverPage）。
CoverBackground {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f0c29" }
            GradientStop { position: 0.5; color: "#302b63" }
            GradientStop { position: 1.0; color: "#24243e" }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#22ffffff"
        border.width: 1
        border.color: "#44ffffff"
    }

    Image {
        source: Qt.resolvedUrl("../images/qqgui-mascot.png")
        visible: status === Image.Ready

        opacity: 0.9
        fillMode: Image.PreserveAspectFit
        smooth: true
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Theme.paddingLarge
        width: parent.width - 2 * Theme.paddingLarge
        height: parent.height - 4 * Theme.paddingLarge
    }

    Row {
        spacing: Theme.paddingSmall
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium

        Label { text: "QQ"; color: "white"; font.bold: true }
        Label { text: qsTr("Glass"); color: "white"; opacity: 0.6 }
    }
}
