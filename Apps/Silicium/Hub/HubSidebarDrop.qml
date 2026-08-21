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
import Silicium.Controllers
import Silicium.Theme

DropArea {

    id: globalDropArea

    property bool dragActive: false

    anchors.fill: parent

    onEntered: (drag) => {

        if (drag.hasUrls) {
            dragActive = true
            drag.accept(Qt.LinkAction);
        }
    }

    onExited: dragActive = false

    onDropped: (drop) => {

        dragActive = false
        if (drop.hasUrls) {
            for (var i = 0; i < drop.urls.length; i++) {
                HubController.addVM(drop.urls[i])
            }
            drop.acceptProposedAction();
        }
    }

    Rectangle {

        anchors.fill: parent
        color: "transparent"
        border.color: dragActive ? Palette.border : "transparent"
        border.width: 4
        radius: Style.radius
    }
}
