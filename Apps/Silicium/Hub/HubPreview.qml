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

    required property HubSidebarController sidebarController
    readonly property var vInfo: HubController.vInfo
    readonly property var sInfo: HubController.sInfo

    // Selection state
    readonly property bool vSelected: HubController.vSelected
    readonly property bool sSelected: HubController.sSelected
    readonly property bool selected: HubController.selected

    // Virtual machine properties
    readonly property string vUUID: vInfo.uuid ?? ""
    readonly property string vUUIDprev: sidebarController.prevVM(vUUID)
    readonly property string vUUIDnext: sidebarController.nextVM(vUUID)
    readonly property string vName: vInfo.name ?? ""
    readonly property string vAuthor: vInfo.author ?? ""
    readonly property string vDescription: vInfo.description ?? ""
    readonly property string vEngine: vInfo.engine ?? ""
    readonly property string vPlatform: vInfo.platform ?? ""
    readonly property string vScreenshot: vInfo.screenshotUrl ?? ""
    readonly property string vCreated: vInfo.created ?? ""
    readonly property bool vReadOnly: vInfo.readonly ?? true
    readonly property bool vCompatible: vInfo.compatible ?? true

    // Snapshot properties
    readonly property string sUUID: sInfo.uuid ?? ""
    readonly property string sUUIDprev: sidebarController.prevSnap(sUUID)
    readonly property string sUUIDnext: sidebarController.nextSnap(sUUID)
    readonly property string sName: sInfo.name ?? ""
    readonly property string sScreenshot: sInfo.screenshotUrl ?? ""
    readonly property string sCreated:sInfo.created ?? ""
    readonly property bool sCompatible: sInfo.compatible ?? false

    // Prev/Next item
    readonly property string prev: sSelected ? sUUIDprev : vUUIDprev
    readonly property string next: sSelected ? sUUIDnext : vUUIDnext

    padding: 0

    background: Rectangle {
        color: "transparent"
    }

    opacity: vUUID ? 1 : 0
    visible: opacity > 0

    //
    // Actions
    //

    Action {
        id: powerAction
        text: "Power"
        onTriggered: HubController.open(vUUID)
        icon.name: "power_settings_circle"
    }

    Action {
        id: snapshotAction
        text: "Restore Snapshot"
        onTriggered: HubController.open(vUUID)
        icon.name: HubController.isOpen ? "refresh" : "play_circle"
    }

    Action {
        id: deleteAction
        text: "Delete"
        onTriggered: {
            let toDelete = sUUID
            let toSelect = next !== "" ? next : prev
            HubController.select(toSelect)
            HubController.remove(toDelete)
        }
        icon.name: "delete"
    }

    Action {
        id: prevAction
        text: "Prev"
        enabled: prev !== ""
        onTriggered: HubController.selected = prev
        icon.name: "chevron_left"
    }

    Action {
        id: nextAction
        text: "Next"
        enabled: next !== ""
        onTriggered: HubController.selected = next
        icon.name: "chevron_right"
    }

    //
    // Background (screenshot)
    //

    HubPreviewImage {

        id: bgImage
        anchors.fill: parent
        visible: (vSelected && vScreenshot) || (sSelected && sCompatible)
        source: vSelected ? vScreenshot : sScreenshot
        title: vName
        author: vAuthor
        description: vDescription
        comingSoon: vPlatform === "AMIGA"
    }

    SiOverlayRect {

        anchors.centerIn: parent
        width: parent.width * 0.85
        height: Math.max(220, warningText.contentHeight + 2 * Style.mediumSpacing)
        visible: sSelected && !sCompatible
        color: "#D0800000"

        RowLayout {

            id: theRow
            anchors.fill: parent
            spacing: 0

            SiOverlayButton {

                id: warningButton
                Layout.alignment: Qt.AlignVCenter
                background: Rectangle { color: "transparent" }
                size: 220
                enabled: false
                symbol: "do_not_touch"
            }

            SiText {
                id: warningText
                anchors.margins: 10
                Layout.fillWidth: true
                lineHeight: Style.large * 1.3
                lineHeightMode: Text.FixedHeight
                text: "This snapshot is incompatible because it was created with a different release. However, you may still choose to boot the machine from its power-on state."
                // "\n\nNote that incompatible snapshots will be deleted automatically the next time the machine is hibernated."
                color: "white"
                font.bold: true
                font.pixelSize: Style.large
                wrapMode: Text.WordWrap
                // horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    //
    // Foreground overlay
    //

    ColumnLayout {

        anchors.fill: parent

        VSpacer {
        }

        //
        // Engine info
        //

        Image {

            visible: vSelected && vScreenshot === ""
            source: vEngine
            Layout.preferredWidth: 0.65 * parent.width
            Layout.alignment: Qt.AlignHCenter
            fillMode: Image.PreserveAspectFit

            NumberAnimation on opacity {

                id: engineFadeIn
                duration: 800
                easing.type: Easing.OutCubic
                from: 0
                to: 1
            }

            Connections {

                target: HubController

                function onSelectionChanged() {
                    engineFadeIn.restart()
                }
            }
        }

        VSpacer {
        }

        //
        // Info overlay
        //

        HubPreviewInfo {

            id: infoPanel
            sidebarController: root.sidebarController
            width: parent.width * 0.85
            height: 80
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Style.largeSpacing
            leftAction: vSelected ? powerAction : snapshotAction
            rightAction: null // sSelected ? deleteAction : null
            prevAction: prevAction
            nextAction: nextAction
            title: (vSelected ? vInfo.name : sSelected ? sInfo.name : "") ?? ""
            created: (vSelected ? vInfo.created : sSelected ? sInfo.created : "") ?? ""
            modified: (vSelected ? vInfo.modified : sSelected ? sInfo.modified : "") ?? ""
        }
    }
}
