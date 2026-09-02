import QtQuick
import QtQuick.Window
import Silicium.Controllers

Window {

    id: root

    property SiAmigaController amiga: SiAmigaController

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    title: "SiAmiga"
    color: "black"

    SiAmigaCanvas {

        controller: root.amiga
    }
}
