import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

ToolButton {

    id: control

    property url iconSource: ""

    implicitWidth: 46
    implicitHeight: 28

    onClicked: popup.open()

    // BUTTON CONTENT
    contentItem: RowLayout {
        spacing: 4
        anchors.centerIn: parent

        Image {
            source: control.iconSource
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: "#30000000"
        }

        SiText {
            text: "▾"
            font.pixelSize: 10
            color: "#444"
        }
    }

    // BACKGROUND
    background: Rectangle {
        radius: 5
        color: (control.down || popup.visible)
            ? "#20000000"
            : (control.hovered ? "#10000000" : "transparent")

        border.color: (control.down || popup.visible)
            ? "#30000000"
            : "transparent"
    }

    // 🔥 THE IMPORTANT PART
    Popup {
        id: popup

        y: control.height
        x: control.width - width

        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#f6f6f6"
            border.color: "#999"
            radius: 6
        }

        contentItem: ColumnLayout {
            spacing: 0
        }
    }

    // ✅ THIS is now safe and simple
    default property alias content: popup.contentItem.data
}