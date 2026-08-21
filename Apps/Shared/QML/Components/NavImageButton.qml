import QtQuick
import QtQuick.Controls
import Silicium.Theme

ToolButton {

    id: control

    property string source: ""

    implicitWidth: 28
    implicitHeight: 26
    padding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: SiTemplateImage {

        source: control.source
        /*
        text: control.symbol
        font.family: Fonts.symbols
        font.pixelSize: 20
        color: control.enabled ? Palette.secondary : Palette.disabled
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        */
    }

    background: Rectangle {

        anchors.fill: parent
        visible: control.enabled && (control.hovered || control.pressed || control.checked)
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        radius: 5
        color: control.pressed || control.checked ? "#30000000" : "#10000000"
    }

    SiToolTip {
        
        text: control.text
    }
}

/*
ToolButton {

    id: control
    font.pixelSize: Style.fontSize
    icon.width: Style.iconSmall
    icon.height: Style.iconSmall

    implicitWidth: 28
    implicitHeight: 28

    property string symbol: ""

    background: Rectangle {

        radius: 5

        color: {
            if (control.enabled && control.down) return "#20000000"
            if (control.enabled && control.hovered) return "#10000000"
            return "transparent"
        }

        // When pressed, add an inner shadow effect
        Rectangle {
            anchors.fill: parent
            visible: control.down
            color: "transparent"
            border.color: "#30000000"
            border.width: 1
        }
    }
}
*/