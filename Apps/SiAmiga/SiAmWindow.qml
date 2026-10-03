import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ApplicationWindow {

    id: root

    property SiAmController amiga: SiAmController
    readonly property SiAmInfoController info: amiga.info

    readonly property real titleBarInset: contentItem.SafeArea.margins.top

    property alias actions: siActions

    property bool showCommandBar: true
    property bool showStatusBar: true
    property bool shutdownInProgress: false
    property bool loggerOpen: false

    readonly property bool overlayed: Preferences.chromePlacement === 1
    readonly property bool unified: Preferences.chromeTitleBar === 1
    readonly property bool compact: Preferences.chromeLayout === 1

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    topPadding: 0

    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    title: ""
    color: "black"

    //
    // Main area
    //

    SiChrome {

        id: chrome

        anchors.fill: parent
        z: 10

        overlayed: root.overlayed
        unified: root.unified
        compact: root.compact
        showCommandBar: root.showCommandBar
        showStatusBar: root.showStatusBar

        titleBarInset: root.titleBarInset
        titleText: "SiAmiga"

        titleBarContent: [

            SiSymbolButton {

                id: chromeToggle

                symbol: "page_header"
                color: Palette.secondary
                background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

                onClicked: root.showCommandBar = !root.showCommandBar
            },

            SiSymbolButton {

                id: statusBarToggle

                symbol: "page_footer"
                color: Palette.secondary
                background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

                onClicked: root.showStatusBar = !root.showStatusBar
            }
        ]

        menuContent: SiAmMenu {

            anchors.fill: parent

            amiga: root.amiga
            window: root

            onOpenAbout: aboutWindow.show()

            // Lets the View menu's checkable items show the right state; the
            // window owns the visibility and answers the signals below.
            toolbarVisible: root.showCommandBar
            statusBarVisible: root.showStatusBar

            onToggleToolbar: root.showCommandBar = !root.showCommandBar
            onToggleStatusBar: root.showStatusBar = !root.showStatusBar
        }

        toolbarContent: SiAmToolbar {

            anchors.fill: parent

            amiga: root.amiga
            window: root
        }

        statusBarContent: SiAmStatusbar {

            anchors.fill: parent

            amiga: root.amiga
            // The background is drawn by the chrome
            color: "transparent"
        }
    }

    SiAmCanvas {

        id: canvas

        anchors.fill: parent
        anchors.topMargin: chrome.canvasStart
        anchors.bottomMargin: parent.height - chrome.canvasEnd
    }

    MouseArea {

        anchors.fill: canvas
        hoverEnabled: true
        preventStealing: true

        onPressed: {

            if (Preferences.retainMouseByClicking && !canvasOverlay.visible) {
                root.amiga.captureMouse()
            }
        }

        onDoubleClicked: {

            if (Preferences.retainMouseByDoubleClicking && !canvasOverlay.visible) {
                root.amiga.captureMouse()
            }
        }
    }

    //
    // Drop area
    //

    SiAmDropOverlay {

        anchors.fill: canvas
        controller: root.amiga
        window: root
    }

    //
    // RetroShell / Logger
    //

    SiAmCanvasOverlay {

        id: canvasOverlay

        anchors.fill: parent
        anchors.topMargin: chrome.overlayStart
        anchors.bottomMargin: parent.height - chrome.overlayEnd

        amiga: root.amiga
        loggerOpen: root.loggerOpen
    }

    //
    // Auxiliary components
    //

    SiAmDevPanel {

        x: 20
        // Unlike SiC64Window's canvas (which starts below the toolbar
        // unless auto-hide is on), SiAmToolbar always floats above the
        // canvas at z: 10 -- see its own header comment. Anchoring under it
        // here, rather than reusing SiC64DevPanel's fixed y: 20, keeps this
        // panel from starting out hidden under that opaque toolbar.
        y: chrome.chromeHeight + Style.mediumSpacing
        visible: root.amiga.debugPanel && Preferences.developerMode
    }

    NotificationCenter {

        id: notifications
        maxWidth: root.width - 2 * Style.largeSpacing
        maxHeight: root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    SiBanner {

        id: hintBanner

        anchors.fill: parent
        z: 2
    }

    // Shows the banner with the given message for a few seconds, as VMWindow
    // does for SiC64.
    function showHint(message) {

        // Readable, and gone again three seconds later without being told
        hintBanner.show(message, 500, 3000)
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

    //
    // Connections
    //

    Connections {

        target: root.amiga

        function onShutdown() {

            root.shutdownInProgress = true
            Qt.quit()
        }

        // What the controller reports when an action of ours fails, e.g.
        // loading a snapshot from a machine that has none.
        function onShowError(title, text) {

            root.showError(title, text)
        }

        // Worth saying, not worth interrupting for -- e.g. that a hard drive
        // just created is too large to travel in a snapshot. VMWindow does
        // the same for SiC64.
        function onShowNotification(title, message) {

            notifications.show(title, message)
        }
    }

    //
    // Auxiliary windows
    //

    SiAmDiskCreator {

        id: diskCreatorDialog
        amiga: root.amiga
    }

    SiAmHardDiskCreator {

        id: hardDiskCreatorDialog
        amiga: root.amiga
    }

    SiAmConfigWindow {

        id: configWindow
        controller: root.amiga
    }

    SiAmKeyboardWindow {

        id: keyboardWindow
        controller: root.amiga
    }

    SiAmCPUPanel {

        id: cpuInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmLogicAnalyzerPanel {

        id: logicAnalyzerWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmXRayPanel {

        id: xrayScannerWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmCIAPanel {

        id: ciaInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmMemoryPanel {

        id: memoryInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmAgnusPanel {

        id: agnusInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmCopperPanel {

        id: copperInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmBlitterPanel {

        id: blitterInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmPaulaPanel {

        id: paulaInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmDenisePanel {

        id: deniseInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmPortPanel {

        id: portInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmEventsPanel {

        id: eventsInspectorWindow
        controller: root.amiga
        actions: root.actions
    }

    SiAmAbout {

        id: aboutWindow
        visible: false
    }

    //
    // Actions
    //

    SiAmActions {

        id: siActions
        hostWindow: root
        amiga: root.amiga
        configWindowRef: configWindow
        keyboardWindowRef: keyboardWindow
        cpuInspectorRef: cpuInspectorWindow
        logicAnalyzerRef: logicAnalyzerWindow
        xrayScannerRef: xrayScannerWindow
        ciaInspectorRef: ciaInspectorWindow
        memoryInspectorRef: memoryInspectorWindow
        agnusInspectorRef: agnusInspectorWindow
        copperInspectorRef: copperInspectorWindow
        blitterInspectorRef: blitterInspectorWindow
        paulaInspectorRef: paulaInspectorWindow
        deniseInspectorRef: deniseInspectorWindow
        portInspectorRef: portInspectorWindow
        eventsInspectorRef: eventsInspectorWindow
        hardDiskCreatorRef: hardDiskCreatorDialog
        userDialogRef: errorDialog
    }

    //
    // Errors
    //

    function showError(title, text) {

        errorDialog.titleText = title
        errorDialog.bodyText = text
        errorDialog.buttons = Dialog.Ok
        errorDialog.okLabel = qsTr("OK")
        errorDialog.acceptedCallback = null
        errorDialog.open()
    }

    SiUserDialog {

        id: errorDialog
        sound: true
    }

    //
    // Media files
    //

    function proceedWithUnsavedFloppyDisk(driveNr, proceed) {

        if (Preferences.ejectWithoutAsking || !amiga.media.driveModified(driveNr)) {
            proceed()
            return
        }

        errorDialog.titleText = qsTr("Drive df%1 contains an unsaved disk.").arg(driveNr)
        errorDialog.bodyText = qsTr("Your changes will be lost if you proceed.")
        errorDialog.buttons = Dialog.Cancel | Dialog.Ok
        errorDialog.okLabel = qsTr("Proceed")
        errorDialog.acceptedCallback = proceed
        errorDialog.open()
    }

    function newDiskAction(driveNr) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            diskCreatorDialog.driveNr = driveNr
            diskCreatorDialog.open()
        })
    }

    //
    // Closing
    //

    /* Closing sequence, mirroring SiC64's (see VMWindow.qml):
     *
     *    1. Pause the emulator
     *    2. Optional: ask what to save
     *    3. hibernate()
     *    4. byebye()
     *
     * The window refuses the first close and goes away only once the machine
     * has been put away, because everything from here on is asynchronous:
     * a dialog is waiting for an answer, and a window that closed underneath
     * it would take the answer -- and the machine -- with it.
     */
    onClosing: function(closeEvent) {

        if (shutdownInProgress) return

        closeEvent.accepted = false
        amiga.pause()

        if (amiga.readOnly) {
            byebye()
        } else if (Preferences.showHibernationDialog) {
            hibernationDialog.open()
        } else {
            hibernate(Preferences.hibernateSnapshot, Preferences.hibernateWorkspace)
        }
    }

    SiHibernationDialog {

        id: hibernationDialog
        onConfirmed: (snapshot, workspace) => root.hibernate(snapshot, workspace)
    }

    function hibernate(snapshot, workspace) {

        if (snapshot || workspace) amiga.hibernate(snapshot, workspace)
        byebye()
    }

    function byebye() {

        // Tells the controller to wind down, which comes back as onShutdown
        amiga.shutdown()
    }
}
