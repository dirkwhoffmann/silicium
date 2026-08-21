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
import Silicium.Theme

Item {

    id: root

    required property PrefController controller
    readonly property var port: AppController.inputManager.port0Info
    readonly property real dx: controller.dx
    readonly property real dy: controller.dy

    // Currently recorded mouse button (if any)
    property int activeKey: -1

    readonly property real barLength: 40
    implicitWidth: theColumn.implicitWidth
    implicitHeight: theColumn.implicitHeight

    // Indicates whether the pointer is over the record buttons
    readonly property bool overButtons: buttonRowHover.hovered

    component MouseRecordButton: RecordButton {

        required property int nr

        // Live state of the physical mouse button this one stands for.
        required property bool buttonDown

        listening: activeKey === nr
        recordable: true
        triggered: buttonDown && !root.overButtons && activeKey === -1

        onClicked: {
            activeKey = activeKey === nr ? -1 : nr
        }

        onKeyRecorded: (key, virtualKey) => {
            controller.setMouseKeyset(nr, key, virtualKey)
            activeKey = -1
        }
    }

    ColumnLayout {

        id: theColumn
        spacing: 0

        RowLayout {

            id: buttons
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            Layout.bottomMargin: 16

            HoverHandler { id: buttonRowHover }

            //
            // Button
            //

            MouseRecordButton {

                nr: 0
                topLabel: "Left"
                bottomLabel: root.port.keyname0 ? root.port.keyname0 : ""
                centerLabel: root.port.virtualkey0 >= 0 ? root.port.virtualkey0 : ""
                buttonDown: controller.mbLeft
            }

            MouseRecordButton {

                nr: 1
                topLabel: "Middle"
                bottomLabel: root.port.keyname1 ? root.port.keyname1 : ""
                centerLabel: root.port.virtualkey1 >= 0 ? root.port.virtualkey1 : ""
                buttonDown: controller.mbMiddle
            }

            MouseRecordButton {

                nr: 2
                topLabel: "Right"
                bottomLabel: root.port.keyname2 ? root.port.keyname2 : ""
                centerLabel: root.port.virtualkey2 >= 0 ? root.port.virtualkey2 : ""
                buttonDown: controller.mbRight
            }
        }

        GridLayout {

            id: grid
            columns: 3
            rows: 3
            columnSpacing: 0
            rowSpacing: 0

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            Layout.bottomMargin: 16

            //
            // Row 1: . / Up / .
            //

            Item { }

            MouseAxis {

                id: upIndicator
                value: Math.max(-dy, 0)
                topLabel: dy.toFixed(2)
                orientation: -90
            }

            Item { }

            //
            // Row 2: Left / . / Right
            //

            MouseAxis {

                id: leftIndicator
                value: Math.max(-dx, 0)
                leftLabel: dx.toFixed(2)
                orientation: 180
            }

            Item {

                Layout.preferredWidth: 40
                Layout.preferredHeight: 40

                SiText {
                    anchors.centerIn: parent
                    text: "drag_pan"
                    font.family: Fonts.symbols
                    font.pixelSize: 32
                    color: Palette.tertiary
                }
            }

            MouseAxis {

                id: rightIndicator
                value: Math.max(dx, 0)
                rightLabel: dx.toFixed(2)
                orientation: 0
            }

            //
            // Row 3: . / Down / .
            //

            Item { }

            MouseAxis {

                id: downIndicator
                value: Math.max(dy, 0)
                bottomLabel: dy.toFixed(2)
                orientation: 90
            }

            Item { }
        }
    }
}