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

// Port of vAmiga's own GUI/Settings/ViewControllers/AudioSettings.swift.
// Shaped like SiC64AudioConfig.qml (In/Out/Drive Volumes/Synthesis sections)
// but the Amiga side differs where the hardware does:
//
//   - 4 audio channels in, not 3 SID voices -- straight port of that part.
//   - No SID engine/model to pick: Paula has one filter chain (AUD_FILTER_TYPE,
//     7 presets: None/A500/A1000/A1200/Low/LED/High) instead of a ReSID/
//     resampling-quality choice.
//   - Up to 4 floppy drives and 4 hard drives, not 2 -- SiAmConfigController
//     exposes their step/poll/insert/eject volumes and pan per-drive
//     (driveStepVolume(nr)/hdPan(nr)/...) rather than as one pair of C64
//     drive properties. The Step/Poll/Insert/Eject sliders here still act
//     as one shared control apiece (matching Configuration.swift's own
//     stepVolume/pollVolume/insertVolume/ejectVolume wrappers, which read
//     drive 0 and write every drive at once) -- only the per-drive pan
//     knobs are genuinely per-drive.
//   - A Sampling Method (None/Nearest/Linear) and an Adaptive Sample Rate
//     toggle, which the C64 side has no counterpart for.
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 100
    readonly property int comboWidth: 220
    readonly property int sectionWidth: 320

    // Configuration.swift's stepVolume/pollVolume/insertVolume/ejectVolume
    // wrappers write every relevant drive at once, not just one -- see the
    // class comment. Mirrored here since SiAmConfigController only exposes
    // the underlying per-drive accessors.
    function setAllDriveStepVolume(v) {
        for (let i = 0; i < 4; i++) config.setDriveStepVolume(i, v)
        for (let i = 0; i < 4; i++) config.setHdStepVolume(i, v)
    }
    function setAllDrivePollVolume(v) { for (let i = 0; i < 4; i++) config.setDrivePollVolume(i, v) }
    function setAllDriveInsertVolume(v) { for (let i = 0; i < 4; i++) config.setDriveInsertVolume(i, v) }
    function setAllDriveEjectVolume(v) { for (let i = 0; i < 4; i++) config.setDriveEjectVolume(i, v) }

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

                        sliderValue: config.AUD_VOLL
                        onSliderMoved: (value) => config.AUD_VOLL = Math.round(value)
                    }

                    AudioControl {

                        label: "Right"
                        Layout.fillWidth: true
                        knob: false

                        sliderValue: config.AUD_VOLR
                        onSliderMoved: (value) => config.AUD_VOLR = Math.round(value)
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
                implicitHeight: 320

                ColumnLayout {

                    Layout.fillWidth: true
                    spacing: Style.mediumSpacing

                    RowLayout {

                        Layout.leftMargin: Style.largeSpacing
                        Layout.rightMargin: Style.largeSpacing

                        HSpacer {}

                        AudioControl {

                            label: "Step"
                            Layout.fillWidth: true
                            knob: false

                            sliderValue: config.driveStepVolume(0)
                            onSliderMoved: (value) => root.setAllDriveStepVolume(Math.round(value))
                        }

                        AudioControl {

                            label: "Poll"
                            Layout.fillWidth: true
                            knob: false

                            sliderValue: config.drivePollVolume(0)
                            onSliderMoved: (value) => root.setAllDrivePollVolume(Math.round(value))
                        }

                        AudioControl {

                            label: "Insert"
                            Layout.fillWidth: true
                            knob: false

                            sliderValue: config.driveInsertVolume(0)
                            onSliderMoved: (value) => root.setAllDriveInsertVolume(Math.round(value))
                        }

                        AudioControl {

                            label: "Eject"
                            Layout.fillWidth: true
                            knob: false

                            sliderValue: config.driveEjectVolume(0)
                            onSliderMoved: (value) => root.setAllDriveEjectVolume(Math.round(value))
                        }

                        HSpacer {}
                    }

                    RowLayout {

                        Layout.fillWidth: true
                        Layout.leftMargin: Style.largeSpacing
                        Layout.rightMargin: Style.largeSpacing
                        spacing: Style.largeSpacing

                        ColumnLayout {

                            Layout.fillWidth: true

                            Repeater {

                                model: 4

                                AudioControl {

                                    required property int index
                                    label: "Df%1".arg(index)
                                    slider: false

                                    knobValue: 100 - (config.drivePan(index) / 4)
                                    onKnobMoved: (value) => config.setDrivePan(index, Math.round(4 * (100 - value)))
                                }
                            }
                        }

                        ColumnLayout {

                            Layout.fillWidth: true

                            Repeater {

                                model: 4

                                AudioControl {

                                    required property int index
                                    label: "Hd%1".arg(index)
                                    slider: false

                                    knobValue: 100 - (config.hdPan(index) / 4)
                                    onKnobMoved: (value) => config.setHdPan(index, Math.round(4 * (100 - value)))
                                }
                            }
                        }
                    }
                }
            }

            //
            // Audio Filter
            //

            ConfigSection {

                header: "AUDIO FILTER"
                size: root.sectionWidth

                SiComboBoxControl {

                    l: "Filter:"
                    lwidth: root.labelWidth
                    controlWidth: root.comboWidth
                    model: ["None", "A500", "A1000", "A1200", "Low", "LED", "High"]
                    currentIndex: config.AUD_FILTER_TYPE
                    onCurrentIndexChanged: config.AUD_FILTER_TYPE = currentIndex
                }
            }

            //
            // Sampler
            //

            ConfigSection {

                header: "SAMPLER"
                size: root.sectionWidth

                SiComboBoxControl {

                    id: samplingCombo
                    l: "Sampling:"
                    lwidth: root.labelWidth
                    controlWidth: root.comboWidth
                    model: ["Latest sample", "Nearest neighbor", "Linear interpolation"]
                    currentIndex: config.AUD_SAMPLING_METHOD
                    onCurrentIndexChanged: config.AUD_SAMPLING_METHOD = currentIndex

                    HoverHandler { id: samplingHover }
                    ToolTip.visible: samplingHover.hovered
                    ToolTip.delay: 500
                    ToolTip.text: samplingCombo.currentIndex === 0
                        ? "Selects the most recent sample from the ring buffer. Minimizes latency but may introduce jitter when the sample rate fluctuates."
                        : samplingCombo.currentIndex === 1
                        ? "Picks the sample closest to the target timestamp. Improves timing accuracy over the latest-sample method but may still have minor mismatches."
                        : "Computes a value between two neighboring samples for smoother output. Increases computation slightly but reduces artifacts and improves fidelity."
                }

                SiComboBoxControl {

                    l: "Sample rate:"
                    lwidth: root.labelWidth
                    controlWidth: root.comboWidth
                    model: ["Constant", "Adaptive (ASR)"]
                    currentIndex: config.AUD_ASR ? 1 : 0
                    onCurrentIndexChanged: config.AUD_ASR = currentIndex === 1

                    HoverHandler { id: asrHover }
                    ToolTip.visible: asrHover.hovered
                    ToolTip.delay: 500
                    ToolTip.text: config.AUD_ASR
                        ? "ASR (Adaptive Sample Rate) dynamically adjusts the sampling rate to maintain audio sync, preventing buffer underflows and overflows caused by drift between emulated and real-time playback rates."
                        : "Synthesizes audio at a constant sampling rate, ignoring drift between emulated and real-time playback rates. This may cause buffer underflows and overflows over time, leading to audio stutter or glitches."
                }

                RowLayout {

                    Layout.fillWidth: true
                    spacing: Style.smallSpacing

                    SiLabel { text: "Capacity:"; Layout.preferredWidth: root.labelWidth }

                    SiSliderControl {

                        Layout.preferredWidth: root.comboWidth
                        from: 512
                        to: 65536
                        value: config.AUD_BUFFER_SIZE
                        onMoved: (value) => config.AUD_BUFFER_SIZE = Math.round(value)
                    }

                    SiText { text: "%1 samples".arg(config.AUD_BUFFER_SIZE); color: Palette.secondary }
                }
            }
        }
}
