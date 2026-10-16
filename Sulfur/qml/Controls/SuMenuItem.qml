import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

MenuItem {

    id: root

    // Only reserve room for the checkmark gutter when this menu actually
    // has a checkmark to show somewhere; otherwise it's just stray padding.
    readonly property real indicatorMargin: (root.menu && root.menu.hasCheckmark) ? 24 : Style.mediumSpacing

    // The color of the item's content
    readonly property color color: root.highlighted ? Palette.accentText
                                 : root.enabled ? Palette.primary
                                                : Palette.tertiary

    implicitWidth: contentItem.implicitWidth + indicatorMargin + Style.mediumSpacing
    implicitHeight: root.visible ? 26 : 0
    rightPadding: 0

    contentItem: RowLayout {

        anchors.fill: parent
        anchors.leftMargin: root.indicatorMargin
        anchors.rightMargin: Style.mediumSpacing
        spacing: 6

        SuSymbol {

            Layout.alignment: Qt.AlignVCenter
            visible: symbol !== ""
            symbol: root.action ? root.action.icon.name : ""
            width: Style.large
            height: Style.large

            color: root.color
        }

        SuText {

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            // Strip the "&" mnemonic marker -- macOS menus don't show
            // underlined accelerators, so there's nothing useful to render it as.
            text: root.text.replace(/&/g, "")

            font.pixelSize: Style.regular
            font.bold: root.font.bold

            color: root.color

            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            DebugRect {}
        }

        SuText {

            Layout.alignment: Qt.AlignVCenter
            visible: text !== ""
            text: root.action && root.action.shortcut ? Shortcuts.nativeText(root.action.shortcut) : ""
            font.pixelSize: Style.small

            color: root.highlighted ? Qt.alpha(Palette.accentText, 0.8) : Palette.tertiary

            verticalAlignment: Text.AlignVCenter
        }
    }

    arrow: SuSymbol {

        x: parent.width - width
        anchors.verticalCenter: parent.verticalCenter
        visible: root.subMenu !== null
        symbol: "chevron_right"
        width: 20
        height: 20
        color: root.color
    }

    indicator: SuSymbol {

        x: 2 + (18 - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        visible: root.checkable && root.checked
        symbol: "check"
        width: 20
        height: 20
        font.bold: true
        color: root.color
    }

    background: Rectangle {

        color: root.highlighted ? Palette.accent : "transparent"
        radius: Style.radius
    }
}
