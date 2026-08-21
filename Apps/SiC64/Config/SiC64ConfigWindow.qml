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
import Silicium.Theme

Window {

    id: root

    // Page indices. Must match the order of the sidebar model and the
    // StackLayout children below.
    enum Page {
        Roms,
        Hardware,
        Devices,
        Performance,
        Audio,
        Video,
        Server
    }

    required property C64Controller controller
    readonly property var config: controller.configController
    readonly property var cc: controller.configController
    property int currentIndex: 0

    title: "Configurator"
    visible: false
    width: 860
    height: 440
    color: Palette.background

    // Brings the window to the front, optionally switching to a specific page
    function showPage(page) {

        currentIndex = page
        sidebar.currentIndex = page
        show()
        raise()
        requestActivate()
    }

    Connections {

        target: cc

        function onShowError(title, text) {

            errorDialog.titleText = title
            errorDialog.bodyText = text
            errorDialog.buttons = Dialog.Ok
            errorDialog.open()
        }
    }

    SiUserDialog {

        id: errorDialog
        sound: true
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

                model: [

                    {name: "Roms", symbol: "memory_alt"},
                    {name: "Hardware", symbol: "developer_board"},
                    {name: "Devices", symbol: "flowchart"},
                    {name: "Peformance", symbol: "sprint"},
                    {name: "Audio", symbol: "music_note_2"}, //"discover_tune"},
                    {name: "Video", symbol: "monitor"},
                    {name: "Server", symbol: "nest_remote_comfort_sensor"},
                ]

                delegate: ItemDelegate {

                    required property int index
                    required property string name
                    required property string symbol

                    id: category
                    width: parent?.width ?? 0
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

        StackLayout {

            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 0 // Style.mediumSpacing
            Layout.rightMargin: 0 // Style.mediumSpacing
            Layout.topMargin: 0 // Style.mediumSpacing
            Layout.bottomMargin: 0 // Style.mediumSpacing
            currentIndex: root.currentIndex

            SiC64RomConfig {
                controller: root.controller
            }

            SiC64HardwareConfig {
                controller: root.controller
            }

            SiC64DevicesConfig {
                controller: root.controller
            }

            SiC64PerformanceConfig {
                controller: root.controller
            }

            SiC64AudioConfig {
                controller: root.controller
            }

            SiC64VideoConfig {
                controller: root.controller
            }

            SiC64ServerConfig {
                controller: root.controller
            }
        }
    }
}
