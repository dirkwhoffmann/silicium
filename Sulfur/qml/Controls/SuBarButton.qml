import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

AbstractButton {

    id: control

    readonly property bool active: control.checked || control.pressed || control.hovered

    property string symbol: ""
    property string awesome: ""
    property string phosphor: ""

    Layout.preferredWidth: 32
    Layout.preferredHeight: Style.barItemHeight
    Layout.fillHeight: true

    padding: 0

    contentItem: SuSymbol {

        symbol: control.symbol
        awesome: control.awesome
        phosphor: control.phosphor
        scale: 0.7
        opacity: 0.8

        color: !control.enabled ? Palette.disabled
            : control.active ? Palette.accentText
                : Palette.primary
    }

    background: Rectangle {

        anchors.fill: parent
        anchors.margins: 0
        radius: Style.radius
        color: control.enabled && control.active ? Palette.accent : "transparent"
        border.color: "black"
        border.width: 0 // 2
    }

    SuToolTip {

        text: control.text
    }
}
