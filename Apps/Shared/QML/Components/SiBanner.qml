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
 * Everything goes through show(text, minDuration): the text appears for at
 * least minDuration milliseconds, and an empty text is simply the message
 * that says nothing, which is what makes the banner go away. So a hint that
 * shows itself for three seconds is
 *
 *     show("Release mouse by shaking", 3000)
 *     hide()
 *
 * and a job that reports what it is doing calls show() per step and hide()
 * at the end.
 *
 * Messages are queued, not overwritten. A job that races through its steps
 * would otherwise flash text far too briefly to read, or skip a step
 * altogether; here every message gets its time on screen and the next one
 * waits its turn -- including the empty one, so the last message of a job
 * that finishes instantly is still readable.
 *
 * The banner fills its parent and shows nothing while it has nothing to say,
 * so it can be laid over the canvas and left there.
 */
Item {

    id: root

    // How long a message stays up when show() is not told
    property int minimumTime: 500

    // Where the pill sits within the banner
    property int alignment: Qt.AlignVCenter

    // What the banner is showing at the moment. Set it through show().
    readonly property string text: shown

    opacity: shown === "" ? 0.0 : 1.0
    visible: opacity > 0.01


    //
    // Showing and hiding
    //

    /* Puts a message on screen, or in the queue behind one that has not had
     * its time yet. Saying the same thing twice in a row says it once: a job
     * repeating itself is not news.
     */
    function show(message, minDuration) {

        const time = minDuration === undefined ? root.minimumTime : minDuration
        const last = queue.length ? queue[queue.length - 1].text : shown

        if (message === last) return

        if (holdTimer.running) {
            queue.push({ text: message, time: time })
        } else {
            display({ text: message, time: time })
        }
    }

    // Takes the banner away, once everything queued has been shown
    function hide() { show("", 0) }


    //
    // Internals
    //

    // What is on screen, and what is waiting to be
    property string shown: ""
    property var queue: []

    function display(entry) {

        shown = entry.text

        /* A message with no time of its own holds nothing back, so whatever
         * is queued behind it follows at once.
         */
        if (entry.time > 0) {
            holdTimer.interval = entry.time
            holdTimer.restart()
        } else if (queue.length) {
            display(queue.shift())
        }
    }

    // Guards the time the message on screen was given
    Timer {

        id: holdTimer
        onTriggered: if (root.queue.length) root.display(root.queue.shift())
    }

    Behavior on opacity {

        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
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
            text: root.shown
            color: "white"
            font.pixelSize: Style.huge
            font.bold: true
        }
    }
}
