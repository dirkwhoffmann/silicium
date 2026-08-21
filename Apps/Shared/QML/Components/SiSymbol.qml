import QtQuick
import QtQuick.Controls
import Silicium.Theme

AbstractButton {

    id: root

    property string symbol
    property string awesome
    property string phosphor
    property int size: Size.regular
    property color color: Palette.primary

    property real scale: 0.8
    implicitWidth: Size.iconSize(size)
    implicitHeight: Size.iconSize(size)
    enabled: false

    font.family: symbol ? Fonts.symbols : phosphor ? Fonts.phosphor : Fonts.awesome

    contentItem: SiText {

        id: label

        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        // Phosphor icons are selected via ligatures, and non-Regular weights
        // require a matching name suffix (e.g. "gear-bold") -- see
        // Fonts.phosphorSuffix.
        text: symbol ? symbol : phosphor ? phosphor + Fonts.phosphorSuffix : awesome
        font.family: root.font.family
        font.bold: root.font.bold

        // Scale icon with button size
        font.pixelSize: Math.round(Math.min(width, height) * root.scale)

        color: root.color
    }
}

/*
SiSymbolButton {

    enabled: false
    color: Palette.primary
}
*/