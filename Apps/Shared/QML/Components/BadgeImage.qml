import QtQuick
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root

    property alias mainSource: mainImage.source
    property alias badgeSource: badgeImage.source
    property real iconSize: Style.iconHuge

    implicitWidth: iconSize
    implicitHeight: iconSize

    //
    // Main Icon
    //

    Image {

        id: mainImage

        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.left: parent.left
        anchors.top: parent.top
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    //
    // Overlay icon (badge)
    //

    Image {

        id: badgeImage

        width: parent.width * 0.5
        height: parent.height * 0.5
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        fillMode: Image.PreserveAspectFit
    }
}