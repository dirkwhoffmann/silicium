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

    readonly property int labelWidth: 100
    readonly property int comboWidth: 220
    readonly property int sectionWidth: 320

    toolbar: ConfigToolbar {

        heading: "Devices Settings"

        menuContent: [

            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreDevicesDefaults()
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
        // Floppy drive 8
        //

        ConfigSection {

            id: drive8
            header: "FLOPPY DRIVE 8"
            size: root.sectionWidth
            checkable: true
            checked: config.DRIVE8_CONNECTED
            onClicked: config.DRIVE8_CONNECTED = checked;

            SiComboBoxControl {

                id: autoConfig8
                l: "Config:"
                lwidth: root.labelWidth
                model: ["Derive from ROM", "Custom"]
                enabled: drive8.enabled && root.config.DRIVE8_CONNECTED
                currentIndex: root.config.DRIVE8_AUTO_CONFIG ? 0 : 1
                onCurrentIndexChanged: root.config.DRIVE8_AUTO_CONFIG = currentIndex === 0;
                HSpacer { size: 20 }
            }

            SiComboBoxControl {

                l: "Type:"
                lwidth: root.labelWidth
                model: ["Commodore 1541", "Commodore 1541C", "Commodore 1541 II"]
                enabled: autoConfig8.enabled && autoConfig8.currentIndex === 1
                currentIndex: root.config.DRIVE8_TYPE
                onCurrentIndexChanged: root.config.DRIVE8_TYPE = currentIndex;
                SiHelpButton { onClicked: root.help("vc1541-models.md") }
            }

            SiComboBoxControl {

                l: "Extra RAM:"
                lwidth: root.labelWidth
                // controlWidth: root.comboWidth
                model: ["None", "$8000 - $9FFF", "$6000 - $7FFF", "$4000 - $7FFF"]
                enabled: autoConfig8.enabled && autoConfig8.currentIndex === 1
                currentIndex: config.DRIVE8_RAM
                onCurrentIndexChanged: config.DRIVE8_RAM = currentIndex;
                SiHelpButton { onClicked: root.help("vc1541-ram.md") }
            }

            SiComboBoxControl {

                l: "Parallel Cable:"
                lwidth: root.labelWidth
                model: ["None", "Standard", "Dolphin"]
                enabled: autoConfig8.enabled && autoConfig8.currentIndex === 1
                currentIndex: config.DRIVE8_PARCABLE
                onCurrentIndexChanged: config.DRIVE8_PARCABLE = currentIndex;
                SiHelpButton { onClicked: root.help("vc1541-parallel-cable.md") }
            }
        }

        //
        // Floppy drive 9
        //

        ConfigSection {

            id: drive9
            header: "FLOPPY DRIVE 9"
            size: root.sectionWidth
            checkable: true
            checked: config.DRIVE9_CONNECTED
            onClicked: config.DRIVE9_CONNECTED = checked;

            SiComboBoxControl {

                id: autoConfig9
                l: "Config:"
                lwidth: root.labelWidth
                model: ["Derive from ROM", "Custom"]
                enabled: drive9.enabled && root.config.DRIVE9_CONNECTED
                currentIndex: root.config.DRIVE9_AUTO_CONFIG ? 0 : 1
                onCurrentIndexChanged: root.config.DRIVE9_AUTO_CONFIG = currentIndex === 0;
                HSpacer { size: 20 }
            }

            SiComboBoxControl {

                l: "Type:"
                lwidth: root.labelWidth
                // controlWidth: root.comboWidth
                model: ["Commodore 1541", "Commodore 1541C", "Commodore 1541 II"]
                enabled: autoConfig9.enabled && autoConfig9.currentIndex === 1
                currentIndex: root.config.DRIVE9_TYPE
                onCurrentIndexChanged: root.config.DRIVE9_TYPE = currentIndex;
                SiHelpButton { onClicked: root.help("vc1541-models.md") }
            }

            SiComboBoxControl {

                l: "Extra RAM:"
                lwidth: root.labelWidth
                // controlWidth: root.comboWidth
                model: ["None", "$8000 - $9FFF", "$6000 - $7FFF", "$4000 - $7FFF"]
                enabled: autoConfig9.enabled && autoConfig9.currentIndex === 1
                SiHelpButton { onClicked: root.help("vc1541-ram.md") }
                currentIndex: config.DRIVE9_RAM
                onCurrentIndexChanged: config.DRIVE9_RAM = currentIndex;
            }

            SiComboBoxControl {

                l: "Parallel Cable:"
                lwidth: root.labelWidth
                // controlWidth: root.comboWidth
                model: ["None", "Standard", "Dolphin"]
                enabled: autoConfig9.enabled && autoConfig9.currentIndex === 1
                SiHelpButton { onClicked: root.help("vc1541-parallel-cable.md") }
                currentIndex: config.DRIVE9_PARCABLE
                onCurrentIndexChanged: config.DRIVE9_PARCABLE = currentIndex;
            }
        }

        //
        // Datasette
        //

        ConfigSection {

            header: "DATASETTE"
            size: root.sectionWidth
            checkable: true

            checked: config.DAT_CONNECT
            onClicked: config.DAT_CONNECT = checked;

            SiComboBoxControl {

                l: "Type:"
                lwidth: root.labelWidth
                model: ["Commodore 1530"]

                SiHelpButton {
                    onClicked: root.help("datasette.md")
                }

                currentIndex: config.DAT_MODEL
                onCurrentIndexChanged: config.DAT_MODEL = currentIndex;
            }
        }

        //
        // Mouse
        //

        ConfigSection {

            header: "MOUSE"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Type:"
                lwidth: root.labelWidth
                model: ["Commodore 1350", "Commodore 1351", "Neos", "Paddle (POTX)", "Paddle (POTY)", "Paddle (POTX + POTY)"]
                SiHelpButton { onClicked: root.help("mouse.md") }
                currentIndex: config.MOUSE_MODEL
                onCurrentIndexChanged: config.MOUSE_MODEL = currentIndex;
            }
        }

        //
        // Joystick
        //

        ConfigSection {

            header: "JOYSTICK"
            size: root.sectionWidth

            SiCheckBoxControl {

                l: "Auto-fire:"
                lwidth: root.labelWidth
                Layout.fillWidth: true

                checked: config.AUTOFIRE
                onClicked: config.AUTOFIRE = checked;

                SiSliderControl {

                    l: "Fast"
                    r: "Slow"
                    // lwidth: 32
                    // rwidth: 32

                    from: 1
                    to: 25

                    value: config.AUTOFIRE_DELAY
                    onMoved: (value) => config.AUTOFIRE_DELAY = value
                }
            }

            SiCheckBoxControl {

                l: "Burst mode:"
                lwidth: root.labelWidth

                checked: config.AUTOFIRE_BURSTS
                onClicked: config.AUTOFIRE_BURSTS = checked;

                SiNumberInputControl {

                    l: "Fire"
                    r: "bullets per burst"
                    controlWidth: 48

                    intValue: config.AUTOFIRE_BULLETS
                    onValueEdited: (value) => config.AUTOFIRE_BULLETS = value
                }
            }
        }
    }
}
