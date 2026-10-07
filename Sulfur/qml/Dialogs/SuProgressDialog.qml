import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

SuDialog {

    id: root

    // What the job is doing, as a whole and at the moment
    property alias task: taskLabel.text
    property alias subtask: subtaskLabel.text

    // How far along the job is, from 0.0 to 1.0
    property real progress: 0.0

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.largeSpacing

        BusyIndicator {

            running: root.visible
            implicitWidth: 64
            implicitHeight: 64
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {

            Layout.fillWidth: true
            spacing: Style.smallSpacing

            SuText {

                id: taskLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                font.pixelSize: Style.large // regular
                font.bold: true
            }

            SuProgressBar {

                Layout.fillWidth: true
                implicitHeight: 4
                value: root.progress
            }

            SuText {

                id: subtaskLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                color: Palette.secondary
                font.pixelSize: Style.small // regular
                font.bold: false
            }
        }
    }
}
