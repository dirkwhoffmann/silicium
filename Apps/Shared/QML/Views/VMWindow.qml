import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ApplicationWindow {

    id: root

    required property C64Controller vmc

    property string uuid: ""
    property bool lostFocusWhileRunning : false

    readonly property int centerX: width / 2
    readonly property int centerY: height / 2

    property int notificationMaxHeight: 400
    property int notificationMaxWidth: 300

    readonly property SiUserDialog errorDialog: errorDialog

    title: vmc.name + (Preferences.developerMode ? " - " + vmc.uuid : "")
    visible: true
    width: 900
    height: 600
    minimumWidth: 400
    minimumHeight: 300

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme


    //
    // Lifetime
    //

    Component.onCompleted: {

        if (vmc.readOnly) {

            notifications.show(
                "Read-only Virtual Machine",
                "This preconfigured virtual machine is a temporary showcase designed to demonstrate the " +
                "emulator's capabilities. Any changes you make will be lost when the emulator shuts down.\n" +
                "To save your progress, you can clone this instance in the Central Hub to convert it into a " +
                "regular virtual machine.")
        }
    }


    //
    // Notifications
    //

    signal showNotification(title: string, message: string)

    Connections {

        target: root

        function onShowNotification(title, message) {

            notifications.show(title, message)
        }
    }

    NotificationCenter {

        id: notifications
        maxWidth: notificationMaxWidth // root.width - 2 * Style.largeSpacing
        maxHeight: notificationMaxHeight // root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    SiUserDialog {

        id: errorDialog
        sound: true
    }

    //
    // Focus
    //

    onActiveChanged: {

        if (active) {

            if (Preferences.pauseWhileInBackground) {
                if (lostFocusWhileRunning) vmc.run()
            }

        } else {

            lostFocusWhileRunning = vmc.isRunning
            if (Preferences.pauseWhileInBackground) {
                vmc.pause()
            }
        }
    }

    //
    // Closing
    //

    ShutDownManager {

        id: shutDownManager
        controller: root.vmc
        showProgress: true
    }

    onClosing: function(closeEvent) { shutDownManager.windowClosing(closeEvent) }

    // For the windows built on this one (see SiC64Window)
    function byebye() {

        shutDownManager.byebye()
    }

    //
    // Toolbar
    //

    // Whether the toolbar (header) is currently shown. Exposed so a window's
    // View menu can offer a "Toolbar" visibility toggle.
    property bool toolbarVisible: true

    // Compact-menu mode (JetBrains style): the menu bar stays hidden and the
    // toolbar shows a hamburger button instead. Clicking it swaps the toolbar
    // row for the menu bar; the menu bar's close button swaps back. Which row
    // is currently revealed is a presentation detail owned by the concrete
    // header component (e.g. SiC64Toolbar), not by this window.
    readonly property bool compactMenu: Preferences.chromeLayout === 1

    // No default header here -- each concrete window supplies its own,
    // combining its app-specific menu with its own window actions (see
    // SiC64Window's SiC64Toolbar and SiC64Actions).

    //
    // Pause overlay
    //

    SiOverlayButton {

        id: playButton
        anchors.fill: parent
        visible: opacity > 0.01
        size: 220
        symbol: "play_circle"
        opacity: vmc.isPaused ? 1.0 : 0.0
        z: 1

        onClicked: {

            vmc.run()
        }

        Behavior on opacity {

            NumberAnimation {
                duration: 350
                easing.type: Easing.Linear
            }
        }
    }

    //
    // Hint banner
    //
    //
    // A small pill-shaped banner used to briefly tell the user how to
    // recover something they just hid -- e.g. the mouse capture hint below,
    // or (see SiC64Window) a hint for bringing back a hidden toolbar.
    // Similar to the "Press Esc to exit" banner browsers show.

    // Shows the banner with the given message for a few seconds. Concrete
    // windows (e.g. SiC64Window) call this directly for their own hints.
    function showHint(message) {

        // Readable, and gone again three seconds later without being told
        hintBanner.show(message, 500, 3000)
    }

    // When the mouse is captured, briefly tell the user how to get it back.
    // Which release methods are mentioned depends on the Controls
    // preferences; if none are enabled, no hint is shown.

    Connections {

        target: AppController.inputManager

        function onCaptureMouseChanged() {

            // Only the capturing is of interest here, not the release
            if (!AppController.inputManager.captureMouse) return

            const key = Shortcuts.nativeText(Preferences.mouseHotkey)
            const byPressing = Preferences.releaseMouseByPressing
            const byShaking = Preferences.releaseMouseByShaking

            if (byPressing && byShaking) {
                showHint(qsTr("Release mouse by pressing %1 or shaking").arg(key))
            } else if (byPressing) {
                showHint(qsTr("Release mouse by pressing %1").arg(key))
            } else if (byShaking) {
                showHint(qsTr("Release mouse by shaking"))
            }
            // else: no release method configured -- nothing useful to show.
        }
    }

    SiBanner {

        id: hintBanner

        anchors.fill: parent
        z: 2
    }

    /* What the machine is busy with, for as long as it is busy (see
     * Controller::runTask). Unlike a hint, this one is not on a timer: the
     * job says when it is over by reporting an empty text.
     */
    SiBanner {

        id: progressBanner

        anchors.fill: parent
        z: 2
        alignment: Qt.AlignBottom

        Connections {

            target: vmc

            // The end of the job comes through as an empty text, which the
            // banner already understands as "nothing to say".
            function onShowProgress(what, percentage) {

                progressBanner.show(what, undefined, undefined, percentage)
            }
        }
    }
}