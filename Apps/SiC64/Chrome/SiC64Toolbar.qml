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
import Sulfur

//
// The icon toolbar of the C64 window, handed to the chrome (see SiC64Chrome)
//

Item {

    id: root

    readonly property C64Controller c64: C64Controller

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

        SuBarButton {

            action: root.window.actions.config
            // symbol: "settings"
            // awesome: "gear"
            phosphor: "gear"
        }

        SuBarDivider {}

        SuBarButton {

            id: inspectButton
            // symbol: "search"
            // awesome: "magnifying-glass"
            phosphor: "magnifying-glass"
            text: qsTr("Inspector")
            onClicked: inspectMenu.open()

            SuMenu {

                id: inspectMenu
                y: inspectButton.height

                SuMenuItem {
                    action: root.window.actions.openCPUInspector
                }
                SuMenuItem {
                    action: root.window.actions.openMemoryInspector
                }
                SuMenuItem {
                    action: root.window.actions.openBusInspector
                }
                SuMenuItem {
                    action: root.window.actions.openCIAInspector
                }
                SuMenuItem {
                    action: root.window.actions.openVICInspector
                }
                SuMenuItem {
                    action: root.window.actions.openSIDInspector
                }
                SuMenuItem {
                    action: root.window.actions.openEventsInspector
                }
            }
        }

        SuBarDivider {}

        SuBarButton {

            action: root.window.actions.retroShell
            phosphor: "terminal-window"
            checkable: true
            checked: root.c64.retroShell
        }

        SuBarDivider {}

        SuBarButton {

            action: root.window.actions.logger
            phosphor: "clipboard"
            checkable: true
            checked: root.window.actions.logger.isOpen
        }

        SuBarDivider {}

        HSpacer {}

        SuBarDivider {}

        SuBarButton {
            phosphor: "database"
            action: root.window.actions.saveWorkspace
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: "download-simple"
            action: root.window.actions.saveSnapshot
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: "upload-simple"
            action: root.window.actions.loadSnapshot
        }

        SuBarDivider {}

        HSpacer {}

        SuBarDivider {}

        DeviceSelectorFlat {

            id: port0Selector
            port: "Control Port 1"
            deviceModel: AppController.inputManager.deviceList
            currentIndex: AppController.inputManager.port0
            onDeviceSelected: (index) => AppController.inputManager.port0 = index
        }

        SuBarDivider {}

        DeviceSelectorFlat {

            id: port1Selector
            port: "Control Port 2"
            deviceModel: AppController.inputManager.deviceList
            currentIndex: AppController.inputManager.port1
            onDeviceSelected: (index) => AppController.inputManager.port1 = index
        }

        SuBarDivider {}

        HSpacer {}

        SuBarDivider {}

        SuBarButton {
            phosphor: "keyboard"
            action: root.window.actions.keyboard
            checkable: true
            checked: root.window.actions.keyboard.isOpen
        }

        SuBarDivider {}

        HSpacer {}

        SuBarDivider {}

        SuBarButton {
            visible: Preferences.developerMode
            phosphor: "bug-beetle"
            action: root.window.actions.debug
            checkable: true
            checked: root.c64.debugPanel
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: root.c64.isPaused ? "play-circle" : "pause-circle"
            action: root.window.actions.pause
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: "arrows-clockwise"
            action: root.window.actions.reset
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: "power"
            action: root.window.actions.power
        }
    }
}
