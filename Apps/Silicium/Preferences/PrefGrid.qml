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

ConfigGrid { }
/*
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
*/

/*
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Item {

    id: root
    required property PrefController controller
    property int paneMargin: 0
    property int paneSpacing: 0

    readonly property int paneWidth: (grid.width - 2 * paneMargin - paneSpacing) / 2
    default property alias gridContent: grid.data

    GridLayout {

        id: grid

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.paneMargin
        anchors.rightMargin: root.paneMargin

        columns: 2
        rowSpacing: root.paneSpacing
        columnSpacing: root.paneSpacing
    }
}

 */