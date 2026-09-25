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
import Silicium.Theme

/* A modal dialog with a progress bar, showing what a job is doing.
 *
 * What to show and for how long is the ticker's part (see SiTicker, whose
 * show() and hide() this passes on); this is what it looks like -- the
 * message goes above the bar, and the value a message was shown with drives
 * the bar itself. SiBanner is the quieter alternative.
 *
 * The dialog comes up with the first message and closes itself when the
 * ticker runs dry, so a caller only ever calls show().
 */
Item {

    id: root

    // The dialog itself, for a caller that wants to place or size it
    property alias dialog: progressDialog

    // What a message is worth when show() is not told (see SiTicker)
    property alias minimumTime: ticker.minimumTime
    property alias maximumTime: ticker.maximumTime

    readonly property alias text: ticker.text

    function show(message, minTime, maxTime, value) {

        ticker.show(message, minTime, maxTime, value)
    }

    function hide() { ticker.hide() }

    /* The ticker is the message source, not the display: what is on screen
     * is the dialog's own label, which follows it. Nothing draws it, so it
     * is kept out of the way rather than laid out.
     */
    SiTicker {

        id: ticker
        visible: false

        /* Asking the text itself, not 'showing': a handler for a property
         * runs before the bindings that read that property are
         * re-evaluated, so 'showing' here is still the answer for the
         * previous text -- which opens the dialog when the job ends and
         * closes it when one starts.
         */
        onTextChanged: ticker.text === "" ? progressDialog.close() : progressDialog.open()
    }

    SiProgressDialog {

        id: progressDialog

        text: ticker.text
        progress: ticker.value

        // A job is not something to dismiss: it ends when it ends.
        buttons: Dialog.NoButton
        closePolicy: Popup.NoAutoClose
    }
}
