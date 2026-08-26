import QtQuick 2.2

// QQ 原生小表情（本地官方图库按 id 映射）
Item {
    id: tile
    width: 50
    height: 54

    property int faceId: 0

    Image {
        anchors.centerIn: parent
        width: 46
        height: 46
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        source: "file:///home/defaultuser/qqcat-faces/" + faceId + ".png"
    }
}
