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

// The X-Ray box that used to live in SiAmLogicAnalyzerPanel.qml, paired with a live
// preview -- same split as SiC64BusPanel.qml's "DMA Channels" + "Preview"
// boxes, including the same "Show as overlay" toggle: the X-Ray debugger
// always paints its raw visualization into its own texture (PixelEngine::
// xrayTexture, mirrored here by SiAmDmaView) whenever XRAY_MODE is not
// XRAY_NONE, and only additionally blends it into the real picture when
// XRAY_OVERLAY is also on -- so the preview works independently of whether
// the live display is affected.
SiAmInspectorWindow {

    id: root

    title: qsTr("Layers Inspector")
    currentController: controller.layersController

    readonly property var cc: controller.configController
    readonly property int tab: 21
    readonly property int tabtab: 42

    // Mirrors vamiga::XRayMode (see DmaDebuggerTypes.h)
    readonly property int xrayNone: 0
    readonly property int xrayDma: 1
    readonly property int xrayLayers: 2

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

    // A single bit of Opt.DENISE_HIDDEN_LAYERS, paired with the XRAY_COLORn
    // slot it shares with XRayMode::XRAY_DMA (see PixelEngine::hide for the
    // bit layout: sprites 0-7 in bits 0x01-0x80, playfield 1 in 0x100,
    // playfield 2 in 0x200).
    component LayerRow: ChannelRow {

        required property int bit

        on: (cc.DENISE_HIDDEN_LAYERS & bit) !== 0
        onToggled: (value) => cc.DENISE_HIDDEN_LAYERS = value ?
                       (cc.DENISE_HIDDEN_LAYERS | bit) :
                       (cc.DENISE_HIDDEN_LAYERS & ~bit)
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // X-Ray
        //

        SiBox {

            title: qsTr("X-Ray")
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            SiComboBoxControl {

                Layout.fillWidth: true
                model: [qsTr("Off"), qsTr("DMA Debugger"), qsTr("Layers")]
                currentIndex: cc.XRAY_MODE
                onCurrentIndexChanged: cc.XRAY_MODE = currentIndex
            }

            VSpacer { size: Style.mediumSpacing }

            //
            // DMA channels (only shown in DMA Debugger mode)
            //

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Copper DMA")
                on: cc.XRAY_DMA_CHANNEL0; swatch: cc.XRAY_COLOR0
                onToggled: (value) => cc.XRAY_DMA_CHANNEL0 = value
                onColorPicked: (value) => cc.XRAY_COLOR0 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Blitter DMA")
                on: cc.XRAY_DMA_CHANNEL1; swatch: cc.XRAY_COLOR1
                onToggled: (value) => cc.XRAY_DMA_CHANNEL1 = value
                onColorPicked: (value) => cc.XRAY_COLOR1 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Disk DMA")
                on: cc.XRAY_DMA_CHANNEL2; swatch: cc.XRAY_COLOR2
                onToggled: (value) => cc.XRAY_DMA_CHANNEL2 = value
                onColorPicked: (value) => cc.XRAY_COLOR2 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Audio DMA")
                on: cc.XRAY_DMA_CHANNEL3; swatch: cc.XRAY_COLOR3
                onToggled: (value) => cc.XRAY_DMA_CHANNEL3 = value
                onColorPicked: (value) => cc.XRAY_COLOR3 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Sprite DMA")
                on: cc.XRAY_DMA_CHANNEL4; swatch: cc.XRAY_COLOR4
                onToggled: (value) => cc.XRAY_DMA_CHANNEL4 = value
                onColorPicked: (value) => cc.XRAY_COLOR4 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Bitplane DMA")
                on: cc.XRAY_DMA_CHANNEL5; swatch: cc.XRAY_COLOR5
                onToggled: (value) => cc.XRAY_DMA_CHANNEL5 = value
                onColorPicked: (value) => cc.XRAY_COLOR5 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("CPU DMA")
                on: cc.XRAY_DMA_CHANNEL6; swatch: cc.XRAY_COLOR6
                onToggled: (value) => cc.XRAY_DMA_CHANNEL6 = value
                onColorPicked: (value) => cc.XRAY_COLOR6 = value
            }

            ChannelRow {

                visible: cc.XRAY_MODE === xrayDma
                label: qsTr("Memory Refresh DMA")
                on: cc.XRAY_DMA_CHANNEL7; swatch: cc.XRAY_COLOR7
                onToggled: (value) => cc.XRAY_DMA_CHANNEL7 = value
                onColorPicked: (value) => cc.XRAY_COLOR7 = value
            }

            //
            // Hidden layers (only shown in Layers mode) -- share the same
            // XRAY_COLORn palette as the DMA channels above.
            //

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 0"); bit: 0x01
                swatch: cc.XRAY_COLOR0
                onColorPicked: (value) => cc.XRAY_COLOR0 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 1"); bit: 0x02
                swatch: cc.XRAY_COLOR1
                onColorPicked: (value) => cc.XRAY_COLOR1 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 2"); bit: 0x04
                swatch: cc.XRAY_COLOR2
                onColorPicked: (value) => cc.XRAY_COLOR2 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 3"); bit: 0x08
                swatch: cc.XRAY_COLOR3
                onColorPicked: (value) => cc.XRAY_COLOR3 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 4"); bit: 0x10
                swatch: cc.XRAY_COLOR4
                onColorPicked: (value) => cc.XRAY_COLOR4 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 5"); bit: 0x20
                swatch: cc.XRAY_COLOR5
                onColorPicked: (value) => cc.XRAY_COLOR5 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 6"); bit: 0x40
                swatch: cc.XRAY_COLOR6
                onColorPicked: (value) => cc.XRAY_COLOR6 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Sprite 7"); bit: 0x80
                swatch: cc.XRAY_COLOR7
                onColorPicked: (value) => cc.XRAY_COLOR7 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Playfield 1"); bit: 0x100
                swatch: cc.XRAY_COLOR8
                onColorPicked: (value) => cc.XRAY_COLOR8 = value
            }

            LayerRow {
                visible: cc.XRAY_MODE === xrayLayers
                label: qsTr("Playfield 2"); bit: 0x200
                swatch: cc.XRAY_COLOR9
                onColorPicked: (value) => cc.XRAY_COLOR9 = value
            }

            VSpacer { size: Style.mediumSpacing }

            SiCheckBoxControl {

                indent: tab
                visible: cc.XRAY_MODE !== xrayNone
                checked: cc.XRAY_OVERLAY
                onClicked: cc.XRAY_OVERLAY = checked
                r: qsTr("Show as overlay")
            }

            SiComboBoxControl {

                indent: tabtab
                Layout.fillWidth: true
                visible: cc.XRAY_MODE === xrayDma
                enabled: cc.XRAY_OVERLAY
                model: [qsTr("Foreground layer"), qsTr("Background layer"), qsTr("Mixed layers")]
                currentIndex: cc.XRAY_OVERLAY_STYLE
                onCurrentIndexChanged: cc.XRAY_OVERLAY_STYLE = currentIndex
            }

            SiSliderControl {

                visible: cc.XRAY_MODE !== xrayNone
                indent: tabtab
                Layout.fillWidth: true
                l: qsTr("Opacity")
                from: 0
                to: 255
                value: cc.XRAY_OVERLAY_OPACITY
                onMoved: (value) => cc.XRAY_OVERLAY_OPACITY = value
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
                visible: cc.XRAY_MODE !== xrayNone
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

            // Placeholder shown while X-Ray is off
            Item {

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: cc.XRAY_MODE === xrayNone

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
