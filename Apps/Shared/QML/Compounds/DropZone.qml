import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Theme

Item {

    id: root

    property int zoneWidth: 96
    property Action action

    visible: action
    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight
    Layout.maximumWidth: implicitWidth
    Layout.maximumHeight: implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: true

    property alias containsDrag: dragArea.containsDrag

    Column {

        id: column

        spacing: Style.mediumSpacing

        Rectangle {

            implicitWidth: zoneWidth
            implicitHeight: zoneWidth
            border.width: 1
            border.color: Palette.background
            color: Palette.surface
            opacity: dragArea.containsDrag ? 1.0 : 0.9
            radius: Style.radius

            Image {

                id: embeddedImage
                opacity: !enabled ? 0.2 : dragArea.containsDrag ? 0.8 : 0.6
                anchors.fill: parent
                anchors.margins: Style.smallSpacing
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: enabled ? action.icon.source : Assets.iconUrl(Assets.DropNone)
                layer.enabled: true
                layer.effect: MultiEffect {

                    source: embeddedImage
                    anchors.fill: embeddedImage
                    colorization: 1
                    brightness: 1.0
                    colorizationColor: Palette.primary
                }
            }
        }

        Rectangle {

            implicitWidth: zoneWidth
            implicitHeight: 48
            border.width: 1
            border.color: Palette.background
            color: Palette.surface
            opacity: 0.9
            radius: Style.radius
            clip: true

            SiText {

                text: action.text
                font.pixelSize: Style.large
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    DropArea {

        DebugRect {}

        id: dragArea
        anchors.fill: parent

        onEntered: {
            console.log("Zone entered")
        }
        onExited: {
            console.log("Zone exited")
        }

        onDropped: function (drop) {

            action.trigger()
            drop.acceptProposedAction()
        }
    }
}