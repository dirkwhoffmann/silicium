// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

VMWindow {

    id: root

    property C64Controller c64: C64Controller
    property real aspectRatio: 800.0 / 614.0
    property bool statusbarVisible: true
    property bool loggerOpen: false

    // Whether the toolbar is currently shown. Exposed so the View menu can
    // offer a "Toolbar" visibility toggle.
    property bool toolbarVisible: true

    // Compact-menu mode (JetBrains style): the menu bar stays hidden and the
    // toolbar shows a hamburger button instead. Clicking it swaps the toolbar
    // row for the menu bar; the menu bar's close button swaps back. Which row
    // is currently revealed is a presentation detail owned by the toolbar
    // (SiC64Toolbar), not by this window.
    readonly property bool compactMenu: Preferences.chromeLayout === 1

    // Set while the window is in the background, if the machine was running
    property bool lostFocusWhileRunning: false

    title: c64.name + (Preferences.developerMode ? " - " + c64.uuid : "")
    visible: true
    width: 782
    height: 652
    minimumWidth: 400
    minimumHeight: 200

    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    //
    // Fullscreen
    //

    property bool wasFullScreen: false

    onVisibilityChanged: function(visibility) {

        const isFullScreen = visibility === Window.FullScreen

        if (isFullScreen && !wasFullScreen) {

            // Entering fullscreen: hide the chrome to maximize canvas space
            toolbarVisible = false
            statusbarVisible = false

        } else if (!isFullScreen && wasFullScreen) {

            // Leaving fullscreen: bring everything back
            toolbarVisible = true
            statusbarVisible = true
        }

        wasFullScreen = isFullScreen
    }

    // Shared with SiC64Menu's "Toolbar" shortcut, so the item and the hint
    // below can never drift out of sync with each other.
    readonly property string toolbarShortcut: "Ctrl+Alt+T"

    // Hiding the toolbar (the shortcut above, the View menu, or entering
    // fullscreen) leaves no menu behind to bring it back from -- show a
    // hint so the user isn't stuck having to remember the shortcut.
    onToolbarVisibleChanged: {
        if (!toolbarVisible) {
            hintBanner.showHint(qsTr("Recover toolbar by pressing %1").arg(Shortcuts.nativeText(toolbarShortcut)))
        }
    }

    //
    // Main area
    //

    // Floats over the canvas (z above it) instead of using header:, which
    // reserves its own layout slot above the content area. An overlaid menu
    // type (see Preferences.chromePlacement) lets the canvas extend behind it,
    // while a standard one anchors the canvas below it -- the same
    // reserved-space layout header: used to give.
    //
    // SiAmiga additionally drops the window's title bar in the overlay
    // types and offers a toggle beside the window buttons; this window has
    // neither yet, so here the setting reaches the canvas and the
    // toolbar's own fill, and nothing else.
    SiC64Toolbar {

        id: toolbar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10

        c64: root.c64
        onOpenConfigurator: (page) => configWindow.showPage(page)
        onOpenAbout: {
            aboutWindow.show()
            aboutWindow.raise()
            aboutWindow.requestActivate()
        }

        compactMenu: root.compactMenu

        toolbarVisible: root.toolbarVisible
        statusBarVisible: root.statusbarVisible

        onToggleToolbar: root.toolbarVisible = !root.toolbarVisible
        onToggleStatusBar: root.statusbarVisible = !root.statusbarVisible

        window: root
    }

    //
    // Status bar
    //

    footer: SiC64Statusbar {

        id: statusbar
        c64: root.c64

        visible: root.statusbarVisible
    }

    //
    // Main Canvas
    //

    CanvasWrapper {

        id: wrapper
        // Overlaid: extends behind the toolbar, which is laid over it.
        // Standard: starts below the toolbar instead -- no reason to let it
        // hide part of the picture permanently.
        anchors.top: Preferences.chromePlacement === 1 ? parent.top : toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        aspectRatio: root.aspectRatio
        resizeMode: Preferences.resizeMode
        fadeIn: true // root.c64.launchWithWorkspace

        onClicked: {
            console.log("Canvas wrapper clicked")

            if (Preferences.retainMouseByClicking && !overlayPanel.visible) {
                console.log("Capture mouse")
                root.c64.captureMouse()
            }
        }

        onDoubleClicked: {
            if (Preferences.retainMouseByDoubleClicking && !overlayPanel.visible) {
                root.c64.captureMouse()
            }
        }

        SiC64Canvas {

            controller: root.c64
        }

        SiC64DevPanel {

            controller: root.c64
            x: 20
            y: 20
            visible: root.c64.debugPanel && Preferences.developerMode
        }
    }

    //
    // Pause overlay
    //

    SiOverlayButton {

        id: playButton
        anchors.fill: parent
        visible: opacity > 0.01
        size: 220
        symbol: "play_circle"
        opacity: c64.isPaused ? 1.0 : 0.0
        z: 1

        onClicked: {

            c64.run()
        }

        Behavior on opacity {

            NumberAnimation {
                duration: 350
                easing.type: Easing.Linear
            }
        }
    }

    //
    // Drop area
    //

    SiC64DropOverlay {

        id: overlay
        // Anchor to the canvas rather than the whole window, so the drop zones
        // stay clear of the toolbar / menu bar (which otherwise overlap and
        // hide the top row when the canvas starts below the toolbar).
        anchors.fill: wrapper
        z: 1
        controller: c64
        window: root
    }

    //
    // Console overlay (RetroShell / Logger)
    //

    Item {

        id: overlayPanel
        anchors.fill: parent
        opacity: (root.c64.retroShell || root.loggerOpen) ? 0.85 : 0.0
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
        SiC64RetroShell {
            controller: root.c64
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

        const targetComponent = root.c64.retroShell ? retroShellComponent
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

        target: root.c64

        function onRetroShellChanged() {
            updateOverlayStack()
        }
    }

    //
    // Auxiliary components
    //

    NotificationCenter {

        id: notifications
        maxWidth: wrapper.width - 2 * Style.largeSpacing
        maxHeight: wrapper.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    SiHintBanner {

        id: hintBanner
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

            target: c64

            // The end of the job comes through as an empty text, which the
            // banner already understands as "nothing to say".
            function onShowProgress(what, percentage) {

                progressBanner.show(what, undefined, undefined, percentage)
            }
        }
    }

    //
    // Connections
    //

    Connections {

        target: c64

        function onPort0Changed() {
            AppController.inputManager.port0 = port0
        }

        function onPort1Changed() {
            AppController.inputManager.port1 = port1
        }

        function onSnapshotLimitReached() {

            errorDialog.titleText = qsTr("Snapshot Limit Reached")
            errorDialog.bodyText = qsTr("The snapshot storage has reached maximum capacity. If you continue, the oldest snapshot will be deleted.")
            errorDialog.buttons = Dialog.Cancel | Dialog.Ok
            errorDialog.okLabel = qsTr("OK")
            errorDialog.acceptedCallback = function () {

                c64.shrinkSnapshotStorage(Preferences.maxSnapshots - 1)
                c64.saveSnapshot()
            }
            errorDialog.open()
        }

        //
        // Error handling
        //

        // Standard error (shows up in the emulator window)
        function onShowError(title, text) {

            showError(title, text)
        }

        // Fatal error (delegated to the hub window)
        function onShowFatalError(title, text) {

            // Hand the message to the Hub over the RPC link rather than
            // showing it here: a fatal error means this window is in no state
            // to be used, and the Hub outlives it. If we were started
            // standalone there is no Hub listening, so the packet is dropped
            // and the log line below is all that remains.
            console.warn("Fatal error:", title, "-", text)
            c64.notifyFatalError(title, text)

            // Then go away. byebye() rather than close(): close() would run
            // the normal shutdown sequence, which pauses and then asks
            // whether to hibernate -- neither a dialog on a dead window nor
            // persisting the state that just failed makes sense here. The
            // notification above is already on the wire (the stdio transport
            // flushes every packet), so quitting cannot lose it.
            shutDownManager.byebye()
        }

        function onSnapshotSaved(vUUID, sUUID) {

            console.log("Snapshot saved", vUUID, sUUID)
        }
    }

    //
    // Auxiliary windows
    //

    FileDialog {

        id: insertDiskDialog
        title: qsTr("Insert Disk")
        nameFilters: [qsTr("Disk images (*.d64 *.g64 *.t64 *.prg *.p00 *.zip *.gz)"), qsTr("All files (*)")]

        property int driveNr: 8

        onAccepted: root.c64.media.insertDisk(driveNr, selectedFile)
    }

    SiC64DiskCreator {

        id: diskCreatorDialog
        c64: root.c64
    }

    SiC64DiskExporter {

        id: diskExporterDialog
        c64: root.c64
    }

    FileDialog {

        id: insertTapeDialog
        title: qsTr("Insert Tape")
        nameFilters: [qsTr("Tape images (*.tap *.zip *.gz)"), qsTr("All files (*)")]

        onAccepted: root.c64.media.insertTape(selectedFile)
    }

    FileDialog {

        id: exportTapeDialog
        title: qsTr("Export Tape")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Tape image (*.tap)")]
        defaultSuffix: "tap"

        onAccepted: root.c64.media.exportTape(selectedFile)
    }

    FileDialog {

        id: attachCartridgeDialog
        title: qsTr("Attach Cartridge")
        nameFilters: [qsTr("Cartridge images (*.crt *.zip *.gz)"), qsTr("All files (*)")]

        onAccepted: root.c64.media.attachCartridge(selectedFile)
    }

    FileDialog {

        id: exportCartridgeDialog
        title: qsTr("Export Cartridge")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Cartridge image (*.crt)")]
        defaultSuffix: "crt"

        onAccepted: root.c64.media.exportCartridge(selectedFile)
    }

    SiC64ConfigWindow {

        id: configWindow
        controller: root.c64
    }

    SiC64KeyboardSheet {

        id: keyboardSheet
        controller: root.c64
        anchors.horizontalCenter: parent.horizontalCenter
        // Slide down from the canvas top, so the sheet clears the toolbar /
        // menu bar instead of dropping behind them.
        slideTop: wrapper.y
        z: 2
    }

    SiC64KeyboardWindow {

        id: keyboardWindow
        controller: root.c64
    }

    SiC64EventsPanel {

        id: eventsInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64CIAPanel {

        id: ciaInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64VICPanel {

        id: vicInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64SIDPanel {

        id: sidInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64BusPanel {

        id: busInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64CPUPanel {

        id: cpuInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64MemoryPanel {

        id: memoryInspectorWindow
        controller: root.c64
        actions: root.actions
    }

    SiC64About {

        id: aboutWindow
        visible: false
    }

    //
    // Actions
    //

    // All window actions live in SiC64Actions. SiC64Toolbar and SiC64Menu pull
    // this window in directly (as SiC64Window, not the generic VMWindow) to
    // reach them -- VMWindow itself has no notion of actions.
    SiC64Actions {

        id: siActions
        hostWindow: root
        c64: root.c64
        configWindowRef: configWindow
        keyboardSheetRef: keyboardSheet
        keyboardWindowRef: keyboardWindow
        eventsInspectorRef: eventsInspectorWindow
        ciaInspectorRef: ciaInspectorWindow
        busInspectorRef: busInspectorWindow
        cpuInspectorRef: cpuInspectorWindow
        memoryInspectorRef: memoryInspectorWindow
        vicInspectorRef: vicInspectorWindow
        sidInspectorRef: sidInspectorWindow
    }

    // Single injection point for every window action. Consumers reach
    // individual actions via window.actions.xxx (e.g. window.actions.reset)
    // instead of a dozen separate window-level Action aliases.
    property alias actions: siActions

    //
    // Errors
    //

    // Shows a modal error dialog with a single OK button. Used both for
    // errors reported by the emulator core (see onShowError below) and for
    // actions that aren't implemented yet (see SiC64Actions' inspectAction).
    function showError(title, text) {

        errorDialog.titleText = title
        errorDialog.bodyText = text
        errorDialog.buttons = Dialog.Ok
        errorDialog.okLabel = qsTr("OK")
        // Clear any callback left over from a previous errorDialog use (e.g.
        // onSnapshotLimitReached below) -- a plain error has no accept action.
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

        if (Preferences.ejectWithoutAsking || !c64.media.hasModifiedDisk(driveNr)) {
            proceed()
            return
        }

        errorDialog.titleText = qsTr("Drive %1 contains an unsaved disk.").arg(driveNr)
        errorDialog.bodyText = qsTr("Your changes will be lost if you proceed.")
        errorDialog.buttons = Dialog.Cancel | Dialog.Ok
        errorDialog.okLabel = qsTr("Proceed")
        errorDialog.acceptedCallback = proceed
        errorDialog.open()
    }

    function insertDiskAction(driveNr) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            insertDiskDialog.driveNr = driveNr
            insertDiskDialog.open()
        })
    }

    function newDiskAction(driveNr) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            diskCreatorDialog.driveNr = driveNr
            diskCreatorDialog.open()
        })
    }

    function exportDiskAction(driveNr) {

        diskExporterDialog.driveNr = driveNr
        diskExporterDialog.open()
    }

    function ejectDiskAction(driveNr) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            c64.media.ejectDisk(driveNr)
        })
    }

    function insertRecentDiskAction(driveNr, index) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            c64.media.insertRecentDisk(driveNr, index)
        })
    }

    function insertTapeAction() {
        insertTapeDialog.open()
    }

    function exportTapeAction() {
        exportTapeDialog.open()
    }

    function attachCartridgeAction() {
        attachCartridgeDialog.open()
    }

    function exportCartridgeAction() {
        exportCartridgeDialog.open()
    }

    //
    // Lifetime
    //

    Component.onCompleted: {

        updateOverlayStack()

        if (c64.readOnly) {

            notifications.show(
                "Read-only Virtual Machine",
                "This preconfigured virtual machine is a temporary showcase designed to demonstrate the " +
                "emulator's capabilities. Any changes you make will be lost when the emulator shuts down.\n" +
                "To save your progress, you can clone this instance in the Central Hub to convert it into a " +
                "regular virtual machine.")
        }
    }

    onActiveChanged: {

        if (active) {

            if (Preferences.pauseWhileInBackground) {
                if (lostFocusWhileRunning) c64.run()
            }

        } else {

            lostFocusWhileRunning = c64.isRunning
            if (Preferences.pauseWhileInBackground) {
                c64.pause()
            }
        }
    }

    //
    // Closing
    //

    ShutDownManager {

        id: shutDownManager
        controller: root.c64
        showProgress: true
    }

    onClosing: function(closeEvent) { shutDownManager.windowClosing(closeEvent) }
}
