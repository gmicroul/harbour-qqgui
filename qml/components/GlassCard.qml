import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: root
    property alias radius: bg.radius
    property alias borderColor: bg.border.color
    property alias borderWidth: bg.border.width
    property alias bgColor: bg.color
    property bool highlight: false
    property real bgOpacity: 0.09
    default property alias content: inner.data

    implicitWidth: 200
    implicitHeight: 100

    // 外阴影 — 柔和抬起感
    Rectangle {
        id: shadow
        anchors.fill: bg
        anchors.topMargin: 2
        radius: bg.radius
        color: Qt.rgba(0,0,0,0.22)
        opacity: 0.55
        z: -1
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 18
        color: root.highlight
               ? Qt.rgba(0.42,0.56,1.0,0.16)
               : Qt.rgba(1,1,1, root.bgOpacity)
        border.color: root.highlight
                      ? Qt.rgba(0.66,0.73,1.0,0.28)
                      : Qt.rgba(1,1,1,0.15)
        border.width: 1

        // 顶部高光内描边
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: parent.radius
            color: Qt.rgba(1,1,1,0.18)
            opacity: 0.7
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: 1
    }
}
