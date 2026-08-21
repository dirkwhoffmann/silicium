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
import Silicium.Theme

/* Shared skeleton of every settings page: a toolbar above a scrollable column
 * of content. Used directly by the config panels and, through PrefPage, by the
 * preferences pages.
 */
Item {

    id: root

    // The page's toolbar. Declare a ConfigToolbar here, or leave it unset for a
    // page that needs none. A Loader puts it above the content: that way the
    // page declares the toolbar it wants while this component decides where it
    // goes, and an unset toolbar costs no space.
    property Component toolbar: null

    // Optional artwork, pinned to the right edge behind the content.
    property url background: ""

    // The artwork item itself, so content can sample it -- e.g. a SiGlass pane
    // wanting a blurred crop of what sits behind it.
    readonly property alias backgroundItem: bg

    // Gap between the items of the content column. Zero by default because the
    // config panels place explicit VSpacers where they want air -- an implicit
    // gap would double up with those.
    property int contentSpacing: 0

    readonly property int paneSpacing: Style.mediumSpacing

    // Height of the visible viewport. Content is laid out by implicit height,
    // so a page holding an item that has none (and therefore can't use
    // Layout.fillHeight) can size it against this instead.
    readonly property int pageHeight: scrollView.availableHeight

    default property alias content: contentColumn.data

    // Covers the page with a rendered markdown file (see SiHelpButton).
    function help(file) {

        helpOverlay.showMarkdown(file)
    }

    Image {

        id: bg
        visible: root.background.toString() !== ""
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        fillMode: Image.PreserveAspectFit
        source: root.background
    }

    ColumnLayout {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing
        spacing: root.paneSpacing

        Loader {

            Layout.fillWidth: true
            sourceComponent: root.toolbar
            visible: status === Loader.Ready
        }

        ScrollView {

            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            contentWidth: availableWidth

            ColumnLayout {

                id: contentColumn
                // Bind the width of the layout to the viewport of the scroll view
                width: scrollView.availableWidth
                spacing: root.contentSpacing
            }
        }
    }

    HelpOverlay {

        id: helpOverlay
        anchors.fill: parent
    }
}
