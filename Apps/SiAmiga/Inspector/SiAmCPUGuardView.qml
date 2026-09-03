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

// Port of vAmiga's own GuardTableView (its BreakTableView/WatchTableView
// specializations) -- one reusable breakpoint/watchpoint table, parameterized
// by 'model' (a SiAmGuardModel) and driven entirely through row-index
// signals, matching SiAmCopperController's own toggleGuardEnabled(index)/
// removeGuard(index) convention (SiAmGuardModel exposes 'addr'/'enabled'
// roles only, no per-row "nr" -- row position already doubles as the guard's
// index in vAmiga's GuardsAPI, since guardNr()/moveTo() are addressed the
// same way).
SiBox {

    id: root

    property alias model: list.model
    required property int numBase
    signal toggle(int row)
    signal remove(int row)
    signal move(int row, int addr)
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

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {

                    id: list
                    anchors.fill: parent
                    clip: true

                    // Row height, captured once from a real footer field
                    // instance rather than derived from contentHeight
                    // (contentHeight includes the footer, so computing rowH
                    // from it would feed back into the footer's own height).
                    property real rowH: 24

                    // Row currently being edited (its address cell shows a
                    // text field instead of a plain label), or -1.
                    property int editingRow: -1

                    // Whether the footer's "add new guard" row is being
                    // edited -- like editingRow, but for the one row that
                    // has no guard behind it yet.
                    property bool addingNew: false

                    footer: Item {

                        width: list.width
                        height: Math.max(list.rowH, list.height - list.count * list.rowH)

                        Rectangle {

                            id: newRow
                            width: parent.width
                            height: list.rowH
                            color: list.count % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                            RowLayout {

                                anchors.fill: parent
                                spacing: Style.smallSpacing

                                Item { Layout.preferredWidth: 20 }
                                Item { Layout.preferredWidth: 1 }

                                Value {
                                    Layout.fillWidth: true
                                    visible: !list.addingNew
                                    text: qsTr("Add address...")
                                    font.family: Fonts.main
                                    color: Palette.tertiary
                                    TapHandler { onTapped: list.addingNew = true }
                                }

                                SiTextField {

                                    Layout.fillWidth: true
                                    visible: list.addingNew
                                    size: Size.regular
                                    font.family: Fonts.mono

                                    Component.onCompleted: list.rowH = implicitHeight

                                    onVisibleChanged: if (visible) forceActiveFocus()

                                    onAccepted: {

                                        const addr = root.parseAddr(text)
                                        if (!isNaN(addr)) root.add(addr)
                                        text = ""
                                    }

                                    onActiveFocusChanged: if (!activeFocus) list.addingNew = false
                                }

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

                        id: guardDelegate

                        required property int index
                        required property string addr

                        // SiAmGuardModel's role is named 'enabled', which
                        // collides with Item's own 'enabled' property -- so
                        // it's read via the delegate's implicit 'model'
                        // context property (model.enabled) below instead of
                        // a same-named required property.
                        readonly property bool guardEnabled: model.enabled

                        width: ListView.view.width
                        height: list.rowH
                        color: index % 2 === 0 ? Palette.control.lighter(1.025) : Palette.control.darker(1.025)

                        RowLayout {

                            anchors.fill: parent
                            spacing: Style.smallSpacing

                            SiSymbol {

                                Layout.preferredWidth: 20
                                Layout.alignment: Qt.AlignVCenter
                                enabled: true
                                size: Size.small
                                awesome: "circle-pause"
                                color: guardDelegate.guardEnabled ? Palette.accent : Palette.disabled
                                onClicked: root.toggle(guardDelegate.index)
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Palette.surfaceBorder }

                            Value {

                                Layout.fillWidth: true
                                visible: list.editingRow !== guardDelegate.index
                                text: guardDelegate.addr
                                color: guardDelegate.guardEnabled ? Palette.primary : Palette.disabled
                                TapHandler { onTapped: list.editingRow = guardDelegate.index }
                            }

                            SiTextField {

                                Layout.fillWidth: true
                                visible: list.editingRow === guardDelegate.index
                                size: Size.regular
                                text: guardDelegate.addr

                                onVisibleChanged: if (visible) { selectAll(); forceActiveFocus() }

                                onAccepted: {
                                    const addr = root.parseAddr(text)
                                    if (!isNaN(addr)) root.move(guardDelegate.index, addr)
                                    list.editingRow = -1
                                }

                                onActiveFocusChanged: if (!activeFocus && list.editingRow === guardDelegate.index) list.editingRow = -1
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
                                onClicked: root.remove(guardDelegate.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
