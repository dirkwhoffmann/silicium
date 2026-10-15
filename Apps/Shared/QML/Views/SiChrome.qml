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
import QtQuick.Effects
import QtQuick.Layouts
import Silicium.Preferences
import Sulfur

/* The window chrome: the title bar, the command bar (the toolbar and menu
 * strip) and the status bar. The component fills its parent and floats above
 * the canvas. Its appearance is controlled by three major options:
 *
 * overlayed:
 *
 *   If true, the command bar and the status bar are drawn on top of the
 *   canvas with a subtle transparency effect. If false, the bars are drawn as
 *   solid bars above and below the canvas.
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

    required property VMWindow window

    // Content
    property alias menuContent: menuSlot.data
    property alias toolbarContent: toolbarSlot.data
    property alias statusBarContent: statusBarSlot.data

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool compact

    // If false, the menu is native and the chrome has no menu row
    property bool customMenu: true

    // Shows or hides the command bar and the status bar. The chrome owns this
    // state; the window actions change it.
    property bool showCommandBar: true
    property bool showStatusBar: true

    // Title bar height
    required property real titleBarInset

    // Window title, drawn in QML. The native title is not used, because
    // its view swallows mouse clicks and so blocks dragging the window.
    property string titleText: ""

    // Whether the machine is paused, which the title bar shows next to the title
    property bool paused: false

    // State of the menu / toolbar switch (0 = menu, 1 = toolbar)
    property int menuSwitch: 0

    // Computed properties
    readonly property bool titleBarOverlayed: root.overlayed && root.unified
    readonly property bool commandBarOverlayed: root.overlayed
    readonly property bool statusBarOverlayed: root.overlayed

    readonly property bool showTitleBar: root.showCommandBar || !root.unified
    readonly property bool showMenu: root.customMenu && root.showCommandBar && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: root.showCommandBar && (!root.customMenu || !root.compact || menuSwitch === 1)

    // The height of the title bar and the command bar together
    readonly property real chromeHeight: content.height

    /* Where the picture below the chrome starts and ends, in the coordinates
     * of the parent (which the chrome fills).
     *
     * Start: below the command bar, unless the chrome is overlaid. Then it is
     * below the title bar, or at the very top if that is unified with the
     * chrome.
     *
     * End: above the status bar, unless the chrome is overlaid. Then the
     * status bar is drawn over the picture, which runs down to the bottom.
     */
    readonly property real canvasStart: !root.overlayed ? root.chromeHeight
                                      : root.unified    ? 0
                                                        : root.titleBarInset
    readonly property real canvasEnd: !root.overlayed && root.showStatusBar
                                      ? root.height - statusBar.height
                                      : root.height

    /* The area between the command bar and the status bar, in the coordinates
     * of the parent. Independent of the overlay mode, as it is meant for what
     * must not be covered by the chrome (e.g., the console overlay).
     */
    readonly property real overlayStart: root.chromeHeight
    readonly property real overlayEnd: root.showStatusBar
                                       ? root.height - statusBar.height
                                       : root.height

    // Colors
    readonly property real titleBarAlpha: titleBarOverlayed ? 0.9 : 1.0
    readonly property real commandBarAlpha: commandBarOverlayed ? 0.9 : 1.0
    readonly property real statusBarAlpha: statusBarOverlayed ? 0.9 : 1.0
    readonly property color titleBarBg: root.unified ? Palette.toolbar : Palette.titlebar

    // Draws the background of the command bar and the status bar in overlay mode
    component BarBackground: Rectangle {

        property color tint: Palette.toolbar
        property bool hovered: false

        // Vertical offset of the drop shadow (negative: it falls upwards)
        property real shadowOffset: 4

        visible: root.overlayed
        anchors.fill: parent

        color: Qt.alpha(tint, hovered ? 1.0 : 0.9)
        border.color: Qt.alpha(tint, hovered ? 1.0 : 0.6)

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.8
            shadowVerticalOffset: shadowOffset
        }
    }

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

            SuSymbol {

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: titleLabel.left
                anchors.rightMargin: Style.smallSpacing
                visible: root.showTitleBar && root.paused
                phosphor: "pause"
                size: Size.small
                color: Palette.secondary
            }

            Text {

                id: titleLabel
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

                SuSymbolButton {

                    symbol: "page_header"
                    color: root.showTitleBar ? Palette.secondary : "white"
                    background: Rectangle {
                        visible: root.titleBarOverlayed
                        color: Palette.toolbar
                        radius: height / 2
                    }

                    onClicked: root.window.actionsRef.toggleCommandBar.trigger()
                }

                SuSymbolButton {

                    symbol: "page_footer"
                    color: Palette.secondary
                    background: Rectangle { color: Palette.toolbar; radius: height / 2 }

                    onClicked: root.window.actionsRef.toggleStatusBar.trigger()
                }
            }

            Rectangle {

                visible: root.showTitleBar && !root.unified
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                Layout.fillWidth: true
                height: 1
                // Layout.preferredHeight: 1
                color: "red" // Qt.alpha(root.titleBarBg.darker(1.1), root.titleBarAlpha)
            }

        }

        //
        // Command bar
        //

        /*
        Rectangle {

            visible: root.showCommandBar && !root.overlayed
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Palette.toolbar, root.commandBarAlpha)
        }
        */

        Item {

            id: commandBar

            visible: root.showMenu || root.showToolbar
            Layout.fillWidth: true
            Layout.preferredHeight: barRows.implicitHeight

            HoverHandler {

                id: commandBarHover
            }

            BarBackground {

                hovered: commandBarHover.hovered
            }

            ColumnLayout {

                id: barRows

                anchors.fill: parent
                spacing: 0

                Rectangle {

                    visible: root.showMenu
                    color: root.overlayed ? "transparent" : Qt.alpha(Palette.toolbar, root.commandBarAlpha)
                    Layout.fillWidth: true
                    implicitHeight: menuRow.implicitHeight

                    RowLayout {

                        id: menuRow
                        anchors.fill: parent

                        spacing: 0

                        SuBarButton {

                            visible: root.compact
                            phosphor: "list"
                            text: qsTr("Show Toolbar")
                            onClicked: root.menuSwitch = 1
                        }

                        SuBarDivider {

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
                    color: root.overlayed ? "transparent" : Qt.alpha(Palette.toolbar, root.commandBarAlpha)
                    Layout.fillWidth: true
                    implicitHeight: toolbarRow.implicitHeight

                    RowLayout {

                        id: toolbarRow
                        anchors.fill: parent
                        spacing: 0

                        SuBarButton {

                            visible: root.compact && root.customMenu
                            phosphor: "list"
                            text: qsTr("Show Menu")
                            onClicked: root.menuSwitch = 0
                        }

                        SuBarDivider {

                            visible: root.compact && root.customMenu
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

                Rectangle {

                    // visible: root.showCommandBar && !root.overlayed
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "red" // Palette.toolbarBorder  // "red" // Qt.alpha(Palette.toolbar.darker(1.1), root.commandBarAlpha)
                }
            }
        }
    }

    //
    // Status bar
    //

    Item {

        id: statusBar

        visible: root.showStatusBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: statusBarSlot.height + separatorHeight

        readonly property real separatorHeight: root.overlayed ? 0 : 1

        HoverHandler {

            id: statusBarHover
        }

        BarBackground {

            hovered: statusBarHover.hovered

            // Mirrors the command bar: the shadow falls on the picture
            shadowOffset: -4
        }

        // Separator to the picture (mirrors the one below the command bar)
        Rectangle {

            visible: root.showStatusBar && !root.overlayed
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: "red" // Qt.alpha(Palette.toolbar.darker(1.1), root.statusBarAlpha)
        }

        Rectangle {

            id: statusBarSlot

            color: root.overlayed ? "transparent" : Palette.toolbar
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.topMargin: statusBar.separatorHeight

            onChildrenChanged: {

                height = Qt.binding(() =>
                    Math.max(0, ...Array.from(children, c => c.implicitHeight)))
            }
        }
    }
}
