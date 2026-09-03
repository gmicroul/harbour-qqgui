import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: root
    // 放在 Page 最底层, fills parent
    // 用深色渐变 + 3 颗柔光 Blob 做出毛玻璃的底

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b0f1f" }
            GradientStop { position: 0.45; color: "#141a33" }
            GradientStop { position: 1.0; color: "#1e2346" }
        }
    }

    // subtle vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.32) }
        }
        opacity: 0.6
    }

    // --- 柔光 blob, 只用透明度+渐变模拟毛玻璃光斑,不依赖 GraphicalEffects ---
    // 左上 蓝紫
    Rectangle {
        width: parent.width * 1.15
        height: width
        x: -parent.width * 0.35
        y: -height * 0.28
        radius: width / 2
        opacity: 0.42
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.45,0.52,1.0,0.55) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    // 右上 粉紫
    Rectangle {
        width: parent.width * 0.95
        height: width
        x: parent.width * 0.45
        y: -height * 0.18
        radius: width / 2
        opacity: 0.34
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.82,0.45,1.0,0.42) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    // 底部 青蓝
    Rectangle {
        width: parent.width * 1.3
        height: width
        x: -parent.width * 0.15
        y: parent.height * 0.48
        radius: width / 2
        opacity: 0.30
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.24,0.78,0.92,0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // 顶部细腻高光线
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Qt.rgba(1,1,1,0.07)
    }
}
