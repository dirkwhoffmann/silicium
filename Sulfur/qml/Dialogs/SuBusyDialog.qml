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
import QtQuick.Effects
import Sulfur

/* A square box with a busy indicator in it, looking like a SuBanner. It is
 * shown while something is going on that the user can only wait for. As it is
 * modal, nothing underneath reacts to the mouse until it goes away, and it
 * cannot be dismissed by the user: whoever shows it takes it away again.
 */
Popup {

    id: root

    property int boxSize: 160

    anchors.centerIn: Overlay.overlay
    width: boxSize
    height: boxSize
    padding: 0

    modal: true
    closePolicy: Popup.NoAutoClose

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
    }

    background: Rectangle {

        radius: Style.largeSpacing * 2
        color: Palette.overlay
        border.color: Palette.overlayBorder

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }
    }

    contentItem: Item {

        BusyIndicator {

            anchors.centerIn: parent
            implicitWidth: root.boxSize / 2
            implicitHeight: root.boxSize / 2
            palette.dark: "white"
            running: root.visible
        }
    }
}
