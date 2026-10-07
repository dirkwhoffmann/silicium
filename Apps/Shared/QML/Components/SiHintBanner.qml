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
import Sulfur

/* A small pill-shaped banner used to briefly tell the user how to recover
 * something they just hid -- e.g. how to get the mouse back after it was
 * captured, or (see SiC64Window) how to bring back a hidden toolbar. Similar to
 * the "Press Esc to exit" banner browsers show.
 *
 * The banner fills its parent and floats above its siblings. Call showHint()
 * for hints of your own. The one about releasing the mouse is built in: it is
 * shown whenever the mouse gets captured, and mentions the release methods
 * enabled in the Controls preferences (none enabled, no hint).
 */
SuBanner {

    id: root

    anchors.fill: parent
    z: 2

    // Shows the banner with the given message for a few seconds
    function showHint(message) {

        // Gone again three seconds later without being told
        show(message, 3000)
    }

    Connections {

        target: AppController.inputManager

        function onCaptureMouseChanged() {

            // Only the capturing is of interest here, not the release
            if (!AppController.inputManager.captureMouse) return

            const key = Shortcuts.nativeText(Preferences.mouseHotkey)
            const byPressing = Preferences.releaseMouseByPressing
            const byShaking = Preferences.releaseMouseByShaking

            if (byPressing && byShaking) {
                root.showHint(qsTr("Release mouse by pressing %1 or shaking").arg(key))
            } else if (byPressing) {
                root.showHint(qsTr("Release mouse by pressing %1").arg(key))
            } else if (byShaking) {
                root.showHint(qsTr("Release mouse by shaking"))
            }
            // else: no release method configured -- nothing useful to show.
        }
    }
}
