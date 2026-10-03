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

//
// The icon toolbar of the C64 window, handed to the chrome (see SiC64Chrome)
//

Item {

    id: root

    required property C64Controller c64

    // The owning window supplies its single "actions" property (see
    // SiC64Window), which the toolbar buttons drive via window.actions.reset,
    // window.actions.pause, window.actions.config, etc.
    required property SiC64Window window

    // As tall as the row of buttons wants to be, so that the strip this is
    // handed to can take its own height from it.
    implicitHeight: row.implicitHeight

    RowLayout {

        id: row

        anchors.fill: parent
        spacing: 0

        NavTextButtonFlat {

            action: root.window.actions.config
            // symbol: "settings"
            // awesome: "gear"
            phosphor: "gear"
        }

        NavDivider {}

        NavTextButtonFlat {

            id: inspectButton
            // symbol: "search"
            // awesome: "magnifying-glass"
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
                    action: root.window.actions.openMemoryInspector
                }
                SiMenuItem {
                    action: root.window.actions.openBusInspector
                }
                SiMenuItem {
                    action: root.window.actions.openCIAInspector
                }
                SiMenuItem {
                    action: root.window.actions.openVICInspector
                }
                SiMenuItem {
                    action: root.window.actions.openSIDInspector
                }
                SiMenuItem {
                    action: root.window.actions.openEventsInspector
                }
            }
        }

        NavDivider {}

        NavTextButtonFlat {

            action: root.window.actions.retroShell
            phosphor: "terminal-window"
            checkable: true
            checked: root.c64.retroShell
        }

        NavDivider {}

        NavTextButtonFlat {

            action: root.window.actions.logger
            phosphor: "clipboard"
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
            checkable: true
            checked: root.window.actions.keyboard.isOpen
        }

        NavDivider {}

        HSpacer {}

        NavDivider {}

        NavTextButtonFlat {
            visible: Preferences.developerMode
            phosphor: "bug-beetle"
            action: root.window.actions.debug
            checkable: true
            checked: root.c64.debugPanel
        }

        NavDivider {}

        NavTextButtonFlat {
            phosphor: root.c64.isPaused ? "play-circle" : "pause-circle"
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
