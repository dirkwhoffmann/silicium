import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Assets
import Silicium.Components
import Silicium.Controllers
import Silicium.Preferences

Rectangle {

    id: canvas

    property C64Controller controller

    anchors.fill: parent
    color: "black"

    SiC64Renderer {

        id: texture
        controller: canvas.controller
        anchors.fill: parent

        Component.onCompleted: {
            controller.renderer = texture
        }
    }
}