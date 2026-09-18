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
    // squeezing everything below its natural size.
    height: 540
    minimumHeight: 420

    readonly property var denise: controller.deniseController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // SiWordViewControl/SiByteViewControl (Apps/Shared/QML/Compounds) hold
    // the structural bits; this panel only adds the width override and the
    // hex/decimal toggle binding.
    component SiHex16: SiWordViewControl {

        controlWidth: 64
        base: root.numBase
        padded: root.numPadded
    }

    component SiHex8: SiByteViewControl {

        controlWidth: 40
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

                                RowLayout {
                                    spacing: Style.tinySpacing
                                    SiHex16 { l: qsTr("BPLCON0"); lwidth: 65; value: denise.bplcon0 }
                                }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.hires; l: qsTr("HIRES"); lwidth: 90 }
                                SiWordViewControl { indent: 4; l: "BPU"; value: denise.bpu }
                                    /*
                                    RowLayout {
                                        spacing: Style.smallSpacing
                                        Item { Layout.preferredWidth: 4 }
                                        SiHex8 { controlWidth: 32; value: denise.bpu }
                                        SiLabel { text: qsTr("Bitplanes in use")
                                    }

                                     */
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.homod; l: qsTr("HAM"); lwidth: 90 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.dbplf; l: qsTr("DPF"); lwidth: 90 }
                                SiCheckBoxControl { indent: 4; readOnly: true; enabled: denise.shresEnabled; checked: denise.shres; l: qsTr("SHRES"); lwidth: 90 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.lace; l: qsTr("LACE"); lwidth: 90 }

                                RowLayout {
                                    Layout.topMargin: Style.mediumSpacing
                                    spacing: Style.tinySpacing
                                    SiHex16 { l: qsTr("CLXDAT"); lwidth: 65; value: denise.clxdat }
                                }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                RowLayout {
                                    spacing: Style.tinySpacing
                                    SiHex16 { l: qsTr("BPLCON1"); lwidth: 65; value: denise.bplcon1 }
                                }
                                RowLayout {
                                    spacing: Style.smallSpacing
                                    SiHex8 { controlWidth: 32; value: denise.p1h }
                                    SiLabel { text: qsTr("Playfield 1 delay") }
                                }
                                RowLayout {
                                    spacing: Style.smallSpacing
                                    SiHex8 { controlWidth: 32; value: denise.p2h }
                                    SiLabel { text: qsTr("Playfield 2 delay") }
                                }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                RowLayout {
                                    spacing: Style.tinySpacing
                                    SiHex16 { l: qsTr("BPLCON2"); lwidth: 65; value: denise.bplcon2 }
                                }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf2pri; l: qsTr("PF2PRI"); lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf2p2;  l: qsTr("PF2P2");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf2p1;  l: qsTr("PF2P1");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf2p0;  l: qsTr("PF2P0");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf1p2;  l: qsTr("PF1P2");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf1p1;  l: qsTr("PF1P1");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.pf1p0;  l: qsTr("PF1P0");  lwidth: 60 }
                            }

                            ColumnLayout {

                                spacing: Style.tinySpacing

                                RowLayout {
                                    spacing: Style.tinySpacing
                                    SiHex16 { l: qsTr("BPLCON3"); lwidth: 65; value: denise.bplcon3 }
                                }
                                RowLayout {
                                    spacing: Style.smallSpacing
                                    Item { Layout.preferredWidth: 4 }
                                    SiHex8 { controlWidth: 32; value: denise.colorBank }
                                    SiLabel { text: qsTr("Color bank") }
                                }
                                RowLayout {
                                    spacing: Style.smallSpacing
                                    Item { Layout.preferredWidth: 4 }
                                    SiHex8 { controlWidth: 32; value: denise.pf2of }
                                    SiLabel { text: qsTr("PF2 offset") }
                                }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.loct;      l: qsTr("LOCT");      lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.brdrblnk;  l: qsTr("BRDRBLNK");  lwidth: 60 }
                                SiCheckBoxControl { indent: 4; readOnly: true; checked: denise.brdsprt;   l: qsTr("BRDSPRT");   lwidth: 60 }
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

                                SiHex16 { value: denise.diwstrt }

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

                                SiHex16 { value: denise.diwstop }

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
                        SiHex16 { controlWidth: 48; value: denise.sprVStart }
                        SiLabel { text: "-" }
                        SiHex16 { controlWidth: 48; value: denise.sprVStop }

                        SiLabel { text: qsTr("HPOS") }
                        SiHex16 { controlWidth: 48; value: denise.sprHStart }

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
