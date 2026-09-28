// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Preferences
import Silicium.Theme

/* The strip the menu and toolbar are drawn in.
 *
 * This is the half of the chrome that is the same whichever machine is being
 * emulated: how tall the strip is, which of its two rows are on show, and
 * what it is filled with. The other half -- what the rows actually contain --
 * belongs to the emulator, which supplies it as a child that fills this:
 *
 *     SiToolbarWrapper {
 *         id: toolbar
 *         toolbarVisible: window.toolbarVisible
 *         compactMenu: window.compactMenu
 *
 *         SiAmToolbar { anchors.fill: parent; wrapper: toolbar; ... }
 *     }
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

    /* Compact mode: only one row at a time, the menu or the icons, swapped by
     * a button the emulator's own rows carry. The state lives here because it
     * decides how tall the strip is, and the rows reach it through the
     * 'wrapper' they are given.
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
    readonly property bool showAny: showMenu || showToolbar

    // The height of one row, which the rows themselves ask for as well.
    readonly property real rowHeight: 28

    /* A transparent overlay (Preferences.overlayType) lets the picture show
     * through the strip instead of the theme's own fill. It is dimmed rather
     * than cleared so that labels and icons keep something to stand against
     * -- a bare picture behind them is unreadable on anything but a dark
     * scene. An attached menu has the row to itself and is always filled,
     * whatever the overlay type happens to say.
     */
    readonly property bool seeThrough: Preferences.menuType === 1
                                       && Preferences.overlayType === 1

    implicitHeight: (showMenu ? rowHeight : 0)
                    + (showToolbar ? rowHeight : 0)
                    + (showAny ? 1 : 0)
    height: implicitHeight

    // Declared before anything a caller adds, so their rows are drawn on top
    // of this rather than behind it.
    Rectangle {

        anchors.fill: parent

        color: root.seeThrough
            ? Qt.rgba(Palette.toolbar.r, Palette.toolbar.g, Palette.toolbar.b, 0.55)
            : Palette.toolbar

        Rectangle {

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Palette.toolbarBorder
        }
    }
}
