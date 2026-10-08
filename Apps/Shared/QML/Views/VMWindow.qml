import QtQuick
import QtQuick.Controls
import Silicium.Preferences
import Sulfur

/* The common base of the emulator windows (SiC64Window and SiAmWindow).
 */
ApplicationWindow {

    id: root

    // The window's chrome (set by the concrete window)
    property SiChrome chromeRef: null

    // The machine of the window (set by the concrete window). Needs isRunning,
    // run() and pause().
    property var controllerRef: null

    // The window's actions (set by the concrete window). Needs toolbarShortcut.
    property var actionsRef: null

    //
    // Fullscreen
    //

    property bool wasFullScreen: false

    onVisibilityChanged: function(visibility) {

        const isFullScreen = visibility === Window.FullScreen

        if (chromeRef) {

            if (isFullScreen && !wasFullScreen) {

                // Entering fullscreen: hide the chrome to maximize canvas space
                chromeRef.showCommandBar = false
                chromeRef.showStatusBar = false

            } else if (!isFullScreen && wasFullScreen) {

                // Leaving fullscreen: bring everything back
                chromeRef.showCommandBar = true
                chromeRef.showStatusBar = true
            }
        }

        wasFullScreen = isFullScreen
    }

    //
    // Focus
    //

    // Set while the window is in the background, if the machine was running
    property bool lostFocusWhileRunning: false

    // If the preferences say so, the machine pauses while the window is in the
    // background, and carries on if it was running when the window comes back
    onActiveChanged: {

        if (!controllerRef) return

        if (active) {

            if (Preferences.pauseWhileInBackground) {
                if (lostFocusWhileRunning) controllerRef.run()
            }

        } else {

            lostFocusWhileRunning = controllerRef.isRunning
            if (Preferences.pauseWhileInBackground) {
                controllerRef.pause()
            }
        }
    }

    //
    // Hints
    //

    SiHintBanner {

        id: hintBanner
    }

    function showToolbarHint() {

        Qt.callLater(function () {

            if (!chromeRef.showCommandBar) {
                hintBanner.showHint(qsTr("Recover toolbar by pressing %1")
                    .arg(Shortcuts.nativeText(actionsRef.toolbarShortcut)))
            }
        })
    }

    //
    // Closing
    //

    /* The window refuses the first close and goes away only once the machine
     * has been put away, because everything from here on is asynchronous: a
     * dialog is waiting for an answer, and a window that closed underneath it
     * would take the answer -- and the machine -- with it.
     *
     *    1. Pause the machine
     *    2. Optional: ask what to save (hibernation dialog)
     *    3. hibernate(), which saves in the background and reports its
     *       progress to the status bar, and says when it is done
     *       (onHibernated)
     *    4. byebye()
     *
     * The machine (controllerRef) needs a readOnly property, the methods
     * pause(), hibernate(snapshot, workspace) and shutdown(), and the
     * hibernated and shutdown signals.
     */

    // True once the controller reported that it has wound down
    property bool shutdownInProgress: false

    onClosing: function(closeEvent) {

        if (shutdownInProgress) return

        // Prevent the window from closing immediately
        closeEvent.accepted = false

        controllerRef.pause()

        if (controllerRef.readOnly) {
            byebye()
        } else if (Preferences.showHibernationDialog) {
            hibernationDialog.open()
        } else {
            hibernate(Preferences.hibernateSnapshot, Preferences.hibernateWorkspace)
        }
    }

    function hibernate(snapshot, workspace) {

        // Asynchronous: the machine goes away from onHibernated
        if (snapshot || workspace) {

            controllerRef.hibernate(snapshot, workspace)
            return
        }

        byebye()
    }

    // Goes away right now, without pausing, asking or hibernating
    function byebye() {

        controllerRef.shutdown()
    }

    SiHibernationDialog {

        id: hibernationDialog
        parent: Overlay.overlay

        onConfirmed: (snapshot, workspace) => root.hibernate(snapshot, workspace)
    }

    //
    // Notifications
    //

    NotificationCenter {

        id: notifications
        maxWidth: root.width - 2 * Style.largeSpacing
        maxHeight: root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    // Shows a notification. The machine's own notifications arrive here too.
    function showNotification(title, message) {

        notifications.show(title, message)
    }

    //
    // Errors
    //

    SuUserDialog {

        id: errorDialog
        sound: true
    }

    // The dialog, for the windows that use it for other questions as well.
    // (Named apart from the id: an alias whose name is the id it targets
    // resolves to undefined.)
    property alias userDialog: errorDialog

    // Shows a modal error dialog with a single OK button. Used for errors
    // reported by the machine and for actions that can't be carried out.
    function showError(title, text) {

        errorDialog.titleText = title
        errorDialog.bodyText = text
        errorDialog.buttons = Dialog.Ok
        errorDialog.okLabel = qsTr("OK")

        // Clear any callback left over from a previous use of the dialog --
        // a plain error has no accept action
        errorDialog.acceptedCallback = null
        errorDialog.open()
    }

    //
    // Lifetime
    //

    // A read-only machine is a temporary showcase: say so, once, when the
    // window is up. (The machine is set by the concrete window, whose bindings
    // are in place by now.)
    Component.onCompleted: {

        if (controllerRef && controllerRef.readOnly) {

            showNotification(
                "Read-only Virtual Machine",
                "This preconfigured virtual machine is a temporary showcase designed to demonstrate the " +
                "emulator's capabilities. Any changes you make will be lost when the emulator shuts down.\n" +
                "To save your progress, you can clone this instance in the Central Hub to convert it into a " +
                "regular virtual machine.")
        }
    }

    //
    // Connections
    //

    Connections {

        target: root.controllerRef

        // Worth saying, not worth interrupting for -- e.g. that a hard drive
        // just created is too large to travel in a snapshot.
        function onShowNotification(title, message) {

            root.showNotification(title, message)
        }

        // What the machine reports when an action of ours fails, e.g. loading
        // a snapshot from a machine that has none
        function onShowError(title, text) {

            root.showError(title, text)
        }

        // Fatal error (delegated to the Hub)
        function onShowFatalError(title, text) {

            // Hand the message to the Hub over the RPC link rather than
            // showing it here: a fatal error means this window is in no state
            // to be used, and the Hub outlives it. If we were started
            // standalone there is no Hub listening, so the packet is dropped
            // and the log line below is all that remains.
            console.warn("Fatal error:", title, "-", text)
            root.controllerRef.notifyFatalError(title, text)

            // Then go away. byebye() rather than close(): close() would run
            // the normal shutdown sequence, which pauses and then asks
            // whether to hibernate -- neither a dialog on a dead window nor
            // persisting the state that just failed makes sense here. The
            // notification above is already on the wire (the stdio transport
            // flushes every packet), so quitting cannot lose it.
            root.byebye()
        }

        // Everything is saved: the machine can go
        function onHibernated() {

            root.byebye()
        }

        // The machine has wound down
        function onShutdown() {

            root.shutdownInProgress = true
            Qt.quit()
        }

        // The snapshot storage is full: ask before the oldest snapshot goes
        function onSnapshotLimitReached() {

            userDialog.titleText = qsTr("Snapshot Limit Reached")
            userDialog.bodyText = qsTr("The snapshot storage has reached maximum capacity. If you continue, the oldest snapshot will be deleted.")
            userDialog.buttons = Dialog.Cancel | Dialog.Ok
            userDialog.okLabel = qsTr("OK")
            userDialog.acceptedCallback = function () {

                root.controllerRef.shrinkSnapshotStorage(Preferences.maxSnapshots - 1)
                root.controllerRef.saveSnapshotAsync()
            }
            userDialog.open()
        }
    }
}
