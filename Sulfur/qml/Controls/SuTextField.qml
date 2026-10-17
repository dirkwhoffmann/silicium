import QtQuick
import QtQuick.Controls
import Sulfur

TextField {

    id: control

    property int size: Size.regular

    font.family: Fonts.main
    font.pixelSize: Size.fontSize(size)
    color: control.enabled ? Palette.primary : Palette.tertiary

    background: Rectangle {

        id: inputBackground
        radius: 4
        color: !control.enabled ? Palette.disabled : control.activeFocus ? Palette.insetFocused : Palette.inset
        border.color: control.activeFocus ? Palette.insetBorderFocused : Palette.insetBorder
        border.width: 1

        // Subtle inner shadow for text fields
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            border.color: "#15000000"
            anchors.margins: 1
        }
    }
}
