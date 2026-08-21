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
import Silicium.Theme

AbstractButton {

    id: root

    property string symbol
    property string awesome

    property color primary: Palette.primary
    property color disabled: Palette.disabled
    property color control: Palette.control
    property color controlSelected: Palette.controlSelected
    property color controlBorder: Palette.controlBorder
    property color controlBorderSelected: Palette.controlBorderSelected
    property color accent: Palette.accent
    property color accentText: Palette.accentText

    font.family: symbol ? Fonts.symbols : Fonts.awesome
    font.pixelSize: Style.regular

    implicitHeight: 24
    implicitWidth: implicitHeight

    leftPadding: 4
    rightPadding: 4

    background: Rectangle {

        radius: Style.radius
        border.width: 1
        border.color: root.down ? root.accent
            : root.hovered ? root.controlBorderSelected
            : root.controlBorder
        color: root.down ? root.accent
            : root.hovered ? root.controlSelected
            : root.control
        opacity: root.enabled ? 1.0 : 0.5
    }

    contentItem: SiText {

        text: root.symbol ? root.symbol : root.awesome
        font: root.font
        color: root.down ? root.accentText
            : root.enabled ? root.primary
            : root.disabled
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
