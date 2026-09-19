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

    // One probe selector: a single macOS-style combo box that both shows the
    // current selection (probeLabel()) and accepts input the two ways
    // BusPanel.swift's NSComboButton did -- picking a preset from the
    // dropdown, or typing a custom hex address directly into the field.
    component ProbeSelector: SiComboInputControl {

        id: sel

        required property int channel

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignVCenter

        model: root.logicAnalyzer.presetModel()
        textRole: "name"
        placeholderText: qsTr("Address")

        // Plain property assignment (not a binding) is what ComboBox itself
        // does to editText on every keystroke/selection, which breaks a
        // declarative binding here the same way -- so it's restored with
        // Qt.binding() after each accepted edit instead of written once.
        editText: (root.configVersion, root.logicAnalyzer.probeLabel(channel))

        onActivated: (index) => {
            root.logicAnalyzer.selectPreset(channel, index)
            editText = Qt.binding(function() { return (root.configVersion, root.logicAnalyzer.probeLabel(channel)) })
        }

        onAccepted: {
            if (root.logicAnalyzer.selectAddress(channel, editText)) {
                editText = Qt.binding(function() { return (root.configVersion, root.logicAnalyzer.probeLabel(channel)) })
            }
        }
    }

    // Plain row label for the left column, matching SiAmLogicView's own
    // Address Bus / Data Bus rows (which carry no selector of their own).
    component RowLabel: SiLabel {

        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
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

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 240
                spacing: Style.smallSpacing

                // Left column: one row per SiAmLogicView row -- header (DMA
                // Cycle), Address Bus, Data Bus, then the four probe
                // channels -- all equal height, matching how
                // SiAmLogicView::paint() lays its own rows out (headerHeight
                // = h/(numSignals+1) and dy = (h-headerHeight)/numSignals
                // reduce to the same h/7 for every row when numSignals is
                // 6). rowHeight is computed the same way here so each label/
                // selector lines up with its row in the view beside it.
                ColumnLayout {

                    id: leftColumn
                    // maximumWidth is what actually clamps this column --
                    // preferredWidth alone doesn't stop it from growing past
                    // 220, since each ProbeSelector below is a flexible,
                    // fillWidth-seeking control (see SiAmDeniseSprPanel.qml's
                    // own leftColumn for the same fix, needed there for the
                    // same reason).
                    Layout.preferredWidth: 220
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 220
                    Layout.fillHeight: true
                    spacing: 0

                    readonly property real rowHeight: height / 7

                    RowLabel { text: qsTr("DMA Cycle"); Layout.preferredHeight: leftColumn.rowHeight }
                    RowLabel { text: qsTr("Address Bus"); Layout.preferredHeight: leftColumn.rowHeight }
                    RowLabel { text: qsTr("Data Bus"); Layout.preferredHeight: leftColumn.rowHeight }

                    ProbeSelector { channel: 0; Layout.preferredHeight: leftColumn.rowHeight }
                    ProbeSelector { channel: 1; Layout.preferredHeight: leftColumn.rowHeight }
                    ProbeSelector { channel: 2; Layout.preferredHeight: leftColumn.rowHeight }
                    ProbeSelector { channel: 3; Layout.preferredHeight: leftColumn.rowHeight }
                }

                Rectangle {

                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
