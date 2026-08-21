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
import Silicium.Theme

GridLayout {

    width: parent.width
    columns: 2
    rowSpacing: Style.smallSpacing
    columnSpacing: Style.smallSpacing

    property int columnWidth: width / columns

    Item {
        Layout.preferredWidth: columnWidth - (columnSpacing / 2)
    }
    Item {
        Layout.preferredWidth: columnWidth- (columnSpacing / 2)
    }
}
