import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

SuDialog {

    id: root
    property alias text: label.text
    property real progress: 0.0

    ColumnLayout {

        id: column
        Layout.fillWidth: true
        spacing: 10

        SuText {

            id: label
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: Style.regular
            font.bold: false
        }

        SuProgressBar {

            id: control
            Layout.fillWidth: true
            value: root.progress
        }
    }
}