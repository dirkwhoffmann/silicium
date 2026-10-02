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

    implicitHeight: content.implicitHeight

    // Content
    property alias titleBarContent: titleBarSlot.data
    property alias menuContent: menuSlot.data
    property alias toolbarContent: toolbarSlot.data

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool compact
    required property bool hidden

    // Title bar height
    required property real titleBarInset

    // Window title, drawn in QML. The native title is not used, because
    // its view swallows mouse clicks and so blocks dragging the window.
    property string titleText: ""

    // State of the menu / toolbar switch (0 = menu, 1 = toolbar)
    property int menuSwitch: 0

    // Computed properties
    readonly property bool titleBarOverlayed: root.overlayed && root.unified
    readonly property bool commandBarOverlayed: root.overlayed

    readonly property bool showTitleBar: !root.hidden || !root.unified
    readonly property bool showCommandBar: !root.hidden
    readonly property bool showMenu: !root.hidden && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: !root.hidden && (!root.compact || menuSwitch === 1)

    // Where the picture below the chrome starts
    readonly property real canvasStart: !root.overlayed ? root.y + root.height
                                      : root.unified    ? 0
                                                        : root.titleBarInset

    // Colors
    readonly property real titleBarAlpha: titleBarOverlayed ? 0.9 : 1.0
    readonly property real commandBarAlpha: commandBarOverlayed ? 0.9 : 1.0
    readonly property color commandBarBg: Palette.toolbar
    readonly property color titleBarBg: root.unified ? Palette.toolbar : Palette.background

    //
    // Components
    //

    // A two pixel line, a light one on top of a dark one, which closes off the
    // command bar. Not drawn while the command bar is hidden.
    /*
    component Separator: ColumnLayout {

        property real alpha

        spacing: 0
        visible: !root.hidden

        Rectangle {

            Layout.fillWidth: true
            Layout.preferredHeight: 1
            // color: Palette.toolbar.lighter(1.05)
            color: Qt.alpha(Palette.toolbar.darker(1.1), alpha)
        }

        Rectangle {

            Layout.fillWidth: true
            Layout.preferredHeight: 1
            // color: Palette.toolbar.darker(1.1)
            color: Qt.alpha(Palette.toolbar.lighter(1.05), alpha)
        }
    }

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

            color: showTitleBar ? Qt.alpha(root.titleBarBg, root.titleBarAlpha) : "transparent"

            // Dragging the title bar moves the window. Declared first, so that
            // the items on top of it (the title and the content) get their
            // clicks.
            MouseArea {

                anchors.fill: parent
                onPressed: Window.window.startSystemMove()
            }

            Text {

                anchors.centerIn: parent
                visible: root.showTitleBar
                text: root.titleText
                color: Palette.secondary
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width / 2)
                horizontalAlignment: Text.AlignHCenter
            }

            Row {

                id: titleBarSlot

                anchors.right: parent.right
                anchors.rightMargin: Style.mediumSpacing
                anchors.verticalCenter: parent.verticalCenter

                spacing: Style.smallSpacing
            }

            Rectangle {

                visible: root.showTitleBar
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                Layout.fillWidth: true
                height: 1
                // Layout.preferredHeight: 1
                color: Qt.alpha(root.titleBarBg.darker(1.1), root.titleBarAlpha)
            }

        }

        //
        // Separator (optional)
        //

        /*
        Rectangle {

            visible: root.showTitleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(root.titleBarBg.darker(1.1), root.titleBarAlpha)
        }

         */

        Rectangle {

            visible: root.showCommandBar
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(root.commandBarBg.lighter(1.05), root.commandBarAlpha)
        }

        /*
        Separator {

            Layout.fillWidth: true
        }
        */

        //
        // Menu row
        //

        Rectangle {

            visible: root.showMenu
            color: Qt.alpha(root.commandBarBg, root.commandBarAlpha)
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
            color: Qt.alpha(root.commandBarBg, root.commandBarAlpha)
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

            visible: root.showCommandBar
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(root.commandBarBg.darker(1.1), root.commandBarAlpha)
        }

        /*
        Separator {

            Layout.fillWidth: true
        }

         */
    }
}
