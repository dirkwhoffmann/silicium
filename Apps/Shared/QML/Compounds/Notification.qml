import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

Item {

    id: root

    property alias title: title.text
    property alias message: message.text
    required property int severity

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitWidth: 300
    implicitHeight: delegateItem.implicitHeight

    signal close()

    DebugRect {}

    HoverHandler {

        id: hoverHandler
    }

    ColumnLayout {

        id: delegateItem

        anchors.fill: parent
        Layout.fillWidth: true

        //
        // First row
        //

        RowLayout {

            Layout.fillWidth: true
            // Layout.preferredHeight: closeSymbol.implicitHeight
            spacing: Style.mediumSpacing

            SiSymbol {

                Layout.alignment: Qt.AlignVCenter
                symbol: root.severity === 0 ? "info-circle" : "circle-exclamation";
                font.pixelSize: Style.large
                font.family: Fonts.awesome
                font.bold: true
                color: root.severity === 0 ? Palette.accent : Palette.error;
            }

            SiText {

                id: title
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                font.bold: true
                font.pixelSize: Style.regular
                color: Palette.primary
            }

            /*
            SiSymbolButton {

                id: closeSymbol
                visible: hoverHandler.hovered
                Layout.alignment: Qt.AlignVCenter
                symbol: "close"
                font.pixelSize: Style.huge
                onClicked: { console.log("Close clicked"); root.close() }
            }

             */
        }

        //
        // Second row
        //

        SiText {

            id: message
            Layout.fillWidth: true
            Layout.leftMargin: title.x
            wrapMode: Text.WordWrap
            font.pixelSize: Style.regular
            color: Palette.secondary
        }
    }
}