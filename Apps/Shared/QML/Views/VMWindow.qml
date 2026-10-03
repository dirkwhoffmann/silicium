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
}
