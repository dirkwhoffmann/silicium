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

/* A window that draws its own title bar, so that the title bar follows the
 * theme instead of the look of the operating system. The window buttons are
 * still provided by the OS and are drawn on top of the title bar.
 *
 * The children are placed in the area below the title bar. An optional
 * toolbar can be placed in between by assigning to 'toolbar'. Set 'titleText'
 * instead of 'title': the native title is empty, because its view swallows
 * mouse clicks and so blocks dragging the window.
 */
Window {

    id: root

    default property alias content: contentArea.data

    // An optional item between the title bar and the content
    property alias toolbar: toolbarSlot.data

    // The title that is drawn in the title bar
    property string titleText: ""

    // The height of the title bar, as the window reports it
    readonly property real titleBarInset: root.contentItem.SafeArea.margins.top

    title: ""
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    color: Palette.background

    Rectangle {

        id: titleBar

        anchors { left: parent.left; right: parent.right; top: parent.top }
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

        anchors { left: parent.left; right: parent.right; top: titleBar.bottom }

        // The toolbar spans the window
        onChildrenChanged: {

            for (const child of children) child.width = Qt.binding(() => toolbarSlot.width)

            height = Qt.binding(() =>
                Math.max(0, ...Array.from(children, c => c.implicitHeight)))
        }
    }

    Item {

        id: contentArea

        anchors { left: parent.left; right: parent.right; top: toolbarSlot.bottom; bottom: parent.bottom }
    }
}
