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
 * Two ways to use it, depending on who decides when it goes away:
 *
 *   reveal(text)  shows it for 'timeout' milliseconds and hides it again.
 *                 That fits a hint -- something the user is told once.
 *   text = "..."  shows it until the text is set back to "". That fits a
 *                 running job, which is over when it says it is over.
 *
 * The banner fills its parent and shows nothing where it has no text, so it
 * can be laid over the canvas and left there.
 */
Item {

    id: root

    // What the banner says. Empty means it is not shown.
    property string text: ""

    // How long reveal() leaves it up, in milliseconds
    property int timeout: 3000

    // Where the pill sits within the banner
    property int alignment: Qt.AlignVCenter

    opacity: root.text === "" ? 0.0 : 1.0
    visible: opacity > 0.01

    // Shows the given text and takes it away again after 'timeout'
    function reveal(message) {

        root.text = message
        hideTimer.restart()
    }

    Behavior on opacity {

        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    Timer {

        id: hideTimer
        interval: root.timeout
        onTriggered: root.text = ""
    }

    Rectangle {

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: root.alignment === Qt.AlignVCenter ? parent.verticalCenter : undefined
        anchors.bottom: root.alignment === Qt.AlignBottom ? parent.bottom : undefined
        anchors.bottomMargin: Style.largeSpacing * 2

        width: label.implicitWidth + 2 * Style.largeSpacing
        height: label.implicitHeight + 2 * Style.largeSpacing
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

        SiText {

            id: label
            anchors.centerIn: parent
            text: root.text
            color: "white"
            font.pixelSize: Style.huge
            font.bold: true
        }
    }
}
