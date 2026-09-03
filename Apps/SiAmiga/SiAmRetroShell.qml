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
import Silicium.Controllers
import Silicium.Assets
import Silicium.Theme

// Direct port of SiC64RetroShell.qml. Both apps' cores share the same
// RetroShellAPI shape (RetroShellInfo.cursorRel, RSKey, text()/press()) --
// see SiAmController::pressRetroShellKey(), a line-for-line port of
// C64Controller's own -- so this view needed no adaptation beyond the
// controller type it binds to.
Rectangle {

    id: root

    required property SiAmController controller
    property alias blinkingCursor: fakeCursor.isAnimated

    color: "transparent"

    ScrollView {

        id: scrollView
        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        focus: true
        Keys.priority: Keys.BeforeItem

        Connections {

            target: controller

            function onRetroShellChanged() {
                if (controller.retroShell) root.forceActiveFocus()
            }
        }

        Keys.onPressed: (event) => {

            controller.pressRetroShellKey(event.key, event.modifiers, event.text)
            event.accepted = true
        }

        TextArea {

            id: textArea

            Component.onCompleted: {

                Qt.callLater(function() {
                    textArea.forceActiveFocus()
                })
            }

            Connections {

                target: controller

                function onRetroShellChanged() {

                    Qt.callLater(function() {
                        textArea.forceActiveFocus()
                    })
                }
            }

            text: controller.retroShellText || ""

            onTextChanged: {
                textArea.cursorPosition = textArea.length
            }

            color: "lightsteelblue"
            font.family: Fonts.mono
            font.weight: 600
            font.pixelSize: 14
            readOnly: true
            cursorVisible: false
            wrapMode: Text.Wrap
            selectByMouse: true
            padding: Style.mediumSpacing

            background: Rectangle {
                color: "transparent"
            }

        }

        //
        // Cursor
        //

        Rectangle {

            id: fakeCursor
            width: 10
            height: 16
            color: "white"
            opacity: 0.5
            radius: 1
            visible: true

            property bool isAnimated: true
            property int cursorPos: Math.max(0, textArea.length + controller.cursorPos - 1)

            x: textArea.positionToRectangle(cursorPos).x
            y: textArea.positionToRectangle(cursorPos).y

            SequentialAnimation on opacity {

                id: cursorAnimation
                loops: Animation.Infinite
                running: fakeCursor.isAnimated && fakeCursor.visible

                PauseAnimation {
                    duration: 400
                }
                NumberAnimation {
                    from: 0.5;
                    to: 0; duration: 60
                }
                PauseAnimation {
                    duration: 400
                }
                NumberAnimation {
                    from: 0;
                    to: 0.5; duration: 60
                }
            }

            onIsAnimatedChanged: {

                if (!isAnimated) {
                    opacity = 0.5;
                }
            }
        }
    }
}
