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
 * shown while something is going on that the user can only wait for. While it
 * is active, nothing underneath reacts to the mouse or the keyboard, and the
 * user cannot dismiss it: whoever activates it deactivates it again.
 *
 * This is not a Popup, on purpose. A modal popup blocks the whole window, and
 * a window that draws its own title bar is moved by dragging that bar. Here,
 * the blocking item simply starts below it ('topInset'), so the window can be
 * moved all the time.
 *
 * Fill the window with it; it should sit above everything else.
 */
Item {

    id: root

    // Whether the box is up
    property bool active: false

    property int boxSize: 160

    // The height of the strip along the top edge that is left alone
    property real topInset: 0

    // How long it takes to fade in and out
    property int fadeTime: 150

    anchors.fill: parent
    z: 100

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: root.fadeTime } }

    // Takes in everything the items below would have got
    MouseArea {

        anchors.fill: parent
        anchors.topMargin: root.topInset
        enabled: root.active
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        onWheel: (wheel) => wheel.accepted = true
    }

    // Keeps the keyboard from reaching the items below
    FocusScope {

        anchors.fill: parent
        focus: root.active
        onFocusChanged: if (focus) forceActiveFocus()

        Keys.onPressed: (event) => event.accepted = true
        Keys.onReleased: (event) => event.accepted = true
    }

    Rectangle {

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.topInset / 2
        width: root.boxSize
        height: root.boxSize

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

        BusyIndicator {

            anchors.centerIn: parent
            implicitWidth: root.boxSize * 0.8
            implicitHeight: root.boxSize * 0.8
            palette.text: "white"
            running: root.visible
        }
    }
}
