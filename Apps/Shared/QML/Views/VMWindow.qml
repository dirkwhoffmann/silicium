import QtQuick
import QtQuick.Controls
import Silicium.Preferences

/* The common base of the emulator windows (SiC64Window and SiAmWindow).
 */
ApplicationWindow {

    id: root

    /* The height of the title bar row: the part of the window at the top that
     * the system reserves for its buttons (the window has an expanded client
     * area, see its flags). The chrome draws its own title bar of that height.
     */
    readonly property real titleBarInset: contentItem.SafeArea.margins.top

    // The window's chrome (set by the concrete window)
    property SiChrome chromeRef: null

    // The machine of the window (set by the concrete window). Needs isRunning,
    // run() and pause().
    property var controllerRef: null

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
}
