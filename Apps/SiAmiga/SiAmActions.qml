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
import Silicium.Controllers
import Silicium.Preferences

//
// Central definition of all SiAmiga window actions
//

Item {

    id: root

    required property SiAmController amiga
    required property var configWindowRef
    required property var keyboardWindowRef
    required property var cpuInspectorRef
    required property var logicAnalyzerRef
    required property var xrayScannerRef
    required property var ciaInspectorRef
    required property var memoryInspectorRef
    required property var agnusInspectorRef
    required property var copperInspectorRef
    required property var blitterInspectorRef
    required property var paulaInspectorRef
    required property var deniseInspectorRef
    required property var portInspectorRef
    required property var eventsInspectorRef
    required property var hardDiskCreatorRef
    required property var userDialogRef
    required property var diskCreatorRef
    required property var canvasOverlayRef
    required property var chromeRef
    required property var aboutWindowRef

    //
    // Keyboard shortcuts
    //
    // The one place where the shortcuts are managed. The actions below use
    // them, and so do the menu items that are handled by the window itself and
    // therefore have no action (Toolbar, Status Bar, Quit).
    //

    readonly property var configShortcut: StandardKey.Preferences
    readonly property string keyboardShortcut: "Ctrl+K"
    readonly property string resetShortcut: "Ctrl+R"
    readonly property string hardResetShortcut: "Ctrl+Meta+R"
    readonly property var captureMouseShortcut: Preferences.mouseHotkey
    readonly property string toggleWarpShortcut: "Meta+Tab"
    readonly property string toolbarShortcut: "Ctrl+Alt+T"
    readonly property string statusBarShortcut: "Ctrl+Alt+B"
    readonly property var quitShortcut: StandardKey.Quit

    property alias config: configAction
    property alias openCPUInspector: openCPUInspectorAction
    property alias openLogicAnalyzer: openLogicAnalyzerAction
    property alias openXRayScanner: openXRayScannerAction
    property alias openCIAInspector: openCIAInspectorAction
    property alias openMemoryInspector: openMemoryInspectorAction
    property alias openAgnusInspector: openAgnusInspectorAction
    property alias openCopperInspector: openCopperInspectorAction
    property alias openBlitterInspector: openBlitterInspectorAction
    property alias openPaulaInspector: openPaulaInspectorAction
    property alias openDeniseInspector: openDeniseInspectorAction
    property alias openPortInspector: openPortInspectorAction
    property alias openEventsInspector: openEventsInspectorAction
    property alias retroShell: retroShellAction
    property alias logger: loggerAction
    property alias keyboard: keyboardAction
    property alias saveWorkspace: saveWorkspaceAction
    property alias saveSnapshot: saveSnapshotAction
    property alias loadSnapshot: loadSnapshotAction
    property alias pause: pauseAction
    property alias reset: resetAction
    property alias power: powerAction
    property alias debug: debugAction
    property alias captureOrReleaseMouse: captureOrReleaseMouseAction
    property alias hardReset: hardResetAction
    property alias softReset: softResetAction
    property alias brk: brkAction
    property alias stepOver: stepOverAction
    property alias stepInto: stepIntoAction
    property alias finishLine: finishLineAction
    property alias finishFrame: finishFrameAction
    property alias toggleWarp: toggleWarpAction
    property alias toggleCommandBar: toggleCommandBarAction
    property alias toggleStatusBar: toggleStatusBarAction
    property alias showAbout: showAboutAction
    property alias formatHex: formatHexAction
    property alias formatHexPadded: formatHexPaddedAction
    property alias formatDecimal: formatDecimalAction
    property alias formatDecimalPadded: formatDecimalPaddedAction

    /* Runs 'proceed', after asking first if the floppy disk in the drive holds
     * changes that have not been saved (unless the preferences say not to ask).
     *
     * A function rather than an Action: it takes the drive it is about.
     */
    function proceedWithUnsavedFloppyDisk(driveNr, proceed) {

        if (Preferences.ejectWithoutAsking || !amiga.media.driveModified(driveNr)) {
            proceed()
            return
        }

        const dialog = userDialogRef
        dialog.titleText = qsTr("Drive df%1 contains an unsaved disk.").arg(driveNr)
        dialog.bodyText = qsTr("Your changes will be lost if you proceed.")
        dialog.buttons = Dialog.Cancel | Dialog.Ok
        dialog.okLabel = qsTr("Proceed")
        dialog.acceptedCallback = proceed
        dialog.open()
    }

    // Asks for a new floppy disk, and warns first where changes are at stake
    function newDiskAction(driveNr) {

        proceedWithUnsavedFloppyDisk(driveNr, function () {
            diskCreatorRef.driveNr = driveNr
            diskCreatorRef.open()
        })
    }

    /* Asks for a new hard drive, and warns first where one is at stake.
     *
     * A function rather than an Action: it takes the slot it is about, and
     * an Action carries no argument. The dialogs it drives are the window's
     * (see SiAmWindow.qml) -- this is the decision, not the furniture.
     */
    function newHardDiskAction(driveNr) {

        const hasDisk =
                driveNr === 0 ? amiga.info.hdHasDisk0 :
                        driveNr === 1 ? amiga.info.hdHasDisk1 :
                                driveNr === 2 ? amiga.info.hdHasDisk2 :
                                        driveNr === 3 ? amiga.info.hdHasDisk3 : false

        // The image file is asked about as well as the drive: the new one
        // is written under that same name (hdN.hdf), so a file left in the
        // folder by an earlier drive is overwritten even when the slot
        // itself is empty.
        const existing = amiga.media.hdExistingImage(driveNr)

        const creator = hardDiskCreatorRef

        if (!hasDisk && existing === "") {
            creator.driveNr = driveNr
            creator.open()
            return
        }

        const dialog = userDialogRef
        dialog.titleText = hasDisk ?
            qsTr("Hd%1 already holds a hard drive.").arg(driveNr) :
            qsTr("The machine folder already holds %1.").arg(existing)
        dialog.bodyText = qsTr("Creating a new one replaces it. Anything on " +
                               "it that has not been exported will be lost.")
        dialog.buttons = Dialog.Cancel | Dialog.Ok
        dialog.okLabel = qsTr("Proceed")
        dialog.acceptedCallback = function () {
            creator.driveNr = driveNr
            creator.open()
        }
        dialog.open()
    }


    Action {

        id: configAction
        text: qsTr("Open Configurator")
        shortcut: root.configShortcut
        onTriggered: configWindowRef.showPage(configWindowRef.currentIndex)
    }

    // The toolbar's Inspector button (SiAmToolbar.qml) and the Debug menu's
    // "Inspector" submenu (SiAmMenu.qml) both show a small picker ("CPU...",
    // "Bus...") rather than triggering one of these directly; each shows or
    // raises its window (there's exactly one of each -- see SiAmWindow.qml)
    // when picked, mirroring SiC64Actions' own per-panel actions.
    Action {

        id: openCPUInspectorAction
        text: qsTr("CPU...")
        icon.name: "memory"
        onTriggered: {

            cpuInspectorRef.show()
            cpuInspectorRef.raise()
            cpuInspectorRef.requestActivate()
        }
    }

    Action {

        id: openLogicAnalyzerAction
        text: qsTr("Logic Analyzer...")
        icon.name: "cable"
        onTriggered: {

            logicAnalyzerRef.show()
            logicAnalyzerRef.raise()
            logicAnalyzerRef.requestActivate()
        }
    }

    Action {

        id: openXRayScannerAction
        text: qsTr("XRay...")
        icon.name: "stack"
        onTriggered: {

            xrayScannerRef.show()
            xrayScannerRef.raise()
            xrayScannerRef.requestActivate()
        }
    }

    Action {

        id: openCIAInspectorAction
        text: qsTr("CIA...")
        icon.name: "developer_board"
        onTriggered: {

            ciaInspectorRef.show()
            ciaInspectorRef.raise()
            ciaInspectorRef.requestActivate()
        }
    }

    Action {

        id: openMemoryInspectorAction
        text: qsTr("Memory...")
        icon.name: "memory_alt"
        onTriggered: {

            memoryInspectorRef.show()
            memoryInspectorRef.raise()
            memoryInspectorRef.requestActivate()
        }
    }

    Action {

        id: openAgnusInspectorAction
        text: qsTr("Agnus...")
        icon.name: "hub"
        onTriggered: {

            agnusInspectorRef.show()
            agnusInspectorRef.raise()
            agnusInspectorRef.requestActivate()
        }
    }

    Action {

        id: openCopperInspectorAction
        text: qsTr("Copper...")
        icon.name: "content_copy"
        onTriggered: {

            copperInspectorRef.show()
            copperInspectorRef.raise()
            copperInspectorRef.requestActivate()
        }
    }

    Action {

        id: openBlitterInspectorAction
        text: qsTr("Blitter...")
        icon.name: "bolt"
        onTriggered: {

            blitterInspectorRef.show()
            blitterInspectorRef.raise()
            blitterInspectorRef.requestActivate()
        }
    }

    Action {

        id: openPaulaInspectorAction
        text: qsTr("Paula...")
        icon.name: "music_note_2"
        onTriggered: {

            paulaInspectorRef.show()
            paulaInspectorRef.raise()
            paulaInspectorRef.requestActivate()
        }
    }

    Action {

        id: openDeniseInspectorAction
        text: qsTr("Denise...")
        icon.name: "monitor"
        onTriggered: {

            deniseInspectorRef.show()
            deniseInspectorRef.raise()
            deniseInspectorRef.requestActivate()
        }
    }

    Action {

        id: openPortInspectorAction
        text: qsTr("Ports...")
        icon.name: "usb"
        onTriggered: {

            portInspectorRef.show()
            portInspectorRef.raise()
            portInspectorRef.requestActivate()
        }
    }

    Action {

        id: openEventsInspectorAction
        text: qsTr("Events...")
        icon.name: "schedule"
        onTriggered: {

            eventsInspectorRef.show()
            eventsInspectorRef.raise()
            eventsInspectorRef.requestActivate()
        }
    }

    // RetroShell and the Logger share a single overlay slot (see
    // SiAmCanvasOverlay), so opening one closes the
    // other. Both actions' "checked"/"isOpen" state is read by the toolbar
    // buttons, which stay pressed down for as long as their panel is the
    // one showing.
    Action {

        id: retroShellAction
        text: amiga.retroShell ? qsTr("Close RetroShell") : qsTr("Open RetroShell")
        onTriggered: {

            if (amiga.retroShell) {
                amiga.retroShell = false
            } else {
                canvasOverlayRef.loggerOpen = false
                amiga.retroShell = true
            }
        }
    }

    Action {

        id: loggerAction

        property bool isOpen: canvasOverlayRef.loggerOpen

        text: canvasOverlayRef.loggerOpen ? qsTr("Close Logger") : qsTr("Open Logger")
        onTriggered: {

            if (canvasOverlayRef.loggerOpen) {
                canvasOverlayRef.loggerOpen = false
            } else {
                amiga.retroShell = false
                canvasOverlayRef.loggerOpen = true
            }
        }
    }

    // Opens the virtual keyboard window. Triggered by the Keyboard menu's
    // "Show..." item and the toolbar's keyboard button -- SiAmiga has no
    // sheet variant to distinguish this from (see the class comment).
    Action {

        id: keyboardAction
        text: qsTr("Open Keyboard")
        shortcut: root.keyboardShortcut
        onTriggered: {

            keyboardWindowRef.show()
            keyboardWindowRef.raise()
            keyboardWindowRef.requestActivate()
        }
    }

    Action {

        id: saveWorkspaceAction
        text: qsTr("Save Workspace")
        onTriggered: amiga.saveWorkspace()
    }

    Action {

        id: saveSnapshotAction
        text: qsTr("Save Snapshot")
        onTriggered: amiga.saveSnapshot()
    }

    Action {

        id: loadSnapshotAction
        text: qsTr("Load Snapshot")
        onTriggered: amiga.revertSnapshot()
    }

    Action {

        id: pauseAction
        text: amiga.isPaused ? qsTr("Run") : qsTr("Pause")
        onTriggered: amiga.runOrPause()
    }

    Action {

        id: resetAction
        text: qsTr("Reset")
        shortcut: root.resetShortcut
        onTriggered: amiga.reset()
    }

    Action {

        id: powerAction
        text: amiga.isPoweredOn ? qsTr("Power Off") : qsTr("Power On")
        onTriggered: amiga.powerOnOrOff()
    }

    Action {

        id: debugAction
        text: qsTr("Debug Panel")
        onTriggered: amiga.toggleDebugPanel()
    }

    // Edit menu commands (see SiAmMenu's Edit menu).
    Action {

        id: captureOrReleaseMouseAction
        text: amiga.mouseCaptured ? qsTr("Release Mouse") : qsTr("Capture Mouse")
        shortcut: root.captureMouseShortcut
        onTriggered: amiga.captureOrReleaseMouse()
    }

    Action {

        id: hardResetAction
        text: qsTr("Hard Reset")
        shortcut: root.hardResetShortcut
        onTriggered: amiga.reset()
    }

    Action {

        id: softResetAction
        text: qsTr("Soft Reset")
        onTriggered: amiga.softReset()
    }

    Action {

        id: brkAction
        text: qsTr("BRK")
        onTriggered: amiga.brk()
    }

    Action {

        id: stepOverAction
        text: qsTr("Step Over")
        enabled: amiga.isPaused
        onTriggered: amiga.stepOver()
    }

    Action {

        id: stepIntoAction
        text: qsTr("Step Into")
        enabled: amiga.isPaused
        onTriggered: amiga.stepInto()
    }

    Action {

        id: finishLineAction
        text: qsTr("Finish Line")
        enabled: amiga.isPaused
        onTriggered: amiga.finishLine()
    }

    Action {

        id: finishFrameAction
        text: qsTr("Finish Frame")
        enabled: amiga.isPaused
        onTriggered: amiga.finishFrame()
    }

    Action {

        id: toggleWarpAction
        text: qsTr("Toggle Warp Mode")
        shortcut: root.toggleWarpShortcut
        onTriggered: amiga.toggleWarp()
    }

    // View menu commands. The state they toggle belongs to the chrome.
    Action {

        id: toggleCommandBarAction
        text: qsTr("Toolbar")
        shortcut: root.toolbarShortcut
        checkable: true
        checked: chromeRef.showCommandBar
        onTriggered: chromeRef.showCommandBar = !chromeRef.showCommandBar
    }

    Action {

        id: toggleStatusBarAction
        text: qsTr("Status Bar")
        shortcut: root.statusBarShortcut
        checkable: true
        checked: chromeRef.showStatusBar
        onTriggered: chromeRef.showStatusBar = !chromeRef.showStatusBar
    }

    Action {

        id: showAboutAction
        text: qsTr("About")
        onTriggered: aboutWindowRef.show()
    }

    // Inspector number format (SiAmInspectorToolbar's format menu). Unlike
    // C64Controller's single 0..3 'format' enum, SiAmInspectorController
    // keeps hex/decimal and padded/unpadded as two independent booleans
    // (see that class), so each of these sets both rather than one enum.
    Action {

        id: formatHexAction
        text: qsTr("Hex")
        checkable: true
        checked: amiga.inspectorController.hex && !amiga.inspectorController.padded
        onTriggered: { amiga.inspectorController.hex = true; amiga.inspectorController.padded = false }
    }

    Action {

        id: formatHexPaddedAction
        text: qsTr("Hex, zero padded")
        checkable: true
        checked: amiga.inspectorController.hex && amiga.inspectorController.padded
        onTriggered: { amiga.inspectorController.hex = true; amiga.inspectorController.padded = true }
    }

    Action {

        id: formatDecimalAction
        text: qsTr("Decimal")
        checkable: true
        checked: !amiga.inspectorController.hex && !amiga.inspectorController.padded
        onTriggered: { amiga.inspectorController.hex = false; amiga.inspectorController.padded = false }
    }

    Action {

        id: formatDecimalPaddedAction
        text: qsTr("Decimal, zero padded")
        checkable: true
        checked: !amiga.inspectorController.hex && amiga.inspectorController.padded
        onTriggered: { amiga.inspectorController.hex = false; amiga.inspectorController.padded = true }
    }
}
