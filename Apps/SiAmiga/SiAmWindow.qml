import QtQuick
import QtQuick.Window
import Silicium.Controllers

Window {

    id: root

    property SiAmController amiga: SiAmController

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    title: "SiAmiga"
    color: "black"

    SiAmCanvas {

        controller: root.amiga
    }

    // No menu/toolbar action opens either of these yet -- wiring that in is
    // a later step, alongside the panels' actual content.
    SiAmConfigWindow {

        id: configWindow
        controller: root.amiga
    }

    SiAmAbout {

        id: aboutWindow
        visible: false
    }
}
