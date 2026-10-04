import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

SuDialog {

    id: root

    property string titleText: ""
    property string bodyText: ""
    property url iconSource: SulfurSettings.dialogIcon
    property url badgeSource: SulfurSettings.dialogBadge

    default property alias content: dynamicContent.data

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.largeSpacing

        BadgeImage {

            Layout.alignment: Qt.AlignTop
            mainSource: root.iconSource
            badgeSource: root.badgeSource
        }

        ColumnLayout {

            Layout.alignment: Qt.AlignTop
            spacing: Style.mediumSpacing

            SuText {

                text: root.titleText
                font.bold: true
                font.pixelSize: Style.regular
                Layout.fillWidth: true
                visible: text !== ""
            }

            SuText {

                text: root.bodyText
                font.pixelSize: Style.regular
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {

                id: dynamicContent
                Layout.fillWidth: true
                spacing: Style.mediumSpacing
            }

            VSpacer {}
        }
    }
}