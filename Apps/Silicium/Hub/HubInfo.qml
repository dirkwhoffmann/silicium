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
import QtQuick.Effects
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

Pane {

    id: root
    background: Rectangle {
        color: "transparent"
    }

    // Properties
    readonly property var vInfo: HubController.vInfo
    readonly property var sInfo: HubController.sInfo

    // Selection state
    readonly property bool vSelected: HubController.vSelected
    readonly property bool sSelected: HubController.sSelected
    readonly property bool selected: HubController.selected

    component Header : Rectangle {

        property alias text: label.text
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        color: "transparent"

        SiText {

            id: label
            anchors.centerIn: parent
            font.pixelSize: Style.huge
            font.bold: true
            color: "white"
        }
    }

    component KeyLabel : SiText {

        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight | Qt.AlignTop
        Layout.preferredWidth: 120
        font.pixelSize: Style.large
        font.bold: true
        color: "white"
        opacity: 0.7
    }

    component ValueLabel : SiText {

        horizontalAlignment: Text.AlignLeft
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        font.pixelSize: Style.large
        font.bold: true
        color: "white"
        wrapMode: Text.Wrap
    }

    component KeyValueRow : RowLayout {

        required property string keyLabel
        required property string valueLabel

        spacing: Style.mediumSpacing

        KeyLabel {
            text: parent.keyLabel
            DebugRect {}
        }

        ValueLabel {
            text: parent.valueLabel
            DebugRect {}
        }
    }

    component CustomScrollView : ScrollView {

        id: scrollView

        default property alias content: dynamicContent.data

        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        background: Rectangle { color: "transparent" }

        ColumnLayout {

            id: dynamicContent
            spacing: 6
            width: scrollView.availableWidth - 2 * Style.hugeSpacing
            x: Style.hugeSpacing
        }
    }

    //
    // Main component
    //

    ColumnLayout {

        anchors.fill: parent

        Header {
            text: vSelected ? "Virtual Machine" : sSelected ? "Snapshot" : "No Selection"
        }

        HLine { margin: Style.hugeSpacing }

        Rectangle {

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"

            //
            // Virtual Machine Info
            //

            CustomScrollView {

                visible: vSelected

                VSpacer { size: Style.largeSpacing }

                KeyValueRow { keyLabel: "Location:"; valueLabel: vInfo.svmpath ?? "" }
                KeyValueRow { keyLabel: "Version:"; valueLabel: vInfo.version ?? "" }
                KeyValueRow { keyLabel: "UUID:"; valueLabel: vInfo.uuid ?? "" }
                KeyValueRow { keyLabel: "Name:"; valueLabel: vInfo.name ?? "" }
                KeyValueRow { keyLabel: "Platform:"; valueLabel: vInfo.platform ?? "" }
                KeyValueRow { keyLabel: "Created:"; valueLabel: vInfo.created ?? "" }
                KeyValueRow { keyLabel: "Modified:"; valueLabel: vInfo.modified ?? "" }
                KeyValueRow { keyLabel: "Preinstalled:"; valueLabel: vInfo.preinstalled ?? "" }
                KeyValueRow { keyLabel: "Compatible:"; valueLabel: vInfo.compatible ?? "" }
                KeyValueRow { keyLabel: "Startup Script:"; valueLabel: vInfo.startup ?? "" }

                Repeater {

                    model: vInfo.meta ?? []

                    delegate: KeyValueRow {

                        required property string key
                        required property string value

                        keyLabel: key + ":"
                        valueLabel: value
                    }
                }

                VSpacer { size: Style.largeSpacing }
            }

            //
            // Snapshot Info
            //

            CustomScrollView {

                visible: sSelected

                VSpacer { size: Style.largeSpacing }

                KeyValueRow { keyLabel: "Version:"; valueLabel: sInfo.version ?? "" }
                KeyValueRow { keyLabel: "UUID:"; valueLabel: sInfo.uuid ?? "" }
                KeyValueRow { keyLabel: "Name:"; valueLabel: sInfo.name ?? "" }
                KeyValueRow { keyLabel: "Platform:"; valueLabel: sInfo.platform ?? "" }
                KeyValueRow { keyLabel: "Created:"; valueLabel: sInfo.created ?? "" }
                KeyValueRow { keyLabel: "Modified:"; valueLabel: sInfo.modified ?? "" }
                KeyValueRow { keyLabel: "Screenshot:"; valueLabel: sInfo.screenshot ?? "" }
                KeyValueRow { keyLabel: "Binary:"; valueLabel: sInfo.binary ?? "" }
                KeyValueRow { keyLabel: "Compatible:"; valueLabel: sInfo.compatible ?? "" }

                VSpacer { size: Style.largeSpacing }
            }
        }
    }
}
