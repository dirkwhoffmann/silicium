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

// Port of vAmiga's own GUI/Inspector/BusPanel.swift + LogicView.swift. Two
// boxes, matching the Swift window: a "Logic Analyzer" box (the 228-cycle
// DMA timing-diagram grid -- SiAmLogicView, a QQuickPaintedItem port of
// LogicView.swift's drawHairlines/drawLabels/drawSignal -- plus its four
// probe selectors, a zoom slider and the Symbolic checkbox) and a "DMA
// Debugger" box (the eight visualize-channel checkboxes/colors plus the
// display-mode combo and opacity slider, straight off SiAmConfigController's
// DMA_DEBUG_* properties -- same shape as SiC64BusPanel.qml's own
// ChannelRow, just eight channels instead of six and no separate "show as
// overlay" toggle, since vAmiga has no DMA_DEBUG_OVERLAY option distinct
// from DMA_DEBUG_ENABLE).
Item {

    id: root

    required property SiAmController controller

    readonly property var bus: controller.busController
    readonly property var cc: controller.configController
    readonly property var ic: controller.inspectorController

    property real zoom: 1

    // probeLabel() is a plain Q_INVOKABLE (LA_PROBE/LA_ADDR live on
    // SiAmConfigController, read fresh on every call), so it carries no
    // property-change notification of its own to bind against. This counter
    // is bumped on every configChanged and referenced (via the comma
    // operator) from each ProbeSelector's button text, forcing that binding
    // to re-evaluate whenever a preset or custom address is applied.
    property int configVersion: 0
    Connections {
        target: cc
        function onConfigChanged() { root.configVersion++ }
    }

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
            checked: chRow.on
            onClicked: chRow.toggled(checked)
            r: chRow.label
        }

        SiColorWell {

            value: chRow.swatch
            onPicked: (value) => chRow.colorPicked(value)
        }
    }

    // One "Connect..." probe selector: a button showing the current
    // selection (probeLabel()) that opens a menu of presets, plus a small
    // text field for typing a custom hex address -- the two ways
    // BusPanel.swift's NSComboButton accepts input (menu pick or the
    // embedded free-text field).
    component ProbeSelector: RowLayout {

        id: sel

        required property int channel

        spacing: Style.smallSpacing

        SiLabel { text: qsTr("Channel %1:").arg(sel.channel); Layout.preferredWidth: 70 }

        Button {

            id: presetButton
            Layout.preferredWidth: 110
            text: (root.configVersion, root.bus.probeLabel(sel.channel))

            onClicked: presetMenu.popup()

            Menu {

                id: presetMenu

                Instantiator {

                    model: root.bus.presetModel()

                    delegate: Loader {

                        required property var modelData
                        required property int index

                        sourceComponent: modelData.separator ? separatorComp : itemComp

                        Component {
                            id: separatorComp
                            MenuSeparator { }
                        }

                        Component {
                            id: itemComp
                            MenuItem {
                                text: modelData.name
                                onTriggered: root.bus.selectPreset(sel.channel, index)
                            }
                        }
                    }

                    onObjectAdded: (index, object) => presetMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => presetMenu.removeItem(object)
                }
            }
        }

        TextField {

            Layout.preferredWidth: 70
            placeholderText: qsTr("Address")
            selectByMouse: true

            onAccepted: {
                if (root.bus.selectAddress(sel.channel, text)) text = ""
            }
        }
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Logic Analyzer
        //

        SiBox {

            title: qsTr("Logic Analyzer")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.smallSpacing

            ColumnLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.smallSpacing

                GridLayout {

                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Style.largeSpacing
                    rowSpacing: Style.tinySpacing

                    ProbeSelector { channel: 0 }
                    ProbeSelector { channel: 1 }
                    ProbeSelector { channel: 2 }
                    ProbeSelector { channel: 3 }
                }

                Rectangle {

                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    color: Palette.control
                    border.width: 1
                    border.color: Palette.controlBorder
                    radius: Style.radius
                    clip: true

                    Flickable {

                        id: flick
                        anchors.fill: parent
                        anchors.margins: 1
                        contentWidth: width * root.zoom
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.horizontal: ScrollBar { }

                        SiAmLogicView {

                            width: flick.contentWidth
                            height: flick.height
                            hex: root.ic.hex
                            symbolic: symbolicBox.checked
                            textColor: Palette.primary
                            hairlineColor: Palette.controlBorder
                        }
                    }
                }

                RowLayout {

                    Layout.fillWidth: true
                    spacing: Style.mediumSpacing

                    SiCheckBoxControl { id: symbolicBox; r: qsTr("Symbolic") }

                    SiLabel { text: qsTr("Zoom") }

                    SiSliderControl {

                        Layout.fillWidth: true
                        from: 1
                        to: 21
                        value: root.zoom
                        onMoved: (value) => root.zoom = value
                    }
                }
            }
        }

        //
        // DMA Debugger
        //

        SiBox {

            title: qsTr("DMA Debugger")
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            SiCheckBoxControl {

                checked: cc.DMA_DEBUG_ENABLE
                onClicked: cc.DMA_DEBUG_ENABLE = checked
                r: qsTr("Visualize bus accesses")
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

            SiComboBoxControl {

                Layout.fillWidth: true
                enabled: cc.DMA_DEBUG_ENABLE
                model: [qsTr("Foreground layer"), qsTr("Background layer"), qsTr("Mixed layers")]
                currentIndex: cc.DMA_DEBUG_MODE
                onCurrentIndexChanged: cc.DMA_DEBUG_MODE = currentIndex
            }

            SiSliderControl {

                enabled: cc.DMA_DEBUG_ENABLE
                Layout.fillWidth: true
                l: qsTr("Opacity")
                from: 0
                to: 255
                value: cc.DMA_DEBUG_OPACITY
                onMoved: (value) => cc.DMA_DEBUG_OPACITY = value
            }

            VSpacer { }
        }
    }
}
