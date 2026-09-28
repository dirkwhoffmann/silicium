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
import QtQuick.Layouts
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

/* What the icon row holds.
 *
 * Only its contents: the strip's height, which of its rows are on show, what
 * it is filled with and the compact-mode button that swaps the rows over all
 * belong to the SiToolbarWrapper this is handed to, which is the same for
 * every emulator. The menu row is SiAmMenu, handed to the same wrapper
 * alongside this one.
 *
 * Port of SiC64Toolbar.qml, trimmed the same way SiAmMenu.qml was trimmed
 * relative to SiC64Menu.qml: the workspace/snapshot save/load buttons aren't
 * wired to anything because that subsystem doesn't exist in SiAmiga yet.
 * Every other button is wired via root.window.actions (see SiAmActions.qml),
 * same as SiC64Toolbar's window.actions.* calls.
 */
Item {

    id: root

    required property SiAmController amiga
    required property SiAmWindow window

    RowLayout {

        anchors.fill: parent
        spacing: 0

        NavTextButtonFlat {

            phosphor: "gear"
            action: root.window.actions.config
        }

        NavDivider {}

        NavTextButtonFlat {

            id: inspectButton
            phosphor: "magnifying-glass"
            text: qsTr("Inspector")
            onClicked: inspectMenu.open()

            SiMenu {

                id: inspectMenu
                y: inspectButton.height

                SiMenuItem {
                    action: root.window.actions.openCPUInspector
                }
                SiMenuItem {
                    action: root.window.actions.openCIAInspector
                }
                SiMenuItem {
                    action: root.window.actions.openMemoryInspector
                }
                SiMenuItem {
                    action: root.window.actions.openAgnusInspector
                }
                SiMenuItem {
                    action: root.window.actions.openCopperInspector
                }
                SiMenuItem {
                    action: root.window.actions.openBlitterInspector
                }
                SiMenuItem {
                    action: root.window.actions.openPaulaInspector
                }
                SiMenuItem {
                    action: root.window.actions.openDeniseInspector
                }
                SiMenuItem {
                    action: root.window.actions.openPortInspector
                }
                SiMenuItem {
                    action: root.window.actions.openEventsInspector
                }
                SiMenuSeparator {

                }
                SiMenuItem {
                    action: root.window.actions.openLogicAnalyzer
                }
                SiMenuItem {
                    action: root.window.actions.openXRayScanner
                }
            }
        }

        NavDivider {}

        NavTextButtonFlat {

            phosphor: "terminal-window"
            action: root.window.actions.retroShell
            checkable: true
            checked: root.amiga.retroShell
        }

        NavDivider {}

        NavTextButtonFlat {

            phosphor: "clipboard"
            action: root.window.actions.logger
            checkable: true
            checked: root.window.actions.logger.isOpen
        }

        NavDivider {}

        HSpacer {}

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "database"
            action: root.window.actions.saveWorkspace
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "download-simple"
            action: root.window.actions.saveSnapshot
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "upload-simple"
            action: root.window.actions.loadSnapshot
        }

        NavDivider {}

        HSpacer {}

        NavDivider {}

        DeviceSelectorFlat {

            id: port0Selector
            port: "Control Port 1"
            deviceModel: AppController.inputManager.deviceList
            currentIndex: AppController.inputManager.port0
            onDeviceSelected: (index) => AppController.inputManager.port0 = index
        }

        NavDivider {}

        DeviceSelectorFlat {

            id: port1Selector
            port: "Control Port 2"
            deviceModel: AppController.inputManager.deviceList
            currentIndex: AppController.inputManager.port1
            onDeviceSelected: (index) => AppController.inputManager.port1 = index
        }

        NavDivider {}

        HSpacer {}

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "keyboard"
            action: root.window.actions.keyboard
        }

        NavDivider {}

        HSpacer {}

        NavDivider {}

        NavTextButtonFlat {
            visible: Preferences.developerMode
            phosphor: "bug-beetle"
            action: root.window.actions.debug
            checkable: true
            checked: root.amiga.debugPanel
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: root.amiga.isPaused ? "play-circle" : "pause-circle"
            action: root.window.actions.pause
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "arrows-clockwise"
            action: root.window.actions.reset
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: "power"
            action: root.window.actions.power
        }
    }
}
