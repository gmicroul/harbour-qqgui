import QtQuick 2.2

// 全屏底板：照搬 harbour-pi FrostedBackground（深紫渐变 + 三色光斑 + 底部黑遮罩）。
// 背景光斑用 pi 原固定值（380/420/500 系），属底板豁免 75px 约束，见 README。
Item {
    id: root
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f0c29" }
            GradientStop { position: 0.5; color: "#302b63" }
            GradientStop { position: 1.0; color: "#24243e" }
        }
    }

    Rectangle { x: -80; y: -60; width: 380; height: 380; radius: 190; color: "#7f5af0"; opacity: 0.55 }
    Rectangle { x: parent.width - 200; y: parent.height * 0.35; width: 420; height: 420; radius: 210; color: "#ff6a88"; opacity: 0.45 }
    Rectangle { x: parent.width * 0.25; y: parent.height - 180; width: 500; height: 300; radius: 150; color: "#2cb4ff"; opacity: 0.35 }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#66000000" }
        }
    }
}
