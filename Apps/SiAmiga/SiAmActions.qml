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
// Central definition of all SiAmiga window actions. Port of SiC64Actions.qml,
// trimmed to what SiAmiga actually has: the per-panel inspector actions
// below (openCPUInspector, openBusInspector, ...) mirror C64Actions' own
// set, but each just switches SiAmInspectorWindow's page rather than
// raising a distinct window -- SiAmiga hosts every panel in one shared
// window instead of SiC64's one-window-per-panel set (see that file). No
// saveWorkspace/saveSnapshot/loadSnapshot or stopAndGo (no workspace/
// snapshot persistence or datasette-era pause alias exist here), and no
// keyboardWindowAction distinct from a sheet-based 'keyboard' action --
// SiAmiga's keyboard is a standalone window only, so the one 'keyboard'
// action covers what SiC64Actions splits into 'keyboard' (sheet) and
// 'keyboardWindowAction' (window).
//
// SiAmToolbar and SiAmMenu pull their actions from this the same way
// SiC64Toolbar/SiC64Menu do: via window.actions.xxx (see SiAmWindow.qml's
// 'actions' alias), not by taking an SiAmActions reference of their own.
//

Item {

    id: root

    required property var hostWindow
    required property SiAmController amiga
    required property var configWindowRef
    required property var keyboardWindowRef
    required property var inspectorWindowRef

    property alias config: configAction
    property alias openInspector: openInspectorAction
    property alias openCPUInspector: openCPUInspectorAction
    property alias openBusInspector: openBusInspectorAction
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
    property alias formatHex: formatHexAction
    property alias formatHexPadded: formatHexPaddedAction
    property alias formatDecimal: formatDecimalAction
    property alias formatDecimalPadded: formatDecimalPaddedAction

    Action {

        id: configAction
        text: qsTr("Open Configurator")
        shortcut: StandardKey.Preferences
        onTriggered: configWindowRef.showPage(configWindowRef.currentIndex)
    }

    // Reopens the Inspector on whichever page it last showed -- kept as a
    // plain keyboard-shortcut entry point. The toolbar's Inspector button
    // (SiAmToolbar.qml) and the Debug menu's "Inspector" submenu
    // (SiAmMenu.qml) instead use the eleven per-panel actions below, one
    // shared Inspector window standing in for SiC64's one-window-per-panel
    // set (see SiAmInspectorWindow.qml) -- each action just switches that
    // window's page instead of raising a distinct window.
    Action {

        id: openInspectorAction
        text: qsTr("Show Inspector...")
        shortcut: "Ctrl+I"
        onTriggered: {

            inspectorWindowRef.showPage(inspectorWindowRef.currentIndex)
            inspectorWindowRef.raise()
            inspectorWindowRef.requestActivate()
        }
    }

    Action {

        id: openCPUInspectorAction
        text: qsTr("CPU...")
        icon.name: "memory"
        onTriggered: inspectorWindowRef.showPage(0)
    }

    Action {

        id: openBusInspectorAction
        text: qsTr("Bus...")
        icon.name: "cable"
        onTriggered: inspectorWindowRef.showPage(1)
    }

    Action {

        id: openCIAInspectorAction
        text: qsTr("CIA...")
        icon.name: "developer_board"
        onTriggered: inspectorWindowRef.showPage(2)
    }

    Action {

        id: openMemoryInspectorAction
        text: qsTr("Memory...")
        icon.name: "memory_alt"
        onTriggered: inspectorWindowRef.showPage(3)
    }

    Action {

        id: openAgnusInspectorAction
        text: qsTr("Agnus...")
        icon.name: "hub"
        onTriggered: inspectorWindowRef.showPage(4)
    }

    Action {

        id: openCopperInspectorAction
        text: qsTr("Copper...")
        icon.name: "content_copy"
        onTriggered: inspectorWindowRef.showPage(5)
    }

    Action {

        id: openBlitterInspectorAction
        text: qsTr("Blitter...")
        icon.name: "bolt"
        onTriggered: inspectorWindowRef.showPage(6)
    }

    Action {

        id: openPaulaInspectorAction
        text: qsTr("Paula...")
        icon.name: "music_note_2"
        onTriggered: inspectorWindowRef.showPage(7)
    }

    Action {

        id: openDeniseInspectorAction
        text: qsTr("Denise...")
        icon.name: "monitor"
        onTriggered: inspectorWindowRef.showPage(8)
    }

    Action {

        id: openPortInspectorAction
        text: qsTr("Ports...")
        icon.name: "usb"
        onTriggered: inspectorWindowRef.showPage(9)
    }

    Action {

        id: openEventsInspectorAction
        text: qsTr("Events...")
        icon.name: "schedule"
        onTriggered: inspectorWindowRef.showPage(10)
    }

    // RetroShell and the Logger share a single overlay slot (see
    // SiAmWindow's "Console overlay" section), so opening one closes the
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
                hostWindow.loggerOpen = false
                amiga.retroShell = true
            }
        }
    }

    Action {

        id: loggerAction

        property bool isOpen: hostWindow.loggerOpen

        text: hostWindow.loggerOpen ? qsTr("Close Logger") : qsTr("Open Logger")
        onTriggered: {

            if (hostWindow.loggerOpen) {
                hostWindow.loggerOpen = false
            } else {
                amiga.retroShell = false
                hostWindow.loggerOpen = true
            }
        }
    }

    // Opens the virtual keyboard window. Triggered by the Keyboard menu's
    // "Show..." item and the toolbar's keyboard button -- SiAmiga has no
    // sheet variant to distinguish this from (see the class comment).
    Action {

        id: keyboardAction
        text: qsTr("Open Keyboard")
        shortcut: "Ctrl+K"
        onTriggered: {

            keyboardWindowRef.show()
            keyboardWindowRef.raise()
            keyboardWindowRef.requestActivate()
        }
    }

    Action {

        id: pauseAction
        text: amiga.isPaused ? qsTr("Run") : qsTr("Pause")
        onTriggered: amiga.runOrPause()
    }

    Action {

        id: resetAction
        text: qsTr("Reset")
        shortcut: "Ctrl+R"
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
        shortcut: Preferences.mouseHotkey
        onTriggered: amiga.captureOrReleaseMouse()
    }

    Action {

        id: hardResetAction
        text: qsTr("Hard Reset")
        shortcut: "Ctrl+Meta+R"
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
        shortcut: "Meta+Tab"
        onTriggered: amiga.toggleWarp()
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
