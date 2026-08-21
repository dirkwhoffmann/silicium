import QtQuick
import QtQuick.Layouts
import Silicium.Theme

ColumnLayout {

    id: root
    spacing: 10 // Internal spacing between title and description
    property url image: ""
    property alias title: titleLabel.text
    property alias description: descriptionLabel.text

    RowLayout {

        Layout.alignment: Qt.AlignHCenter
        spacing: Style.mediumSpacing

        Image {
            id: imageIcon
            source: root.image
            visible: root.image.toString() !== ""
            sourceSize: Qt.size(32, 32)
        }

        SiText {
            id: titleLabel
            font.weight: Font.DemiBold
            font.pixelSize: Style.heading
            color: Palette.primary
        }
    }

    SiText {
        id: descriptionLabel
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        font.pixelSize: Style.large
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: Palette.secondary
    }
}