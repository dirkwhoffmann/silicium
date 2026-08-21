import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Pane {

    id: textContainer

    property bool visibleTarget: false
    property alias text: descriptionText.text

    Layout.fillWidth: true
    Layout.topMargin: 0
    Layout.bottomMargin: 0
    Layout.leftMargin: 0
    Layout.rightMargin: 0
    Layout.preferredHeight: visibleTarget ? innerPane.implicitHeight + padding * 2 : 0

    padding: Style.mediumSpacing

    background: Rectangle {

        color: "transparent" // "#30ff0000"
        radius: Style.radius

    }

    clip: true

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    Pane {

        id: innerPane
        anchors.fill: parent
        padding: Style.mediumSpacing

        background: Rectangle {

            color: "#a0ffffff"
            radius: Style.radius

            opacity: textContainer.visibleTarget ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }

        SiText {
            id: descriptionText
            width: parent.width
            padding: 0
            text: ""
            font.pixelSize: 13
            color: Palette.secondary
            wrapMode: Text.WordWrap

            // Rectangle { anchors.fill: parent; color: "#300000ff" }

            opacity: textContainer.visibleTarget ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }
    }
}
