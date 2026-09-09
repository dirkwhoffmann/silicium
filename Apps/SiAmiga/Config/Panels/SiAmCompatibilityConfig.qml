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

SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 70
    readonly property int sectionWidth: 320

    // DiskController::checkOption only accepts -1, 1, 2, 4, 8 for DC_SPEED
    // (-1 = as fast as possible, 1 = real disk speed, 2/4/8 = that many
    // times faster) -- see DiskController.cpp.
    readonly property var driveSpeeds: [-1, 1, 2, 4, 8]
    readonly property var driveSpeedNames: ["Turbo", "Original", "2x", "4x", "8x"]

    // Configuration.swift's todBug/eClockSyncing wrappers read CiaA and
    // write both chips at once -- see the class comment.
    function setCiaTodBug(v) { config.CIA_A_TODBUG = v ? 1 : 0; config.CIA_B_TODBUG = v ? 1 : 0 }
    function setCiaEClockSyncing(v) { config.CIA_A_ECLOCK_SYNCING = v; config.CIA_B_ECLOCK_SYNCING = v }

    toolbar: ConfigToolbar {

        heading: "Compatibility Settings"

        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreCompatibilityDefaults()
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
        // Floppy Drives
        //

        ConfigSection {

            header: "FLOPPY DRIVES"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "Speed:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: root.driveSpeedNames
                currentIndex: root.driveSpeeds.indexOf(config.DC_SPEED)
                onCurrentIndexChanged: config.DC_SPEED = root.driveSpeeds[currentIndex]
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                r: "Emulate mechanical delays"
                checked: config.DRIVE_MECHANICS
                onClicked: config.DRIVE_MECHANICS = checked
            }

            SiCheckBoxControl {

                l: "Piracy:"
                lwidth: root.labelWidth
                r: "Ignore writes to DSKSYNC"
                checked: config.DC_LOCK_DSKSYNC
                onClicked: config.DC_LOCK_DSKSYNC = checked
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                r: "Always find a SYNC mark"
                checked: config.DC_AUTO_DSKSYNC
                onClicked: config.DC_AUTO_DSKSYNC = checked
            }
        }

        //
        // Chipset Features
        //

        ConfigSection {

            header: "CHIPSET FEATURES"
            size: root.sectionWidth

            SiCheckBoxControl {

                r: "Emulate Slow Ram mirror"
                checked: config.MEM_SLOW_RAM_MIRROR
                onClicked: config.MEM_SLOW_RAM_MIRROR = checked
            }

            SiCheckBoxControl {

                r: "Emulate TOD bug"
                checked: config.CIA_A_TODBUG !== 0
                onClicked: root.setCiaTodBug(checked)
            }

            SiCheckBoxControl {

                r: "Emulate dropped register writes"
                checked: config.AGNUS_PTR_DROPS
                onClicked: config.AGNUS_PTR_DROPS = checked
            }
        }

        //
        // Keyboard
        //

        ConfigSection {

            header: "KEYBOARD"
            size: root.sectionWidth

            SiCheckBoxControl {

                l: "Protocol:"
                lwidth: root.labelWidth
                r: "Transmit keycodes bit by bit"
                checked: config.KBD_ACCURACY
                onClicked: config.KBD_ACCURACY = checked
            }
        }

        //
        // Timing
        //

        ConfigSection {

            header: "TIMING"
            size: root.sectionWidth

            SiCheckBoxControl {

                r: "Sync CIA accesses with E-clock"
                checked: config.CIA_A_ECLOCK_SYNCING
                onClicked: root.setCiaEClockSyncing(checked)
            }

            SiCheckBoxControl {
                
                r: "Emulate Slow Ram bus delays"
                checked: config.MEM_SLOW_RAM_DELAY
                onClicked: config.MEM_SLOW_RAM_DELAY = checked
            }
        }

        //
        // Blitter Accuracy
        //

        ConfigSection {

            header: "BLITTER ACCURACY"
            size: root.sectionWidth

            // The tick numbers and the two descriptive labels need
            // independent vertical offsets (numbers at 0%/50%/100% of the
            // slider's travel, descriptions at 25%/75%, in between) -- a
            // GridLayout only has whole rows shared by every column, so it
            // can't shift one side against the other. Positioning both
            // sides directly off bltSlider.height instead can.
            RowLayout {

                Layout.fillWidth: true
                spacing: Style.smallSpacing

                Item {

                    Layout.preferredWidth: tick2.implicitWidth
                    Layout.preferredHeight: bltSlider.height
                    Layout.alignment: Qt.AlignVCenter

                    SiLabel { id: tick2; text: "2"; anchors.horizontalCenter: parent.horizontalCenter; y: 0 }
                    SiLabel { text: "1"; anchors.horizontalCenter: parent.horizontalCenter; y: (parent.height - height) / 2 }
                    SiLabel { text: "0"; anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - height }
                }

                SiSlider {

                    id: bltSlider
                    orientation: Qt.Vertical
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 60
                    from: 0
                    to: 2
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    value: config.BLITTER_ACCURACY
                    onMoved: config.BLITTER_ACCURACY = value
                }

                Item {

                    Layout.fillWidth: true
                    Layout.preferredHeight: bltSlider.height
                    Layout.alignment: Qt.AlignVCenter

                    SiLabel {
                        text: "Move data word by word"
                        y: bltSlider.height * 0.25 - height / 2
                        color: config.BLITTER_ACCURACY >= 2 ? Palette.primary : Palette.tertiary
                    }

                    SiLabel {
                        text: "Use up bus cycles"
                        y: bltSlider.height * 0.75 - height / 2
                        color: config.BLITTER_ACCURACY >= 1 ? Palette.primary : Palette.tertiary
                    }
                }
            }
        }

        //
        // Sprites
        //

        ConfigSection {

            header: "SPRITES"
            size: root.sectionWidth

            SiCheckBoxControl {
                r: "Detect Sprite-Sprite collisions"
                checked: config.DENISE_CLX_SPR_SPR
                onClicked: config.DENISE_CLX_SPR_SPR = checked
            }

            SiCheckBoxControl {
                r: "Detect Sprite-Playfield collisions"
                checked: config.DENISE_CLX_SPR_PLF
                onClicked: config.DENISE_CLX_SPR_PLF = checked
            }

            SiCheckBoxControl {
                r: "Detect Playfield-Playfield collisions"
                checked: config.DENISE_CLX_PLF_PLF
                onClicked: config.DENISE_CLX_PLF_PLF = checked
            }
        }
    }
}
