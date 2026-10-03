import QtQuick
import QtQuick.Controls
import Silicium.Preferences
import Silicium.Theme

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

    // Whether to show a progress bar after hibernating, before going away
    property bool showHibernationProgress: false

    /* The window refuses the first close and goes away only once the machine
     * has been put away (see ShutDownManager).
     */
    ShutDownManager {

        id: shutDownManager
        controller: root.controllerRef
        showProgress: root.showHibernationProgress
    }

    onClosing: function(closeEvent) { shutDownManager.windowClosing(closeEvent) }

    // Goes away right now, without pausing, asking or hibernating
    function byebye() {

        shutDownManager.byebye()
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

    Connections {

        target: root.controllerRef

        // Worth saying, not worth interrupting for -- e.g. that a hard drive
        // just created is too large to travel in a snapshot.
        function onShowNotification(title, message) {

            root.showNotification(title, message)
        }
    }

    //
    // Errors
    //

    SiUserDialog {

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
}
