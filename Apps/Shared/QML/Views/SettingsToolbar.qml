// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

/* Shared toolbar of every settings page: a burger menu and a heading, plus
 * whatever the page appends. Specialised by ConfigToolbar and PrefToolbar --
 * see SettingsPage, which hosts one of these above its content.
 */
ToolBar {

    id: root

    property alias menuContent: burgerMenu.contentData
    property alias heading: headingText.text

    /* Everything besides the burger menu and the heading comes from the user of
     * this component and is appended to the row: an HSpacer plus a ConfigLock
     * for the config panels, the device selector for DevicesPrefs. Without a
     * spacer the items stay left, next to the heading.
     */
    default property alias content: contentRow.data

    Layout.fillWidth: true
    leftPadding: Style.mediumSpacing
    rightPadding: Style.mediumSpacing
    topPadding: Style.smallSpacing
    bottomPadding: Style.smallSpacing

    // Always as tall as a toolbar holding the burger button, so a page without
    // a menu (or without any items at all) doesn't get a stunted bar.
    implicitHeight: Math.max(implicitContentHeight, Style.iconLarge) + topPadding + bottomPadding

    background: Rectangle {

        color: Palette.surfaceElevated
        radius: Style.radius
    }

    RowLayout {

        id: contentRow
        anchors.fill: parent

        SiSymbolButton {

            id: menuButton
            symbol: "Menu"
            // No point in a burger that opens an empty menu.
            visible: burgerMenu.count > 0
            // Larger than any Size level -- keep the explicit pixel dimensions.
            implicitWidth: Style.iconLarge
            implicitHeight: Style.iconLarge

            onClicked: burgerMenu.open()

            SiMenu {

                id: burgerMenu
                y: menuButton.height
            }
        }

        SiText {

            id: headingText
            font.bold: true
            color: Palette.primary
        }
    }
}
