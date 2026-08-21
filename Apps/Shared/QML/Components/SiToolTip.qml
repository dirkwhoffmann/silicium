import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Theme

ToolTip {

    id: root

    delay: 500
    timeout: 3000
    visible: parent.hovered && root.text !== ""
    topPadding: Style.mediumSpacing
    bottomPadding: Style.mediumSpacing
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    property color primaryColor: Palette.primary
    property color backgroundColor: Palette.background
    property color backgroundBorderColor: Palette.backgroundBorder

    contentItem: SiText {

        text: root.text
        font.pixelSize: Style.small
        color: root.primaryColor
    }

    background: Rectangle {

        color: root.backgroundColor
        border.color: root.backgroundBorderColor
        radius: Style.radius
    }
}