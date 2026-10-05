// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Sulfur

/* A play button, shown over the picture while the machine is paused.
 * Clicking it resumes the machine.
 *
 * Anchor it where it should go (the windows put it in the upper right corner
 * of the canvas area); it floats above its siblings.
 */
SuOverlayButton {

    id: root

    // The machine. Needs an isPaused property and a run() method.
    required property var controller

    visible: opacity > 0.01
    size: 64
    symbol: "play_circle"
    opacity: controller.isPaused ? 1.0 : 0.0
    z: 1

    onClicked: controller.run()

    Behavior on opacity {

        NumberAnimation {
            duration: 350
            easing.type: Easing.Linear
        }
    }
}
