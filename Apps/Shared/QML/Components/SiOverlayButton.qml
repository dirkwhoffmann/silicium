import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Silicium.Theme

ToolButton {

    id: control
    property string symbol: ""
    property real size: 48
    property real scaleFactor: 1.05
    property real hoverExpansion: 0
    property alias color: content.color

    implicitWidth: size
    implicitHeight: size

    contentItem: SiText {

        id: content
        text: control.symbol
        color: control.enabled ? "#fff" : "#ccc"
        font.family: Fonts.symbols
        font.pixelSize: (0.8 * control.size) + (control.enabled && hovered ? hoverExpansion : 0)
        scale: control.enabled && hovered ? scaleFactor : 1.0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 120
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }
    }

    background: Rectangle {

        anchors.fill: parent
        visible: true
        anchors.topMargin: 0
        anchors.bottomMargin: 2
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        radius: 5
        color: control.enabled && hovered ? "#E0000000" : "#C0000000"
        border.color: control.down ? "#90ffffff" :  "#50ffffff"

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }
    }
}
