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
import Silicium.Components
import Silicium.Controllers
import Silicium.Theme

// Port of vAmiga's own GUI/Inspector/DenisePanel.swift + SpriteTableView.swift.
// Its own top-level window (see SiAmInspectorWindow.qml).
SiAmInspectorWindow {

    id: root

    title: qsTr("Denise Inspector")
    currentController: controller.deniseController

    // Every inspector otherwise shares SiAmInspectorWindow.qml's 880x440
    // default, and the Registers page's Control box (each BPLCONx column
    // packed into a 16-row, single-column bit list at Size.tiny) fit
    // exactly within that -- until each column grew a separator plus its
    // own decoded sub-field(s) below (BPU under BPLCON0, BANK/PF2OF/SPRES
    // under BPLCON3, ...), pushing the tallest column (BPLCON3, now 20
    // rows) past what 440 has room for. Control is wrapped in a
    // SiScrollBox so nothing is ever unreachable, but scrolling should be
    // the fallback for an unusually tall column, not the routine way to
    // see BPU/BANK/etc. on first look -- hence the modest height bump here
    // instead of leaving every inspector's shared default to absorb it.
    // height: 510
    // minimumHeight: 480

    readonly property var denise: controller.deniseController
    readonly property var ic: controller.inspectorController
    readonly property int numBase: ic.hex ? 16 : 10
    readonly property bool numPadded: ic.padded

    // Registers tab sizing knobs, passed down to SiAmDeniseRegPanel: lw
    // sizes the indented per-bit labels ("HIRES", "BPU", ...); hlw is
    // wider, for the un-indented register-name header row of each group
    // ("BPLCON0", "DIWSTRT", ...), which needs more characters than fit in
    // lw.
    readonly property int lw: 64
    readonly property int hlw: 62
    readonly property int indent: 0

    // Which page the stack shows: 0 = Registers, 1 = Colors, 2 = Sprites --
    // same Program/Trace/Debug tab-bar idiom as SiAmCPUPanel.qml, adopted
    // here so the growing set of AGA-only registers has room of its own
    // instead of squeezing the Sprites box sideways, and so the Colors tab
    // (four 32-swatch boxes, one per AGA color bank) has the whole window
    // to itself rather than sharing the Registers page with Display window.
    property int page: 0

    Item {

        anchors.fill: parent
        anchors.margins: Style.mediumSpacing

        SiBox {

            id: stackBox
            anchors.fill: parent
            anchors.topMargin: tabControl.height / 2
            spacing: Style.mediumSpacing

            VSpacer { size: Style.tinySpacing }

            StackLayout {

                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.page

                //
                // Registers
                //

                SiAmDeniseRegPanel {

                    denise: root.denise
                    numBase: root.numBase
                    numPadded: root.numPadded
                    lw: root.lw
                    hlw: root.hlw
                    indent: root.indent
                }

                //
                // Colors -- one box per AGA color bank (4 banks of 32
                // registers each; see SiAmDeniseController's own colorAt(n)
                // comment), same swatch-grid style as the single Colors box
                // this replaced, now with its own tab instead of sharing
                // the Registers page with Display window.
                //

                SiAmDeniseColPanel {

                    denise: root.denise
                }

                //
                // Sprites
                //

                SiAmDeniseSprPanel {

                    denise: root.denise
                    numBase: root.numBase
                    numPadded: root.numPadded
                }
            }
        }

        SiSegmentedControl {

            id: tabControl
            anchors.horizontalCenter: stackBox.horizontalCenter
            anchors.verticalCenter: stackBox.top

            model: [qsTr("Registers"), qsTr("Colors"), qsTr("Sprites")]
            segmentWidth: 90
            currentIndex: root.page
            onActivated: (index) => root.page = index
        }
    }
}
