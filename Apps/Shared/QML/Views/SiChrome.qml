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
    property list<QtObject> menuContent
    property list<QtObject> toolbarContent
    property alias statusBarContent: statusBarSlot.data

    // Visual style
    required property bool overlayed
    required property bool unified
    required property bool compact

    // If false, the menu is native and the chrome has no menu row
    property bool customMenu: true

    // Shows or hides the command bar and the status bar
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
    readonly property bool showTitleBar: root.showCommandBar || !root.unified
    readonly property bool showMenu: root.customMenu && (!root.compact || menuSwitch === 0)
    readonly property bool showToolbar: !root.customMenu || !root.compact || menuSwitch === 1
    // readonly property bool showMenu: root.customMenu && root.showCommandBar && (!root.compact || menuSwitch === 0)
    // readonly property bool showToolbar: root.showCommandBar && (!root.customMenu || !root.compact || menuSwitch === 1)
    // readonly property bool showCommandBar: root.showMenu || root.showToolbar

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

    /* The background of the title bar, the command bar and the status bar.
     * Draws the fill, an optional drop shadow, and optional lines along the
     * top and bottom edge. The children are the content of the bar.
     *
     * If 'translucent' is set, the bar is somewhat see-through and gets more
     * opaque while the mouse is over it.
     */
    component BarRect: Item {

        id: bar

        property color color: Palette.toolbar
        property color lineColor: Palette.toolbarBorder
        property bool filled: true          // False: draws nothing
        property bool translucent: false
        property real shadow: 0             // Vertical offset, 0 = no shadow
        property bool topLine: false
        property bool bottomLine: false

        // Opacity of the content while the bar is translucent and not hovered
        property real idleOpacity: 1.0

        default property alias content: inner.data

        implicitHeight: inner.implicitHeight

        readonly property real fillAlpha: translucent && !hover.hovered ? 0.9 : 1.0
        readonly property real lineAlpha: translucent && !hover.hovered ? 0.6 : 1.0

        HoverHandler { id: hover }

        Rectangle {

            visible: bar.filled
            anchors.fill: parent
            color: Qt.alpha(bar.color, bar.fillAlpha)
            Behavior on color { ColorAnimation { duration: 200 } }

            layer.enabled: bar.shadow !== 0
            layer.effect: MultiEffect {

                shadowEnabled: true
                shadowColor: "#80000000"
                shadowBlur: 0.8
                shadowVerticalOffset: bar.shadow
            }
        }

        ColumnLayout {

            id: inner
            anchors.fill: parent
            spacing: 0
            opacity: bar.translucent && !hover.hovered ? bar.idleOpacity : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {

            visible: bar.filled && bar.topLine
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: Qt.alpha(bar.lineColor, bar.lineAlpha)
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Rectangle {

            visible: bar.filled && bar.bottomLine
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Qt.alpha(bar.lineColor, bar.lineAlpha)
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // The title bar: the window title and the buttons on its right
    component TitleBar: Item {

        Layout.fillWidth: true
        Layout.preferredHeight: root.titleBarInset


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
                // background: Rectangle { color: Palette.toolbar; radius: height / 2 }
                onClicked: root.window.actionsRef.toggleCommandBar.trigger()
            }

            SuSymbolButton {

                symbol: "page_footer"
                color: root.showTitleBar ? Palette.secondary : "white"
                // background: Rectangle { color: Palette.toolbar; radius: height / 2 }
                onClicked: root.window.actionsRef.toggleStatusBar.trigger()
            }
        }
    }

    //
    // CommandBar
    //

    component CommandBar: ColumnLayout {

        Layout.fillWidth: true
        visible: root.showCommandBar
        spacing: 0

        //
        // Menu row
        //

        Item {

            visible: root.showMenu
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

                    data: root.menuContent

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

        Item {

            visible: root.showToolbar
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

                    data: root.toolbarContent

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onChildrenChanged: {

                        implicitHeight = Qt.binding(() =>
                            Math.max(0, ...Array.from(children, c => c.implicitHeight)))
                    }
                }
            }
        }
    }

    //
    // Main
    //
    // A unified title bar is drawn together with the command bar. Otherwise,
    // the title bar is a bar of its own.
    //

    Loader {

        id: content

        anchors { left: parent.left; right: parent.right; top: parent.top }
        sourceComponent: root.unified ? unifiedBars : splitBars
    }

    //
    // Header (unified)
    //

    Component {

        id: unifiedBars

        BarRect {

            filled: root.showCommandBar
            translucent: root.overlayed
            idleOpacity: 0.5
            shadow: root.overlayed ? 4 : 0
            bottomLine: true

            TitleBar { }
            CommandBar { }
        }
    }

    //
    // Header (split)
    //

    Component {

        id: splitBars

        ColumnLayout {

            spacing: 0

            BarRect {

                Layout.fillWidth: true
                color: Palette.titlebar
                lineColor: Palette.titlebar.darker(1.1)
                bottomLine: true

                TitleBar { }
            }

            BarRect {

                Layout.fillWidth: true
                visible: root.showCommandBar
                translucent: root.overlayed
                idleOpacity: 0.5
                shadow: root.overlayed ? 4 : 0
                topLine: root.overlayed
                bottomLine: true

                CommandBar { }
            }
        }
    }

    //
    // Status bar
    //

    BarRect {

        id: statusBar

        visible: root.showStatusBar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: implicitHeight

        translucent: root.overlayed
        shadow: root.overlayed ? -4 : 0
        topLine: true
        // bottomLine: root.overlayed

        Item {

            id: statusBarSlot

            Layout.fillWidth: true

            onChildrenChanged: {

                implicitHeight = Qt.binding(() =>
                    Math.max(0, ...Array.from(children, c => c.implicitHeight)))
            }
        }
    }
}
