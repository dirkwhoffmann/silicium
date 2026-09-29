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

    // Set once the machine has been put away and the app is on its way out,
    // so the close this window asks for a second time is let through.
    property bool shutdownInProgress: false

    // Whether the Logger overlay is showing, mirroring SiC64Window's own
    // loggerOpen -- RetroShell has its own visibility on SiAmController
    // (amiga.retroShell) since, unlike the Logger, other things also care
    // whether it's open (e.g. a future physical-keyboard passthrough would
    // need to stop routing keys to the emulator while it's up). The two are
    // mutually exclusive -- see the toolbar's RetroShell/Logger buttons.
    property bool loggerOpen: false

    // Compact-menu mode (JetBrains style): the menu bar stays hidden and the
    // toolbar shows a hamburger button instead. SiAmToolbar owns which row is
    // currently revealed; this only says whether the mode is on. SiC64 gets
    // the same binding from VMWindow, which this window does not derive from.
    readonly property bool compactMenu: Preferences.menuStyle === 1

    visible: true
    width: 800
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    // Nothing but the toggle stands in the title bar row once the chrome is
    // hidden, and a name floating over the picture on its own reads as a
    // caption on it rather than as the window's. What the row is filled with
    // goes the same way -- see the rectangle that paints it.
    title: root.toolbarVisible ? "SiAmiga" : ""
    color: "black"

    /* The two ways of arranging the chrome (Preferences.menuType).
     *
     * Attached keeps the picture clear of the chrome: the menu and toolbar
     * have a strip of their own and the picture starts below it. Overlaid
     * lets the picture fill the window and lays the strip over it, in the
     * same place it would otherwise have been.
     *
     * The title bar row is ours either way -- see the flags below -- so this
     * decides only what happens underneath it.
     */
    readonly property bool overlaid: Preferences.menuType === 1

    /* The title bar row belongs to us, always.
     *
     * ExpandedClientAreaHint hands us the whole window frame to draw on
     * (NSWindowStyleMaskFullSizeContentView on macOS) and
     * NoTitleBarBackgroundHint takes the title bar's own backdrop away, so
     * what shows up there is ours to paint -- which is what lets the chrome
     * toggle sit up there whichever way the chrome is arranged. Unlike
     * FramelessWindowHint this keeps the window buttons, the drag region and
     * the name the windowing system writes in the row. Neither flag needs a
     * platform #ifdef: where the window manager cannot honour them they are
     * ignored, and titleBarInset below then reports nothing to work around.
     */
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint

    /* An ApplicationWindow is a Control, and a Control insets its own
     * contentItem by the safe area. Dropping the padding hands the whole
     * window to contentItem and leaves the figure itself readable below, so
     * each item decides for itself whether to honour it -- the picture does
     * not, the toolbar does.
     */
    topPadding: 0

    // The row the title bar would have been, which is now ours to draw in.
    // Nothing at all on a platform that would not hand it over.
    readonly property real titleBarInset: contentItem.SafeArea.margins.top


    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    SiAmCanvas {

        id: canvas

        // Overlaid, it runs the full height of the window, title bar row and
        // all. Attached, it starts below the strip -- which is itself below
        // the title bar row -- so that no part of it is ever covered.
        anchors.fill: parent
        anchors.topMargin: root.overlaid ? 0 : toolbar.y + toolbar.height

        controller: root.amiga
    }

    /* Paints the chrome behind the strip, where the picture does not reach.
     *
     * Only in the attached arrangement is there any: the strip is inset from
     * the edges it was given, and the picture starts below all of it, so the
     * gap around the strip would otherwise show the window's own black.
     * Filling it with what the strip is filled with makes the strip and its
     * surround read as one band of chrome. Overlaid there is nothing to
     * paint -- the picture runs on underneath and around the strip, which is
     * what makes it look laid on top.
     *
     * With the chrome hidden there is likewise nothing to surround. It has
     * to go rather than merely be covered: it starts at the top of the
     * window, so anything left of it would show through the title bar row
     * the moment that row goes transparent.
     */
    Rectangle {

        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.overlaid || !root.toolbarVisible ? 0
                                                      : toolbar.y + toolbar.height
        z: 4

        color: toolbar.fill
    }

    /* Paints the title bar row.
     *
     * The windowing system has stopped putting a backdrop up there (see the
     * flags above), so the row would otherwise show whatever is behind it.
     * What goes in it is the user's choice -- see titleBarFill in
     * SiToolbarWrapper, which owns both the colours it picks between.
     *
     * It is drawn after the band above, and so over it, because in the
     * attached arrangement the two overlap: the band starts at the top of
     * the window and this decides what that first stretch of it looks like.
     * On a platform that kept its title bar to itself the inset is nothing
     * and this paints nothing.
     *
     * With the chrome hidden it paints nothing either. There is no strip for
     * the row to belong to, so a band of toolbar colour across the top would
     * be chrome standing on its own; clearing it hands the row back to
     * whatever is behind -- the picture, overlaid, and the window's own
     * black when attached.
     */
    Rectangle {

        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.titleBarInset
        z: 4

        color: root.toolbarVisible ? toolbar.titleBarFill : "transparent"
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
     */
    MouseArea {

        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.titleBarInset
        z: 5

        onPressed: root.startSystemMove()
    }

    // Hides and shows the menu and toolbar
    SiSymbolButton {

        id: chromeToggle

        anchors.right: parent.right
        anchors.rightMargin: Style.mediumSpacing
        y: (root.titleBarInset - height) / 2
        z: 20
        phosphor: "list"
        color: "white" // "#888888"
        background: Rectangle { color: "#20000000"; radius: height / 2 }

        onClicked: root.toolbarVisible = !root.toolbarVisible
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
        anchors.topMargin: root.titleBarInset
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10

        toolbarVisible: root.toolbarVisible
        compactMenu: root.compactMenu
        
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

    footer: SiAmStatusbar {

        id: statusbar
        amiga: root.amiga

        visible: root.statusBarVisible
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
