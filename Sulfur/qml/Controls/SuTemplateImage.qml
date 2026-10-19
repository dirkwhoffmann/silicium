import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sulfur

Item {
    id: root

    property url source
    property color color: Palette.primary
    property string symbol
    property string awesome
    property string phosphor
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

        visible: root.awesome !== "" || root.symbol !== "" || root.phosphor !== ""
        font.family: Fonts.iconFamily(root.symbol, root.phosphor, root.awesome)

        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        contentItem: SuText {

            id: label

            text: Fonts.iconText(root.symbol, root.phosphor, root.awesome)
            font: symbolButton.font

            color: symbolButton.checked
                ? Palette.accent
                : !symbolButton.enabled
                    ? Palette.tertiary
                    : root.color

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
        colorizationColor: root.color
    }
}
