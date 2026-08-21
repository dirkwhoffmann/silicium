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

    title: qsTr("Bus Inspector")
    currentController: controller.busController

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
            enabled: root.cc.DMA_DEBUG_ENABLE
            indent: tab
            checked: chRow.on
            onClicked: chRow.toggled(checked)
            r: chRow.label
        }

        HSpacer {
        }

        SiColorWell {

            value: chRow.swatch
            onPicked: (value) => chRow.colorPicked(value)
        }
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // DMA channels (incl. overlay controls), Preview
        //

        RowLayout {

            id: content

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.largeSpacing

            SiBox {

                title: qsTr("DMA Channels")
                Layout.fillHeight: true
                Layout.preferredWidth: 280
                spacing: Style.tinySpacing

                SiCheckBoxControl {

                    checked: cc.DMA_DEBUG_ENABLE
                    onClicked: cc.DMA_DEBUG_ENABLE = checked
                    r: qsTr("DMA Debugger")
                }

                ChannelRow {

                    label: qsTr("Refresh cycles")
                    on: cc.DMA_DEBUG_CHANNEL0; swatch: cc.DMA_DEBUG_COLOR0
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL0 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR0 = value
                }

                ChannelRow {

                    label: qsTr("Idle reads")
                    on: cc.DMA_DEBUG_CHANNEL1; swatch: cc.DMA_DEBUG_COLOR1
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL1 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR1 = value
                }

                ChannelRow {

                    label: qsTr("Character accesses")
                    on: cc.DMA_DEBUG_CHANNEL2; swatch: cc.DMA_DEBUG_COLOR2
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL2 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR2 = value
                }

                ChannelRow {

                    label: qsTr("Graphics accesses")
                    on: cc.DMA_DEBUG_CHANNEL3; swatch: cc.DMA_DEBUG_COLOR3
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL3 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR3 = value
                }

                ChannelRow {

                    label: qsTr("Sprite-pointer accesses")
                    on: cc.DMA_DEBUG_CHANNEL4; swatch: cc.DMA_DEBUG_COLOR4
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL4 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR4 = value
                }

                ChannelRow {

                    label: qsTr("Sprite-data accesses")
                    on: cc.DMA_DEBUG_CHANNEL5; swatch: cc.DMA_DEBUG_COLOR5
                    onToggled: (value) => cc.DMA_DEBUG_CHANNEL5 = value
                    onColorPicked: (value) => cc.DMA_DEBUG_COLOR5 = value
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
                    indent: tabtab
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
            // Live DMA texture preview
            //

            SiBox {

                title: qsTr("Preview")
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 0
                // clip: true
                // spacing: Style.tinySpacing

                Rectangle {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: cc.DMA_DEBUG_ENABLE
                    color: "black"
                    border.width: 1
                    border.color: Palette.surfaceBorder
                    radius: Style.radius
                    clip: true

                    SiC64DmaView {

                        // Inset by the corner radius so the square texture
                        // never reaches the rounded corners -- the black
                        // rectangle shows through there, blending with the
                        // view's own black background.
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
                        phosphor: "island"
                        // Scales with the cell -- size the glyph in pixels directly.
                        width: Math.min(parent.width, parent.height) * 0.75
                        height: width
                        color: Palette.disabled
                    }
                }
            }
        }
    }
}
