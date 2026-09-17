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
import QtQuick.Layouts
import Silicium.Preferences
import Silicium.Theme

// SiBox variant whose content lives inside a ScrollView instead of sitting
// directly in the Pane -- for a box whose content can outgrow the space
// available to it (a register list, the CPU panel's flag grid, ...): the
// content stretches to fill the box when there's room, and scrolls,
// independently of any sibling box, once the box shrinks below what its
// content needs. This is the ScrollView-around-a-Layout trick used by hand
// throughout the Inspector panels (SiAmCIAPanel's Registers box first,
// SiAmPaulaPanel's Interrupts/Disk Controller/Audio boxes, ...) -- factored
// out here so a panel just declares one of these instead of repeating the
// ScrollView plus the Math.max(implicitWidth/Height, available...) pair by
// hand every time.
//
// Usage is identical to a plain SiBox: children added directly become rows
// in the (scrollable) content column.
//
//     SiScrollBox {
//         title: qsTr("Registers")
//         GridLayout { columns: 2; ... }
//     }
Item {

    id: root

    property alias title: header.text
    property alias font: header.font
    property color color: Palette.elevation
    property color borderColor: Palette.surface
    property alias spacing: container.spacing
    default property alias content: container.data

    // The Pane's own padding, i.e. the gap between the box's border and its
    // (scrollable) content -- see SiBox's own 'padding' for why this is
    // exposed rather than hardcoded.
    property alias padding: pane.padding

    // Control-size level (see Size), forwarded to any sized children placed
    // inside the box's content column.
    property int size: Size.regular

    implicitWidth: theColumn.implicitWidth
    implicitHeight: theColumn.implicitHeight

    // A box that scrolls its own content should never be blocked from
    // shrinking below that content's natural size by the Item default
    // (Layout.minimumWidth/Height default to implicitWidth/Height, since
    // this root is a plain Item rather than a Layout) -- that's the whole
    // point of the ScrollView below, so it's set here rather than left for
    // every caller to remember.
    Layout.minimumWidth: 0
    Layout.minimumHeight: 0

    ColumnLayout {

        id: theColumn
        anchors.fill: parent
        spacing: 0

        SiLabel {

            id: header
            visible: title !== ""
            leftPadding: Style.mediumSpacing
            font.pixelSize: Style.small
        }

        Pane {

            id: pane
            Layout.fillWidth: true
            Layout.fillHeight: true

            background: Rectangle {

                id: paneBg
                radius: Style.radius
                color: root.color
                border.width: 1
                border.color: root.borderColor
            }

            ScrollView {

                id: scrollView
                anchors.fill: parent
                clip: true
                contentWidth: container.width
                contentHeight: container.height

                // The larger of the content column's own implicit size and
                // the ScrollView's available size -- stretches to fill a
                // bigger box, and only falls back to scrolling once the box
                // gets smaller than the content's natural size (see
                // SiAmCPUPanel.qml's Layout.fillWidth comment for the
                // related default-heuristic pitfall this sidesteps).
                ColumnLayout {

                    id: container

                    width: Math.max(implicitWidth, scrollView.availableWidth)
                    height: Math.max(implicitHeight, scrollView.availableHeight)
                }
            }
        }
    }
}
