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

    readonly property int typeRam: 1
    readonly property int typeChar: 2
    readonly property int typeKernal: 3
    readonly property int typeBasic: 4
    readonly property int typeIO: 5
    readonly property int typeCrtLo: 6
    readonly property int typeCrtHi: 7
    readonly property int typePP: 8

    title: qsTr("Memory Inspector")
    currentController: controller.memoryController

    readonly property var mem: controller.memoryController
    readonly property var displayedBankInfo: mem.banks.length > 0 ? mem.banks[mem.displayedBank] : ({})

    // 0 = hex, 1 = hex zero-padded, 2 = decimal, 3 = decimal zero-padded.
    readonly property int numBase: (controller.format === 0 || controller.format === 1) ? 16 : 10

    // Global row across the whole 16-bank x 256-row address space, i.e. the
    // row currently scrolled to the top of the dump list. Reacts to both the
    // dump list's scroll position AND mem.displayedBank -- the latter matters
    // on its own because jumping banks (TypeInfo taps, a bank-list click, a
    // search jump) changes displayedBank without moving the list's scroll
    // offset (the row model updates in place so scrolling isn't disturbed),
    // so contentY alone isn't enough to notice a bank change. Drives the
    // slider's displayed position.
    readonly property real globalRow: mem.displayedBank * 256 + dumpList.contentY / dumpList.rowH
    onGlobalRowChanged: navSlider.value = globalRow

    // 0 = Data view, 1 = Heatmap
    property int view: 0

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

    readonly property var typeColors: ({

        1: "#99FF99", // RAM
        2: "#FFFF99", // CHAR
        3: "#99CCFF", // KERNAL
        4: "#FF9999", // BASIC
        5: "#99FFFF", // IO
        6: "#CC99FF", // CRTLO
        7: "#FF99FF", // CRTHI
        8: "#33AA33"  // PP
    })

    component TypeInfo: SiControl {

        id: typeInfo

        property int memType: 0

        size: Size.small
        rwidth: 60
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
    }

    component MemLayoutStrip: Rectangle {

        implicitHeight: 22
        color: "transparent"
        clip: true

        RowLayout {

            anchors.fill: parent
            spacing: 1

            Repeater {

                model: mem.banks

                delegate: Rectangle {

                    required property var modelData
                    required property int index
                    readonly property color dark: modelData.color.darker(1.3)

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Style.radius
                    border.width: 1
                    border.color: Qt.alpha(Palette.backdrop, 0.5)

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
        // Source selector + mode flags + search
        //

        RowLayout {

            Layout.fillWidth: true
            spacing: Style.mediumSpacing

            SiLabel { text: qsTr("Inspect") }

            SiComboBox {
                
                Layout.preferredWidth: 190
                model: [
                    qsTr("Visible Banks (CPU)"),
                    qsTr("Visible Banks (VIC)"),
                    qsTr("RAM"),
                    qsTr("ROM"),
                    qsTr("IO")]

                currentIndex: mem.source
                onActivated: (index) => mem.source = index
            }

            Item { Layout.fillWidth: true }

            SiCheckBoxControl { size: Size.small; checked: mem.exrom; r: qsTr("EXROM") }
            SiCheckBoxControl { size: Size.small; checked: mem.game; r: qsTr("GAME") }
            SiCheckBoxControl { size: Size.small; checked: mem.charen; r: qsTr("CHAREN") }
            SiCheckBoxControl { size: Size.small; checked: mem.loram; r: qsTr("LORAM") }
            SiCheckBoxControl { size: Size.small; checked: mem.hiram; r: qsTr("HIRAM") }

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
        // Navigation: current bank readout, address slider, bank-type jumps
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

                // Continuous position across the full 16-bank x 256-row
                // address space (see root.globalRow), not a per-bank stop --
                // dragging scrolls the dump list smoothly, and scrolling the
                // dump list moves the handle back, kept in sync through
                // root.globalRow below. Deliberately not a plain
                // "value: root.globalRow" binding -- QQC2 Slider assigns
                // 'value' imperatively while dragging, which would silently
                // break that binding for good after the first drag.
                Layout.fillWidth: true
                from: 0; to: 16 * 256 - 1
                unicolor: true

                onMoved: {

                    const bank = Math.floor(value / 256)
                    const localRow = value - bank * 256

                    if (mem.displayedBank !== bank) mem.displayedBank = bank
                    dumpList.contentY = localRow * dumpList.rowH
                }
            }

            RowLayout {

                spacing: Style.smallSpacing

                HSpacer { }
                TypeInfo { memType: root.typePP; r: qsTr("RAM + PP") }
                TypeInfo { memType: root.typeRam; r: qsTr("RAM") }
                TypeInfo { memType: root.typeBasic; r: qsTr("BASIC") }
                TypeInfo { memType: root.typeChar; r: qsTr("CHAR") }
                TypeInfo { memType: root.typeKernal; r: qsTr("KERNAL") }
                TypeInfo { memType: root.typeIO; r: qsTr("I/O") }
                TypeInfo { memType: root.typeCrtLo; r: qsTr("CRTLO") }
                TypeInfo { memType: root.typeCrtHi; r: qsTr("CRTHI") }
                HSpacer { }
            }
        }

        //
        // View selector
        //

        RowLayout {

            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SiSegmentedControl {

                model: [qsTr("Data View"), qsTr("Heatmap")]
                currentIndex: root.view
                onActivated: (index) => root.view = index
            }

            Item { Layout.fillWidth: true }
        }

        //
        // Content
        //

        StackLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.view

            RowLayout {

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
                                        text: index.toString(10).toUpperCase().padStart(2, " ")
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

                            HeaderLabel { text: qsTr("Addr"); horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredWidth: 60 }
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
                                        Layout.preferredWidth: 60
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

            //
            // Heatmap view
            //

            Rectangle {

                color: "transparent"
                border.color: Palette.surfaceBorder
                border.width: 0
                radius: Style.radius
                clip: true

                SiC64Heatmap {

                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.leftMargin: 2
                    anchors.rightMargin: 0
                    anchors.bottomMargin: 0
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
