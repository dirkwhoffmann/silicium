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

SettingsPage {

    id: root

    required property C64Controller controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 84
    readonly property int comboWidth: 200
    readonly property int sectionWidth: 320

    readonly property var sidAddressModel: {
        var model = [];
        for (var addr = 0xD400; addr <= 0xD7E0; addr += 0x20) {
            model.push("$" + addr.toString(16).toUpperCase());
        }
        return model;
    }

    toolbar: ConfigToolbar {

        heading: "Hardware Settings"
        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreHardwareDefaults()
            }
        ]

        HSpacer { }

        ConfigLock {

            onClicked: controller.powerOnOrOff()
        }
    }

    ConfigGrid {

        id: grid

        //
        // VICII
        //

        ConfigSection {

            header: "VICII"
            size: root.sectionWidth

            SiComboBoxControl {

                lwidth: root.labelWidth
                l: "Revision:"
                model: ["MOS 6569 R1 (PAL)", "MOS 6569 R3", "MOS 8565", "MOS 6567  R56A (NTSC)", "MOS 6567", "MOS 8562"]

                SiHelpButton {
                    onClicked: root.help("vic-revision.md")
                }

                currentIndex: config.VICII_REVISION
                onCurrentIndexChanged: config.VICII_REVISION = currentIndex;
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                r: "Emulate grey dot bug"

                SiHelpButton {
                    onClicked: root.help("vic-gray-dot-bug.md")
                }
                HSpacer {}

                checked: config.VICII_GRAY_DOT_BUG
                onClicked: config.VICII_GRAY_DOT_BUG = checked;
            }

            // VSpacer {}
        }

        //
        // SID
        //

        ConfigSection {

            header: "SID"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Revision:"
                lwidth: root.labelWidth
                // Order must match SIDRevision (MOS_6581 = 0, MOS_8580 = 1),
                // since currentIndex is the raw enum value.
                model: ["MOS 6581", "MOS 8580"]
                // help.visible: true
                // onHelpClicked: root.help("sid-revision.md")

                SiHelpButton {
                    onClicked: root.help("sid-revision.md")
                }

                currentIndex: config.SID_REV
                onCurrentIndexChanged: config.SID_REV = currentIndex;
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "SID 2 at"

                SiComboBoxControl {

                    model: sidAddressModel
                    currentIndex: (config.SID_ADDRESS1 - 0xD400) / 0x20
                    onCurrentIndexChanged: config.SID_ADDRESS1 = currentIndex * 0x20 + 0xD400;

                    SiHelpButton {
                        onClicked: root.help("multi-sid.md")
                    }
                }
                checked: config.SID_ENABLE1
                onClicked: config.SID_ENABLE1 = checked;
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "SID 3 at"

                SiComboBoxControl {

                    model: sidAddressModel
                    currentIndex: (config.SID_ADDRESS2 - 0xD400) / 0x20
                    onCurrentIndexChanged: config.SID_ADDRESS2 = currentIndex * 0x20 + 0xD400;
                }
                // Add a spacer matching the size of the help button
                HSpacer { size: 20 }

                checked: config.SID_ENABLE2
                onClicked: config.SID_ENABLE2 = checked;

            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "SID 4 at"

                SiComboBoxControl {

                    model: sidAddressModel
                    currentIndex: (config.SID_ADDRESS3 - 0xD400) / 0x20
                    onCurrentIndexChanged: config.SID_ADDRESS3 = currentIndex * 0x20 + 0xD400;
                }
                // Add a spacer matching the size of the help button
                HSpacer { size: 20 }

                checked: config.SID_ENABLE3
                onClicked: config.SID_ENABLE3 = checked;
            }
        }

        //
        // CIAs
        //

        ConfigSection {

            header: "CIAs"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Revision:"
                lwidth: root.labelWidth
                model: ["MOS 6526", "MOS 8521"]

                SiHelpButton { onClicked: root.help("cia-revision.md") }

                currentIndex: config.CIA_REVISION
                onCurrentIndexChanged: config.CIA_REVISION = currentIndex;
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                r: "Emulate timer B bug"

                SiHelpButton { onClicked: root.help("cia-timer-b-bug.md") }
                HSpacer {}

                checked: config.CIA_TIMER_B_BUG
                onClicked: config.CIA_TIMER_B_BUG = checked;
            }
        }

        //
        // Logic board
        //

        ConfigSection {

            header: "LOGIC BOARD"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Glue Logic:"
                lwidth: root.labelWidth
                model: ["Discrete", "Custom IC"]

                SiHelpButton {
                    onClicked: root.help("glue-logic.md")
                }

                currentIndex: config.GLUE_LOGIC
                onCurrentIndexChanged: config.GLUE_LOGIC = currentIndex;
            }
        }

        //
        // Power supply
        //

        ConfigSection {

            header: "POWER SUPPLY"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Frequency:"
                lwidth: root.labelWidth
                model: ["50Hz stable", "50Hz unstable", "60Hz stable", "60Hz unstable"]

                SiHelpButton {
                    onClicked: root.help("power-supply.md")
                }

                currentIndex: config.POWER_GRID
                onCurrentIndexChanged: config.POWER_GRID = currentIndex;
            }
        }

        //
        // Power up
        //

        ConfigSection {

            header: "POWER UP"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "RAM pattern:"
                lwidth: root.labelWidth
                model: ["VICE", "CSS", "Zeroes", "Ones", "Random"]

                SiHelpButton {
                    onClicked: root.help("ram-pattern.md")
                }

                currentIndex: config.MEM_INIT_PATTERN
                onCurrentIndexChanged: config.MEM_INIT_PATTERN = currentIndex;
            }
        }
    }
}
