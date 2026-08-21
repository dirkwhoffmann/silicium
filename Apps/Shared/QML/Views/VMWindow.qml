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
    property bool shutdownInProgress: false

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
    // Dialogs
    //

    SiUserDialog {

        id: hibernationDialog
        titleText: "Hibernate"
        badgeSource: Assets.iconUrl(Assets.Help)
        bodyText: "The virtual machine is about to hibernate. Would you like to save your current changes?"

        SiCheckBoxControl {
            id: snapshotBox
            r: "Save machine state as a snapshot"
            checked: Preferences.hibernateSnapshot
        }

        SiCheckBoxControl {
            id: workspaceBox
            r: "Save current workspace"
            checked: Preferences.hibernateWorkspace
        }

        buttons: Dialog.Cancel | Dialog.Ok
        okLabel: snapshotBox.checked || workspaceBox.checked ? "Save" : "Quit"
        onAccepted: hibernate(snapshotBox.checked, workspaceBox.checked)
    }

    SiProgressDialog {

        id: hibernationProgressDialog
        text: "Hibernating virtual machine..."

        onVisibleChanged: {

            if (visible) {
                hibernationProgressDialog.progress = 0.0;
                fakeAnim.start();
            } else {
                fakeAnim.stop();
            }
        }

        NumberAnimation {

            id: fakeAnim
            target: hibernationProgressDialog
            property: "progress"
            from: 0.0
            to: 1.0
            duration: 1200.0
            easing.type: Easing.Linear

            onFinished: byebye();
        }
    }

    //
    // Closing
    //

    // Closing sequence...
    //
    //    1. Pause emulator
    //    2. Optional: Show hibernation dialog
    //    3. hibernate()
    //    4. Optional: Show hibernation progress bar
    //    5. byebye()

    onClosing: function(closeEvent) {

        console.log("onClosing: ", closeEvent, vmc.readOnly)

        if (!shutdownInProgress) {

            // Prevent the window from closing immediately
            closeEvent.accepted = false;

            vmc.pause()

            if (vmc.readOnly) {
                byebye()
            } else if (Preferences.showHibernationDialog) {
                hibernationDialog.open()
            } else {
                hibernate(Preferences.hibernateSnapshot, Preferences.hibernateWorkspace)
            }
        }
    }

    function hibernate(hibernateSnapshot, hibernateWorkspace) {

        if (hibernateSnapshot || hibernateWorkspace) {

            vmc.hibernate(hibernateSnapshot, hibernateWorkspace);
            hibernationProgressDialog.open()
            return
        }

        byebye()
    }

    function byebye() {

        console.log("Bye bye")
        vmc.shutdown()

        // HubController.closeWindow(uuid);
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
    readonly property bool compactMenu: Preferences.menuStyle === 1

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
        hintBanner.reveal(message)
    }

    // When the mouse is captured, briefly tell the user how to get it back.
    // Which release methods are mentioned depends on the Controls
    // preferences; if none are enabled, no hint is shown.

    Connections {

        target: vmc

        function onMouseWasCaptured() {

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

        function onShutdown() {

            shutdownInProgress = true
            Qt.quit()
        }
    }

    Item {

        id: hintBanner

        anchors.fill: parent
        z: 2
        opacity: 0.0
        visible: opacity > 0.01

        property string message: ""

        function reveal(msg) {

            message = msg
            opacity = 1.0
            hideTimer.restart()
        }

        Behavior on opacity {

            NumberAnimation {
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }

        Timer {

            id: hideTimer
            interval: 3000
            onTriggered: hintBanner.opacity = 0.0
        }

        Rectangle {

            anchors.centerIn: parent

            width: hintLabel.implicitWidth + 2 * Style.largeSpacing
            height: hintLabel.implicitHeight + 2 * Style.largeSpacing
            radius: height / 2

            color: "#A0000000"
            border.color: "#50ffffff"

            layer.enabled: true
            layer.effect: MultiEffect {

                shadowEnabled: true
                shadowColor: "#80000000"
                shadowBlur: 0.8
                shadowVerticalOffset: 4
            }

            SiText {

                id: hintLabel
                anchors.centerIn: parent
                text: hintBanner.message
                color: "white"
                font.pixelSize: Style.huge
                font.bold: true
            }
        }
    }
}