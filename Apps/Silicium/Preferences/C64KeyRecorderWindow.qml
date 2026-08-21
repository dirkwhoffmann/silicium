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
import Silicium.Preferences
import Silicium.Theme

Window {

    id: root

    required property PrefController controller

    title: "Key Map Recorder"
    visible: false
    width: column.implicitWidth + 2 * Style.largeSpacing
    height: column.implicitHeight + 2 * Style.largeSpacing
    color: Palette.background

    readonly property real keyUnit: 38
    readonly property real keyGap: 2

    Connections {

        target: AppController.inputManager

        function onKeyChanged() {
            controller.captureKey(AppController.inputManager.pKey)
        }
    }

    Component.onCompleted: {

        if (!controller.recording) controller.toggleRecording()
    }

    onClosing: if (controller.recording) controller.toggleRecording()

    ColumnLayout {

        id: column

        anchors.fill: parent
        anchors.margins: Style.largeSpacing
        spacing: Style.largeSpacing

        //
        // Header row
        //

        RowLayout {

            id: headerRow

            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Style.mediumSpacing

            SiText {

                text: "STEP 1: SELECT A C64 KEY TO RECORD"
                font.pixelSize: Style.small
                color: controller.selectedKey === -1 ? Palette.accent : Palette.tertiary
            }

            SiText {
                text: "|"
                color: Palette.tertiary
            }

            SiText {

                text: "STEP 2: PRESS A KEY ON THE PHYSICAL KEYBOARD"
                font.pixelSize: Style.small
                color: controller.selectedKey !== -1 ? Palette.accent : Palette.tertiary
            }

            /*
            SiText {

                text: controller.selectedKey === -1
                    ? "STEP 1: SELECT A KEY TO RECORD"
                    : "STEP 2: PRESS THE CORRESPONDING KEY ON YOUR PHYSICAL KEYBOARD"
                font.family: Fonts.main
                font.pixelSize: Style.small
                color: Palette.tertiary
            }

             */

            HSpacer {}

            NavBarGroup {

                NavTextButton {

                    symbol: "replay"
                    font.pixelSize: Style.large
                    onClicked: {
                        console.log("Resetting kb mapping")
                        controller.revertKeyMap()
                    }

                    SiToolTip {

                        text: "Revert to Default Keymap"
                    }
                }
            }
        }

        //
        // Key section
        //

        Item {

            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height

            Repeater {

                model: controller.keyModel

                delegate: SiButton {

                    id: keyControl

                    readonly property bool stacked: model.label.indexOf("\n") !== -1

                    x: model.x * (root.keyUnit + root.keyGap)
                    y: model.y * (root.keyUnit + root.keyGap)
                    width: model.width * root.keyUnit + (model.width - 1) * root.keyGap
                    height: model.height * root.keyUnit + (model.height - 1) * root.keyGap
                    text: model.label
                    font.family: model.specialFont ? Fonts.c64 : Fonts.main
                    font.pixelSize: stacked ? Style.tiny : Style.regular

                    onPressed: controller.selectKey(controller.selectedKey === model.nr ? -1 : model.nr)

                    // Hovering any key previews its current mapping.
                    // controller.selectedKey is referenced purely so this binding
                    // re-evaluates whenever a mapping is captured while the tooltip
                    // is already visible (mappingInfo() is a plain invokable call
                    // with no change notification of its own).
                    SiToolTip {

                        visible: keyControl.hovered
                        text: controller.selectedKey !== undefined ? controller.mappingInfo(model.nr) : ""
                    }

                    // Tints already-mapped keycaps blueish
                    Rectangle {

                        anchors.fill: parent
                        radius: Style.radius
                        color: "#400080FF"
                        visible: controller.selectedKey !== model.nr && controller.isMapped(model.nr)
                    }

                    // Highlights the key currently awaiting a scancode
                    Connections {

                        target: controller

                        function onSelectedKeyChanged() {
                            keyControl.down = (controller.selectedKey === model.nr) ? true : undefined
                        }
                    }
                }
            }
        }
    }
}
