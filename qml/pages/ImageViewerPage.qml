import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    // local file path (file:// url) of the full-size image
    property alias source: image.source

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        Image {
            id: image
            anchors.centerIn: parent
            width: parent.width
            height: parent.height * 0.86
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }

        BusyIndicator {
            visible: image.status === Image.Loading
            running: visible
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }

        Label {
            visible: image.status === Image.Error
            anchors.centerIn: parent
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            text: qsTr("image unavailable")
        }
    }
}
