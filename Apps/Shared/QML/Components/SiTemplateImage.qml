import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Silicium.Theme

Item {
    id: root

    property url source
    property color color
    property string symbol
    property string awesome
    property alias fillMode: image.fillMode

    implicitWidth: image.implicitWidth
    implicitHeight: image.implicitHeight

    Image {

        id: image
        source: root.source ?? ""
        anchors.fill: parent
        visible: false

        fillMode: Image.PreserveAspectFit
    }

    AbstractButton {

        id: symbolButton

        visible: root.awesome !== "" || root.symbol !== ""
        font.family: root.symbol ? Fonts.symbols : Fonts.awesome

        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        contentItem: SiText {

            id: label

            text: root.symbol ? root.symbol : root.awesome
            font: symbolButton.font

            color: symbolButton.checked
                ? Palette.accent
                : !symbolButton.enabled
                    ? Palette.tertiary
                    : Palette.primary

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MultiEffect {

        anchors.fill: parent

        visible: root.source
        source: image
        colorization: 1.0
        brightness: 1.0
        colorizationColor: Palette.primary
    }
}
