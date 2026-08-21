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

        heading: "Audio Settings"
        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreAudioDefaults()
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
        // Audio In
        //

        ConfigSection {

            header: "AUDIO IN"
            size: root.sectionWidth
            implicitHeight: 180

            RowLayout {

                HSpacer {}

                AudioControl {

                    label: "Channel 1"
                    Layout.fillWidth: true

                    sliderValue: config.AUD_VOL0
                    onSliderMoved: (value) => config.AUD_VOL0 = Math.round(value)
                    knobValue: 100 - (config.AUD_PAN0 / 4)
                    onKnobMoved: (value) => config.AUD_PAN0 = Math.round(4 * (100 - value))
                }

                AudioControl {

                    label: "Channel 2"
                    Layout.fillWidth: true

                    sliderValue: config.AUD_VOL1
                    onSliderMoved: (value) => config.AUD_VOL1 = Math.round(value)
                    knobValue: 100 - (config.AUD_PAN1 / 4)
                    onKnobMoved: (value) => config.AUD_PAN1 = Math.round(4 * (100 - value))
                }

                AudioControl {

                    label: "Channel 3"
                    Layout.fillWidth: true

                    sliderValue: config.AUD_VOL2
                    onSliderMoved: (value) => config.AUD_VOL2 = Math.round(value)
                    knobValue: 100 - (config.AUD_PAN2 / 4)
                    onKnobMoved: (value) => config.AUD_PAN2 = Math.round(4 * (100 - value))
                }

                AudioControl {

                    label: "Channel 4"
                    Layout.fillWidth: true

                    sliderValue: config.AUD_VOL3
                    onSliderMoved: (value) => config.AUD_VOL3 = Math.round(value)
                    knobValue: 100 - (config.AUD_PAN3 / 4)
                    onKnobMoved: (value) => config.AUD_PAN3 = Math.round(4 * (100 - value))
                }

                HSpacer {}
            }
        }

        //
        // Audio Out
        //

        ConfigSection {

            header: "AUDIO OUT"
            size: root.sectionWidth
            implicitHeight: 180

            RowLayout {

                Layout.leftMargin: Style.largeSpacing
                Layout.rightMargin: Style.largeSpacing

                HSpacer {}

                AudioControl {

                    label: "Left"
                    Layout.fillWidth: true
                    knob: false

                    sliderValue: config.AUD_VOL_L
                    onSliderMoved: (value) => config.AUD_VOL_L = Math.round(value)
                }

                AudioControl {

                    label: "Right"
                    Layout.fillWidth: true
                    knob: false

                    sliderValue: config.AUD_VOL_R
                    onSliderMoved: (value) => config.AUD_VOL_R = Math.round(value)
                }

                HSpacer {}
            }
        }

        //
        // Drive Volumes
        //

        ConfigSection {

            header: "DRIVE VOLUMES"
            size: root.sectionWidth
            implicitHeight: 180

            RowLayout {

                Layout.leftMargin: Style.largeSpacing
                Layout.rightMargin: Style.largeSpacing

                HSpacer {}

                AudioControl {

                    label: "Step"
                    Layout.fillWidth: true
                    knob: false

                    sliderValue: config.DRV_STEP_VOL
                    onSliderMoved: (value) => config.DRV_STEP_VOL = Math.round(value)
                }

                AudioControl {

                    label: "Insert"
                    Layout.fillWidth: true
                    knob: false

                    sliderValue: config.DRV_INSERT_VOL
                    onSliderMoved: (value) => config.DRV_INSERT_VOL = Math.round(value)
                }

                AudioControl {

                    label: "Eject"
                    Layout.fillWidth: true
                    knob: false

                    sliderValue: config.DRV_EJECT_VOL
                    onSliderMoved: (value) => config.DRV_EJECT_VOL = Math.round(value)
                }

                ColumnLayout {

                    Layout.fillWidth: true

                    AudioControl {

                        label: "Drive 8"
                        slider: false

                        knobValue: 100 - (config.DRIVE8_PAN / 4)
                        onKnobMoved: (value) => config.DRIVE8_PAN = Math.round(4 * (100 - value))
                    }

                    AudioControl {

                        label: "Drive 9"
                        slider: false

                        knobValue: 100 - (config.DRIVE9_PAN / 4)
                        onKnobMoved: (value) => config.DRIVE9_PAN = Math.round(4 * (100 - value))
                    }
                }

                HSpacer {}
            }
        }


        //
        // Audio Synthesis
        //

        ConfigSection {

            header: "AUDIO SYNTHESIS"
            size: root.sectionWidth

            SiComboBoxControl {

                l: "SID Engine:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["ReSID"]
                SiHelpButton { onClicked: root.help("sid-models.md") }
                currentIndex: config.SID_ENGINE
                onCurrentIndexChanged: config.SID_ENGINE = currentIndex
            }

            SiCheckBoxControl {

                lwidth: root.labelWidth
                r: "Audio Filter"
                checked: config.SID_FILTER
                onClicked: config.SID_FILTER = checked;
            }

            SiComboBoxControl {

                l: "Interpolation:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth
                model: ["Nearest", "Interpolate", "Resample"]
                SiHelpButton { onClicked: root.help("") }
                currentIndex: config.SID_SAMPLING
                onCurrentIndexChanged: config.SID_SAMPLING = currentIndex
            }
        }
    }
}
