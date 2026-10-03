// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

SiChrome {

    id: root

    required property SiAmController amiga
    required property SiAmWindow window

    // Emitted by the Amiga menu's "About" item, which the window handles
    signal openAbout()

    // Visual style, from the appearance preferences
    overlayed: Preferences.chromePlacement === 1
    unified: Preferences.chromeTitleBar === 1
    compact: Preferences.chromeLayout === 1

    titleText: "SiAmiga"

    titleBarContent: [

        SiSymbolButton {

            id: chromeToggle

            symbol: "page_header"
            color: Palette.secondary
            background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

            onClicked: root.window.showCommandBar = !root.window.showCommandBar
        },

        SiSymbolButton {

            id: statusBarToggle

            symbol: "page_footer"
            color: Palette.secondary
            background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

            onClicked: root.window.showStatusBar = !root.window.showStatusBar
        }
    ]

    menuContent: SiAmMenu {

        anchors.fill: parent

        amiga: root.amiga
        window: root.window

        onOpenAbout: root.openAbout()

        // Lets the View menu's checkable items show the right state; the
        // window owns the visibility and answers the signals below.
        toolbarVisible: root.showCommandBar
        statusBarVisible: root.showStatusBar

        onToggleToolbar: root.window.showCommandBar = !root.window.showCommandBar
        onToggleStatusBar: root.window.showStatusBar = !root.window.showStatusBar
    }

    toolbarContent: SiAmToolbar {

        anchors.fill: parent

        amiga: root.amiga
        window: root.window
    }

    statusBarContent: SiAmStatusbar {

        anchors.fill: parent

        amiga: root.amiga
        // The background is drawn by the chrome
        color: "transparent"
    }
}
