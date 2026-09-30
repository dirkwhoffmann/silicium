import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ApplicationWindow {

    id: root

    property SiAmController amiga: SiAmController
    readonly property SiAmInfoController info: amiga.info

    // Shared with SiAmMenu's "Toolbar" shortcut hint.
    readonly property string toolbarShortcut: "Ctrl+Alt+T"

    property bool toolbarVisible: true
    property bool statusBarVisible: true
    property bool shutdownInProgress: false
    property bool loggerOpen: false
    // readonly property bool compactMenu: Preferences.menuStyle === 1

    readonly property bool overlayed: Preferences.menuType === 1
    readonly property bool unified: Preferences.titleBar === 1
    readonly property bool compact: Preferences.menuStyle === 1

    readonly property real titleBarInset: contentItem.SafeArea.margins.top

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300

    // title: root.toolbarVisible ? "SiAmiga" : ""
    title: toolbar.showTitleBar ? "SiAmiga" : ""
    color: "black"

    // Window flags
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint

    topPadding: 0

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    SiAmCanvas {

        id: canvas

        // Overlaid, it runs the full height of the window: title bar row,
        // strip and status bar all lie over it. Attached, it stops short of
        // each of them -- the strip begins at the top of the window and takes
        // the title bar row in, the status bar sits on the bottom edge -- so
        // that no part of it is ever covered.
        anchors.fill: parent
        anchors.topMargin: root.overlayed ? 0 : toolbar.y + toolbar.height
        anchors.bottomMargin: root.overlayed || !statusbar.visible
                              ? 0 : statusbar.height

        controller: root.amiga
    }

    /* Drags the window by what used to be the title bar.
     *
     * Moving a window by its title bar is something the frame does, and the
     * frame is no longer up there -- the picture is, and a content view
     * keeps the press to itself. So this strip takes the press and hands it
     * straight back to the window manager, which then runs its own drag,
     * snapping and all. It covers exactly the inset the safe area asks for,
     * which is nothing at all on a platform that left the title bar alone.
     *
     * It sits above the picture and below the toggle beside it, so the one
     * thing drawn in this row keeps its clicks and the rest of the row
     * moves the window. The window buttons are the windowing system's own
     * and sit above everything, so they keep theirs too.
     *
     * The strip covers this row as well, and stands above it, but it puts
     * nothing there that takes a press -- a plain rectangle lets one through
     * to whatever is under it -- so the presses still arrive here.
     */
    MouseArea {

        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.titleBarInset
        z: 5

        onPressed: root.startSystemMove()
    }

    // Click-to-capture-the-mouse handler, mirroring SiC64Window's
    // CanvasWrapper-provided MouseArea (see its own header comment). Declared
    // right after the canvas -- and before SiAmDevPanel below -- so it sits
    // underneath any interactive foreground content and doesn't swallow its
    // clicks, while SiAmCanvas itself (a plain Rectangle) accepts no mouse
    // events and lets clicks fall through to here.
    MouseArea {

        anchors.fill: canvas
        hoverEnabled: true
        preventStealing: true

        onPressed: {

            if (Preferences.retainMouseByClicking && !overlayPanel.visible) {
                // Route through the controller (not the InputManager
                // directly) so the capture hint gets shown via
                // mouseWasCaptured().
                root.amiga.captureMouse()
            }
        }

        onDoubleClicked: {

            if (Preferences.retainMouseByDoubleClicking && !overlayPanel.visible) {
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

    SiAmDevPanel {

        controller: root.amiga
        x: 20
        // Unlike SiC64Window's canvas (which starts below the toolbar
        // unless auto-hide is on), SiAmToolbar always floats above the
        // canvas at z: 10 -- see its own header comment. Anchoring under it
        // here, rather than reusing SiC64DevPanel's fixed y: 20, keeps this
        // panel from starting out hidden under that opaque toolbar.
        y: toolbar.y + toolbar.height + Style.mediumSpacing
        visible: root.amiga.debugPanel && Preferences.developerMode
    }

    //
    // Console overlay (RetroShell / Logger)
    //

    Item {

        id: overlayPanel
        anchors.fill: parent
        opacity: (root.amiga.retroShell || root.loggerOpen) ? 0.85 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {

            NumberAnimation {

                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {

            anchors.fill: parent
            color: "#000000"
        }

        StackView {

            id: overlayStack
            anchors.fill: parent

            replaceEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1 }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0 }
            }
        }
    }

    Component {

        id: retroShellComponent
        SiAmRetroShell {
            controller: root.amiga
            blinkingCursor: false
        }
    }

    Component {

        id: loggerComponent
        LogView {
        }
    }

    property Component currentOverlayComponent: null

    function updateOverlayStack() {

        const targetComponent = root.amiga.retroShell ? retroShellComponent
                               : root.loggerOpen ? loggerComponent
                               : null

        if (targetComponent && targetComponent !== currentOverlayComponent) {

            if (currentOverlayComponent) {
                overlayStack.replace(targetComponent)
            } else {
                overlayStack.replace(targetComponent, StackView.Immediate)
            }

            currentOverlayComponent = targetComponent
        }
    }

    onLoggerOpenChanged: updateOverlayStack()

    Connections {

        target: root.amiga

        function onRetroShellChanged() {
            updateOverlayStack()
        }

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

    NotificationCenter {

        id: notifications
        maxWidth: root.width - 2 * Style.largeSpacing
        maxHeight: root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    //
    // Errors
    //

    // Shows a modal error dialog with a single OK button, as SiC64Window
    // does -- without one, everything the controller reports goes nowhere.
    function showError(title, text) {

        errorDialog.titleText = title
        errorDialog.bodyText = text
        errorDialog.buttons = Dialog.Ok
        errorDialog.okLabel = qsTr("OK")
        // The dialog is shared with proceedWithUnsavedFloppyDisk below, whose
        // callback would otherwise still be armed when OK is pressed here.
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

    /* Warns before a modified disk is thrown away.
     *
     * The port of SiC64Window's function of the same name, down to the
     * preference that turns it off -- the core has no undo for an ejected
     * disk, so what has not been exported is gone.
     */
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

    SiAmDiskCreator {

        id: diskCreatorDialog
        amiga: root.amiga
    }

    SiAmHardDiskCreator {

        id: hardDiskCreatorDialog
        amiga: root.amiga
    }

    /* Reached from SiAmActions, where the actions that drive these two live.
     * Named apart from the ids they point at: an alias whose name is the id
     * it targets resolves to undefined.
     */
    property alias hardDiskCreator: hardDiskCreatorDialog
    property alias userDialog: errorDialog

    Component.onCompleted: updateOverlayStack()

    //
    // Actions
    //

    // All window actions live in SiAmActions. SiAmToolbar and SiAmMenu pull
    // this window in directly (as SiAmWindow, not a generic base) to reach
    // them -- mirrors SiC64Window's own actions wiring.
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
    }

    // Single injection point for every window action. Consumers reach
    // individual actions via window.actions.xxx (e.g. window.actions.reset).
    property alias actions: siActions

    // Sits below the title bar row rather than using header:, which would
    // reserve its own layout slot above the content area -- see
    // SiC64Window.qml for the full rationale. That row is the window's own
    // in a standard window and nothing at all in an overlaid one, so the
    // same offset puts this in the same place either way; what changes is
    // only whether the picture runs on underneath it.
    SiToolbarWrapper {

        id: toolbar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10

        overlayed: root.overlayed
        unified: root.unified
        compact: root.compact
        hidden: !root.toolbarVisible

        titleBarInset: root.titleBarInset

        titleBarContent: [

            SiSymbolButton {

                id: chromeToggle

                symbol: "page_header"
                color: Palette.secondary
                background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

                onClicked: root.toolbarVisible = !root.toolbarVisible
            },

            SiSymbolButton {

                id: statusBarToggle

                symbol: "page_footer"
                color: Palette.secondary
                background: Rectangle { color: Qt.alpha(Palette.background, 0.5); radius: height / 2 }

                onClicked: root.statusBarVisible = !root.statusBarVisible
            }
        ]

        menuContent: SiAmMenu {

            anchors.fill: parent

            amiga: root.amiga
            window: root

            onOpenAbout: aboutWindow.show()

            // Lets the View menu's checkable items show the right state; the
            // window owns the visibility and answers the signals below.
            toolbarVisible: root.toolbarVisible
            statusBarVisible: root.statusBarVisible

            onToggleToolbar: root.toolbarVisible = !root.toolbarVisible
            onToggleStatusBar: root.statusBarVisible = !root.statusBarVisible
        }

        toolbarContent: SiAmToolbar {

            anchors.fill: parent

            amiga: root.amiga
            window: root
        }
    }

    /* The status bar, arranged the way the chrome at the top is.
     *
     * Anchored to the bottom edge rather than handed to 'footer:', because a
     * footer reserves a slot of its own below the content area and so can
     * only ever be attached. Sitting in the content area instead lets the
     * same item be either: overlaid, the picture runs on beneath it and it
     * takes the strip's fill, translucent like the strip; attached, the
     * picture stops above it (see the canvas) and it is filled outright.
     *
     * Which of the two is not this bar's decision any more than it was the
     * strip's -- it is the same preference, read once at the top of the file.
     */
    SiAmStatusbar {

        id: statusbar

        visible: root.statusBarVisible
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        z: 10

        amiga: root.amiga
        color: root.overlayed ? Qt.alpha(Palette.toolbar, 0.85) : Palette.toolbar
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
