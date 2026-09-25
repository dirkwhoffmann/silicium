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
import Silicium.Theme

/* A pill-shaped banner that floats over the machine, like the "Press Esc to
 * exit" banner browsers show.
 *
 * What to show and for how long is the ticker's part (see SiTicker, whose
 * show() and hide() this passes on); this is what it looks like. SiAmiga
 * shows the same messages in its status bar ticker instead.
 */
Item {

    id: root

    // Where the pill sits within the banner
    property int alignment: Qt.AlignVCenter

    // How long it takes to fade in and out
    property int fadeTime: 1000

    // What a message is worth when show() is not told (see SiTicker)
    property alias minimumTime: ticker.minimumTime
    property alias maximumTime: ticker.maximumTime

    // What the banner is showing at the moment. Set it through show().
    readonly property alias text: ticker.text

    function show(message, minTime, maxTime) { ticker.show(message, minTime, maxTime) }
    function hide() { ticker.hide() }

    opacity: ticker.showing ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {

        NumberAnimation {
            duration: root.fadeTime
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: root.alignment === Qt.AlignVCenter ? parent.verticalCenter : undefined
        anchors.bottom: root.alignment === Qt.AlignBottom ? parent.bottom : undefined
        anchors.bottomMargin: Style.largeSpacing * 2

        width: ticker.implicitWidth + 2 * Style.largeSpacing
        height: ticker.implicitHeight + 2 * Style.largeSpacing
        radius: height / 2

        color: "#A0000000"
        border.color: "#50ffffff"

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }

        SiTicker {

            id: ticker
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: Style.huge
            font.bold: true
        }
    }
}
