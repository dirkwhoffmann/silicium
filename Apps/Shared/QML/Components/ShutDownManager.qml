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
import Silicium.Preferences

/* Manages the closing sequence of a window that hosts a virtual machine.
 *
 *    1. Pause the machine
 *    2. Optional: ask what to save (hibernation dialog)
 *    3. hibernate()
 *    4. Optional: show a progress bar (showProgress)
 *    5. byebye()
 *
 * The window refuses the first close and goes away only once the machine has
 * been put away, because everything from here on is asynchronous: a dialog is
 * waiting for an answer, and a window that closed underneath it would take the
 * answer -- and the machine -- with it. To use it, forward the window's
 * closing signal:
 *
 *     ShutDownManager { id: shutDownManager; controller: root.machine }
 *     onClosing: (closeEvent) => shutDownManager.windowClosing(closeEvent)
 */
Item {

    id: root

    /* The machine to put away. Needs a readOnly property and the methods
     * pause(), hibernate(snapshot, workspace) and shutdown().
     */
    required property var controller

    // Whether to show a progress bar after hibernating, before going away
    property bool showProgress: false

    // True once the controller reported that it has wound down
    property bool shutdownInProgress: false

    // Call this from the window's closing handler
    function windowClosing(closeEvent) {

        if (shutdownInProgress) return

        // Prevent the window from closing immediately
        closeEvent.accepted = false

        controller.pause()

        if (controller.readOnly) {
            byebye()
        } else if (Preferences.showHibernationDialog) {
            hibernationDialog.open()
        } else {
            hibernate(Preferences.hibernateSnapshot, Preferences.hibernateWorkspace)
        }
    }

    function hibernate(snapshot, workspace) {

        if (snapshot || workspace) {

            controller.hibernate(snapshot, workspace)

            if (showProgress) {
                progressDialog.open()
                return
            }
        }

        byebye()
    }

    // Tells the controller to wind down, which comes back as onShutdown
    function byebye() {

        controller.shutdown()
    }

    Connections {

        target: root.controller

        function onShutdown() {

            root.shutdownInProgress = true
            Qt.quit()
        }
    }

    // The dialogs center themselves on their parent, which must therefore be
    // the window and not this (empty) item
    SiHibernationDialog {

        id: hibernationDialog
        parent: Overlay.overlay

        onConfirmed: (snapshot, workspace) => root.hibernate(snapshot, workspace)
    }

    SiProgressDialog {

        id: progressDialog
        parent: Overlay.overlay
        text: qsTr("Hibernating virtual machine...")

        onVisibleChanged: {

            if (visible) {
                progressDialog.progress = 0.0
                fakeAnim.start()
            } else {
                fakeAnim.stop()
            }
        }

        NumberAnimation {

            id: fakeAnim
            target: progressDialog
            property: "progress"
            from: 0.0
            to: 1.0
            duration: 1200.0
            easing.type: Easing.Linear

            onFinished: root.byebye()
        }
    }
}
