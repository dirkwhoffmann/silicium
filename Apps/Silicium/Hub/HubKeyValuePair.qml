// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Layouts
import Silicium.Theme

RowLayout {

    id: root
    property alias keyText: keyLabel.text
    property alias valueText: valueLabel.text
    property int keyWidth: 60
    property int valueWidth: 0

    spacing: Style.mediumSpacing
    Layout.fillWidth: true

    SiText {
        id: keyLabel
        visible: text !== ""
        Layout.fillWidth: root.keyWidth <= 0
        Layout.preferredWidth: root.keyWidth > 0 ? root.keyWidth : -1
        color: Palette.primary
        Rectangle { anchors.fill: parent; color: "#10ff0000" }
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
    }

    SiText {
        id: valueLabel
        Layout.fillWidth: root.valueWidth <= 0
        Layout.preferredWidth: root.valueWidth > 0 ? root.valueWidth : -1
        color: Palette.secondary
        Rectangle { anchors.fill: parent; color: "#1000ff00" }
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
    }
}
