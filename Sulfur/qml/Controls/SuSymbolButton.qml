import QtQuick
import QtQuick.Controls
import Sulfur

AbstractButton {

    id: root

    property string symbol
    property string awesome
    property string phosphor
    property int size: Size.regular
    property color color: Palette.primary
    property color hoverColor: Palette.primary
    property color checkedColor: Palette.accent

    property real scale: 0.8

    implicitWidth: Size.iconSize(size)
    implicitHeight: Size.iconSize(size)

    font.family: Fonts.iconFamily(symbol, phosphor, awesome)

    contentItem: SuText {

        id: label

        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Fonts.iconText(symbol, phosphor, awesome)
        font.family: root.font.family
        font.bold: root.font.bold
        font.pixelSize: Math.round(Math.min(width, height) * root.scale)

        color:
            !root.enabled ? Palette.disabled :
                root.checked ? root.checkedColor : root.color
    }
}
