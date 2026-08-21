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
import Silicium.Components
import Silicium.Controllers
import Silicium.Theme

SiC64InspectorWindow {

    id: root

    title: qsTr("SID Inspector")
    currentController: controller.sidController

    readonly property var sid: controller.sidController
    readonly property int numBase: (controller.format === 0 || controller.format === 1) ? 16 : 10
    readonly property bool numPadded: controller.format === 1 || controller.format === 3

    // Shared width for every SiBox
    readonly property real columnWidth: Math.max(260,
        (scrollView.availableWidth - Style.largeSpacing * 2) / 3)

    component SiByteViewControl: SiNumberViewControl {

        size: Size.small
        font.weight: 500
        controlWidth: 32
        bits: 8
        base: root.numBase
        padded: root.numPadded
    }

    // Read-only, combo-box-styled summary of a set of mutually-combinable
    // flags (e.g. the waveform or filter-type bits) -- joins the active
    // flag names with "+", or shows "None" when nothing is set.
    function flagSummary(flags) {

        var parts = []
        for (var i = 0; i < flags.length; i++) {
            if (flags[i][0]) parts.push(flags[i][1])
        }
        return parts.length ? parts.join("+") : qsTr("None")
    }

    // One SID voice: waveform readout, frequency/pulse width, ADSR envelope
    // and the gate/sync/ring/test control bits.
    component Voice: SiBox {

        id: voiceBox

        property var v: ({})
        readonly property int lwidth: 60
        readonly property string waveformText: root.flagSummary([
            [v.wavTriangle, qsTr("Triangle")],
            [v.wavSawtooth, qsTr("Sawtooth")],
            [v.wavPulse, qsTr("Pulse")],
            [v.wavNoise, qsTr("Noise")]
        ])

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        SiTextControl {

            size: Size.small
            l: qsTr("Waveform:")
            lwidth: voiceBox.lwidth
            text: voiceBox.waveformText
        }

        RowLayout {

            Layout.fillWidth: true

            SiByteViewControl {

                l: qsTr("Frequency:")
                lwidth: voiceBox.lwidth
                bits: 16
                value: voiceBox.v.frequency
            }

            HSpacer { }

            SiByteViewControl {

                l: qsTr("Width:")
                // lwidth: 80
                bits: 12
                value: voiceBox.v.pulseWidth
            }
        }

        SiControl {

            size: Size.small
            l: qsTr("ADSR:")
            lwidth: voiceBox.lwidth
            hasFlexControl: false

            control: [

                RowLayout {

                    spacing: Style.smallSpacing

                    SiByteViewControl { bits: 4; value: voiceBox.v.attackRate }
                    SiText { text: "-"; Layout.leftMargin: 1 }
                    SiByteViewControl { bits: 4; value: voiceBox.v.decayRate }
                    SiText { text: "-"; Layout.leftMargin: 1 }
                    SiByteViewControl { bits: 4; value: voiceBox.v.sustainRate }
                    SiText { text: "-"; Layout.leftMargin: 1 }
                    SiByteViewControl { bits: 4; value: voiceBox.v.releaseRate }
                }
            ]
        }

        SiCheckBoxControl {

            size: Size.small
            indent: voiceBox.lwidth
            checked: voiceBox.v.test
            r: qsTr("Test")

            SiCheckBoxControl { size: Size.small; checked: voiceBox.v.gate; r: qsTr("Gate") }
            SiCheckBoxControl { size: Size.small; checked: voiceBox.v.sync; r: qsTr("Sync") }
            SiCheckBoxControl { size: Size.small; checked: voiceBox.v.ring; r: qsTr("Ring") }
        }

        VSpacer { }
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Top row
        //

        RowLayout {

            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SiSegmentedControl {
                model: ["SID 1", "SID 2", "SID 3", "SID 4"]
                currentIndex: sid.selectedSID
                onActivated: (index) => sid.selectedSID = index
            }

            Item { Layout.fillWidth: true }
        }

        //
        // Content area
        //

        ScrollView {

            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            contentWidth: content.implicitWidth

            GridLayout {

                id: content

                columns: 3
                columnSpacing: Style.largeSpacing
                rowSpacing: Style.largeSpacing

                //
                // Voices
                //

                Repeater {

                    model: sid.voices

                    delegate: Voice {

                        required property var modelData
                        required property int index

                        title: qsTr("Voice %1").arg(index + 1)
                        v: modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.columnWidth
                    }
                }

                //
                // Volume/pots/filter, Audio buffer
                //

                SiBox {

                    id: mixerBox

                    readonly property int lwidth: 60

                    title: qsTr("Volume, Potentiometer, Audio Filter")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: Style.mediumSpacing

                    RowLayout {

                        Layout.fillWidth: true
                        spacing: Style.tinySpacing

                        SiByteViewControl {

                            l: qsTr("Volume:")
                            lwidth: mixerBox.lwidth
                            value: sid.volume
                        }

                        HSpacer { }

                        SiByteViewControl {

                            l: qsTr("PotX:")
                            value: sid.volume
                        }

                        HSpacer { }

                        SiByteViewControl {

                            l: qsTr("PotY:")
                            value: sid.potY
                        }
                    }

                    SiTextControl {

                        size: Size.small
                        l: qsTr("Filter type:")
                        lwidth: mixerBox.lwidth
                        text: root.flagSummary([
                            [sid.filterLowPass, qsTr("Low")],
                            [sid.filterBandPass, qsTr("Band")],
                            [sid.filterHighPass, qsTr("High")]
                        ])
                    }

                    SiCheckBoxControl {

                        size: Size.small
                        lwidth: mixerBox.lwidth
                        l: qsTr("Apply to:")
                        checked: sid.filter1
                        r: "1"

                        SiCheckBoxControl { size: Size.small; checked: sid.filter2; r: "2" }
                        SiCheckBoxControl { size: Size.small; checked: sid.filter3; r: "3" }
                    }

                    RowLayout {

                        SiByteViewControl {

                            size: Size.small
                            lwidth: mixerBox.lwidth
                            l: qsTr("Cutoff:")
                            bits: 12
                            value: sid.filterCutoff
                        }

                        HSpacer { }

                        SiByteViewControl {

                            size: Size.small
                            l: qsTr("Resonance:")
                            bits: 4
                            value: sid.filterResonance
                        }
                    }

                    VSpacer { }
                }

                SiBox {

                    id: waveformBox
                    title: qsTr("Waveform")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: Style.mediumSpacing

                    SiComboBoxControl {

                        l: "Show:"
                        model: [qsTr("Audio out"), qsTr("Selected SID")]
                        currentIndex: sid.waveformSource
                        onCurrentIndexChanged: sid.waveformSource = currentIndex
                    }

                    Rectangle {

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 100
                        color: Palette.background
                        border.color: Palette.surface
                        border.width: 1
                        radius: Style.radius
                        clip: true

                        SiC64Waveform {

                            anchors.fill: parent
                            anchors.margins: 1
                            // -1 draws the combined buffer; otherwise the selected SID
                            sid: root.sid.waveformSource === 1 ? root.sid.selectedSID : -1
                        }
                    }
                }

                SiBox {

                    id: audioBox
                    title: qsTr("Audio Buffer")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.columnWidth
                    spacing: Style.mediumSpacing

                    SiProgressBarControl {

                        size: Size.small
                        l: "Fill level:"
                        lwidth: 60
                        rwidth: 32
                        from: 0
                        to: 100
                        r: sid.audioFillText
                        value: sid.audioFill
                    }

                    SiLabel {

                        size: Size.small
                        leftPadding: 60
                        text: qsTr("%1 underflows").arg(sid.underflows)
                    }

                    SiLabel {

                        size: Size.small
                        leftPadding: 60
                        text: qsTr("%1 overflows").arg(sid.overflows)
                    }

                    VSpacer { }
                }
            }
        }
    }
}
