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

    property int currentIndex: 0

    title: "Preferences"
    visible: false
    width: 860
    height: 440
    color: Palette.background

    onActiveChanged: {

        // console.log("onActiveChanged: %d\n", root.active);

        if (root.active) {
            prefController.registerAsInputManagerDelegate()
        }
    }

    Component.onCompleted: {

        prefController.registerAsInputManagerDelegate()
    }

    PrefController {

        id: prefController
        window: root

        onDeviceChanged: {
            prefController.registerAsInputManagerDelegate()
        }
    }

    RowLayout {

        anchors.fill: parent
        spacing: 0

        //
        // Sidebar
        //

        Frame {

            Layout.preferredWidth: 180
            Layout.fillHeight: true
            Layout.topMargin: Style.mediumSpacing
            Layout.bottomMargin: Style.mediumSpacing
            Layout.leftMargin: Style.mediumSpacing
            Layout.rightMargin: 0

            background: Rectangle {

                color: Palette.surface
                radius: Style.borderRadius
            }

            ListView {

                id: sidebar
                anchors.fill: parent
                clip: true
                currentIndex: 0

                model: Preferences.developerMode ? [

                    {name: "General", symbol: "settings"},
                    {name: "Appearance", symbol: "select_window"},
                    {name: "Devices", symbol: "joystick"},
                    {name: "Controls", symbol: "keyboard_command_key"},
                    {name: "Developer", symbol: "bug_report"},
                    {name: "Playground", symbol: "playground"}

                ] : [

                    {name: "General", symbol: "settings"},
                    {name: "Appearance", symbol: "select_window"},
                    {name: "Devices", symbol: "joystick"},
                    {name: "Controls", symbol: "keyboard_command_key"},
                    {name: "Developer", symbol: "bug_report"},
                ]

                delegate: ItemDelegate {

                    required property int index
                    required property string name
                    required property string symbol

                    id: category
                    width: parent.width
                    text: name
                    highlighted: ListView.isCurrentItem

                    background: Rectangle {

                        color: highlighted ? Palette.accent : "transparent"
                        radius: highlighted || hovered ? Style.borderRadius : 0
                    }

                    contentItem: RowLayout {

                        spacing: Style.mediumSpacing

                        SiText {

                            Layout.alignment: Qt.AlignVCenter
                            text: symbol
                            font.family: Fonts.symbols
                            font.pixelSize: Style.iconMedium
                            color: highlighted ? Palette.accentText : Palette.accent
                        }

                        SiText {

                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: name
                            color: highlighted ? Palette.accentText : Palette.primary
                        }
                    }

                    onClicked: {

                        sidebar.currentIndex = index
                        root.currentIndex = index
                    }
                }
            }
        }

        //
        // Content area
        //

        StackLayout {

            id: stack

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 0 // Style.mediumSpacing
            Layout.rightMargin: 0 // Style.mediumSpacing
            Layout.topMargin: 0 // Style.mediumSpacing
            Layout.bottomMargin: 0 // Style.mediumSpacing

            currentIndex: root.currentIndex

            GeneralPrefs {
                controller: prefController
            }
            AppearancePrefs {
                controller: prefController
            }
            DevicesPrefs {
                controller: prefController
            }
            ControlsPrefs {
                controller: prefController
            }
            DeveloperPrefs {
                controller: prefController
            }
            PlaygroundPrefs {
                controller: prefController
            }
        }
    }
}
