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

// Port of vAmiga's own GUI/Settings/ViewControllers/PerformanceSettings.swift.
// A plain two-column form (Warp mode/Threading on the left, Speed Boosters/
// Compression on the right), matching SiAmDevicesConfig.qml's flat layout
// rather than SiC64PerformanceConfig's ConfigSection cards.
//
// "Put idle CIAs to sleep" broadcasts CIA_A_IDLE_SLEEP/CIA_B_IDLE_SLEEP
// together, mirroring Configuration.swift's own ciaIdleSleep wrapper (get
// with no id, set with no id -- i.e. both chips at once). vAmiga's
// PerformanceSettingsViewController has no counterpart for
// SiAmConfigController's CIA_A/B_ECLOCK_SYNCING or DC_SPEED/DC_LOCK_DSKSYNC/
// DC_AUTO_DSKSYNC options, so those stay off this panel too.
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 160

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

    RowLayout {

        Layout.fillWidth: true
        spacing: Style.largeSpacing * 2

        //
        // Left column: Warp mode, Threading
        //

        ColumnLayout {

            Layout.fillWidth: true
            spacing: Style.smallSpacing

            SiText { text: "Warp mode"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiLabel { text: "Activation:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    model: ["During disk activity", "Never", "Always"]
                    currentIndex: config.AMIGA_WARP_MODE
                    onCurrentIndexChanged: config.AMIGA_WARP_MODE = currentIndex
                }

                SiLabel { text: "Boot in warp mode for"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiNumberInputControl {
                    Layout.fillWidth: true
                    r: "seconds"
                    controlWidth: 48
                    intValue: config.AMIGA_WARP_BOOT
                    onValueEdited: (value) => config.AMIGA_WARP_BOOT = value
                }
            }

            VSpacer { size: Style.largeSpacing * 2 }

            SiText { text: "Threading"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiLabel { text: "Sync mode:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiCheckBoxControl {
                    r: "VSYNC"
                    checked: config.AMIGA_VSYNC
                    onClicked: config.AMIGA_VSYNC = checked
                }

                SiLabel { text: "Speed:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing
                    SiSliderControl {
                        Layout.fillWidth: true
                        enabled: !config.AMIGA_VSYNC
                        from: 50
                        to: 200
                        stepSize: 5
                        snapMode: Slider.SnapAlways
                        value: config.AMIGA_SPEED_BOOST
                        onMoved: (value) => config.AMIGA_SPEED_BOOST = value
                    }
                    SiText { text: "%1 %".arg(config.AMIGA_SPEED_BOOST); color: config.AMIGA_VSYNC ? Palette.tertiary : Palette.primary }
                }

                SiLabel { text: config.AMIGA_RUN_AHEAD < 0 ? "Run behind:" : "Run ahead:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.smallSpacing
                    SiSliderControl {
                        Layout.fillWidth: true
                        from: -7
                        to: 7
                        value: config.AMIGA_RUN_AHEAD
                        onMoved: (value) => config.AMIGA_RUN_AHEAD = value
                    }
                    SiText { text: "%1 frames".arg(Math.abs(config.AMIGA_RUN_AHEAD)) }
                }
            }

            VSpacer { }
        }

        //
        // Right column: Speed Boosters, Compression
        //

        ColumnLayout {

            Layout.fillWidth: true
            spacing: Style.smallSpacing

            SiText { text: "Speed Boosters"; font.bold: true; font.pixelSize: Style.large }

            ColumnLayout {

                spacing: Style.mediumSpacing

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

            VSpacer { size: Style.largeSpacing * 2 }

            SiText { text: "Compression"; font.bold: true; font.pixelSize: Style.large }

            GridLayout {

                columns: 2
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.mediumSpacing

                SiLabel { text: "Workspaces:"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: root.labelWidth }
                SiComboBoxControl {
                    Layout.fillWidth: true
                    model: ["Off", "On"]
                    currentIndex: config.AMIGA_WS_COMPRESSION ? 1 : 0
                    onCurrentIndexChanged: config.AMIGA_WS_COMPRESSION = currentIndex === 1
                }
            }

            VSpacer { }
        }
    }
}
