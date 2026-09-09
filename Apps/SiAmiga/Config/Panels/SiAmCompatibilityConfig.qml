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

// Port of vAmiga's own GUI/Settings/ViewControllers/CompatibilitySettings.swift.
// ConfigGrid/ConfigSection cards, matching SiAmHardwareConfig's/
// SiAmDevicesConfig's layout -- Floppy Drives, Chipset Features, Keyboard,
// Timing, Blitter Accuracy, Sprites, in that order so the row-major
// 2-column grid keeps Floppy Drives/Keyboard/Blitter Accuracy on the left
// and Chipset Features/Timing/Sprites on the right, the same grouping the
// Swift panel's own layout has.
//
// None of these options are gated behind ConfigLock/isPoweredOff -- unlike
// Agnus/Ram/RTC on the Hardware panel, none of DiskController/Blitter/
// CIA/Denise/Agnus's checkOption() implementations guard these particular
// options on isPoweredOff(), so nothing here needs 'locked'/'controlEnabled'.
//
// "Emulate TOD bug" and "Sync CIA accesses with E-clock" broadcast across
// both CIA chips at once, mirroring Configuration.swift's own todBug/
// eClockSyncing wrappers (get CiaA, set both) -- same pattern as
// SiAmPerformanceConfig's setCiaIdleSleep.
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

            header: "Floppy Drives"
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

            header: "Chipset Features"
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

            header: "Keyboard"
            size: root.sectionWidth

            SiCheckBoxControl {
                r: "Transmit keycodes bit by bit"
                checked: config.KBD_ACCURACY
                onClicked: config.KBD_ACCURACY = checked
            }
        }

        //
        // Timing
        //

        ConfigSection {

            header: "Timing"
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

            header: "Blitter Accuracy"
            size: root.sectionWidth

            GridLayout {

                Layout.fillWidth: true
                columns: 3
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiLabel { text: "2"; Layout.row: 0; Layout.column: 0; Layout.alignment: Qt.AlignHCenter }

                SiSlider {

                    id: bltSlider
                    orientation: Qt.Vertical
                    Layout.row: 0
                    Layout.column: 1
                    Layout.rowSpan: 3
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 90
                    from: 0
                    to: 2
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    value: config.BLITTER_ACCURACY
                    onMoved: config.BLITTER_ACCURACY = value
                }

                SiLabel { text: "1"; Layout.row: 1; Layout.column: 0; Layout.alignment: Qt.AlignHCenter }
                SiLabel {
                    text: "Move data word by word"
                    Layout.row: 1
                    Layout.column: 2
                    color: config.BLITTER_ACCURACY >= 1 ? Palette.primary : Palette.tertiary
                }

                SiLabel { text: "0"; Layout.row: 2; Layout.column: 0; Layout.alignment: Qt.AlignHCenter }
                SiLabel {
                    text: "Use up bus cycles"
                    Layout.row: 2
                    Layout.column: 2
                    color: config.BLITTER_ACCURACY >= 2 ? Palette.primary : Palette.tertiary
                }
            }
        }

        //
        // Sprites
        //

        ConfigSection {

            header: "Sprites"
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
