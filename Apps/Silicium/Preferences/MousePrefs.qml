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

/* The mouse page of the device preferences: controls on the left, a
 * frosted-glass properties panel on the right.
 */
RowLayout {

    id: root

    required property PrefController controller
    property Image backdrop: null
    property bool showEmulationKeys: false

    spacing: Style.mediumSpacing

    //
    // Controls
    //

    ColumnLayout {

        /* A nested layout takes its maximum width from its children, so a column
         * holding only centre-aligned, fixed-width items caps at its content
         * width -- and fillWidth cannot grow an item past its own maximum. That
         * is what collapsed this column when the fillWidth heading went away.
         * Lifting the cap makes the two columns split the row evenly whatever
         * they contain.
         */
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: Number.POSITIVE_INFINITY
        spacing: 0

        VSpacer { }

        MouseVisualizer {

            id: mouseVisualizer
            controller: root.controller
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Style.mediumSpacing
        }

        SiMinMaxSlider {

            Layout.alignment: Qt.AlignHCenter
            bottomText: "Sensitivity"
            topText: liveValue.toFixed(2)
            length: mouseVisualizer.width
            from: 0.5
            to: 1.5
            value: Preferences.mouseSensitivity
            stepSize: 0.1
            onMoved: (value) => Preferences.mouseSensitivity = value
        }

        VSpacer { }

        SiCheckBoxControl {

            r: "Disconnect emulation keys from keyboard"
            checked: Preferences.disconnectEmulationKeys
            onClicked: Preferences.disconnectEmulationKeys = !Preferences.disconnectEmulationKeys
        }
    }

    //
    // Info
    //

    ColumnLayout {

        // Even split, as on the left (see the note there for the maximumWidth).
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: Number.POSITIVE_INFINITY
        spacing: Style.tinySpacing

        Category {

            text: "PROPERTIES"
            Layout.topMargin: Style.mediumSpacing
            Layout.fillWidth: true
        }

        Pane {

            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: Style.mediumSpacing

            background: SiGlass {

                backdrop: root.backdrop
                tint: Qt.alpha(Palette.backgroundElevated, 0.25)
                radius: Style.radius
            }

            ColumnLayout {

                id: info
                readonly property var port: AppController.inputManager.port0Info

                anchors.fill: parent

                /*
                Category {
                    text: "PROPERTIES"
                    Layout.fillWidth: true
                    Layout.bottomMargin: Style.mediumSpacing
                }

                 */

                PrefKeyValue {
                    key: "Type:"
                    value: info?.port?.type
                }

                PrefKeyValue {
                    key: "Status:"
                    value: info?.port?.status
                }

                Category {
                    text: "EMULATION KEYS"
                    visible: root.showEmulationKeys
                    Layout.topMargin: Style.mediumSpacing
                    Layout.fillWidth: true
                    Layout.bottomMargin: Style.mediumSpacing
                }

                PrefKeyValue {
                    key: "Left button:"
                    visible: root.showEmulationKeys
                    value: info.port?.key0 ? `${info.port.virtualkey0} (${info.port.keyname0})` : "NOT SET"
                }
                PrefKeyValue {
                    key: "Middle button:"
                    visible: root.showEmulationKeys
                    value: info.port?.key1 ? `${info.port.virtualkey1} (${info.port.keyname1})` : "NOT SET"
                }
                PrefKeyValue {
                    key: "Right button:"
                    visible: root.showEmulationKeys
                    value: info.port?.key2 ? `${info.port.virtualkey2} (${info.port.keyname2})` : "NOT SET"
                }

                VSpacer { }
            }
        }
    }
}
