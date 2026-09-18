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
// 32 registers each; see SiAmDeniseController's own colorAt(n) comment),
// plus a "Registers" column on the left showing what the 32 physical
// COLORxx registers currently read back as (see colorRegPeek(n)'s own
// comment). Split out of SiAmDenisePanel.qml purely for file size, alongside
// the Registers/Sprites tabs -- see SiAmDeniseRegPanel.qml's own comment.
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

    // One color-register swatch -- a plain circle, matching the round
    // NSColorWell style DenisePanel.swift's colorReg wells use.
    component Swatch: Rectangle {

        id: swatch

        property color value: "black"

        // #RRGGBB and the individual 8-bit channels, computed from the
        // QColor's own 0..1 float channels rather than the raw 12-bit
        // register -- colorAt(n) already expands that to 8 bits per
        // channel (see its own comment), and the swatch shows exactly that
        // expanded color, so the tooltip should match what's on screen
        // rather than the narrower register value.
        readonly property string hex: "#" + [value.r, value.g, value.b]
            .map(c => Math.round(c * 255).toString(16).padStart(2, '0'))
            .join('')
            .toUpperCase()
        readonly property int redValue: Math.round(value.r * 255)
        readonly property int greenValue: Math.round(value.g * 255)
        readonly property int blueValue: Math.round(value.b * 255)

        implicitWidth: 28
        implicitHeight: 28
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 4 // width / 2
        color: value
        border.width: hovered ? 2 : 1
        border.color: Palette.tertiary

        HoverHandler { id: hoverHandler }
        property alias hovered: hoverHandler.hovered

        // Multi-line tooltip laid out as a label/colon/value mini table --
        // SiToolTip only supports a single plain-text string, so this
        // borrows its look (delay/timeout/padding/colors/background)
        // rather than using it directly, and builds its own GridLayout
        // content so the label column can be right-aligned and the value
        // column left-aligned around a centered ":".
        ToolTip {

            delay: 500
            timeout: 3000
            visible: swatch.hovered
            topPadding: Style.mediumSpacing
            bottomPadding: Style.mediumSpacing
            leftPadding: Style.mediumSpacing
            rightPadding: Style.mediumSpacing

            contentItem: GridLayout {

                columns: 3
                rowSpacing: 0
                columnSpacing: Style.tinySpacing

                SiText { text: qsTr("Hex");   Layout.alignment: Qt.AlignRight;  font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: ":";           Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: swatch.hex;    Layout.alignment: Qt.AlignLeft;   font.pixelSize: Style.small; color: Palette.primary }

                SiText { text: qsTr("Red");   Layout.alignment: Qt.AlignRight;  font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: ":";           Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: swatch.redValue;   Layout.alignment: Qt.AlignLeft; font.pixelSize: Style.small; color: Palette.primary }

                SiText { text: qsTr("Green"); Layout.alignment: Qt.AlignRight;  font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: ":";           Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: swatch.greenValue; Layout.alignment: Qt.AlignLeft; font.pixelSize: Style.small; color: Palette.primary }

                SiText { text: qsTr("Blue");  Layout.alignment: Qt.AlignRight;  font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: ":";           Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.small; color: Palette.primary }
                SiText { text: swatch.blueValue;  Layout.alignment: Qt.AlignLeft; font.pixelSize: Style.small; color: Palette.primary }
            }

            background: Rectangle {

                color: Palette.background
                border.color: Palette.backgroundBorder
                radius: Style.radius
            }
        }
    }

    // The 32 physical COLORxx registers -- distinct from the swatch grid on
    // the right, which always shows every bank's true color regardless of
    // whether it's currently bank-selected or readable. This column shows
    // exactly what a CPU/Copper peek of COLORnn returns right now, which is
    // 0 unless the chipset is AGA and RDRAM is set (see colorRegPeek(n)'s
    // own comment).
    SiScrollBox {

        title: qsTr("Registers")
        Layout.fillHeight: true
        spacing: Style.tinySpacing

        ColumnLayout {

            spacing: Style.tinySpacing

            Repeater {

                model: 32

                Si16 {
                    required property int index
                    l: qsTr("COLOR%1").arg(index.toString().padStart(2, '0'))
                    lwidth: 60
                    // denise.colorRevision is read purely to give this
                    // binding a dependency to re-evaluate on --
                    // colorRegPeek(n) is Q_INVOKABLE, so calling it alone
                    // never triggers a re-evaluation when the peeked value
                    // changes. See SiAmDeniseController::m_colorRevision's
                    // own comment.
                    value: { root.denise.colorRevision; return root.denise.colorRegPeek(index) }
                }
            }
        }
    }

    GridLayout {

        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        columnSpacing: Style.mediumSpacing
        rowSpacing: Style.mediumSpacing

        Repeater {

            model: 4

            SiBox {

                id: bankBox
                required property int index

                // Highlights the bank BPLCON3's BANK field currently maps
                // to the 32 physical COLORxx registers -- i.e. the bank the
                // "Registers" column on the left is actually reading from.
                readonly property bool current: index === root.denise.colorBank

                title: qsTr("Bank %1").arg(index)
                font.bold: current
                borderWidth: current ? 2 : 1
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
}
