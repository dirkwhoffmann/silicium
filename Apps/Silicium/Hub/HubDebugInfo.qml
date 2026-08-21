import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Rectangle {

    id: rootRect

    component KeyLabel : SiText {

        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight
        font.pixelSize: Style.small
        font.bold: true
    }

    component ValueLabel : SiText {

        horizontalAlignment: Text.AlignLeft
        Layout.alignment: Qt.AlignLeft
        font.pixelSize: Style.small
        font.bold: true
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(80, debugPanel.implicitHeight + 2 * Style.mediumSpacing)
    Layout.margins: Style.mediumSpacing
    color: Palette.tint
    radius: Style.radius

    ScrollView {

        id: scrollView
        anchors.fill: parent
        anchors.topMargin: Style.mediumSpacing
        anchors.bottomMargin: Style.mediumSpacing
        anchors.leftMargin: Style.mediumSpacing
        anchors.rightMargin: Style.mediumSpacing

        GridLayout {

            id: debugPanel
            width: scrollView.availableWidth
            columns: 2
            columnSpacing: Style.mediumSpacing
            rowSpacing: 0

            KeyLabel {
                text: "vUUID:"
            }
            ValueLabel {
                text: HubController.vInfo.uuid ?? "No UUID"
                Layout.fillWidth: true
            }
            KeyLabel {
                text: "sUUID:"
            }
            ValueLabel {
                text: HubController.sInfo.uuid ?? "No UUID"
                Layout.fillWidth: true
            }
            KeyLabel {
                text: "State:"
            }
            ValueLabel {
                text: HubController.vInfo.state ?? "undefined"
                Layout.fillWidth: true
            }
        }
    }
}
