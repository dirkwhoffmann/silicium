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

Item {

    id: root

    required property PrefController controller
    readonly property var port: AppController.inputManager.port0Info
    property int activeKey: -1

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    component JoystickRecordButton: RecordButton {

        required property int nr

        recordable: controller.keymap != -1
        listening: activeKey === nr

        onClicked: {

            activeKey = activeKey === nr ? -1 : nr
        }
        onKeyRecorded: (key, virtualKey) => {

            controller.setJoyKeyset(controller.keymap, nr, key, virtualKey)
            activeKey = -1
        }
    }

    GridLayout {

        id: grid
        columns: 3
        rows: 3
        anchors.centerIn: parent
        columnSpacing: 4
        rowSpacing: 4

        //
        // Row 1: . / Up / .
        //

        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }

        JoystickRecordButton {

            nr: 0
            topLabel: root.port.keyname0 ? root.port.keyname0 : ""
            centerLabel: root.port.keycodename0 >= 0 ? root.port.keycodename0 : ""
            triggered: controller.joyUp
        }
        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }

        //
        // Row 2: Left / . / Right
        //

        JoystickRecordButton {

            nr: 2
            leftLabel: root.port.keyname2 ? root.port.keyname2 : ""
            centerLabel: root.port.keycodename2 >= 0 ? root.port.keycodename2 : ""
            triggered: controller.joyLeft
        }

        Item {

            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            SiText {
                anchors.centerIn: parent
                text: "gamepad"
                font.family: Fonts.symbols
                font.pixelSize: 40
                color: Palette.secondary
            }
        }

        JoystickRecordButton {

            nr: 3
            rightLabel: root.port.keyname3 ? root.port.keyname3 : ""
            centerLabel: root.port.keycodename3 >= 0 ? root.port.keycodename3 : ""
            triggered: controller.joyRight
        }

        //
        // Row 3: . / Down / .
        //

        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }
        JoystickRecordButton {

            nr: 1
            bottomLabel: root.port.keyname1 ? root.port.keyname1 : ""
            centerLabel: root.port.keycodename1 >= 0 ? root.port.keycodename1 : ""
            triggered: controller.joyDown
        }
        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }

        // Vertical space
        Item {
            Layout.preferredHeight: 40
            Layout.columnSpan: 3
        }

        //
        // Row 3: . / Fire / .
        //

        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }

        JoystickRecordButton {

            nr: 4
            bottomLabel: root.port.keyname4 ? root.port.keyname4 : ""
            centerLabel: root.port.keycodename4 >= 0 ? root.port.keycodename4 : ""
            triggered: controller.joyFire
        }

        Item { Layout.preferredWidth: 40; Layout.preferredHeight: 40 }
    }
}