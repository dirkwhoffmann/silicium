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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Theme

SiDialog {

    id: root

    required property C64Controller c64
    property int driveNr: 8
    readonly property int labelWidth: 90
    readonly property bool cbmSelected: fsCombo.currentIndex === 1

    width: 460
    // height: 200

    onOpened: {

        fsCombo.currentIndex = 1
        nameField.text = qsTr("Empty")
        nameField.selectAll()
        nameField.forceActiveFocus()
    }

    function insert() {

        console.log("Inserting...", nameField.text)
        c64.newDisk(driveNr, cbmSelected ? 1 : 0, nameField.text)
        root.close()
    }

    RowLayout {

        id: contentRow
        Layout.fillWidth: true
        spacing: Style.largeSpacing

        //
        // Disk icon
        //

        Rectangle {

            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            Layout.alignment: Qt.AlignTop
            radius: Style.borderRadius
            color: Palette.surfaceElevated

            Image {

                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit
                source: Assets.iconUrl(Assets.Media525DDCbm)
            }
        }

        //
        // Form
        //

        ColumnLayout {

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Style.mediumSpacing

            SiText {

                text: qsTr("Commodore Floppy Disk")
                font.bold: false // true
                font.pixelSize: Style.large
                Layout.fillWidth: true
            }

            Rectangle {

                Layout.fillWidth: true
                Layout.topMargin: Style.smallSpacing
                Layout.bottomMargin: Style.smallSpacing
                height: 1
                color: Palette.border
            }

            SiComboBoxControl {

                l: qsTr("Capacity:")
                lwidth: root.labelWidth
                model: [qsTr("5.25\" DD")]
                currentIndex: 0
            }

            SiComboBoxControl {

                id: fsCombo
                l: qsTr("File system:")
                lwidth: root.labelWidth
                model: [qsTr("No File System"), qsTr("CBM DOS")]
            }

            SiControl {

                id: nameControl
                l: qsTr("Name:")
                lwidth: root.labelWidth
                visible: root.cbmSelected

                control: [
                    SiTextField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onAccepted: root.insert()
                    }
                ]
            }

            VSpacer {

                visible: !root.cbmSelected
                size: nameControl.implicitHeight
            }
        }
    }

    footer: Item {

        implicitHeight: footerRow.implicitHeight + Style.largeSpacing

        RowLayout {

            id: footerRow
            anchors.fill: parent
            anchors.leftMargin: Style.largeSpacing
            anchors.rightMargin: Style.largeSpacing
            spacing: Style.mediumSpacing
            /*
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.largeSpacing
            anchors.topMargin: 0
            spacing: Style.mediumSpacing

             */

            SiButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            HSpacer { }

            SiButton {
                accented: true
                text: qsTr("Insert")
                onClicked: root.insert()
            }

            /*
            Button {

                id: insertButton
                text: qsTr("Insert")
                implicitHeight: 24
                implicitWidth: Math.max(80, contentItem.implicitWidth + 24)
                leftPadding: 12
                rightPadding: 12

                background: Rectangle {
                    radius: 3
                    color: insertButton.down ? Palette.accentElevated : Palette.accent
                }

                contentItem: SiText {
                    text: insertButton.text
                    color: Palette.accentText
                    font.family: Fonts.main
                    font.pixelSize: Style.regular
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.insert()
            }
            */
        }
    }
}
