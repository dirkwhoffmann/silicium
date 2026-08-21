import QtQuick
import QtQuick.Controls
import Silicium.Theme

RoundButton {

    id: root
    radius: Style.borderRadius

    property color primary: Palette.primary
    property color disabled: Palette.disabled

    background: Rectangle {

        color: root.pressed ? "#44ffffff" : "#11ffffff"
        radius: root.radius
        border.color: root.pressed ? "white" : root.enabled ? "#44ffffff" : "#11ffffff"
        border.width: 1
    }

    contentItem: SiText {

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: parent.text
        color: root.primary
        font.pixelSize: Style.large
    }
}