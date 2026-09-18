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

// Port of vAmiga's own GUI/Inspector/DenisePanel.swift + SpriteTableView.swift.
// Its own top-level window (see SiAmInspectorWindow.qml).
SiAmInspectorWindow {

    id: root

    title: qsTr("Denise Inspector")
    currentController: controller.deniseController

    // The default 880x440 (SiAmInspectorWindow.qml) was sized for the old
    // flat layout, where the register grid and the fixed-height Display
    // window/Colors row sat in separate, independently-sized top-level
    // rows. Now that both live stacked inside one StackLayout page (see
    // root.page below), that page also has to make room for the
    // Program/Trace/Debug-style tab bar's own overlap margin above it, so
    // the same content needs a bit more height than before to avoid
    // squeezing everything below its natural size. Grown again once the
    // BPLCON0 column's bit list grew from 6 to 13 rows (COLOR/GAUD/UHRES/
    // BYPASS/LPEN/ERSY/ECSENA added) -- that column, not the fixed-height
    // Display window/Colors row below it, is now what sets the Registers
    // box's required height.
    height: 720
    minimumHeight: 600

    readonly property var denise: controller.deniseController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded
    readonly property int lw: 64
    readonly property int indent: 16

    // SiWordViewControl/SiByteViewControl (Apps/Shared/QML/Compounds) hold
    // the structural bits; this panel only adds the width override and the
    // hex/decimal toggle binding.

    component Si1: SiBitViewControl {

        size: Size.small
    }

    component Si16: SiWordViewControl {

        size: Size.small
        base: root.numBase
        padded: root.numPadded
    }

    // One color-register swatch -- a plain circle, matching the round
    // NSColorWell style DenisePanel.swift's colorReg wells use.
    component Swatch: Rectangle {

        property color value: "black"

        implicitWidth: 28
        implicitHeight: 28
        radius: width / 2
        color: value
        border.width: 1
        border.color: Palette.controlBorder
    }

    // Which page the stack shows: 0 = Registers, 1 = Sprites -- same
    // Program/Trace/Debug tab-bar idiom as SiAmCPUPanel.qml, adopted here so
    // the growing set of AGA-only registers (still to be added) has room of
    // its own instead of squeezing the Sprites box sideways.
    property int page: 0

    Item {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        SiBox {

            id: stackBox
            anchors.fill: parent
            anchors.topMargin: tabControl.height / 2
            spacing: Style.mediumSpacing

            VSpacer { size: Style.tinySpacing }

            StackLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.page

                //
                // Registers
                //

                ColumnLayout {

                    spacing: Style.mediumSpacing

                    SiBox {

                        title: qsTr("Registers")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.mediumSpacing

                        RowLayout {

                            Layout.fillWidth: true
                            spacing: Style.largeSpacing * 2

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                Si16 { l: qsTr("BPLCON0"); lwidth: root.lw; value: denise.bplcon0 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("HIRES"); checked: denise.hires }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("BPU"); value: denise.bpu }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("HAM"); checked: denise.homod }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("DPF"); checked: denise.dbplf }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("COLOR"); checked: denise.color }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("GAUD"); checked: denise.gaud }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("UHRES"); checked: denise.uhres }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SHRES"); enabled: denise.shresEnabled; checked: denise.shres }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("BYPASS"); checked: denise.bypass }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("LPEN"); checked: denise.lpen }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("LACE"); checked: denise.lace }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ERSY"); checked: denise.ersy }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ECSENA"); checked: denise.ecsena }

                                RowLayout {
                                    Layout.topMargin: Style.mediumSpacing
                                    spacing: Style.tinySpacing
                                    Si16 { l: qsTr("CLXDAT"); lwidth: 65; value: denise.clxdat }
                                }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                Si16 { l: qsTr("BPLCON1"); lwidth: root.lw; value: denise.bplcon1 }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1H"); value: denise.p1h }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2H"); value: denise.p2h }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                Si16 { l: qsTr("BPLCON2"); lwidth: root.lw; value: denise.bplcon2 }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPSEL"); value: denise.zdbpsel }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDBPEN"); checked: denise.zdbpen }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("ZDCTEN"); checked: denise.zdcten }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("KILLEHB"); checked: denise.killehb }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("RDRAM"); checked: denise.rdram }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("SOGEN"); checked: denise.sogen }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2PRI"); checked: denise.pf2pri }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P2");  checked: denise.pf2p2 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P1");  checked: denise.pf2p1 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2P0");  checked: denise.pf2p0 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P2");  checked: denise.pf1p2 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P1");  checked: denise.pf1p1 }
                                Si1 { indent: root.indent; lwidth: root.lw; l: qsTr("PF1P0");  checked: denise.pf1p0 }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                Si16 { l: qsTr("BPLCON3"); lwidth: root.lw; value: denise.bplcon3 }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("BANK");     value: denise.colorBank }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("PF2OF");    value: denise.pf2of }
                                Si1  { indent: root.indent; lwidth: root.lw; l: qsTr("LOCT");     checked: denise.loct }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("SPRES");    value: denise.spres }
                                Si1  { indent: root.indent; lwidth: root.lw; l: qsTr("BRDRBLNK"); checked: denise.brdrblnk }
                                Si1  { indent: root.indent; lwidth: root.lw; l: qsTr("BRDNTRAN"); checked: denise.brdntran }
                                Si1  { indent: root.indent; lwidth: root.lw; l: qsTr("BRDSPRT");  checked: denise.brdsprt }
                                Si1  { indent: root.indent; lwidth: root.lw; l: qsTr("EXTBLKEN"); checked: denise.extblken }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                Si16 { l: qsTr("BPLCON4"); lwidth: root.lw; value: denise.bplcon4 }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("BPLAM"); value: denise.bplam }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("ESPRM"); value: denise.esprm }
                                Si16 { indent: root.indent; lwidth: root.lw; l: qsTr("OSPRM"); value: denise.osprm }
                            }

                            HSpacer { }
                        }

                        VSpacer { }
                    }

                    RowLayout {

                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        spacing: Style.mediumSpacing

                        //
                        // Display window
                        //

                        SiBox {

                            title: qsTr("Display window")
                            Layout.preferredWidth: 460
                            Layout.fillHeight: true

                            RowLayout {

                                Layout.alignment: Qt.AlignVCenter
                                spacing: Style.mediumSpacing

                                Si16 { value: denise.diwstrt }

                                ColumnLayout {

                                    spacing: 2

                                    SiText { Layout.alignment: Qt.AlignLeft; text: "(%1,%2)".arg(denise.hstrt).arg(denise.vstrt); font.pixelSize: Style.small }

                                    Rectangle {

                                        Layout.preferredWidth: 100
                                        Layout.preferredHeight: 70
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Palette.primary

                                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: parent.height + 16; y: -8; color: Palette.controlBorder }
                                        Rectangle { anchors.verticalCenter: parent.verticalCenter; height: 1; width: parent.width + 16; x: -8; color: Palette.controlBorder }
                                    }

                                    SiText { Layout.alignment: Qt.AlignRight; text: "(%1,%2)".arg(denise.hstop).arg(denise.vstop); font.pixelSize: Style.small }
                                }

                                Si16 { value: denise.diwstop }

                                HSpacer { }
                            }
                        }

                        //
                        // Colors
                        //

                        SiBox {

                            title: qsTr("Colors")
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            GridLayout {

                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                columns: 8
                                columnSpacing: Style.smallSpacing
                                rowSpacing: Style.smallSpacing

                                Repeater {
                                    model: 32
                                    Swatch { required property int index; value: denise.colorAt(index) }
                                }
                            }
                        }
                    }
                }

                //
                // Sprites
                //

                SiBox {

                    title: qsTr("Sprites")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Style.tinySpacing

                    RowLayout {

                        Layout.fillWidth: true
                        spacing: Style.tinySpacing

                        Repeater {
                            model: 8
                            SiCheckBoxControl { required property int index; readOnly: true; checked: denise.spriteArmed(index) }
                        }
                    }

                    RowLayout {

                        Layout.fillWidth: true
                        spacing: Style.tinySpacing

                        Repeater {
                            model: 8
                            Button {
                                required property int index
                                text: index
                                checkable: true
                                checked: denise.selectedSprite === index
                                onClicked: denise.selectedSprite = index
                            }
                        }
                    }

                    Rectangle {

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: Style.tinySpacing
                        color: "black"
                        border.width: 1
                        border.color: Palette.surfaceBorder
                        radius: Style.radius
                        clip: true

                        SiAmSpriteView {
                            anchors.fill: parent
                            anchors.margins: Style.radius
                            spriteNr: denise.selectedSprite
                        }
                    }

                    RowLayout {

                        Layout.topMargin: Style.tinySpacing
                        spacing: Style.smallSpacing

                        SiLabel { text: qsTr("VPOS") }
                        Si16 { controlWidth: 48; value: denise.sprVStart }
                        SiLabel { text: "-" }
                        Si16 { controlWidth: 48; value: denise.sprVStop }

                        SiLabel { text: qsTr("HPOS") }
                        Si16 { controlWidth: 48; value: denise.sprHStart }

                        HSpacer { }

                        SiLabel { text: qsTr("AT") }
                        SiCheckBoxControl { readOnly: true; checked: denise.sprAttach }
                    }
                }
            }
        }

        SiSegmentedControl {

            id: tabControl
            anchors.horizontalCenter: stackBox.horizontalCenter
            anchors.verticalCenter: stackBox.top

            model: [qsTr("Registers"), qsTr("Sprites")]
            segmentWidth: 90
            currentIndex: root.page
            onActivated: (index) => root.page = index
        }
    }
}
