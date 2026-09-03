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

// Amiga counterpart to SiC64's inspector windows -- but shaped differently.
// SiC64 gives every panel (Events, CIA, Bus, CPU, Memory, VIC, SID) its own
// top-level window, each built on the generic SiC64InspectorWindow chrome.
// The Amiga side has more panels (11 vs. SiC64's 7) and none of them have
// real content yet, so rather than port that one-window-per-panel shape
// as-is, this hosts every panel in a single window with a Configurator-style
// sidebar (see SiAmConfigWindow.qml, which this borrows its sidebar/
// StackLayout structure from) -- one toolbar, one set of chrome, switching
// pages instead of switching windows. Nothing stops a later pass from
// splitting panels back out into their own windows if that turns out to
// matter once they have real content.

Window {

    id: root

    // Page indices. Must match the order of the sidebar model and the
    // StackLayout children below.
    enum Page {
        CPU,
        Bus,
        CIA,
        Memory,
        Agnus,
        Copper,
        Blitter,
        Paula,
        Denise,
        Port,
        Events
    }

    required property SiAmController controller
    required property SiAmActions actions
    readonly property var inspectorController: controller.inspectorController
    property int currentIndex: 0

    title: qsTr("Inspector")
    visible: false
    width: 880
    height: 440
    minimumWidth: 640
    minimumHeight: 320
    color: Palette.background

    onVisibleChanged: inspectorController.active = visible
    Component.onCompleted: inspectorController.active = visible

    // Brings the window to the front, optionally switching to a specific page
    function showPage(page) {

        currentIndex = page
        sidebar.currentIndex = page
        show()
        raise()
        requestActivate()
    }

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        SiAmInspectorToolbar {

            Layout.fillWidth: true
            amiga: root.controller
            actions: root.actions
            inspectorController: root.inspectorController
        }

        RowLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true
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

                        {name: "CPU", symbol: "memory"},
                        {name: "Bus", symbol: "cable"},
                        {name: "CIA", symbol: "developer_board"},
                        {name: "Memory", symbol: "memory_alt"},
                        {name: "Agnus", symbol: "hub"},
                        {name: "Copper", symbol: "content_copy"},
                        {name: "Blitter", symbol: "bolt"},
                        {name: "Paula", symbol: "music_note_2"},
                        {name: "Denise", symbol: "monitor"},
                        {name: "Ports", symbol: "usb"},
                        {name: "Events", symbol: "schedule"},
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
                currentIndex: root.currentIndex

                SiAmCPUPanel { controller: root.controller }
                SiAmBusPanel { controller: root.controller }
                SiAmCIAPanel { controller: root.controller }
                SiAmMemoryPanel { controller: root.controller }
                SiAmAgnusPanel { controller: root.controller }
                SiAmCopperPanel { controller: root.controller }
                SiAmBlitterPanel { controller: root.controller }
                SiAmPaulaPanel { controller: root.controller }
                SiAmDenisePanel { controller: root.controller }
                SiAmPortPanel { controller: root.controller }
                SiAmEventsPanel { controller: root.controller }
            }
        }
    }
}
