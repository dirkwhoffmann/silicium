import QtQuick
import Silicium.Controllers

Rectangle {

    id: canvas

    property SiAmController controller

    anchors.fill: parent
    color: "black"

    SiAmRenderer {

        id: texture
        controller: canvas.controller
        anchors.fill: parent

        Component.onCompleted: {
            controller.renderer = texture
        }
    }
}
