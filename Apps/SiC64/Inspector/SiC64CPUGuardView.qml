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

SiBox {

    id: root

    property alias model: list.model
    required property int numBase
    signal toggle(int nr)
    signal remove(int nr)
    signal move(int nr, int addr)
    signal add(int addr)

    spacing: 0

    function parseAddr(str) {

        let s = str.trim()
        let b = root.numBase

        if (s.startsWith("0x") || s.startsWith("0X")) {
            s = s.slice(2)
            b = 16

        } else if (s.startsWith("$")) {
            s = s.slice(1)
            b = 16
        }

        return parseInt(s, b)
    }

    component HeaderLabel: SiLabel {

        topPadding: 2
        bottomPadding: 2
        font.weight: 500
        elide: Text.ElideRight
    }

    component Value: SiLabel {

        topPadding: 1
        bottomPadding: 1
        font.family: Fonts.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    Rectangle {

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Palette.control
        border.color: Palette.controlBorder
        border.width: 1
        radius: Style.radius
        clip: true

        ColumnLayout {

            anchors.fill: parent
            anchors.margins: Style.smallSpacing
            spacing: 0

            RowLayout {

                Layout.fillWidth: true
                spacing: Style.smallSpacing
                HeaderLabel { text: ""; Layout.preferredWidth: 20 }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                HeaderLabel { text: qsTr("Address"); Layout.fillWidth: true }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Palette.surfaceBorder }
                HeaderLabel { text: ""; Layout.preferredWidth: 20 }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Palette.surfaceBorder }

            Item {

                id: tableArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {

                    id: list
                    anchors.fill: parent
                    clip: true

                    // Row height, captured once from a real delegate instance
                    // rather than derived from contentHeight -- contentHeight
                    // includes the footer below, so computing rowH from it
                    // would feed back into the footer's own height binding.
                    property real rowH: 24

                    // 'nr' of the guard currently being edited (its address
                    // cell shows a text field instead of the plain label),
                    // or -1 when no row is being edited.
                    property int editingNr: -1

                    // Whether the footer's "add new guard" row is currently
                    // being edited -- like editingNr, but for the one row
                    // that has no guard behind it yet.
                    property bool addingNew: false

                    // The footer holds the permanent "add new guard" row,
                    // plus -- matching Cocoa's usesAlternatingRowBackground
                    // Colors -- alternating-row stripes continuing below it
                    // into any empty space. Using a footer (rather than a
                    // background layered behind the view) keeps everything
                    // part of the same scrollable content, so it stays in
                    // sync while scrolling.
                    footer: Item {

                        width: list.width
                        height: Math.max(list.rowH, list.height - list.count * list.rowH)

                        Rectangle {

                            id: newRow
                            width: parent.width
                            height: list.rowH
                            color: list.count % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                            RowLayout {

                                id: newRowLayout
                                anchors.fill: parent
                                spacing: Style.smallSpacing

                                Item { Layout.preferredWidth: 20 }
                                Item { Layout.preferredWidth: 1 }
                                // Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                                // Default state: a plain prompt that turns
                                // into the editable field on click, mirroring
                                // the address cell of a real data row.
                                Value {
                                    Layout.fillWidth: true
                                    visible: !list.addingNew
                                    text: qsTr("Enter Address...")
                                    font.family: Fonts.main
                                    color: Palette.tertiary
                                    TapHandler { onTapped: list.addingNew = true }
                                }

                                // Typing an address and pressing Return
                                // creates a new breakpoint/watchpoint there;
                                // the field then clears, ready for another.
                                SiTextField {

                                    Layout.fillWidth: true
                                    visible: list.addingNew
                                    size: Size.regular
                                    font.family: Fonts.mono

                                    // Establishes list.rowH from the field's
                                    // intrinsic height (independent of the
                                    // row's actual height, so non-circular),
                                    // so every row is as tall as this field
                                    // even before it's first shown.
                                    Component.onCompleted: list.rowH = implicitHeight

                                    onVisibleChanged: if (visible) forceActiveFocus()

                                    onAccepted: {

                                        const addr = root.parseAddr(text)
                                        if (!isNaN(addr)) root.add(addr)
                                        text = ""
                                    }

                                    onActiveFocusChanged: if (!activeFocus) list.addingNew = false
                                }

                                // Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                                Item { Layout.preferredWidth: 1 }
                                Item { Layout.preferredWidth: 20 }
                            }
                        }

                        Repeater {

                            model: Math.ceil((parent.height - newRow.height) / list.rowH)

                            delegate: Rectangle {

                                required property int index
                                readonly property int absoluteIndex: list.count + 1 + index
                                y: newRow.height + index * list.rowH
                                width: parent.width
                                height: list.rowH
                                color: absoluteIndex % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)
                            }
                        }
                    }

                    delegate: Rectangle {

                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        // Follows list.rowH (established by the footer's
                        // permanent "add new guard" row, see below) rather
                        // than measuring its own content -- otherwise every
                        // row (including that footer row) would visibly
                        // resize the moment the list stopped being empty,
                        // since a data row's natural height doesn't match
                        // the text field's.
                        height: list.rowH
                        color: index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                        RowLayout {

                            id: guardRow
                            anchors.fill: parent
                            spacing: Style.smallSpacing

                            SiSymbol {

                                Layout.preferredWidth: 20
                                Layout.alignment: Qt.AlignVCenter
                                enabled: true
                                size: Size.small
                                awesome: "circle-pause"
                                color: modelData.enabled ? Palette.accent : Palette.disabled
                                onClicked: root.toggle(modelData.nr)
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                            // Address: a plain label that turns into an
                            // editable field on click. Return commits the
                            // new address (root.move); losing focus without
                            // committing just reverts to the label.
                            Value {

                                Layout.fillWidth: true
                                visible: list.editingNr !== modelData.nr
                                text: modelData.addr
                                color: modelData.enabled ? Palette.primary : Palette.disabled
                                TapHandler { onTapped: list.editingNr = modelData.nr }
                            }

                            SiTextField {

                                Layout.fillWidth: true
                                visible: list.editingNr === modelData.nr
                                size: Size.regular
                                text: modelData.addr

                                onVisibleChanged: if (visible) { selectAll(); forceActiveFocus() }

                                onAccepted: {
                                    const addr = root.parseAddr(text)
                                    if (!isNaN(addr)) root.move(modelData.nr, addr)
                                    list.editingNr = -1
                                }

                                // Guarded by the nr check: without it, a row
                                // losing focus because editingNr just moved
                                // to a *different* row would clobber that
                                // reassignment back to -1 in the same beat,
                                // which Qt then reports as a binding loop on
                                // 'visible' (it flips true/false/true again
                                // before the update settles).
                                onActiveFocusChanged: if (!activeFocus && list.editingNr === modelData.nr) list.editingNr = -1
                            }

                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }
                            SiSymbol {

                                Layout.preferredWidth: 20
                                Layout.alignment: Qt.AlignVCenter
                                enabled: true
                                size: Size.small
                                symbol: "delete"
                                scale: 0.9
                                color: Palette.primary
                                onClicked: root.remove(modelData.nr)
                            }
                        }
                    }
                }
            }
        }
    }
}
