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

    //
    // Registers -- collision detection (CLXDAT/CLXCON/
    // CLXCON2) lives here rather than on the Registers
    // tab's Control box: a collision is inherently a
    // sprite/playfield overlap, so it's sprite state, not
    // bitplane state.
    //

    SiBox {

        title: qsTr("Registers")
        Layout.preferredWidth: 140
        Layout.fillHeight: true
        spacing: Style.tinySpacing

        Si16 { l: qsTr("CLXDAT"); lwidth: 65; value: denise.clxdat }
        Si16 { l: qsTr("CLXCON"); lwidth: 65; value: denise.clxcon }
        Si16 { l: qsTr("CLXCON2"); lwidth: 65; value: denise.clxcon2 }

        VSpacer { }
    }

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
