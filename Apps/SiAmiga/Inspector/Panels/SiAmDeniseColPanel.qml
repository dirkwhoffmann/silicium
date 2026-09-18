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

// SiAmDenisePanel's "Colors" tab -- one box per AGA color bank (4 banks of
// 32 registers each; see SiAmDeniseController's own colorAt(n) comment).
// Split out of SiAmDenisePanel.qml purely for file size, alongside the
// Registers/Sprites tabs -- see SiAmDeniseRegPanel.qml's own comment.
GridLayout {

    id: root

    required property var denise

    columns: 2
    columnSpacing: Style.mediumSpacing
    rowSpacing: Style.mediumSpacing

    // One color-register swatch -- a plain circle, matching the round
    // NSColorWell style DenisePanel.swift's colorReg wells use.
    component Swatch: Rectangle {

        id: swatch

        property color value: "black"

        // #RRGGBB, computed from the QColor's own 0..1 float channels
        // rather than the raw 12-bit register -- colorAt(n) already expands
        // that to 8 bits per channel (see its own comment), and the swatch
        // shows exactly that expanded color, so the tooltip should match
        // what's on screen rather than the narrower register value.
        readonly property string hex: "#" + [value.r, value.g, value.b]
            .map(c => Math.round(c * 255).toString(16).padStart(2, '0'))
            .join('')
            .toUpperCase()

        implicitWidth: 28
        implicitHeight: 28
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 4 // width / 2
        color: value
        border.width: 1
        border.color: Palette.tertiary

        HoverHandler { id: hoverHandler }
        property alias hovered: hoverHandler.hovered

        SiToolTip { text: swatch.hex }
    }

    Repeater {

        model: 4

        SiBox {

            id: bankBox
            required property int index

            title: qsTr("Bank %1").arg(index)
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                columns: 8
                columnSpacing: Style.tinySpacing
                rowSpacing: Style.tinySpacing

                Repeater {
                    model: 32
                    Swatch {
                        required property int index
                        // denise.colorRevision is read purely to give this
                        // binding a dependency to re-evaluate on -- colorAt(n)
                        // is Q_INVOKABLE, so calling it alone never triggers a
                        // re-evaluation when the palette changes. See
                        // SiAmDeniseController::m_colorRevision's own comment.
                        value: { root.denise.colorRevision; return root.denise.colorAt(bankBox.index * 32 + index) }
                    }
                }
            }
        }
    }
}
