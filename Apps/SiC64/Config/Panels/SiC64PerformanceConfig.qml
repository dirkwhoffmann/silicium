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
    readonly property int smallIndent: Style.largeSpacing
    readonly property int labelWidth: 100
    readonly property int comboWidth: 220
    readonly property int sectionWidth: 320

    toolbar: ConfigToolbar {

        heading: "Performance Settings"
        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restorePerformanceDefaults()
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
        // Warp
        //

        ConfigSection {

            header: "WARP MODE"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Activation:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["During Disk Activity", "Never", "Always"]

                currentIndex: config.C64_WARP_MODE
                onCurrentIndexChanged: config.C64_WARP_MODE = currentIndex;
            }

            SiNumberInputControl {

                l: "Boot for"
                r: "seconds in warp mode"
                lwidth: root.labelWidth
                controlWidth: 64

                intValue: config.C64_WARP_BOOT
                onValueEdited: (value) => config.C64_WARP_BOOT = value
            }
        }

        //
        // Speed boosters
        //

        ConfigSection {

            header: "SPEED BOOSTERS"
            size: root.sectionWidth

            SiCheckBoxControl {

                lwidth: smallIndent
                r: "Put drive 8 to sleep when not in use"

                checked: config.DRIVE8_POWER_SAVE
                onClicked: config.DRIVE8_POWER_SAVE = checked
            }

            SiCheckBoxControl {

                lwidth: smallIndent
                r: "Put drive 9 to sleep when not in use"

                checked: config.DRIVE9_POWER_SAVE
                onClicked: config.DRIVE9_POWER_SAVE = checked
            }

            SiCheckBoxControl {

                lwidth: smallIndent
                r: "Reduce frame rate in warp mode"

                checked: config.VICII_POWER_SAVE
                onClicked: config.VICII_POWER_SAVE = checked
            }

            SiCheckBoxControl {

                lwidth: smallIndent
                r: "Skip audio synthesis in warp mode"

                checked: config.SID_POWER_SAVE
                onClicked: config.SID_POWER_SAVE = checked
            }
        }

        //
        // Sprites
        //

        ConfigSection {

            header: "SPRITES"
            size: root.sectionWidth

            SiCheckBoxControl {

                r: "Detect sprite-sprite collisions"
                lwidth: smallIndent

                checked: config.VICII_SS_COLLISIONS
                onClicked: config.VICII_SS_COLLISIONS = checked
            }

            SiCheckBoxControl {
                r: "Detect sprite-background collisions"
                lwidth: smallIndent

                checked: config.VICII_SB_COLLISIONS
                onClicked: config.VICII_SB_COLLISIONS = checked
            }
        }

        //
        // Threading
        //

        ConfigSection {

            header: "THREADING"
            size: root.sectionWidth

            SiCheckBoxControl {

                l: "Sync mode:"
                r: "VSYNC"
                lwidth: root.labelWidth

                checked: config.C64_VSYNC
                onClicked: config.C64_VSYNC = checked
            }

            SiSliderControl {

                l: "Speed:"
                r: `${value} %`
                lwidth: root.labelWidth
                rwidth: 60
                from: 50
                to: 200
                stepSize: 5
                snapMode: Slider.SnapAlways

                value: config.C64_SPEED_BOOST
                onMoved: (value) => config.C64_SPEED_BOOST = value
            }

            SiSliderControl {

                l: value < 0 ? "Run behind:" : "Run ahead:"
                r: `${value} frames`
                lwidth: root.labelWidth
                rwidth: 60
                from: -7
                to: 7

                value: config.C64_RUN_AHEAD
                onMoved: (value) => config.C64_RUN_AHEAD = value
            }
        }
    }
}
