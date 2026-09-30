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
 * The whole of the chrome's look is settled here, the title bar row included.
 * A window that has taken over that row says how deep it is and leaves the
 * rest alone:
 *
 *     SiToolbarWrapper {
 *         anchors { top: parent.top; left: parent.left; right: parent.right }
 *         titleBarInset: window.titleBarInset
 *     }
 *
 * so the strip reaches from the top of the window down, covering the row on
 * its way, and what colour any of it comes out is nothing the window needs an
 * opinion about. Where it sits and how far across it goes stay the caller's:
 * it anchors the thing and this only ever settles its own height.
 *
 * It is a layout rather than a plain item because everything in it is stacked:
 * the separator, then the strip, then inside that the two rows. Stating that
 * once, as an order, keeps each piece from having to name the one above it --
 * and a piece that hides is dropped from the stack rather than having to
 * collapse itself to nothing.
 */
ColumnLayout {

    id: root

    spacing: 0

    // The single switch for the whole strip: when false, neither row shows.
    property bool toolbarVisible: true

    /* How deep the row the windowing system would have put the title in is,
     * which only the window can know (it reads it off the safe area). Nothing
     * of ours goes in it -- the window draws the one thing that does -- but
     * the strip covers it, so that the row and what is under it are painted
     * by the same hand and cannot come out looking like two decisions.
     *
     * Zero where the window kept its title bar, and then the strip simply
     * starts at its own top edge.
     */
    property real titleBarInset: 0

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
     * tall as its rows and its own padding, and this is as tall as whichever
     * of its children are showing. No height is stated anywhere along that
     * chain: hide everything and the whole thing closes up to nothing by
     * itself, because a layout leaves out what is not visible.
     *
     * Nothing assigns 'height', so it follows the implicitHeight the layout
     * works out, the way any item's does.
     */

    // DebugRect {}

    //
    // Main
    //

    /* Paints the title bar row.
     *
     * The windowing system has stopped putting a backdrop there, so the row
     * would otherwise show whatever is behind it, and what goes in it is the
     * user's choice -- see titleBarFill above.
     *
     * With the chrome hidden it paints nothing. There is no strip left for
     * the row to belong to, so a band of colour across the top would be
     * chrome standing on its own; clearing it hands the row back to whatever
     * is behind, which is the picture when the strip is laid over it and the
     * window's own background when it is not.
     */
    Rectangle {

        id: titleRow

        Layout.fillWidth: true
        Layout.preferredHeight: root.titleBarInset

        color: root.toolbarVisible || Preferences.titleBar === 0 ? root.titleBarFill : "transparent"
    }

    /* Sets the strip off from the title bar row above it.
     *
     * Only the standard fill needs it. Unified gives the row and the strip
     * the same colour on purpose, and a line across the middle of that would
     * undo the very thing it is for; standard sets them apart already, and
     * this makes the boundary deliberate rather than a place where two
     * greys happen to meet.
     *
     * It is drawn below the title bar row rather than in its last pixel, so
     * that the row comes out exactly as deep as the windowing system said.
     * Standing in the stack between the row and the strip, it takes its own
     * space rather than covering either.
     *
     * It stays when the rows are hidden. What it marks is the foot of the
     * title bar row, and that row is there with or without them; the strip
     * merely happens to be the usual thing on the other side of it.
     */
    Rectangle {

        id: separator

        Layout.fillWidth: true
        Layout.preferredHeight: 1

        visible: Preferences.titleBar === 0
        color: Qt.alpha(Palette.background, 0.5)
    }

    /* What the strip stands on.
     *
     * The strip may be held off the side edges (see inset), and something has
     * to be behind it where it is. Attached, that is the same fill again, so
     * the strip and its surround read as one band of chrome with the picture
     * starting below all of it. Overlaid there is nothing to put there: the
     * picture runs on underneath and around the strip, which is what makes it
     * look laid on top.
     *
     * With no inset the two coincide and this is simply never seen.
     */
    Rectangle {

        id: band

        Layout.fillWidth: true
        Layout.preferredHeight: container.height

        visible: root.toolbarVisible
        color: root.seeThrough ? "transparent" : root.fill

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
            height: layout.implicitHeight + 2 * root.padding

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
}
