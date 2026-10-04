import QtQuick
import QtQuick.Controls
import Sulfur

MenuBarItem {

    id: root

    // Same height as SuBarButton, so both line up in the toolbar row
    implicitHeight: Style.barItemHeight
    topPadding: 0
    bottomPadding: 0
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing

    readonly property bool active: root.hovered || root.pressed || (root.menu && root.menu.visible)

    contentItem: SuText {

        // Strip the "&" mnemonic marker -- macOS menus don't show underlined
        // accelerators, so there's nothing useful to render it as.
        text: root.text.replace(/&/g, "")
        font.pixelSize: Style.regular
        color: root.active ? Palette.accentText : Palette.primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {

        anchors.fill: parent
        radius: Style.radius
        color: root.active ? Palette.accent : "transparent"
    }
}
