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
// Analyzer" box, spanning the whole panel: the DMA timing-diagram grid
// (SiAmLogicView, a QQuickPaintedItem port of LogicView.swift's
// drawHairlines/drawLabels/drawSignal), showing the most recent 256 entries
// of the core's logic-analyzer ring buffer, plus its four probe selectors, a
// zoom slider and the Connect and Symbolic checkboxes. The DMA Debugger box that used to sit
// next to it (the eight visualize-channel checkboxes/colors plus the
// display-mode combo and opacity slider) moved to its own window,
// SiAmXRayPanel.qml, paired there with a live preview.
SiAmInspectorWindow {

    id: root

    title: qsTr("Logic Analyzer")
    currentController: controller.logicAnalyzerController

    readonly property var logicAnalyzer: controller.logicAnalyzerController
    readonly property var ic: controller.inspectorController
    readonly property var cc: controller.configController

    property real zoom: 1

    /* Row tints for the timing diagram, in row order: Address Bus, Data
     * Bus, then probe channels 0..3.
     *
     * The first four are the pastels of the reference layout, taken in the
     * same top-to-bottom order it uses; the last two continue the set so
     * that every row is covered. Shortening this list leaves the remaining
     * rows untinted rather than breaking -- SiAmLogicView treats it as a
     * preference per row, not a fixed-length table.
     *
     * The view picks the ink for a row's signal and values from the tint's
     * own lightness, so a colour swapped here needs nothing else changed.
     */
    readonly property var rowColors: [
        "#A9C9F5",  // Address Bus -- blue
        "#C6B6F0",  // Data Bus    -- magenta
        "#F2B4C6",  // Probe 0     -- light red
        "#A6E3C1",  // Probe 1     -- green
        "#F3D9A4",  // Probe 2     -- amber
        "#A9DCE3"   // Probe 3     -- teal
    ]

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
    component ProbeSelector : SiComboInputControl {

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

    /* The two cell kinds of the hover tooltip's grid.
     *
     * The colon belongs to the key, and the keys are right-aligned while the
     * values are left-aligned, so the three colons line up in one column with
     * the block centred on them -- which is the whole point of laying this
     * out as a grid rather than as one newline-separated string.
     */
    component TipKey: SiText {

        font.pixelSize: Style.small
        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight
    }

    component TipValue: SiText {

        font.pixelSize: Style.small
        leftPadding: 4
        Layout.alignment: Qt.AlignLeft
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
                spacing: Style.mediumSpacing

                /* Indented to start where the timing diagram does, so this
                 * row spans the grid rather than the whole panel.
                 *
                 * Taken from leftColumn's live width plus the grid row's own
                 * spacing rather than from the literal 220 that column is
                 * clamped to: the clamp is a maximum, and the column is free
                 * to come out narrower in a cramped window, which would leave
                 * this row misaligned if the number were repeated here.
                 */
                Layout.leftMargin: leftColumn.width + Style.smallSpacing

                // Gates the core's recording (Opt::LA_CONNECT). With it off
                // the ring buffer stops filling, so the grid freezes on
                // whatever it last held rather than clearing -- same as
                // BusPanel.swift's own Enable switch.
                SiCheckBoxControl {

                    checked: root.cc.LA_CONNECT
                    onClicked: root.cc.LA_CONNECT = checked
                    r: qsTr("Connect")
                }

                SiCheckBoxControl { id: symbolicBox; r: qsTr("Symbolic") }

                SiLabel { text: qsTr("Zoom") }

                SiSliderControl {

                    Layout.fillWidth: true
                    from: 1
                    to: 32
                    value: root.zoom
                    onMoved: (value) => root.zoom = value
                }
            }

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 240
                spacing: Style.smallSpacing

                // Left column: one row per SiAmLogicView row -- header (DMA
                // cycle position), Address Bus, Data Bus, then the four probe
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

                            id: logicView

                            width: flick.contentWidth
                            height: flick.height
                            hex: root.ic.hex
                            padded: root.ic.padded
                            symbolic: symbolicBox.checked
                            textColor: Palette.primary
                            hairlineColor: Palette.controlBorder
                            rowColors: root.rowColors

                            /* Where the column under the pointer was
                             * recorded: { frame, vpos, hpos }, or empty for
                             * a column the trace does not reach back to.
                             *
                             * Re-read on every pointer move rather than
                             * latched when a column is entered: the grid
                             * re-samples itself once per rendered frame, so
                             * the sample a given column shows is not the one
                             * it showed a moment ago.
                             */
                            property var hovered: ({})

                            /* The dwell before the tooltip appears.
                             *
                             * ToolTip has a `delay` of its own, but it does
                             * nothing when `visible` is driven by a binding
                             * rather than by ToolTip.show(): the delayed open
                             * re-enters setVisible(), which starts the delay
                             * over, so the popup never actually opens. The
                             * wait is therefore kept here and the ToolTip is
                             * told to show immediately (delay: 0).
                             *
                             * Only the first appearance waits. Once the
                             * tooltip is up it stays up and tracks the
                             * pointer, so sweeping along the grid reads
                             * continuously instead of re-arming per column.
                             */
                            Timer {

                                id: dwell

                                property bool elapsed: false

                                interval: 500
                                onTriggered: elapsed = true
                            }

                            HoverHandler {

                                id: hoverHandler

                                onPointChanged: logicView.hovered = logicView.sampleAt(point.position.x, point.position.y)

                                onHoveredChanged: {

                                    if (hovered) {

                                        dwell.elapsed = false
                                        dwell.restart()

                                    } else {

                                        dwell.stop()
                                        dwell.elapsed = false
                                        logicView.hovered = ({})
                                    }
                                }
                            }

                            SiToolTip {

                                id: sampleTip

                                // No timeout: this is a readout to compare
                                // columns against, not a hint that has been
                                // read once and is then in the way
                                timeout: -1
                                delay: 0

                                visible: dwell.elapsed && hoverHandler.hovered
                                         && logicView.hovered.hpos !== undefined
                                x: hoverHandler.point.position.x + 16
                                y: hoverHandler.point.position.y + 16

                                contentItem: GridLayout {

                                    columns: 2
                                    columnSpacing: 0
                                    rowSpacing: 1

                                    TipKey { text: qsTr("Frame:") }
                                    TipValue { text: logicView.hovered.frame !== undefined ? logicView.hovered.frame : "" }

                                    TipKey { text: qsTr("vpos:") }
                                    TipValue { text: logicView.hovered.vpos !== undefined ? logicView.hovered.vpos : "" }

                                    TipKey { text: qsTr("hpos:") }
                                    TipValue { text: logicView.hovered.hpos !== undefined ? logicView.hovered.hpos : "" }

                                    /* Only while the pointer is on a signal
                                     * row that has a value there -- both
                                     * cells drop out together, and GridLayout
                                     * closes the row rather than leaving a
                                     * gap.
                                     */
                                    TipKey {
                                        text: qsTr("Value:")
                                        visible: logicView.hovered.value !== undefined
                                    }

                                    TipValue {
                                        text: logicView.hovered.value !== undefined ? logicView.hovered.value : ""
                                        visible: logicView.hovered.value !== undefined
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
