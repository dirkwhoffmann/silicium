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
import Sulfur

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

    // titleText: qsTr("Logic Analyzer")
    currentController: controller.logicAnalyzerController

    readonly property var logicAnalyzer: controller.logicAnalyzerController
    readonly property var ic: controller.inspectorController
    readonly property var cc: controller.configController

    property real zoom: 16

    // The factor by which the + and - buttons change the zoom
    readonly property real zoomStep: 1.5

    /* Sets the zoom, keeping the middle of what is shown where it is. */
    function setZoom(value) {

        const zoom = Math.max(1, Math.min(32, value))
        const middle = (flick.contentX + flick.width / 2) / flick.contentWidth

        root.zoom = zoom
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width,
                                              middle * flick.contentWidth - flick.width / 2))
    }

    function zoomBy(factor) { setZoom(root.zoom * factor) }

    // The most the traces are moved away from the right end while the machine
    // runs, in samples. Without it, the picture stands still between two
    // refreshes and the analyzer looks like it is not running.
    readonly property real jitterSamples: 3

    // Scrolls to the neighborhood of the right end, at a random distance
    function followTrace() {

        const sampleWidth = flick.contentWidth / logicView.segmentCount
        const end = Math.max(0, flick.contentWidth - flick.width)

        flick.contentX = Math.max(0, end - Math.random() * root.jitterSamples * sampleWidth)
    }

    // Scrolls the traces to the left end (0) or the right end (1)
    function scrollTo(position) {

        flick.contentX = position * Math.max(0, flick.contentWidth - flick.width)
    }

    /* When the machine stops, no more frames are rendered and the controller
     * is not ticked anymore. The trace is read one last time, as it is now
     * final, and the newest samples (at the right end) are shown.
     */
    Connections {

        target: root.controller
        function onStateChanged() {

            if (!root.controller.isPaused) return
            logicView.refresh()
            root.scrollTo(1)
        }
    }

    // probeLabel() is a plain Q_INVOKABLE (LA_PROBE/LA_ADDR live on
    // SiAmConfigController, read fresh on every call), so it carries no
    // property-change notification of its own to bind against. This counter
    // is bumped on every configChanged and referenced (via the comma
    // operator) from each ProbeSelector's button text, forcing that binding
    // to re-evaluate whenever a preset or custom address is applied.
    property int configVersion: 0
    Connections {
        target: controller.configController
        function onConfigChanged() { root.configVersion++; logicView.refresh() }
    }

    // The controller is ticked by the renderer (see SiAmRenderer::tick())
    Connections {
        target: root.logicAnalyzer
        function onTraceChanged() {

            logicView.refresh()

            // The newest samples are at the right end. While the machine
            // runs, the traces follow them; a paused machine can be browsed.
            if (root.controller.isRunning) root.followTrace()
        }
    }

    /* One probe selector: a combo box with the preselections ("None",
     * "Memory", the custom registers and "IPL"), followed by the address that
     * is probed. The field shows the address of the selected preselection.
     * Typing an address selects the preselection that has it, or "Memory" if
     * there is none. Nothing is stored here: both controls show what the
     * probe says (see presetIndex() and probeAddress()), and what the user
     * does is an instruction to change the probe.
     */
    component ProbeSelector : RowLayout {

        id: sel

        required property int channel

        // Bumped to put the address field back in step with the probe after
        // an edit that the probe did not take
        property int refresh: 0

        readonly property var presets: root.logicAnalyzer.presetModel()
        readonly property int presetIndex: (root.configVersion, root.logicAnalyzer.presetIndex(channel))
        readonly property bool hasAddress: presets[presetIndex].hasAddress

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Style.smallSpacing

        SuLabeledComboBox {

            id: presetBox

            Layout.fillWidth: true
            model: sel.presets
            textRole: "name"
            isItemEnabled: (itemText, index) => !sel.presets[index].separator

            onActivated: (index) => root.logicAnalyzer.selectPreset(sel.channel, index)

            // Binding rather than a currentIndex binding: the combo box writes
            // the user's choice into currentIndex, which would end the latter
            Binding {
                target: presetBox
                property: "currentIndex"
                value: sel.presetIndex
                restoreMode: Binding.RestoreNone
            }
        }

        SuTextField {

            id: addressField

            opacity: sel.hasAddress ? 1 : 0
            Layout.preferredWidth: 70
            Layout.alignment: Qt.AlignVCenter
            font.capitalization: Font.AllUppercase
            validator: RegularExpressionValidator { regularExpression: /[0-9A-Fa-f]{0,8}/ }

            onEditingFinished: {
                root.logicAnalyzer.selectAddress(sel.channel, text)
                sel.refresh++
            }

            Binding {
                target: addressField
                property: "text"
                value: (root.configVersion, sel.refresh, root.logicAnalyzer.probeAddress(sel.channel))
                restoreMode: Binding.RestoreNone
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
    component TipKey: SuText {

        font.pixelSize: Style.small
        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight
    }

    component TipValue: SuText {

        font.pixelSize: Style.small
        leftPadding: 4
        Layout.alignment: Qt.AlignLeft
    }

    // Plain row label for the left column, matching SiAmLogicView's own
    // Address Bus / Data Bus rows (which carry no selector of their own).
    component RowLabel: SuLabel {

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

            //
            // Traces section
            //

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

                    // Same vertical extent as the grid: it lies inside the frame
                    // of the trace area and leaves room for the scroll bar
                    Layout.topMargin: 1
                    Layout.bottomMargin: 1 + hbar.height
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
                    color: Palette.background
                    border.width: 1
                    border.color: Palette.insetBorder
                    radius: Style.radius
                    clip: true

                    Flickable {

                        id: flick
                        anchors.fill: parent
                        anchors.margins: 1
                        contentWidth: width * root.zoom
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.horizontal: ScrollBar { id: hbar; policy: ScrollBar.AlwaysOn }

                        SiAmLogicView {

                            id: logicView

                            width: flick.contentWidth

                            // Leaves the scroll bar, which is always shown, its own strip
                            height: flick.height - hbar.height
                            hex: root.ic.hex
                            padded: root.ic.padded
                            symbolic: symbolicBox.checked
                            textColor: Palette.primary
                            hairlineColor: Palette.insetBorder

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

                            SuToolTip {

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

            //
            // Control elements (below the traces)
            //

            RowLayout {

                Layout.fillWidth: true
                Layout.leftMargin: leftColumn.width + Style.smallSpacing
                spacing: Style.smallSpacing

                SuLabeledCheckBox {

                    checked: root.cc.LA_CONNECT
                    onClicked: root.cc.LA_CONNECT = checked
                    r: qsTr("Connect")
                }

                HSpacer { size: Style.largeSpacing }

                SuSymbolButton {

                    size: Size.small
                    phosphor: "minus-symbol"
                    enabled: root.zoom > 1
                    onClicked: root.zoomBy(1 / root.zoomStep)
                }

                SuLabeledSlider {

                    Layout.fillWidth: true
                    from: 1
                    to: 32
                    value: root.zoom
                    onMoved: (value) => root.setZoom(value)
                }

                SuSymbolButton {

                    size: Size.small
                    phosphor: "plus-symbol"
                    enabled: root.zoom < 32
                    onClicked: root.zoomBy(root.zoomStep)
                }

                HSpacer { size: Style.largeSpacing }

                SuSymbolButton {

                    size: Size.small
                    phosphor: "arrow-line-left"
                    onClicked: root.scrollTo(0)
                }

                SuSymbolButton {

                    size: Size.small
                    phosphor: "arrow-line-right"
                    onClicked: root.scrollTo(1)
                }

                HSpacer { size: Style.largeSpacing }

                SuLabeledCheckBox {

                    id: symbolicBox
                    r: qsTr("Symbolic")
                }
            }
        }
    }
}
