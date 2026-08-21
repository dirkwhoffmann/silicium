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
import Qt5Compat.GraphicalEffects
import Silicium.Controllers
import Silicium.Theme

// Slide-down variant of the virtual C64 keyboard. Instead of opening in a
// separate window, the keyboard drops down from the top edge of the
// emulator window. Pressing a key with the left mouse button dismisses the
// sheet; pressing it with the right mouse button (which toggles a key
// without releasing it) leaves the sheet open.

Item {

    id: root

    required property C64Controller controller
    property bool shown: false

    // Top edge the sheet slides down from. Set to the canvas top (below the
    // toolbar / menu bar) so the sheet tucks under them rather than being
    // overlapped by them.
    property real slideTop: 0

    width: panel.implicitWidth + 2 * Style.largeSpacing
    height: panel.implicitHeight + 2 * Style.largeSpacing
    y: shown ? slideTop - 1 : slideTop - height
    visible: y > slideTop - height

    Behavior on y {

        NumberAnimation {

            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {

        anchors.fill: parent
        color: Palette.background
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Style.radius
        bottomRightRadius: Style.radius
        border.width: 1
        border.color: Palette.backgroundBorder

        layer.enabled: true
        layer.effect: DropShadow {

            transparentBorder: true
            radius: 30; samples: 20
            color: "#60000000"
            verticalOffset: 10
        }

        // Absorb clicks so they don't fall through to the emulator canvas
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }
    }

    SiC64KeyboardPanel {

        id: panel

        anchors.centerIn: parent
        controller: root.controller

        onKeyActivated: function(button) {

            if (button === Qt.LeftButton) root.shown = false
        }
    }
}
