import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers

ComboBox {
    id: control
    required property var deviceModel

    model: deviceModel
    implicitHeight: 26

    function getIconSource(type) {

        switch (type) {
            case 1:
                return Assets.iconUrl(Assets.Burger)
            case 2:
                return Assets.iconUrl(Assets.Chart)
            case 3:
                return Assets.iconUrl(Assets.Shell)
            default:
                return Assets.iconUrl(Assets.Power)
        }
    }

    // Toolbar view (Icon only)
    contentItem: Item {

        implicitWidth: 28
        implicitHeight: 22

        SiSymbol {

            symbol: control.model[control.currentIndex].icon
            font.pixelSize: Style.large
        }
        /*
        Image {
            anchors.centerIn: parent
            width: 20; height: 20
            source: control.model[control.currentIndex].icon
            fillMode: Image.PreserveAspectFit
        }

         */
    }

    background: Rectangle {

        anchors.fill: parent
        visible: control.hovered || control.pressed
        anchors.topMargin: 0
        anchors.bottomMargin: 2
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        radius: 5
        color: control.pressed ? "#20000000" : "#10000000"

        // When pressed, add an inner shadow effect
        Rectangle {
            anchors.fill: parent
            radius: 5
            visible: control.down
            color: "transparent"
            border.color: "#30000000"
            border.width: 1
        }
    }

    popup: Popup {
        y: control.height
        width: 200
        contentItem: ListView {
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
        }
    }

    // Dropdown view (Icon + Name)
    delegate: ItemDelegate {
        width: parent.width
        contentItem: RowLayout {
            spacing: 12
            SiText {
                // If selected, show check; otherwise, show empty string
                text: control.currentIndex === index ? "✓" : ""

                font.pixelSize: 18
                // color: "white"

                // Set a fixed width so the "empty" space still pushes the icon
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            SiSymbol {
                symbol: modelData.icon
                font.pixelSize: Style.large
            }
            /*
            Image {
                source: modelData.icon
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
            }

             */
            SiText {
                text: modelData.name
                Layout.fillWidth: true
            }
        }
    }
}