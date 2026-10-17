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
import Sulfur

/* An ApplicationWindow that draws its own title bar (see SiWindow, which is
 * the same for a plain Window).
 *
 * The title bar is the top part of the window's header. A toolbar can be
 * placed below it by assigning to 'toolbar', which replaces ApplicationWindow's
 * own 'header' property for this purpose. The remaining children are placed
 * below the title bar and the toolbar, as usual.
 *
 * Set 'titleText' instead of 'title': the native title is empty, because its
 * view swallows mouse clicks and so blocks dragging the window.
 */
ApplicationWindow {

    id: root

    // The title that is drawn in the title bar
    property string titleText: ""

    // An optional item below the title bar
    property alias toolbar: toolbarSlot.data

    /* The height of the title bar, as the window reports it.
     *
     * Read once, when the window gets shown, instead of binding to the safe
     * area: the safe area is recomputed whenever the layout changes, and this
     * value changes the layout (the header grows, the content moves down), so
     * a binding can keep the window busy forever.
     */
    property real titleBarInset: 0

    function updateTitleBarInset() {

        // The root item of the window. Unlike its descendants, its safe area
        // is not affected by the padding of the window.
        const rootItem = root.contentItem.parent ? root.contentItem.parent.parent : null
        const inset = rootItem ? rootItem.SafeArea.margins.top : 0
        if (inset > 0) root.titleBarInset = inset
    }

    // Connections rather than an onVisibleChanged handler, which a window
    // derived from this one would replace by declaring its own
    Connections {

        target: root
        function onVisibleChanged() { if (root.visible) Qt.callLater(root.updateTitleBarInset) }
    }

    Component.onCompleted: root.updateTitleBarInset()

    title: ""
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    color: Palette.background

    /* The header is drawn over the top of the window and does not push the
     * content down by itself, so this is done by the padding.
     */
    topPadding: root.header ? root.header.height : 0

    header: Column {

        Rectangle {

            width: parent.width
            height: root.titleBarInset
            color: Palette.titlebar

            // Dragging the title bar moves the window
            MouseArea {

                anchors.fill: parent
                onPressed: root.startSystemMove()
            }

            Text {

                anchors.centerIn: parent
                text: root.titleText
                color: Palette.secondary
                font.bold: true
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width / 2)
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {

                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: Palette.titlebar.darker(1.1)
            }
        }

        Item {

            id: toolbarSlot

            width: parent.width

            // The toolbar spans the window, as it did when it was the header
            onChildrenChanged: {

                for (const child of children) child.width = Qt.binding(() => toolbarSlot.width)

                height = Qt.binding(() =>
                    Math.max(0, ...Array.from(children, c => c.implicitHeight)))
            }
        }
    }
}
