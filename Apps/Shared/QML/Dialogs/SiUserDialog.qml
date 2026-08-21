import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

SiDialog {

    id: root

    property string titleText: ""
    property string bodyText: ""
    property url iconSource: Assets.iconUrl(Assets.AppIcon)
    property url badgeSource: Assets.iconUrl(Assets.Biohazard)

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

            SiText {

                text: root.titleText
                font.bold: true
                font.pixelSize: Style.regular
                Layout.fillWidth: true
                visible: text !== ""
            }

            SiText {

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