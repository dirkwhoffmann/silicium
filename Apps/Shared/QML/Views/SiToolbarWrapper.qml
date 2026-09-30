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
    property alias titleBarContent: titleBarSlot.data

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
    readonly property bool showTitleBar: !root.hidden || !root.unified
    readonly property bool showMenu: !root.hidden && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: !root.hidden && (!root.compact || menuSwitch === 1)

    // Colors
    readonly property real alpha: root.overlay ? 0.85 : 1.0
    readonly property color commandBarBg: Palette.toolbar
    readonly property color titleBarBg: root.unified ? Palette.toolbar : Palette.background

    // readonly property color titleBarOverlayBg: root.unified ? Qt.alpha(titleBarAttachedBg, 0.85)

    /*
    readonly property color commandBarBg: root.hidden ?
        "transparent" :
        root.overlayed ? Qt.alpha(Palette.toolbar, 0.85) : Palette.toolbar

    readonly property color titleBarBg: (root.unified && !root.hidden)
        ? commandBarBg :
        "transparent"
        : Palette.background
    */

    //
    // Main
    //

    ColumnLayout {

        id: content

        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0

        //
        // Title bar
        //

        Rectangle {

            id: titleRow

            Layout.fillWidth: true
            Layout.preferredHeight: root.titleBarInset

            color: showTitleBar ? Qt.alpha(root.titleBarBg, root.alpha) : "transparent"

            Row {

                id: titleBarSlot

                anchors.right: parent.right
                anchors.rightMargin: Style.mediumSpacing
                anchors.verticalCenter: parent.verticalCenter

                spacing: Style.smallSpacing
            }
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
        // Menu row
        //

        Rectangle {

            visible: root.showMenu
            color: Qt.alpha(root.commandBarBg, root.alpha)
            Layout.fillWidth: true
            implicitHeight: menuRow.implicitHeight

            RowLayout {

                id: menuRow
                Layout.fillWidth: true

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
                    implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
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
                    implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
                }
            }
        }
    }
}
