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
import Silicium.Controllers
import Silicium.Theme

// Port of SiC64MemoryPanel.qml. Unlike SiC64's per-panel inspector windows,
// this is a plain page inside SiAmInspectorWindow's sidebar StackLayout
// (see that file), not its own window -- so there's no
// SiC64InspectorWindow-style base and no title/currentController wiring
// here; SiAmInspectorWindow.updateActiveController() drives
// controller.memoryController.active for it, the same way it already does
// for the Events and CIA panels.
//
// The differences from the C64 version all trace back to
// SiAmMemoryController's own class comment:
//
//  - The source selector is a plain CPU/Agnus toggle, not C64's five-way
//    (CPU/VIC/RAM/ROM/IO) selector, and there's no processor-port mode row
//    (EXROM/GAME/CHAREN/HIRAM/LORAM) at all -- vAmiga's memory map has no
//    such banking bits.
//  - 256 banks of 64 KB (16 MB, 24-bit bus) instead of 16 banks of 4 KB --
//    the bank list, address search and navigation slider all scale up
//    accordingly, and addresses are 6 hex digits instead of 4.
//  - The legend below the navigation strip carries vAmiga's own memory
//    types (see MemoryPanel.swift's MemColors/refreshMemoryLayout) instead
//    of the C64's cartridge/BASIC/KERNAL set, arranged in the same two
//    rows of five vAmiga's own inspector uses: Chip/Fast/WOM/CIA/Chipset,
//    then Slow/ROM/Rom Extension/RTC/Zorro. Six of the ten (every RAM/ROM
//    region, not the four fixed hardware regions CIA/RTC/Chipset/Zorro)
//    show a live KB size read from the core's MemConfig, matching exactly
//    which six get a size label in the Swift reference.
//  - No Heatmap sub-view or view selector -- vAmiga's core has no
//    MEM_HEATMAP-style option to back one (see SiAmMemoryController).
Item {

    id: root

    required property SiAmController controller

    readonly property var mem: controller.memoryController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10

    readonly property var displayedBankInfo: mem.banks.length > 0 ? mem.banks[mem.displayedBank] : ({})

    // Global row across the whole 256-bank x 4096-row address space, i.e.
    // the row currently scrolled to the top of the dump list. See
    // SiC64MemoryPanel's own globalRow for why both the list's scroll
    // position and mem.displayedBank have to be watched.
    readonly property real globalRow: mem.displayedBank * 4096 + dumpList.contentY / dumpList.rowH
    onGlobalRowChanged: navSlider.value = globalRow

    // MemSrc ordinals (see Core/Components/Memory/MemoryTypes.h's MemSrc
    // enum) for the legend/jump buttons below.
    readonly property int typeChip: 1
    readonly property int typeSlow: 3
    readonly property int typeFast: 5
    readonly property int typeCia: 6
    readonly property int typeRtc: 8
    readonly property int typeCustom: 9
    readonly property int typeAutoconf: 11
    readonly property int typeRom: 13
    readonly property int typeWom: 15
    readonly property int typeExt: 16

    component HeaderLabel: SiLabel {

        topPadding: 2
        bottomPadding: 2
        font.weight: 500
        elide: Text.ElideRight
    }

    component Value: SiLabel {

        size: Size.small
        topPadding: 1
        bottomPadding: 1
        font.family: Fonts.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    // Mirrors MemoryPanel.swift's MemColors -- mirror variants share their
    // base type's color (see SiAmMemoryController::colorForType).
    readonly property var typeColors: ({

        1: "#80FF00",  // CHIP
        2: "#80FF00",  // CHIP_MIRROR
        3: "#66CC00",  // SLOW
        4: "#66CC00",  // SLOW_MIRROR
        5: "#4C9900",  // FAST
        6: "#66B2FF",  // CIA
        7: "#66B2FF",  // CIA_MIRROR
        8: "#B266FF",  // RTC
        9: "#FFFF66",  // CUSTOM
        10: "#FFFF66", // CUSTOM_MIRROR
        11: "#FF66B2", // AUTOCONF
        12: "#FF66B2", // ZOR
        13: "#FF0000", // ROM
        14: "#FF0000", // ROM_MIRROR
        15: "#CC0000", // WOM
        16: "#990000"  // EXT
    })

    component TypeInfo: SiControl {

        id: typeInfo

        property int memType: 0
        property string sizeText: ""

        size: Size.small
        rwidth: 90
        hasFlexControl: false

        control: [

            Rectangle {

                width: Size.controlHeight(typeInfo.size) * 0.8
                height: width
                radius: Style.radius
                color: root.typeColors[typeInfo.memType] || Palette.disabled
                border.width: 1
                border.color: Qt.alpha(Palette.backdrop, 0.5)

                TapHandler {
                    onTapped: mem.jumpToType(typeInfo.memType)
                }
            }
        ]

        // Default-property child -- lands in SiControl's accessory slot,
        // after the 'r' label, so each legend entry reads
        // swatch -> type name -> KB size (blank for the four fixed
        // hardware regions with no MemConfig size field -- see the class
        // comment).
        SiText {

            visible: typeInfo.sizeText !== ""
            text: typeInfo.sizeText
            color: Palette.tertiary
        }
    }

    component MemLayoutStrip: Rectangle {

        implicitHeight: 22
        color: "transparent"
        clip: true

        RowLayout {

            anchors.fill: parent
            spacing: 0

            Repeater {

                model: mem.banks

                delegate: Rectangle {

                    required property var modelData
                    required property int index
                    readonly property color dark: modelData.color.darker(1.3)

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    gradient: Gradient {

                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: modelData.color }
                        GradientStop { position: 1.0; color: dark }
                    }
                }
            }
        }
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: Style.mediumSpacing

        //
        // Source selector + search
        //

        RowLayout {

            Layout.fillWidth: true
            spacing: Style.mediumSpacing

            SiLabel { text: qsTr("Inspect") }

            SiComboBox {

                Layout.preferredWidth: 190
                model: [
                    qsTr("Visible Banks (CPU)"),
                    qsTr("Visible Banks (Agnus)")]

                currentIndex: mem.source
                onActivated: (index) => mem.source = index
            }

            Item { Layout.fillWidth: true }

            SiSearchControl {

                controlWidth: 160
                base: root.numBase

                onAccepted: {

                    if (!isNaN(value)) mem.jumpToAddress(value)
                    text = ""
                }
            }
        }

        //
        // Navigation: current bank readout, address slider, legend
        //

        SiBox {

            Layout.fillWidth: true
            spacing: Style.mediumSpacing

            MemLayoutStrip {

                id: layoutStrip
                Layout.fillWidth: true
                Layout.leftMargin: 7
                Layout.rightMargin: 7
            }

            SiSlider {

                id: navSlider

                // Continuous position across the full 256-bank x 4096-row
                // address space (see root.globalRow), not a per-bank stop
                // -- see SiC64MemoryPanel's own navSlider for why this
                // isn't a plain "value: root.globalRow" binding.
                Layout.fillWidth: true
                from: 0; to: 256 * 4096 - 1
                unicolor: true

                onMoved: {

                    const bank = Math.floor(value / 4096)
                    const localRow = value - bank * 4096

                    if (mem.displayedBank !== bank) mem.displayedBank = bank
                    dumpList.contentY = localRow * dumpList.rowH
                }
            }

            ColumnLayout {

                Layout.alignment: Qt.AlignHCenter
                spacing: Style.tinySpacing

                RowLayout {

                    spacing: Style.smallSpacing
                    Layout.alignment: Qt.AlignHCenter

                    TypeInfo { memType: root.typeChip; r: qsTr("Chip Ram"); sizeText: qsTr("%1 KB").arg(mem.chipKB) }
                    TypeInfo { memType: root.typeFast; r: qsTr("Fast Ram"); sizeText: qsTr("%1 KB").arg(mem.fastKB) }
                    TypeInfo { memType: root.typeWom; r: qsTr("Wom"); sizeText: qsTr("%1 KB").arg(mem.womKB) }
                    TypeInfo { memType: root.typeCia; r: qsTr("CIA") }
                    TypeInfo { memType: root.typeCustom; r: qsTr("Chipset") }
                }

                RowLayout {

                    spacing: Style.smallSpacing
                    Layout.alignment: Qt.AlignHCenter

                    TypeInfo { memType: root.typeSlow; r: qsTr("Slow Ram"); sizeText: qsTr("%1 KB").arg(mem.slowKB) }
                    TypeInfo { memType: root.typeRom; r: qsTr("Rom"); sizeText: qsTr("%1 KB").arg(mem.romKB) }
                    TypeInfo { memType: root.typeExt; r: qsTr("Rom Extension"); sizeText: qsTr("%1 KB").arg(mem.extKB) }
                    TypeInfo { memType: root.typeRtc; r: qsTr("RTC") }
                    TypeInfo { memType: root.typeAutoconf; r: qsTr("Zorro") }
                }
            }
        }

        //
        // Content
        //

        RowLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.mediumSpacing

            //
            // Bank list
            //

            Rectangle {

                Layout.preferredWidth: 160
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Palette.control
                border.color: Palette.controlBorder
                border.width: 1
                radius: Style.radius
                clip: true

                ColumnLayout {

                    anchors.fill: parent
                    anchors.margins: 1
                    spacing: 0

                    RowLayout {

                        Layout.fillWidth: true
                        HeaderLabel { text: qsTr("Bank"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 40 }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                        HeaderLabel { text: qsTr("Source"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 140 }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

                    ListView {

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: mem.banks

                        delegate: Rectangle {

                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: bankRow.implicitHeight
                            color: index === mem.displayedBank
                                ? Palette.accent
                                : index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)
                            radius: Style.radius

                            RowLayout {

                                id: bankRow
                                width: parent.width
                                spacing: Style.smallSpacing

                                Value {

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignHCenter
                                    text: index.toString(16).toUpperCase().padStart(2, "0")
                                    color: index === mem.displayedBank ? Palette.accentText : Palette.primary
                                }

                                Rectangle {

                                    Layout.preferredWidth: 1
                                    Layout.fillHeight: true
                                    color: index === mem.displayedBank ? Palette.accentElevated : Palette.surfaceBorder
                                }

                                Value {

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 140
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name
                                    color: index === mem.displayedBank ? Palette.accentText :
                                        modelData.mapped ? Palette.primary : Palette.tertiary
                                }
                            }

                            TapHandler { onTapped: mem.displayedBank = index }
                        }
                    }
                }
            }

            //
            // Memory dump
            //

            Rectangle {

                Layout.preferredWidth: 512
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Palette.control
                border.color: Palette.controlBorder
                border.width: 1
                radius: Style.radius
                clip: true

                ColumnLayout {

                    anchors.fill: parent
                    anchors.margins: 1
                    spacing: 0

                    RowLayout {

                        Layout.fillWidth: true
                        spacing: Style.smallSpacing

                        HeaderLabel { text: qsTr("Addr"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 70 }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                        HeaderLabel { text: qsTr("Data"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 360 }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 26; color: Palette.surfaceBorder }
                        HeaderLabel { text: qsTr("ASCII"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 150 }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

                    ListView {

                        id: dumpList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: mem.rows

                        // All rows share the same delegate height, so this
                        // is constant once at least one row has been laid
                        // out -- used to convert between a scroll offset
                        // and a (possibly fractional) row index (see
                        // root.globalRow).
                        readonly property real rowH: count > 0 ? contentHeight / count : 1

                        delegate: Rectangle {

                            width: ListView.view.width
                            implicitHeight: dumpRow.implicitHeight
                            color: index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                            RowLayout {

                                id: dumpRow
                                width: parent.width
                                spacing: Style.smallSpacing

                                Value {

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 70
                                    horizontalAlignment: Text.AlignHCenter
                                    text: addr
                                    color: Palette.primary
                                }

                                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                                Value {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 360
                                    horizontalAlignment: Text.AlignHCenter
                                    text: hex
                                }

                                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                                Value {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 150
                                    horizontalAlignment: Text.AlignHCenter
                                    text: ascii
                                    color: Palette.primary
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Scroll the dump to a freshly-jumped-to address.
    Connections {

        target: mem

        function onSelectionChanged() {

            if (mem.selectedRow >= 0) {
                dumpList.positionViewAtIndex(mem.selectedRow, ListView.Beginning)
            }
        }
    }
}
