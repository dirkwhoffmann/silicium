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

// Port of SiC64DevPanel.qml: a draggable, semi-transparent debug overlay
// shown over the canvas while Preferences.developerMode and
// SiAmController.debugPanel are both on (see SiAmWindow.qml). SiC64's
// "Input" category reads dx/dy/mbLeft/mbMiddle/mbRight/joyUp/joyDown/
// joyLeft/joyRight/joyFire straight off C64Controller, which tracks them by
// overriding InputManagerDelegate's mouseDxDy()/mouseButton()/
// joystickMotionEvent(). SiAmController doesn't override any of those yet --
// mouse/joystick passthrough to the emulated Amiga hasn't been built, the
// same gap noted in SiAmKeyboardController for the physical keyboard -- so
// this panel's Input category is trimmed to the one thing that already
// works identically on both apps: AppController.inputManager's raw
// qKey/pKey/sKey/mods readout (InputManager itself, not a per-app
// controller, tracks those). The dx/dy/button/joystick rows return once
// SiAmController grows the same InputManagerDelegate overrides.
Rectangle {

    id: root

    required property SiAmController controller

    property real startX: 0
    property real startY: 0

    x: 0
    y: 0

    color: "#DD000000"
    radius: Style.radius

    border.width: 1
    border.color: "#40FFFFFF"

    width: 320
    height: content.implicitHeight + 2 * Style.largeSpacing

    //
    // Dragging
    //

    MouseArea {

        id: dragArea
        anchors.fill: parent
    }

    Connections {

        target: dragArea

        function onPressed(mouse) {

            startX = mouse.x
            startY = mouse.y
        }

        function onPositionChanged(mouse) {

            if (dragArea.pressed) {

                /* Keep the whole panel inside its parent: the lower bound holds
                 * the left and top edges in, the upper bound the right and
                 * bottom ones. Clamping the limits at zero matters when the
                 * parent is smaller than the panel -- a negative limit would
                 * otherwise fight the lower bound and pull the panel off the
                 * opposite side.
                 */
                const maxX = Math.max(0.0, root.parent.width - root.width)
                const maxY = Math.max(0.0, root.parent.height - root.height)

                root.x = Math.min(maxX, Math.max(0.0, root.x + mouse.x - startX))
                root.y = Math.min(maxY, Math.max(0.0, root.y + mouse.y - startY))
            }
        }
    }

    //
    // Components
    //

    component KeyLabel: SiText {

        color: "white"
        font.bold: true
        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight
    }

    component ValueLabel: SiText {

        color: "white"
        font.bold: true
    }

    component KeyValue: RowLayout {

        property alias key: keyLabel.text
        property alias value: valueLabel.text

        spacing: Style.smallSpacing

        KeyLabel {
            id: keyLabel
            Layout.preferredWidth: 100
        }
        SiText {
            text: ":"
        }
        ValueLabel {
            id: valueLabel
            Layout.fillWidth: true
        }
    }


    //
    // Content
    //

    ColumnLayout {

        id: content

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.leftMargin: Style.largeSpacing
        anchors.topMargin: Style.largeSpacing
        anchors.rightMargin: Style.largeSpacing

        //
        // Category selector
        //

        RowLayout {

            Layout.fillWidth: true
            Layout.bottomMargin: Style.largeSpacing

            KeyLabel {
                id: keyLabel
                text: "Category"
                Layout.preferredWidth: 100
            }

            SiText {
                text: ":"
            }

            SiComboBoxControl {

                id: categoryCombo
                Layout.fillWidth: true
                focusable: Qt.NoFocus
                model: ["Input", "Window"]
            }
        }

        //
        // Input
        //

        ColumnLayout {

            width: parent.width
            visible: categoryCombo.currentText === "Input"

            KeyValue {
                key: "qKey"
                value: AppController.inputManager.qKey
            }

            KeyValue {
                key: "pKey"
                value: AppController.inputManager.pKey
            }

            KeyValue {
                key: "sKey"
                value: AppController.inputManager.sKey
            }

            KeyValue {
                key: "Modifiers"
                value: "0b" + AppController.inputManager.mods.toString(2).padStart(8, "0")
            }
        }

        //
        // Window
        //

        ColumnLayout {

            width: parent.width
            visible: categoryCombo.currentText === "Window"

            KeyValue {
                key: "Size"
                value: {
                    const w = Window.window;
                    return w ? `${w.width} × ${w.height}` : "";
                }
            }
        }
    }
}
