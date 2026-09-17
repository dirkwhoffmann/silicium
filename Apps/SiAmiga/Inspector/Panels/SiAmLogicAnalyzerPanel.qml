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

// Port of vAmiga's own GUI/Inspector/BusPanel.swift + LogicView.swift. Its
// own top-level window (see SiAmInspectorWindow.qml). A single "Logic
// Analyzer" box, spanning the whole panel: the 228-cycle DMA timing-diagram
// grid (SiAmLogicView, a QQuickPaintedItem port of LogicView.swift's
// drawHairlines/drawLabels/drawSignal) plus its four probe selectors, a zoom
// slider and the Symbolic checkbox. The DMA Debugger box that used to sit
// next to it (the eight visualize-channel checkboxes/colors plus the
// display-mode combo and opacity slider) moved to its own window,
// SiAmXRayPanel.qml, paired there with a live preview.
SiAmInspectorWindow {

    id: root

    title: qsTr("Logic Analyzer")
    currentController: controller.logicAnalyzerController

    readonly property var logicAnalyzer: controller.logicAnalyzerController
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
        target: controller.configController
        function onConfigChanged() { root.configVersion++ }
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
            text: (root.configVersion, root.logicAnalyzer.probeLabel(sel.channel))

            onClicked: presetMenu.popup()

            Menu {

                id: presetMenu

                Instantiator {

                    model: root.logicAnalyzer.presetModel()

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
                                onTriggered: root.logicAnalyzer.selectPreset(sel.channel, index)
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
                if (root.logicAnalyzer.selectAddress(sel.channel, text)) text = ""
            }
        }
    }

    SiBox {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        title: qsTr("Logic Analyzer")
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
}
