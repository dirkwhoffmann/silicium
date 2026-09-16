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

// The DMA Debugger box that used to live in SiAmBusPanel.qml, paired with a
// live preview -- same split as SiC64BusPanel.qml's "DMA Channels" +
// "Preview" boxes, including the same "Show as overlay" toggle: DmaDebugger
// always paints its raw visualization into its own texture (PixelEngine::
// dmaTexture, mirrored here by SiAmDmaView) whenever DMA_DEBUG_ENABLE is on,
// and only additionally blends it into the real picture when
// DMA_DEBUG_OVERLAY is also on -- so the preview works independently of
// whether the live display is affected.
SiAmInspectorWindow {

    id: root

    title: qsTr("Layers Inspector")
    currentController: controller.layersController

    readonly property var cc: controller.configController
    readonly property int tab: 21
    readonly property int tabtab: 42

    component ChannelRow: RowLayout {

        id: chRow

        required property string label
        property bool on: false
        property color swatch: "black"

        signal toggled(bool value)
        signal colorPicked(color value)

        Layout.fillWidth: true
        spacing: Style.mediumSpacing

        SiCheckBoxControl {

            Layout.fillWidth: true
            indent: tab
            enabled: root.cc.DMA_DEBUG_ENABLE
            checked: chRow.on
            onClicked: chRow.toggled(checked)
            r: chRow.label
        }

        HSpacer { }

        SiColorWell {

            value: chRow.swatch
            onPicked: (value) => chRow.colorPicked(value)
        }
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // DMA Debugger
        //

        SiBox {

            title: qsTr("DMA Channels")
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            SiCheckBoxControl {

                checked: cc.DMA_DEBUG_ENABLE
                onClicked: cc.DMA_DEBUG_ENABLE = checked
                r: qsTr("DMA Debugger")
            }

            ChannelRow {

                label: qsTr("Copper DMA")
                on: cc.DMA_DEBUG_CHANNEL0; swatch: cc.DMA_DEBUG_COLOR0
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL0 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR0 = value
            }

            ChannelRow {

                label: qsTr("Blitter DMA")
                on: cc.DMA_DEBUG_CHANNEL1; swatch: cc.DMA_DEBUG_COLOR1
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL1 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR1 = value
            }

            ChannelRow {

                label: qsTr("Disk DMA")
                on: cc.DMA_DEBUG_CHANNEL2; swatch: cc.DMA_DEBUG_COLOR2
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL2 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR2 = value
            }

            ChannelRow {

                label: qsTr("Audio DMA")
                on: cc.DMA_DEBUG_CHANNEL3; swatch: cc.DMA_DEBUG_COLOR3
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL3 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR3 = value
            }

            ChannelRow {

                label: qsTr("Sprite DMA")
                on: cc.DMA_DEBUG_CHANNEL4; swatch: cc.DMA_DEBUG_COLOR4
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL4 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR4 = value
            }

            ChannelRow {

                label: qsTr("Bitplane DMA")
                on: cc.DMA_DEBUG_CHANNEL5; swatch: cc.DMA_DEBUG_COLOR5
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL5 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR5 = value
            }

            ChannelRow {

                label: qsTr("CPU DMA")
                on: cc.DMA_DEBUG_CHANNEL6; swatch: cc.DMA_DEBUG_COLOR6
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL6 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR6 = value
            }

            ChannelRow {

                label: qsTr("Memory Refresh DMA")
                on: cc.DMA_DEBUG_CHANNEL7; swatch: cc.DMA_DEBUG_COLOR7
                onToggled: (value) => cc.DMA_DEBUG_CHANNEL7 = value
                onColorPicked: (value) => cc.DMA_DEBUG_COLOR7 = value
            }

            VSpacer { size: Style.mediumSpacing }

            SiCheckBoxControl {

                indent: tab
                enabled: cc.DMA_DEBUG_ENABLE
                checked: cc.DMA_DEBUG_OVERLAY
                onClicked: cc.DMA_DEBUG_OVERLAY = checked
                r: qsTr("Show as overlay")
            }

            SiComboBoxControl {

                indent: tabtab
                Layout.fillWidth: true
                enabled: cc.DMA_DEBUG_ENABLE && cc.DMA_DEBUG_OVERLAY
                model: [qsTr("Foreground layer"), qsTr("Background layer"), qsTr("Mixed layers")]
                currentIndex: cc.DMA_DEBUG_MODE
                onCurrentIndexChanged: cc.DMA_DEBUG_MODE = currentIndex
            }

            SiSliderControl {

                enabled: cc.DMA_DEBUG_ENABLE && cc.DMA_DEBUG_OVERLAY
                Layout.fillWidth: true
                l: qsTr("Opacity")
                from: 0
                to: 255
                value: cc.DMA_DEBUG_OPACITY
                onMoved: (value) => cc.DMA_DEBUG_OPACITY = value
            }

            VSpacer { }
        }

        //
        // Live preview
        //

        SiBox {

            title: qsTr("Preview")
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: cc.DMA_DEBUG_ENABLE
                color: "black"
                border.width: 1
                border.color: Palette.surfaceBorder
                radius: Style.radius
                clip: true

                SiAmDmaView {

                    // Inset by the corner radius so the texture never
                    // reaches the rounded corners -- the black rectangle
                    // shows through there, blending with the view's own
                    // black background.
                    anchors.fill: parent
                    anchors.margins: Style.radius
                }
            }

            // Placeholder shown while the DMA debugger is off
            Item {

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !cc.DMA_DEBUG_ENABLE

                SiSymbol {

                    anchors.centerIn: parent
                    phosphor: "eye"
                    // Scales with the cell -- size the glyph in pixels directly.
                    width: Math.min(parent.width, parent.height) * 0.75
                    height: width
                    color: Palette.disabled
                }
            }
        }
    }
}
