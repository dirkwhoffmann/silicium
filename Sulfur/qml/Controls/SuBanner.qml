// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Effects
import Sulfur

/* A pill-shaped banner that floats over the machine, like the "Press Esc to
 * exit" banner browsers show.
 *
 * show() puts a message on it, which takes itself away again after a while.
 * A message shown while another is still up replaces it.
 */
Item {

    id: root

    // Where the pill sits within the banner
    property int alignment: Qt.AlignVCenter

    // How long it takes to fade in and out
    property int fadeTime: 1000

    // How long a message stays when show() is not told, in milliseconds
    property int duration: 3000

    // What the banner is showing at the moment. Set it through show().
    readonly property alias text: label.text

    // Whether there is anything to see
    readonly property bool showing: timer.running

    function show(message, time) {

        label.text = message
        timer.interval = time === undefined ? root.duration : time
        timer.restart()
    }

    function hide() { timer.stop() }

    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {

        NumberAnimation {
            duration: root.fadeTime
            easing.type: Easing.InOutQuad
        }
    }

    Timer { id: timer }

    Rectangle {

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: root.alignment === Qt.AlignVCenter ? parent.verticalCenter : undefined
        anchors.bottom: root.alignment === Qt.AlignBottom ? parent.bottom : undefined
        anchors.bottomMargin: Style.largeSpacing * 2

        width: label.implicitWidth + 2 * Style.largeSpacing
        height: label.implicitHeight + 2 * Style.largeSpacing
        radius: height / 2

        color: Palette.overlay
        border.color: Palette.overlayBorder

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }

        SuLabel {

            id: label
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: Style.huge
            font.bold: true
        }
    }
}
