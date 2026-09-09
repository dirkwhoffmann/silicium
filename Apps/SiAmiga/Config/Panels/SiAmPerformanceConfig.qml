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

    readonly property int labelWidth: 100
    readonly property int sectionWidth: 320

    // Configuration.swift's ciaIdleSleep wrapper reads/writes both chips at
    // once -- see the class comment.
    function setCiaIdleSleep(v) { config.CIA_A_IDLE_SLEEP = v; config.CIA_B_IDLE_SLEEP = v }

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
        // Warp Mode
        //

        ConfigSection {

            header: "WARP MODE"
            size: root.sectionWidth

            SiComboBoxControl {
                l: "Activation:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: ["During disk activity", "Never", "Always"]
                currentIndex: config.AMIGA_WARP_MODE
                onCurrentIndexChanged: config.AMIGA_WARP_MODE = currentIndex
            }

            SiNumberInputControl {
                l: "Boot for"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "seconds in warp mode."
                controlWidth: 48
                intValue: config.AMIGA_WARP_BOOT
                onValueEdited: (value) => config.AMIGA_WARP_BOOT = value
            }
        }

        //
        // Speed Boosters
        //

        ConfigSection {

            header: "SPEED BOOSTERS"
            size: root.sectionWidth

            SiCheckBoxControl {
                r: "Put idle CIAs to sleep"
                checked: config.CIA_A_IDLE_SLEEP
                onClicked: root.setCiaIdleSleep(checked)
            }

            SiCheckBoxControl {
                r: "Put idle audio backend to sleep"
                checked: config.AUD_FASTPATH
                onClicked: config.AUD_FASTPATH = checked
            }

            SiCheckBoxControl {
                r: "Reduce frame rate in warp mode"
                checked: config.DENISE_FRAME_SKIPPING > 0
                onClicked: config.DENISE_FRAME_SKIPPING = checked ? 16 : 0
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
                lwidth: root.labelWidth
                r: "VSYNC"
                checked: config.AMIGA_VSYNC
                onClicked: config.AMIGA_VSYNC = checked
            }

            SiSliderControl {
                l: "Speed:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "%1 %".arg(config.AMIGA_SPEED_BOOST)
                enabled: !config.AMIGA_VSYNC
                from: 50
                to: 200
                stepSize: 5
                snapMode: Slider.SnapAlways
                value: config.AMIGA_SPEED_BOOST
                onMoved: (value) => config.AMIGA_SPEED_BOOST = value
            }

            SiSliderControl {
                l: config.AMIGA_RUN_AHEAD < 0 ? "Run behind:" : "Run ahead:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                r: "%1 frames".arg(Math.abs(config.AMIGA_RUN_AHEAD))
                from: -7
                to: 7
                value: config.AMIGA_RUN_AHEAD
                onMoved: (value) => config.AMIGA_RUN_AHEAD = value
            }
        }

        //
        // Compression
        //

        ConfigSection {

            header: "COMPRESSION"
            size: root.sectionWidth

            SiComboBoxControl {
                l: "Workspaces:"
                lwidth: root.labelWidth
                Layout.fillWidth: true
                model: ["Off", "ADZ / HDZ"]
                currentIndex: config.AMIGA_WS_COMPRESSION ? 1 : 0
                onCurrentIndexChanged: config.AMIGA_WS_COMPRESSION = currentIndex === 1
            }
        }
    }
}
