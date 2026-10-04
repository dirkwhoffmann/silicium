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

Item {

    id: root

    readonly property SiAmController amiga: SiAmController
    required property SiAmWindow window

    // As tall as the row of buttons wants to be, so that the strip this is
    // handed to can take its own height from it.
    implicitHeight: row.implicitHeight

    RowLayout {

        id: row

        anchors.fill: parent
        spacing: 0

        SuBarButton {

            phosphor: "gear"
            action: root.window.actions.config
        }

        SuBarDivider {}

        SuBarButton {

            id: inspectButton
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
                    action: root.window.actions.openCIAInspector
                }
                SuMenuItem {
                    action: root.window.actions.openMemoryInspector
                }
                SuMenuItem {
                    action: root.window.actions.openAgnusInspector
                }
                SuMenuItem {
                    action: root.window.actions.openCopperInspector
                }
                SuMenuItem {
                    action: root.window.actions.openBlitterInspector
                }
                SuMenuItem {
                    action: root.window.actions.openPaulaInspector
                }
                SuMenuItem {
                    action: root.window.actions.openDeniseInspector
                }
                SuMenuItem {
                    action: root.window.actions.openPortInspector
                }
                SuMenuItem {
                    action: root.window.actions.openEventsInspector
                }
                SuMenuSeparator {

                }
                SuMenuItem {
                    action: root.window.actions.openLogicAnalyzer
                }
                SuMenuItem {
                    action: root.window.actions.openXRayScanner
                }
            }
        }

        SuBarDivider {}

        SuBarButton {

            phosphor: "terminal-window"
            action: root.window.actions.retroShell
            checkable: true
            checked: root.amiga.retroShell
        }

        SuBarDivider {}

        SuBarButton {

            phosphor: "clipboard"
            action: root.window.actions.logger
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
        }

        SuBarDivider {}

        HSpacer {}

        SuBarDivider {}

        SuBarButton {
            visible: Preferences.developerMode
            phosphor: "bug-beetle"
            action: root.window.actions.debug
            checkable: true
            checked: root.amiga.debugPanel
        }

        SuBarDivider {}

        SuBarButton {
            phosphor: root.amiga.isPaused ? "play-circle" : "pause-circle"
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
