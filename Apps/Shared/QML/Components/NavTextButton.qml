import QtQuick
import QtQuick.Controls
import Silicium.Theme

ToolButton {

    id: control

    property string symbol: ""
    property string awesome: ""
    property string phosphor: ""
    property alias rotate: textElement.rotation
    implicitWidth: 28
    implicitHeight: 26
    padding: 0
    topPadding: 0
    bottomPadding: 0

    contentItem: SiText {

        id: textElement
        text: control.symbol ? control.symbol
            : control.phosphor ? control.phosphor + Fonts.phosphorSuffix
                : control.awesome
        font.family: control.symbol ? Fonts.symbols
            : control.phosphor ? Fonts.phosphor
                : Fonts.awesome
        font.pixelSize: 20
        color: control.enabled ? Palette.primary : Palette.disabled
        opacity: 0.7
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
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

        id: description
        text: control.text
    }
}