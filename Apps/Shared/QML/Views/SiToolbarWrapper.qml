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

/* The strip the menu and toolbar are drawn in.
 *
 * This is the half of the chrome that is the same whichever machine is being
 * emulated: how tall the strip is, which of its two rows are on show, what it
 * is filled with, and the buttons that swap the rows over in compact mode.
 * The other half -- what the rows themselves hold -- belongs to the emulator,
 * which hands each row its own contents:
 *
 *     SiToolbarWrapper {
 *         toolbarVisible: window.toolbarVisible
 *         compactMenu: window.compactMenu
 *
 *         menuContent: SiAmMenu { anchors.fill: parent; ... }
 *         toolbarContent: SiAmToolbar { anchors.fill: parent; ... }
 *     }
 *
 * Each goes into a row of its own, after whatever that row already carries,
 * and fills what is left of it.
 *
 * Where the strip sits is the window's business, not this component's: a
 * window that has taken over its title bar row starts it below that row, and
 * an ordinary one has nothing to allow for. So callers anchor it themselves
 * and this only ever settles its own height.
 */
Item {

    id: root

    // The single switch for the whole strip: when false, neither row shows.
    property bool toolbarVisible: true

    /* Compact mode: only one row at a time, the menu or the icons, swapped
     * by a button at the near end of whichever row is showing. Both the
     * state and the buttons live here: they are the same for every emulator,
     * and it is this that decides how tall the strip ends up.
     */
    property bool compactMenu: false
    property bool menuRevealed: false
    onCompactMenuChanged: menuRevealed = false

    // Which rows are on show. Both in normal mode; in compact mode they
    // alternate.
    readonly property bool showMenu: root.toolbarVisible
                                     && (!root.compactMenu || root.menuRevealed)
    readonly property bool showToolbar: root.toolbarVisible
                                        && !(root.compactMenu && root.menuRevealed)

    /* An overlaid strip lets the picture show through it instead of standing
     * on the theme's own fill. It is dimmed rather than cleared so that
     * labels and icons keep something to stand against -- a bare picture
     * behind them is unreadable on anything but a dark scene. An attached
     * strip has its row to itself, with no picture behind it to show, and is
     * filled outright.
     */
    readonly property bool seeThrough: Preferences.menuType === 1

    // What the strip is painted with. Stated once here because the window
    // reaches for it when painting the title bar row, and the two must never
    // disagree about what "the toolbar colour" is.
    readonly property color fill: root.seeThrough
        ? Qt.alpha(Palette.background, 0.9)
        : Palette.toolbar

    /* What the title bar row is painted with (Preferences.titleBar).
     *
     * The windowing system no longer puts a backdrop up there, so the row is
     * ours to fill, and this is the choice between the two ways of doing it.
     * "Standard" keeps it looking like the title bar of any other window,
     * with the strip reading as a separate thing below it. "Unified" gives
     * it the strip's own fill, so the row and the strip read as one block of
     * chrome -- the macOS unified look.
     *
     * It lives here rather than in the window because it is the same
     * decision for every window that has one, and because "the toolbar
     * colour" is this component's to define.
     */
    readonly property color titleBarFill: Preferences.titleBar === 1
                                          ? root.fill : Palette.background

    // What each row holds, after the compact-mode button: an item, parented
    // into that row, filling whatever it does not already use.
    property alias menuContent: menuSlot.data
    property alias toolbarContent: toolbarSlot.data

    // How far the strip is held off the edges of the space it was given, and
    // how far its rows are held off its own edges.
    readonly property real inset: 0 // Style.mediumSpacing
    readonly property real padding: Style.smallSpacing //  mediumSpacing

    /* As tall as what it holds.
     *
     * The rows are as tall as the controls standing in them, the strip is as
     * tall as its rows and its own padding, and this is as tall as the strip
     * and the inset it is held off the edges by. No row height is stated
     * anywhere along that chain: hide both rows and the whole thing closes
     * up to nothing by itself.
     *
     * Nothing assigns 'height', so it follows implicitHeight the way any
     * item's does.
     */
    implicitHeight: container.height
    // implicitHeight: container.height > 0 ? container.height + 2 * root.inset : 0

    // DebugRect {}

    //
    // Main
    //

    Rectangle {

        id: container

        anchors {

            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.inset
            rightMargin: root.inset
        }

        // Its rows, plus the padding it holds them off its own edges by.
        height: layout.implicitHeight > 0 ? layout.implicitHeight + 2 * root.padding : 0

        visible: root.toolbarVisible

        // radius: Style.radius
        // border.width: 1
        // border.color: Palette.overlayBorder

        color: root.fill

        ColumnLayout {

            id: layout

            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 0

            /*
            Rectangle {

                Layout.fillWidth: true
                height: 2
                color: "red"
            }

             */

            RowLayout {

                Layout.fillWidth: true
                visible: root.showMenu
                spacing: 0

                NavTextButtonFlat {

                    visible: root.compactMenu
                    phosphor: "list"
                    text: qsTr("Show Toolbar")
                    onClicked: root.menuRevealed = false
                }

                NavDivider {

                    visible: root.compactMenu
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

                    visible: root.compactMenu
                    phosphor: "list"
                    text: qsTr("Show Menu")
                    onClicked: root.menuRevealed = true
                }

                NavDivider {

                    visible: root.compactMenu
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
