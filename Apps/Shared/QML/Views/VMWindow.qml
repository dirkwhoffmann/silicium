import QtQuick
import QtQuick.Controls

/* The common base of the emulator windows (SiC64Window and SiAmWindow).
 *
 * What the windows have in common is meant to move here step by step. For now
 * it is the fullscreen logic.
 */
ApplicationWindow {

    id: root

    /* The window's chrome, set by the concrete window. The chrome is hidden
     * while the window is in fullscreen mode. (Named apart from the id it
     * usually points at: a property whose name is the id it targets resolves
     * to undefined.)
     */
    property SiChrome chromeRef: null

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
}
