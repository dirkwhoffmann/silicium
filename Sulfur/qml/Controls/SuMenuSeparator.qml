import QtQuick
import QtQuick.Controls
import Sulfur

MenuSeparator {

    id: root

    topPadding: Style.smallSpacing
    bottomPadding: Style.smallSpacing
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    implicitHeight: visible ? implicitContentHeight + topPadding + bottomPadding : 0

    contentItem: Rectangle {

        implicitHeight: 1
        color: Palette.tertiary
        opacity: 0.25
    }
}
