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
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

PrefPage {

    id: root

    readonly property var port: AppController.inputManager.port0Info

    Connections {

        target: controller

        function onDeviceChanged() {
            updateStack()
        }
    }

    function updateStack() {

        switch(controller.device) {

            case 0: stack.replace(emptyComponent); break;
            case 1: stack.replace(mouseComponent); break;
            default: stack.replace(gamepadComponent); break;
        }
    }

    //
    // Toolbar
    //

    toolbar: PrefToolbar {

        backdrop: root.backgroundItem

        heading: "Devices Settings"

        menuContent: [

            SiMenuItem {
                text: "Restore factory defaults..."
                onTriggered: Preferences.resetDevicesSettings()
            }
        ]

        HSpacer { }

        SiLabel {

            text: root.port.sdlName ? String(root.port.sdlName) : ""
            rightPadding: Style.mediumSpacing
        }

        SiComboBoxControl {

            id: deviceSelector

            controlWidth: 160

            // Deny focus to not interact with the standard emulation keys
            focusable: false

            // Remove the first element as it represents no device (unconnected port)
            model: AppController.inputManager.deviceList.slice(1)

            textRole: "name"
            iconRole: "icon"

            // Note: - 1 / + 1 is needed because we've removed the first element
            currentIndex: controller.device - 1
            onCurrentIndexChanged: {
                controller.device = currentIndex + 1
            }

            Component.onCompleted: updateStack(model[currentIndex].type)
        }
    }

    //
    // Main
    //

    StackView {

        id: stack
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(240, root.pageHeight)
        clip: true

        replaceEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        replaceExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
    }

    Component {

        id: emptyComponent

        Rectangle {
            color: "transparent"
        }
    }

    Component {

        id: mouseComponent

        MousePrefs {

            controller: root.controller
            backdrop: root.backgroundItem
        }
    }

    Component {

        id: gamepadComponent

        JoystickPrefs {

            controller: root.controller
            backdrop: root.backgroundItem
        }
    }
}