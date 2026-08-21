import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects // For MultiEffect
import Silicium.Theme

RoundButton {
    id: root

    implicitWidth: 136
    implicitHeight: 136
    radius: 8 // Style.borderRadius
    checkable: true

    // Smooth transition between checked/unchecked states
    Behavior on opacity { NumberAnimation { duration: 200 } }

    contentItem: ColumnLayout {
        spacing: 8
        anchors.margins: 12

        Image {
            id: iconImage
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: icon.source
            fillMode: Image.PreserveAspectFit
            // Desaturate slightly if not checked to focus on the active one
            opacity: root.checked ? 1.0 : 0.6
        }

        SiText {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            font.pixelSize: Style.large
            font.bold: root.checked
            // Use a distinct color for the active state
            color: root.checked ? Palette.primary : Palette.secondary
            horizontalAlignment: Text.AlignHCenter
        }
    }

    background: Item {

        Rectangle {
            id: rect
            anchors.fill: parent
            color:root.checked ? "#44ffffff" : "#11ffffff"
            radius: root.radius
            border.color: root.checked ? "white" : "#44ffffff"
            border.width: root.checked ? 3 : 1
        }
    }
}
