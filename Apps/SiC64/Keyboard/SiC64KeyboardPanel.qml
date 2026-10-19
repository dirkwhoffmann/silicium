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
import Sulfur

// Visual content of the virtual C64 keyboard, shared by the standalone
// keyboard window (SiC64KeyboardWindow) and the slide-down keyboard sheet
// (SiC64KeyboardSheet).

ColumnLayout {

    id: root

    readonly property C64Controller controller: C64Controller
    readonly property var kc: controller.keyboardController

    readonly property real keyUnit: 38
    readonly property real keyGap: 2

    // Emitted whenever a key is pressed, reporting which mouse button was
    // used (Qt.LeftButton or Qt.RightButton). Consumers that dismiss on a
    // regular key press (e.g. the slide-down sheet) should react to
    // Qt.LeftButton only, since Qt.RightButton is used to toggle a key
    // (typically a modifier) without leaving it pressed.
    signal keyActivated(int button)

    spacing: Style.largeSpacing

    //
    // Modifier tracking
    //
    // Key cap labels (e.g. "1" vs "!" vs "BLK") follow the toggle buttons in
    // the icon bar, not the actual physical/virtual SHIFT, Commodore or CTRL
    // key state. This lets the user preview a modifier's key caps (e.g. by
    // toggling the Commodore button) without that key actually being held.
    //

    Binding { target: kc.keyModel; property: "shiftPressed"; value: iconBar.shift }
    Binding { target: kc.keyModel; property: "commodorePressed"; value: iconBar.commodore }
    Binding { target: kc.keyModel; property: "controlPressed"; value: iconBar.control }
    Binding { target: kc.keyModel; property: "lowercase"; value: iconBar.lowercase }

    //
    // Header row
    //

    RowLayout {

        id: headerRow

        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: Style.mediumSpacing

        HSpacer {}

        SiC64KeyboardIconBar { id: iconBar }

        HSpacer {}

        SuTemplateImage {

            id: mouseIcon1
            source: Assets.iconUrl(Assets.MousePress)
            opacity: 0.5
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
        }

        SuTemplateImage {

            id: mouseIcon2
            source: Assets.iconUrl(Assets.MousePush)
            opacity: 0.5
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.rightMargin: 10
        }
    }

    //
    // Key section
    //

    Item {

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height

        Repeater {

            model: root.kc.keyModel

            delegate: SuButton {

                id: control

                readonly property bool shiftLock: model.nr == 34

                // The Commodore key shows the company logo instead of a label
                readonly property bool commodoreKey: model.nr == 49
                readonly property bool stacked: model.label.indexOf("\n") !== -1

                accentedDown: true
                x: model.x * (root.keyUnit + root.keyGap)
                y: model.y * (root.keyUnit + root.keyGap)
                width: model.width * root.keyUnit + (model.width - 1) * root.keyGap
                height: model.height * root.keyUnit + (model.height - 1) * root.keyGap
                text: commodoreKey ? "" : model.label

                // The arrow keys (←, ↑, and the cursor keys with and without
                // SHIFT) show the same Phosphor icons as the Amiga keyboard
                phosphor: ({
                    "\u2190": "arrow-left",  "\u2191": "arrow-up",
                    "\u21E7": "arrow-up",    "\u21E9": "arrow-down",
                    "\u21E6": "arrow-left",  "\u21E8": "arrow-right"
                })[model.label] ?? ""
                tooltip: ""
                font.family: model.specialFont ? Fonts.c64 : Fonts.main
                font.pixelSize: stacked ? Style.tiny : Style.regular

                onPressed: shiftLock ? kc.toggle(model.nr) : kc.press(model.nr)
                onReleased: {

                    if (!shiftLock) { kc.release(model.nr) }
                    root.keyActivated(Qt.LeftButton)
                }

                // Tinted with the key's text color, so the logo follows the
                // theme and turns light when the key is pressed
                SuTemplateImage {

                    visible: control.commodoreKey
                    anchors.centerIn: parent
                    width: parent.width - 2 * Style.smallSpacing
                    height: parent.height * 0.55
                    source: "qrc:/icons/chicken-lips.svg"
                    color: control.fgColor
                }

                MouseArea {

                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: {

                        kc.toggle(nr)
                        root.keyActivated(Qt.RightButton)
                    }
                }

                Connections {

                    target: kc

                    function onKeyChanged(nr, isPressed) {

                        if (nr === -1) {
                            control.down = undefined
                        }
                        if (nr === model.nr) {
                            control.down = isPressed ? true : undefined
                        }
                    }
                }
            }
        }
    }
}
