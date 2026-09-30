// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Layouts
import Silicium.Preferences
import Silicium.Theme

/* This component embeds the title bar and the command bar (the toolbar and the
 * menu strip). Its appearance is controlled by three major options:
 *
 * overlayed:
 *
 *   If true, the command bar is drawn on top of the canvas with a
 *   subtle transparany effect. If false, the command bar is drawn solid, above
 *   the canvas.
 *
 * unified:
 *
 *   If true, the title bar and the command bar are drawn as a visually unified
 *   object. When the command bar hides, the title bar hides, too.
 *
 * compact:
 *
 *   If true, the command bar appears as single line of items, either showing
 *   the toolbar items or the menu strip. An additions icon is shown that
 *   allows the user to switch between the toolbar and the menu strip.
 */

ColumnLayout {

    id: root

    spacing: 0

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool compact

    // Title bar height
    required property real titleBarInset

    // Shows or hides the command bar
    property bool hidden: false

    // State of the menu / toolbar switch (0 = menu, 1 = toolbar)
    property int menuSwitch: 0

    // Computed properties
    readonly property bool showMenu: !root.hidden && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: !root.hidden && (!root.compact || menuSwitch === 1)

    // Colors
    readonly property color commandBarBg: root.hidden ?
        "transparent" :
        root.overlayed ? Qt.alpha(Palette.toolbar, 0.9) : Palette.toolbar

    readonly property color titleBarBg: root.unified
        ? commandBarBg
        : Palette.background

    // What each row holds, after the compact-mode button: an item, parented
    // into that row, filling whatever it does not already use.
    property alias menuContent: menuSlot.data
    property alias toolbarContent: toolbarSlot.data

    // How far the strip is held off the edges of the space it was given, and
    // how far its rows are held off its own edges.
    readonly property real inset: 0 // Style.mediumSpacing
    readonly property real padding: Style.smallSpacing //  mediumSpacing

    //
    // Main
    //

    //
    // Title bar
    //

    Rectangle {

        id: titleRow

        Layout.fillWidth: true
        Layout.preferredHeight: root.titleBarInset

        color: root.titleBarBg
    }

    //
    // Separator line
    //

    Rectangle {

        id: separator

        Layout.fillWidth: true
        Layout.preferredHeight: 1

        visible: !root.unified
        color: Qt.alpha(root.commandBarBg, 0.5)
    }

    //
    // Command bar
    //

    Rectangle {

        id: band

        Layout.fillWidth: true
        Layout.preferredHeight: container.height

        visible: !root.hidden
        color: root.commandBarBg

        Rectangle {

            id: container

            color: "transparent"

            anchors {

                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: root.inset
                rightMargin: root.inset
            }

            // Its rows, plus the padding it holds them off its own edges by.
            height: layout.implicitHeight + 2 * root.padding

            ColumnLayout {

                id: layout

                anchors.fill: parent
                anchors.margins: root.padding
                spacing: 0

                RowLayout {

                    Layout.fillWidth: true
                    visible: root.showMenu
                    spacing: 0

                    NavTextButtonFlat {

                        visible: root.compact
                        phosphor: "list"
                        text: qsTr("Show Toolbar")
                        onClicked: root.menuSwitch = 1
                    }

                    NavDivider {

                        visible: root.compact
                    }

                    Item {

                        id: menuSlot

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // The content fills this, so its own height says nothing
                        // about how tall the row wants to be. Its implicit
                        // height does, so that is what gets passed up.
                        implicitHeight: children.length > 0
                                        ? children[0].implicitHeight : 0
                    }
                }

                RowLayout {

                    Layout.fillWidth: true
                    visible: root.showToolbar
                    spacing: 0

                    NavTextButtonFlat {

                        visible: root.compact
                        phosphor: "list"
                        text: qsTr("Show Menu")
                        onClicked: root.menuSwitch = 0
                    }

                    NavDivider {

                        visible: root.compact
                    }

                    Item {

                        id: toolbarSlot

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // The content fills this, so its own height says nothing
                        // about how tall the row wants to be. Its implicit
                        // height does, so that is what gets passed up.
                        implicitHeight: children.length > 0
                                        ? children[0].implicitHeight : 0
                    }
                }
            }
        }
    }
}
