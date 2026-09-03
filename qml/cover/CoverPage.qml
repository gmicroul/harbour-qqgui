import QtQuick 2.2
import Sailfish.Silica 1.0

CoverBackground {
    // 毛玻璃封面

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b0f1f" }
            GradientStop { position: 1.0; color: "#1e2346" }
        }
    }
    // blobs
    Rectangle {
        width: parent.width * 1.1; height: width; x: -width*0.3; y: -height*0.2; radius: width/2; opacity: 0.5
        gradient: Gradient { GradientStop { position: 0.0; color: Qt.rgba(0.45,0.52,1.0,0.5) } GradientStop { position: 1.0; color: "transparent" } }
    }
    Rectangle {
        width: parent.width * 0.9; height: width; x: parent.width*0.4; y: parent.height*0.2; radius: width/2; opacity: 0.35
        gradient: Gradient { GradientStop { position: 0.0; color: Qt.rgba(0.82,0.45,1.0,0.4) } GradientStop { position: 1.0; color: "transparent" } }
    }

    Image {
        source: Qt.resolvedUrl("../images/cemian.png")
        visible: status === Image.Ready
        opacity: 0.92
        fillMode: Image.PreserveAspectFit
        smooth: true
        width: parent.width * 0.82
        height: width
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -18
    }

    // 底部毛玻璃条
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 56
        color: Qt.rgba(0.09,0.11,0.22,0.48)
        border.color: Qt.rgba(1,1,1,0.10)
        border.width: 1
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.10) }
        Column {
            anchors.centerIn: parent
            spacing: 1
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "QQ Bridge"; color: "white"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; font.letterSpacing: 0.5 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "OneBot · Sailfish"; color: Qt.rgba(1,1,1,0.42); font.pixelSize: Theme.fontSizeTiny; font.letterSpacing: 0.8 }
        }
    }
}
