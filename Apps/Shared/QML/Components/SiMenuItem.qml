import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

MenuItem {

    id: root

    // Only reserve room for the checkmark gutter when this menu actually
    // has a checkmark to show somewhere; otherwise it's just stray padding.
    readonly property real indicatorMargin: (root.menu && root.menu.hasCheckmark) ? 24 : Style.mediumSpacing

    implicitWidth: contentItem.implicitWidth + indicatorMargin + Style.mediumSpacing
    implicitHeight: root.visible ? 26 : 0
    rightPadding: 0

    contentItem: RowLayout {

        anchors.fill: parent
        anchors.leftMargin: root.indicatorMargin
        anchors.rightMargin: Style.mediumSpacing
        spacing: 6

        SiSymbol {

            Layout.alignment: Qt.AlignVCenter
            visible: symbol !== ""
            symbol: root.action ? root.action.icon.name : ""
            width: Style.large
            height: Style.large

            color: root.highlighted ? Palette.accentText
                : root.enabled ? Palette.primary
                    : Palette.tertiary
        }

        SiText {

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            // Strip the "&" mnemonic marker -- macOS menus don't show
            // underlined accelerators, so there's nothing useful to render it as.
            text: root.text.replace(/&/g, "")

            font.pixelSize: Style.regular
            font.bold: root.font.bold

            color: root.highlighted ? Palette.accentText
                : root.enabled ? Palette.primary
                    : Palette.tertiary

            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            DebugRect {}
        }

        SiText {

            Layout.alignment: Qt.AlignVCenter
            visible: text !== ""
            text: root.action && root.action.shortcut ? Shortcuts.nativeText(root.action.shortcut) : ""
            font.pixelSize: Style.small

            color: root.highlighted ? Qt.alpha(Palette.accentText, 0.8) : Palette.tertiary

            verticalAlignment: Text.AlignVCenter
        }
    }

    arrow: SiText {

        x: parent.width - width
        anchors.verticalCenter: parent.verticalCenter
        visible: root.subMenu !== null
        text: "chevron_right"
        font.family: Fonts.symbols
        font.pixelSize: 16
        color: root.highlighted ? Palette.accentText : Palette.primary
    }

    indicator: Item {

        visible: root.checkable && root.checked
        width: 18
        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter

        SiText {

            anchors.centerIn: parent
            visible: root.checkable && root.checked
            text: "check"
            font.family: Fonts.symbols
            font.pixelSize: 16
            font.bold: true
            color: root.highlighted ? Palette.accentText : Palette.primary
        }
    }

    background: Rectangle {

        color: root.highlighted ? Palette.accent : "transparent"
        radius: Style.radius
    }
}
