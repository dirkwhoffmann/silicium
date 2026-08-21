import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Silicium.Theme

ProgressBar {

    id: root

    property alias backgroundColor: bgRect.color
    property int size: Size.regular

    implicitHeight: size === Size.regular ? 18 : Size.controlHeight(size)
    palette.highlight: Palette.accent

    background: Rectangle {

        id: bgRect
        color: Palette.backdrop
    }

    contentItem: Item {

        Rectangle {

            width: root.visualPosition * parent.width
            height: parent.height
            color: Palette.accent
        }

        Rectangle {

            width: parent.width
            height: parent.height
            color: "transparent"
            border.color: Palette.controlBorder
            border.width: 1
        }
    }
}
