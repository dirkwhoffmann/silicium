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
// set one-for-one, each raising its own top-level window (see
// SiAmInspectorWindow.qml) so several inspectors can stay open side by
// side, exactly like SiC64. No saveWorkspace/saveSnapshot/loadSnapshot or
// stopAndGo (no workspace/
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
    required property var cpuInspectorRef
    required property var busInspectorRef
    required property var ciaInspectorRef
    required property var memoryInspectorRef
    required property var agnusInspectorRef
    required property var copperInspectorRef
    required property var blitterInspectorRef
    required property var paulaInspectorRef
    required property var deniseInspectorRef
    required property var portInspectorRef
    required property var eventsInspectorRef

    property alias config: configAction
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

        id: openBusInspectorAction
        text: qsTr("Bus...")
        icon.name: "cable"
        onTriggered: {

            busInspectorRef.show()
            busInspectorRef.raise()
            busInspectorRef.requestActivate()
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
