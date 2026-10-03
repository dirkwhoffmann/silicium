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

    readonly property SiAmController amiga: SiAmController
    required property SiAmWindow window

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

            onClicked: root.window.actions.toggleCommandBar.trigger()
        },

        SiSymbolButton {

            id: statusBarToggle

            symbol: "page_footer"
            color: Palette.secondary
            background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

            onClicked: root.window.actions.toggleStatusBar.trigger()
        }
    ]

    menuContent: SiAmMenu {

        anchors.fill: parent

        window: root.window
    }

    toolbarContent: SiAmToolbar {

        anchors.fill: parent

        window: root.window
    }

    statusBarContent: SiAmStatusbar {

        anchors.fill: parent

        // The background is drawn by the chrome
        color: "transparent"
    }
}
