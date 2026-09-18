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

// SiAmDenisePanel's "Sprites" tab. Split out of SiAmDenisePanel.qml purely
// for file size, alongside the Registers/Colors tabs -- see
// SiAmDeniseRegPanel.qml's own comment.
RowLayout {

    id: root

    required property var denise
    required property int numBase
    required property bool numPadded

    spacing: Style.mediumSpacing

    component Si16: SiWordViewControl {

        size: Size.small
        controlWidth: 44
        base: root.numBase
        padded: root.numPadded
    }

    // Left column: which sprites are currently armed, and the raw hardware
    // registers behind them. Two separate boxes (rather than one) so the
    // fixed-size armed row doesn't get stretched by the scrollable register
    // list beneath it.
    ColumnLayout {

        Layout.preferredWidth: 140
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        SiBox {

            title: qsTr("Armed")
            Layout.fillWidth: true
            spacing: Style.tinySpacing

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.tinySpacing

                Repeater {
                    model: 8
                    SiCheckBoxControl {
                        required property int index
                        readOnly: true
                        // denise.revision is read purely to give this binding a
                        // dependency to re-evaluate on -- spriteArmed(n) is
                        // Q_INVOKABLE, so calling it alone never triggers a
                        // re-evaluation when the armed state changes. See
                        // SiAmDeniseController::m_revision's own comment.
                        checked: { denise.revision; return denise.spriteArmed(index) }
                    }
                }
            }
        }

        //
        // Registers -- collision detection (CLXDAT/CLXCON/CLXCON2) lives
        // here rather than on the Registers tab's Control box: a collision
        // is inherently a sprite/playfield overlap, so it's sprite state,
        // not bitplane state. The raw per-sprite registers below it are
        // the chipset's own SPRxDATA/SPRxDATB/SPRxPOS/SPRxCTL, not the
        // decoded hstrt/vstrt/vstop/attach shown to the right -- this is
        // what's actually in the hardware right now, independent of
        // whichever sprite happens to be selected there.
        //

        SiScrollBox {

            title: qsTr("Registers")
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.tinySpacing

            ColumnLayout {

                spacing: Style.tinySpacing

                Si16 { l: qsTr("CLXDAT"); lwidth: 65; value: denise.clxdat }
                Si16 { l: qsTr("CLXCON"); lwidth: 65; value: denise.clxcon }
                Si16 { l: qsTr("CLXCON2"); lwidth: 65; value: denise.clxcon2 }

                Repeater {

                    model: 8

                    ColumnLayout {

                        required property int index

                        Layout.topMargin: Style.smallSpacing
                        spacing: -1

                        // denise.revision is read purely to give each binding
                        // below a dependency to re-evaluate on -- sprData(n)/
                        // sprDatb(n)/sprPos(n)/sprCtl(n) are Q_INVOKABLE, so
                        // calling one alone never triggers a re-evaluation
                        // when the register changes. See
                        // SiAmDeniseController::m_revision's own comment.
                        Si16 { l: qsTr("SPR%1DATA").arg(index); lwidth: 65; value: { denise.revision; return denise.sprData(index) } }
                        Si16 { l: qsTr("SPR%1DATB").arg(index); lwidth: 65; value: { denise.revision; return denise.sprDatb(index) } }
                        Si16 { l: qsTr("SPR%1POS").arg(index);  lwidth: 65; value: { denise.revision; return denise.sprPos(index) } }
                        Si16 { l: qsTr("SPR%1CTL").arg(index);  lwidth: 65; value: { denise.revision; return denise.sprCtl(index) } }
                    }
                }
            }
        }
    }

    SiBox {

        title: qsTr("Sprites")
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.tinySpacing

        SiSegmentedControl {

            Layout.fillWidth: true
            model: [0, 1, 2, 3, 4, 5, 6, 7].map(i => i.toString())
            currentIndex: denise.selectedSprite
            onActivated: (index) => denise.selectedSprite = index
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
