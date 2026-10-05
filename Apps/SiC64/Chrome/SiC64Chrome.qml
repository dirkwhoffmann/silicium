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
import Sulfur

//
// The window chrome of the C64 window: SiChrome, filled with the title bar
// buttons, the menu, the toolbar and the status bar of the C64.
//
// The chrome owns whether the command bar and the status bar are shown (see
// SiChrome). The window actions toggle that state.
//

SiChrome {

    id: root

    property C64Controller c64: C64Controller

    // Visual style, from the appearance preferences
    overlayed: Preferences.chromePlacement === 1
    unified: Preferences.chromeTitleBar === 1
    compact: Preferences.chromeLayout === 1

    // The height of the title bar row, as the window reports it
    titleBarInset: window.contentItem.SafeArea.margins.top

    titleText: c64.name + (Preferences.developerMode ? " - " + c64.uuid : "")
    paused: c64.isPaused

    titleBarContent: [

        SuSymbolButton {

            id: chromeToggle

            symbol: "page_header"
            color: Palette.secondary
            background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

            onClicked: root.window.actions.toggleCommandBar.trigger()
        },

        SuSymbolButton {

            id: statusBarToggle

            symbol: "page_footer"
            color: Palette.secondary
            background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

            onClicked: root.window.actions.toggleStatusBar.trigger()
        }
    ]

    menuContent: SiC64Menu {

        anchors.fill: parent
        window: root.window
    }

    toolbarContent: SiC64Toolbar {

        anchors.fill: parent
        window: root.window
    }

    statusBarContent: SiC64Statusbar {

        anchors.fill: parent
        // The background is drawn by the chrome
        color: "transparent"
    }
}
