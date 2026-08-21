import QtQuick
import QtQuick.Controls
import Silicium.Theme

MenuBarItem {

    id: root

    implicitHeight: 26
    topPadding: 0
    bottomPadding: 0
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    contentItem: SiText {

        // Strip the "&" mnemonic marker -- macOS menus don't show underlined
        // accelerators, so there's nothing useful to render it as.
        text: root.text.replace(/&/g, "")
        font.pixelSize: Style.regular
        color: root.highlighted || root.pressed ? Palette.accentText : Palette.primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {

        anchors.fill: parent
        anchors.margins: 0
        implicitWidth: 30
        implicitHeight: 26
        radius: Style.radius
        color: root.pressed || root.highlighted ? Palette.accent : "transparent"
    }
}
