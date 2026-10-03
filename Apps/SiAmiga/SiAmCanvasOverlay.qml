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

//
// The console overlay (RetroShell / Logger)
//

Item {

    id: root

    required property SiAmController amiga

    // Whether the logger is shown. RetroShell is up to the controller. The
    // window actions open and close the logger.
    property bool loggerOpen: false

    opacity: (amiga.retroShell || loggerOpen) ? 0.85 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {

        NumberAnimation {

            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {

        anchors.fill: parent
        color: "#000000"
    }

    StackView {

        id: stack
        anchors.fill: parent

        replaceEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1 }
        }
        replaceExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0 }
        }
    }

    Component {

        id: retroShellComponent
        SiAmRetroShell {
            controller: root.amiga
            blinkingCursor: false
        }
    }

    Component {

        id: loggerComponent
        LogView {
        }
    }

    property Component currentComponent: null

    function update() {

        const targetComponent = root.amiga.retroShell ? retroShellComponent
                               : root.loggerOpen ? loggerComponent
                               : null

        if (targetComponent && targetComponent !== currentComponent) {

            if (currentComponent) {
                stack.replace(targetComponent)
            } else {
                stack.replace(targetComponent, StackView.Immediate)
            }

            currentComponent = targetComponent
        }
    }

    onLoggerOpenChanged: update()

    Connections {

        target: root.amiga

        function onRetroShellChanged() {
            root.update()
        }
    }

    Component.onCompleted: update()
}
