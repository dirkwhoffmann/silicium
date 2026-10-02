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

/* This component embeds the title bar and the command bar (the toolbar and
 * menu strip). Its appearance is controlled by three major options:
 *
 * overlayed:
 *
 *   If true, the command bar is drawn on top of the canvas with a subtle
 *   transparency effect. If false, the command bar is drawn as a solid bar
 *   above the canvas.
 *
 * unified:
 *
 *   If true, the title bar and command bar are drawn as a visually unified
 *   element. When the command bar is hidden, the title bar is hidden as well.
 *
 * compact:
 *
 *   If true, the command bar appears as a single line of items, showing either
 *   the toolbar items or the menu strip. An additional icon allows the user
 *   to switch between the toolbar and the menu strip.
 */

Item {

    id: root

    // color: root.commandBarBg
    implicitHeight: content.implicitHeight

    // Content
    property alias menuContent: menuSlot.data
    property alias toolbarContent: toolbarSlot.data

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool compact

    // Shows or hides the command bar
    property bool hidden: false

    // State of the menu / toolbar switch (0 = menu, 1 = toolbar)
    property int menuSwitch: 0

    // Computed properties
    readonly property bool showMenu: !root.hidden && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: !root.hidden && (!root.compact || menuSwitch === 1)

    // Colors
    readonly property real alpha: root.overlayed ? 0.9 : 1.0
    readonly property color commandBarBg: Palette.toolbar

    //
    // Main
    //

    ColumnLayout {

        id: content

        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        //
        // Menu row
        //

        Rectangle {

            visible: root.showMenu
            color: Qt.alpha(root.commandBarBg, root.alpha)
            Layout.fillWidth: true
            implicitHeight: menuRow.implicitHeight

            RowLayout {

                id: menuRow
                anchors.fill: parent

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

                    onChildrenChanged: {

                        implicitHeight = Qt.binding(() =>
                            Math.max(0, ...Array.from(children, c => c.implicitHeight)))
                    }
                }
            }
        }

        //
        // Toolbar row
        //

        Rectangle {

            visible: root.showToolbar
            color: Qt.alpha(root.commandBarBg, root.alpha)
            Layout.fillWidth: true
            implicitHeight: toolbarRow.implicitHeight

            RowLayout {

                id: toolbarRow
                anchors.fill: parent
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

                    onChildrenChanged: {

                        implicitHeight = Qt.binding(() =>
                            Math.max(0, ...Array.from(children, c => c.implicitHeight)))
                    }
                }
            }
        }

        //
        // Separator
        //

        Rectangle {

            Layout.fillWidth: true
            // anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 0 }
            height: 1

            visible: !root.hidden
            color: Palette.toolbar.lighter(1.05)
        }

        Rectangle {

            Layout.fillWidth: true
            // anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 1 }
            height: 1

            visible: !root.hidden
            color: Palette.toolbar.darker(1.1)
        }
    }
}
