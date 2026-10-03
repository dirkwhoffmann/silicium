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

    readonly property real titleBarInset: contentItem.SafeArea.margins.top

    property alias actions: siActions

    // Set while the window is in the background, if the machine was running
    property bool lostFocusWhileRunning: false

    // The title is drawn by the chrome, as the native one would block dragging
    visible: true
    width: 782
    height: 652
    minimumWidth: 400
    minimumHeight: 200
    topPadding: 0

    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    Palette.appearance: Preferences.appearance
    Palette.theme: Preferences.colorTheme

    // The chrome the base class hides in fullscreen mode
    chromeRef: chrome

    title: ""

    // Hiding the toolbar (the shortcut, the View menu, or entering fullscreen)
    // leaves no menu behind to bring it back from -- show a hint so the user
    // isn't stuck having to remember the shortcut.
    Connections {

        target: chrome

        function onShowCommandBarChanged() {

            if (!chrome.showCommandBar) {
                hintBanner.showHint(qsTr("Recover toolbar by pressing %1")
                    .arg(Shortcuts.nativeText(siActions.toolbarShortcut)))
            }
        }
    }

    //
    // Main area
    //

    SiC64Chrome {

        id: chrome
        anchors.fill: parent
        z: 10
        window: root
    }

    CanvasWrapper {

        id: wrapper
        anchors.fill: parent
        anchors.topMargin: chrome.canvasStart
        anchors.bottomMargin: parent.height - chrome.canvasEnd
        aspectRatio: root.aspectRatio
        resizeMode: Preferences.resizeMode
        fadeIn: true

        onClicked: {

            if (Preferences.retainMouseByClicking && !canvasOverlay.visible) {
                root.c64.captureMouse()
            }
        }

        onDoubleClicked: {
            if (Preferences.retainMouseByDoubleClicking && !canvasOverlay.visible) {
                root.c64.captureMouse()
            }
        }

        SiC64Canvas {

            id: canvas
        }

        SiC64DevPanel {

            x: 20
            y: 20
            visible: root.c64.debugPanel && Preferences.developerMode
        }
    }

    Item {

        id: overlayArea

        anchors.fill: parent
        anchors.topMargin: chrome.overlayStart
        anchors.bottomMargin: parent.height - chrome.overlayEnd
    }

    //
    // Pause overlay
    //

    PauseOverlay {

        id: pauseOverlay
        anchors.fill: overlayArea
        controller: root.c64
    }

    //
    // Drop area
    //

    SiC64DropOverlay {

        anchors.fill: overlayArea
        window: root
    }

    //
    // Consoles
    //

    SiC64CanvasOverlay {

        id: canvasOverlay
        anchors.fill: overlayArea
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

    //
    // Connections
    //

    Connections {

        target: c64

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
    }

    SiC64DiskExporter {

        id: diskExporterDialog
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
    }

    SiC64KeyboardSheet {

        id: keyboardSheet
        anchors.horizontalCenter: parent.horizontalCenter
        // Slide down from the canvas top, so the sheet clears the toolbar /
        // menu bar instead of dropping behind them.
        slideTop: wrapper.y
        z: 2
    }

    SiC64KeyboardWindow {

        id: keyboardWindow
    }

    SiC64EventsPanel {

        id: eventsInspectorWindow
        actions: root.actions
    }

    SiC64CIAPanel {

        id: ciaInspectorWindow
        actions: root.actions
    }

    SiC64VICPanel {

        id: vicInspectorWindow
        actions: root.actions
    }

    SiC64SIDPanel {

        id: sidInspectorWindow
        actions: root.actions
    }

    SiC64BusPanel {

        id: busInspectorWindow
        actions: root.actions
    }

    SiC64CPUPanel {

        id: cpuInspectorWindow
        actions: root.actions
    }

    SiC64MemoryPanel {

        id: memoryInspectorWindow
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
        chromeRef: chrome
        canvasOverlayRef: canvasOverlay
        aboutWindowRef: aboutWindow
    }

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
