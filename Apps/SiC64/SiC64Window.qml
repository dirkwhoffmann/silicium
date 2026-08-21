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

    vmc: C64Controller

    property C64Controller c64: C64Controller
    property real aspectRatio: 800.0 / 614.0
    property bool statusbarVisible: true
    property bool loggerOpen: false

    width: 782
    height: 652
    minimumWidth: 400
    minimumHeight: 200

    notificationMaxHeight: wrapper.height - 2 * Style.largeSpacing
    notificationMaxWidth: wrapper.width - 2 * Style.largeSpacing

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
            showHint(qsTr("Recover toolbar by pressing %1").arg(Shortcuts.nativeText(toolbarShortcut)))
        }
    }

    // Floats over the canvas (z above it) instead of using header:, which
    // reserves its own layout slot above the content area. With
    // Preferences.autoHideToolbar on, the canvas extends behind it (see
    // wrapper's anchors.top below) so fading the toolbar out reveals the
    // canvas rather than plain window background. With it off, the canvas
    // is anchored below the toolbar instead -- same reserved-space layout
    // header: used to give, and the toolbar itself never fades (see
    // SiC64Toolbar's autoHideActive).
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
    // Dialogs
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

    //
    // Media files
    //

    function proceedWithUnsavedFloppyDisk(driveNr, proceed) {

        if (Preferences.ejectWithoutAsking || !c64.hasModifiedDisk(driveNr)) {
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
            c64.ejectDisk(driveNr)
        })
    }

    function insertRecentDiskAction(driveNr, index) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            c64.insertRecentDisk(driveNr, index)
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

    FileDialog {

        id: insertDiskDialog
        title: qsTr("Insert Disk")
        nameFilters: [qsTr("Disk images (*.d64 *.g64 *.t64 *.prg *.p00 *.zip *.gz)"), qsTr("All files (*)")]

        property int driveNr: 8

        onAccepted: root.c64.insertDisk(driveNr, selectedFile)
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

        onAccepted: root.c64.insertTape(selectedFile)
    }

    FileDialog {

        id: exportTapeDialog
        title: qsTr("Export Tape")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Tape image (*.tap)")]
        defaultSuffix: "tap"

        onAccepted: root.c64.exportTape(selectedFile)
    }

    FileDialog {

        id: attachCartridgeDialog
        title: qsTr("Attach Cartridge")
        nameFilters: [qsTr("Cartridge images (*.crt *.zip *.gz)"), qsTr("All files (*)")]

        onAccepted: root.c64.attachCartridge(selectedFile)
    }

    FileDialog {

        id: exportCartridgeDialog
        title: qsTr("Export Cartridge")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Cartridge image (*.crt)")]
        defaultSuffix: "crt"

        onAccepted: root.c64.exportCartridge(selectedFile)
    }

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
            byebye()
        }

        function onSnapshotSaved(vUUID, sUUID) {

            console.log("Snapshot saved", vUUID, sUUID)
        }
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
        // Auto-hide on: extends behind the floating toolbar, since fading it
        // out is meant to reveal the canvas underneath. Auto-hide off: the
        // toolbar never fades, so start the canvas below it instead -- no
        // reason to let it hide part of the picture permanently.
        anchors.top: Preferences.autoHideToolbar ? parent.top : toolbar.bottom
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
                // Route through the controller (not the InputManager directly)
                // so the capture hint gets shown via mouseWasCaptured().
                root.c64.captureMouse()
            }
        }

        onDoubleClicked: {
            if (Preferences.retainMouseByDoubleClicking && !overlayPanel.visible) {
                // Route through the controller (not the InputManager directly)
                // so the capture hint gets shown via mouseWasCaptured().
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

    Component.onCompleted: updateOverlayStack()

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

    About {

        id: aboutWindow
        visible: false
    }
}
