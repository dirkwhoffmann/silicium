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

        // preferredWidth alone isn't enough to keep this column at a fixed
        // size: the Registers SiScrollBox below wants to be as wide as its
        // content (its ScrollView reports its own natural content width --
        // meant to scroll, not to size this column -- as an implicit size
        // that bubbles up through this ColumnLayout), and Qt Quick Layouts
        // never shrinks a child below whichever of minimumWidth/implicitWidth
        // is larger. maximumWidth is what actually clamps it, forcing the
        // ScrollView to scroll its content instead of stretching the
        // column -- which is the whole reason it's a *Scroll*Box. 480 (up
        // from the original 140) is wide enough for a sprite's four
        // registers side by side -- see the Repeater below -- and the
        // Sprites box on the right still has plenty of room since its own
        // preview was being stretched wider than the sprite itself needs.
        Layout.preferredWidth: 480
        Layout.minimumWidth: 0
        Layout.maximumWidth: 480
        Layout.fillHeight: true
        spacing: Style.mediumSpacing

        SiBox {

            title: qsTr("Armed")
            Layout.fillWidth: true
            spacing: Style.tinySpacing

            // 4x2 rather than a single row of 8 -- 8 checkboxes in one row
            // need more width than this 140px column has to spare (they'd
            // silently inflate the whole column past its preferredWidth
            // hint instead, stealing space from the Sprites box next to
            // it), and this box has the height to spare a second row.
            GridLayout {

                Layout.alignment: Qt.AlignHCenter
                columns: 8
                columnSpacing: Style.smallSpacing
                rowSpacing: Style.tinySpacing

                Repeater {
                    model: 8
                    SiCheckBoxControl {
                        required property int index
                        readOnly: true
                        l: qsTr("%1:").arg(index)
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

                    RowLayout {

                        required property int index

                        Layout.topMargin: Style.smallSpacing
                        spacing: Style.tinySpacing

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

    // Plain wrapper (not a SiBox itself) so the sprite selector can be
    // anchored to spritesBox's top edge and straddle its border, the same
    // "melted into the border" placement SiAmDenisePanel.qml's own
    // Registers/Colors/Sprites tabControl uses for stackBox -- title left
    // empty for the same reason that one has none: the segmented control
    // sitting on the border already identifies this box, a separate title
    // label would just repeat it.
    Item {

        Layout.fillWidth: true
        Layout.fillHeight: true

        SiBox {

            id: spritesBox
            anchors.fill: parent
            anchors.topMargin: spriteSelector.height / 2
            spacing: Style.tinySpacing

            VSpacer { size: Style.tinySpacing }

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.width: 1
                border.color: Palette.surfaceBorder
                radius: Style.radius
                clip: true

                // SiAmSpriteView's own height now tracks its actual content
                // (rows * cell size, see its updateImplicitSize()) rather
                // than being stretched or clipped to whatever this
                // Rectangle happens to be -- so a sprite taller than the
                // available space scrolls into view instead of being cut
                // off. width is bound to the viewport, not left implicit,
                // so cell size (derived from width) tracks this box's own
                // size as it resizes.
                ScrollView {

                    id: spriteScrollView
                    anchors.fill: parent
                    anchors.margins: Style.radius
                    clip: true

                    SiAmSpriteView {

                        width: spriteScrollView.availableWidth
                        spriteNr: denise.selectedSprite
                    }
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

        SiSegmentedControl {

            id: spriteSelector
            anchors.horizontalCenter: spritesBox.horizontalCenter
            anchors.verticalCenter: spritesBox.top

            model: [0, 1, 2, 3, 4, 5, 6, 7].map(i => i.toString())
            currentIndex: denise.selectedSprite
            onActivated: (index) => denise.selectedSprite = index
        }
    }
}
