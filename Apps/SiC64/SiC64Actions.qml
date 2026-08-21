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
// Central definition of all SiC64 window actions
//

Item {

    id: root

    required property var hostWindow
    required property C64Controller c64
    required property var configWindowRef
    required property var keyboardSheetRef
    required property var keyboardWindowRef
    required property var eventsInspectorRef
    required property var ciaInspectorRef
    required property var busInspectorRef
    required property var cpuInspectorRef
    required property var memoryInspectorRef
    required property var vicInspectorRef
    required property var sidInspectorRef

    property alias config: configAction
    property alias openEventsInspector: openEventsInspectorAction
    property alias openCIAInspector: openCIAInspectorAction
    property alias openBusInspector: openBusInspectorAction
    property alias openCPUInspector: openCPUInspectorAction
    property alias openMemoryInspector: openMemoryInspectorAction
    property alias openVICInspector: openVICInspectorAction
    property alias openSIDInspector: openSIDInspectorAction
    property alias retroShell: retroShellAction
    property alias logger: loggerAction
    property alias keyboard: keyboardAction
    property alias keyboardWindowAction: kbdWindowAction
    property alias saveWorkspace: saveWorkspaceAction
    property alias saveSnapshot: saveSnapshotAction
    property alias loadSnapshot: loadSnapshotAction
    property alias pause: pauseAction
    property alias reset: resetAction
    property alias power: powerAction
    property alias debug: debugAction
    property alias captureOrReleaseMouse: captureOrReleaseMouseAction
    property alias stopAndGo: stopAndGoAction
    property alias hardReset: hardResetAction
    property alias softReset: softResetAction
    property alias brk: brkAction
    property alias stepOver: stepOverAction
    property alias stepInto: stepIntoAction
    property alias stepCycle: stepCycleAction
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

    // The toolbar's inspector button (SiC64Toolbar.qml) and the C64 menu's
    // "Inspector" item (SiC64Menu.qml) both show a small picker ("CIA...",
    // "Events...") rather than triggering one of these directly; each shows
    // or raises its window (there's exactly one of each -- see
    // SiC64Window.qml) when picked.
    Action {

        id: openEventsInspectorAction
        text: qsTr("Events...")
        onTriggered: {

            eventsInspectorRef.show()
            eventsInspectorRef.raise()
            eventsInspectorRef.requestActivate()
        }
    }

    Action {

        id: openCIAInspectorAction
        text: qsTr("CIA...")
        onTriggered: {

            ciaInspectorRef.show()
            ciaInspectorRef.raise()
            ciaInspectorRef.requestActivate()
        }
    }

    Action {

        id: openVICInspectorAction
        text: qsTr("VICII...")
        onTriggered: {

            vicInspectorRef.show()
            vicInspectorRef.raise()
            vicInspectorRef.requestActivate()
        }
    }

    Action {

        id: openSIDInspectorAction
        text: qsTr("SID...")
        onTriggered: {

            sidInspectorRef.show()
            sidInspectorRef.raise()
            sidInspectorRef.requestActivate()
        }
    }

    Action {

        id: openBusInspectorAction
        text: qsTr("Bus...")
        onTriggered: {

            busInspectorRef.show()
            busInspectorRef.raise()
            busInspectorRef.requestActivate()
        }
    }

    Action {

        id: openCPUInspectorAction
        text: qsTr("CPU...")
        onTriggered: {

            cpuInspectorRef.show()
            cpuInspectorRef.raise()
            cpuInspectorRef.requestActivate()
        }
    }

    Action {

        id: openMemoryInspectorAction
        text: qsTr("Memory...")
        onTriggered: {

            memoryInspectorRef.show()
            memoryInspectorRef.raise()
            memoryInspectorRef.requestActivate()
        }
    }

    // RetroShell and the Logger share a single overlay slot (see SiC64Window's
    // "Overlay" section), so opening one closes the other. Both actions'
    // "checked"/"isOpen" state is read by the toolbar buttons, which stay
    // pressed down for as long as their panel is the one showing.
    Action {

        id: retroShellAction
        text: c64.retroShell ? qsTr("Close RetroShell") : qsTr("Open RetroShell")
        onTriggered: {

            if (c64.retroShell) {
                c64.retroShell = false
            } else {
                hostWindow.loggerOpen = false
                c64.retroShell = true
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
                c64.retroShell = false
                hostWindow.loggerOpen = true
            }
        }
    }

    // Opens the keyboard as a sheet that slides down from the top of the
    // window. Triggered by the keyboard toolbar button.
    Action {

        id: keyboardAction

        property bool isOpen: keyboardSheetRef.shown

        text: qsTr("Open Keyboard")
        onTriggered: { keyboardSheetRef.shown = !keyboardSheetRef.shown }
    }

    // Opens the keyboard as a standalone window. Triggered by the "Show ..."
    // item in the Keyboard menu.
    Action {

        id: kbdWindowAction
        text: qsTr("Open Keyboard Window")
        onTriggered: {

            keyboardWindowRef.show()
            keyboardWindowRef.raise()
            keyboardWindowRef.requestActivate()
        }
    }

    Action {

        id: saveWorkspaceAction
        text: qsTr("Save Workspace")
        onTriggered: c64.saveWorkspace()
    }

    Action {

        id: saveSnapshotAction
        text: qsTr("Save Snapshot")
        onTriggered: c64.saveSnapshot()
    }

    Action {

        id: loadSnapshotAction
        text: qsTr("Load Snapshot")
        onTriggered: c64.revertSnapshot()
    }

    Action {

        id: pauseAction
        text: c64.isPaused ? qsTr("Run") : qsTr("Pause")
        onTriggered: c64.runOrPause()
    }

    Action {

        id: resetAction
        text: qsTr("Reset")
        shortcut: "Ctrl+R"
        onTriggered: c64.reset()
    }

    Action {

        id: powerAction
        text: c64.isPoweredOn ? qsTr("Power Off") : qsTr("Power On")
        onTriggered: c64.powerOnOrOff()
    }

    Action {

        id: debugAction
        text: qsTr("Debug Panel")
        onTriggered: c64.toggleDebugPanel()
    }

    // Edit menu commands (see SiC64Menu's Edit menu).
    Action {

        id: captureOrReleaseMouseAction
        text: c64.mouseCaptured ? qsTr("Release Mouse") : qsTr("Capture Mouse")
        shortcut: Preferences.mouseHotkey
        onTriggered: c64.captureOrReleaseMouse()
    }

    Action {

        id: stopAndGoAction
        text: qsTr("Pause")
        shortcut: "Ctrl+Meta+Y"
        onTriggered: c64.stopAndGo()
    }

    Action {

        id: hardResetAction
        text: qsTr("Hard Reset")
        shortcut: "Ctrl+Meta+R"
        onTriggered: c64.reset()
    }

    Action {

        id: softResetAction
        text: qsTr("Soft Reset")
        onTriggered: c64.softReset()
    }

    Action {

        id: brkAction
        text: qsTr("BRK")
        onTriggered: c64.brk()
    }

    Action {

        id: stepOverAction
        text: qsTr("Step Over")
        enabled: c64.isPaused
        onTriggered: c64.stepOver()
    }

    Action {

        id: stepIntoAction
        text: qsTr("Step Into")
        enabled: c64.isPaused
        onTriggered: c64.stepInto()
    }

    Action {

        id: stepCycleAction
        text: qsTr("Step Cycle")
        enabled: c64.isPaused
        onTriggered: c64.stepCycle()
    }

    Action {

        id: finishLineAction
        text: qsTr("Finish Line")
        enabled: c64.isPaused
        onTriggered: c64.finishLine()
    }

    Action {

        id: finishFrameAction
        text: qsTr("Finish Frame")
        enabled: c64.isPaused
        onTriggered: c64.finishFrame()
    }

    Action {

        id: toggleWarpAction
        text: qsTr("Toggle Warp Mode")
        shortcut: "Meta+Tab"
        onTriggered: c64.toggleWarp()
    }

    // Inspector number format (SiC64InspectorToolbar's format menu). Values
    // mirror C64Controller.format: 0 = hex, 1 = hex padded, 2 = decimal,
    // 3 = decimal padded.
    Action {

        id: formatHexAction
        text: qsTr("Hex")
        checkable: true
        checked: c64.format === 0
        onTriggered: c64.format = 0
    }

    Action {

        id: formatHexPaddedAction
        text: qsTr("Hex, zero padded")
        checkable: true
        checked: c64.format === 1
        onTriggered: c64.format = 1
    }

    Action {

        id: formatDecimalAction
        text: qsTr("Decimal")
        checkable: true
        checked: c64.format === 2
        onTriggered: c64.format = 2
    }

    Action {

        id: formatDecimalPaddedAction
        text: qsTr("Decimal, zero padded")
        checkable: true
        checked: c64.format === 3
        onTriggered: c64.format = 3
    }
}
