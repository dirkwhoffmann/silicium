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
import Sulfur

Window {

    id: root

    readonly property C64Controller controller: C64Controller
    readonly property var kc: controller.keyboardController

    readonly property int nativeWidth: panel.implicitWidth + 2 * Style.largeSpacing
    readonly property int nativeHeight: panel.implicitHeight + 2 * Style.largeSpacing

    title: "Keyboard"
    visible: false
    width: nativeWidth
    height: nativeHeight
    minimumWidth: nativeWidth
    maximumWidth: nativeWidth
    minimumHeight: nativeHeight
    maximumHeight: nativeHeight
    color: Palette.background

    Component.onCompleted: { kc.window = root }

    onActiveChanged: kc.activeChanged(active)

    SiC64KeyboardPanel {

        id: panel

        anchors.fill: parent
        anchors.margins: Style.largeSpacing
    }
}
