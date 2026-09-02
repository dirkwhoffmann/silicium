import QtQuick
import Silicium.Controllers

Rectangle {

    id: canvas

    property SiAmigaController controller

    anchors.fill: parent
    color: "black"

    SiAmigaRenderer {

        id: texture
        controller: canvas.controller
        anchors.fill: parent

        Component.onCompleted: {
            controller.renderer = texture
        }
    }
}
