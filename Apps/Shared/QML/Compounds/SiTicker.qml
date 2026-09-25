// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Theme

/* A label that shows one short message at a time, in the order they were
 * handed to it.
 *
 * Messages are queued, not overwritten. Something that races through its
 * steps would otherwise flash text far too briefly to read, or skip a step
 * altogether; here every message gets its time before the next one is shown.
 *
 * Each message says how long it is worth:
 *
 *   show(text, minTime, maxTime)
 *
 *   minTime  the next message waits at least this long. 0 means the message
 *            holds nothing back and is replaced as soon as there is
 *            something to replace it with.
 *   maxTime  the message takes itself away after this long, when nothing
 *            else has come along. 0 means it stays until something does --
 *            which is what a running job wants, and a hint does not.
 *
 * An empty text is simply the message that says nothing, which is what makes
 * the ticker go blank. So a hint that shows itself for three seconds is
 *
 *     show("Release mouse by shaking", 500, 3000)
 *
 * and a job reporting what it is doing calls show() per step and hide() at
 * the end. hide() waits its turn like any other message, so the last step of
 * a job that finishes instantly is still readable.
 *
 * A message may also carry a value -- how far along the job is -- for a
 * display with somewhere to put it, such as a progress bar. The ticker
 * itself only shows the text.
 */
SiLabel {

    id: root

    // What a message is worth when show() is not told
    property int minimumTime: 500
    property int maximumTime: 0

    // What the message on screen came with, from 0.0 to 1.0
    readonly property real value: shownValue

    // Whether there is anything to see
    readonly property bool showing: text !== ""

    text: ""


    //
    // Showing and hiding
    //

    /* Puts a message on screen, or in the queue behind one that has not had
     * its time yet.
     *
     * Saying the same thing twice in a row says it once: a job repeating
     * itself is not news. A repeat does update the value, though -- that is
     * how a step that takes a while reports how far along it is, without its
     * text being queued over and over.
     */
    function show(message, minTime, maxTime, value) {

        const entry = {
            text: message,
            min: minTime === undefined ? root.minimumTime : minTime,
            max: maxTime === undefined ? root.maximumTime : maxTime,
            value: value === undefined ? 0.0 : value
        }

        if (queue.length) {

            if (message === queue[queue.length - 1].text) {
                queue[queue.length - 1].value = entry.value
            } else {
                queue.push(entry)
            }
            return
        }

        if (message === text) { shownValue = entry.value; return }

        if (holdTimer.running) queue.push(entry); else display(entry)
    }

    // Blanks the ticker, once everything queued has been shown
    function hide() { show("", 0, 0) }


    //
    // Internals
    //

    // What the message on screen came with, and what is waiting to be shown
    property real shownValue: 0.0
    property var queue: []

    function display(entry) {

        text = entry.text
        shownValue = entry.value

        /* A message with no time of its own holds nothing back, so whatever
         * is queued behind it follows at once.
         */
        if (entry.min > 0) {
            holdTimer.interval = entry.min
            holdTimer.restart()
        } else if (queue.length) {
            display(queue.shift())
            return
        }

        // Past its maximum it goes, whether or not anything follows
        if (entry.max > 0) {
            expiryTimer.interval = Math.max(entry.max, entry.min)
            expiryTimer.restart()
        } else {
            expiryTimer.stop()
        }
    }

    function advance() {

        if (queue.length) { display(queue.shift()); return false }
        return true
    }

    // Guards the time the message on screen was given
    Timer {

        id: holdTimer
        onTriggered: root.advance()
    }

    // Takes a message away that has outstayed its welcome
    Timer {

        id: expiryTimer
        onTriggered: if (root.advance()) root.display({ text: "", min: 0, max: 0, value: 0.0 })
    }
}
