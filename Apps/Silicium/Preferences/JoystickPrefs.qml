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
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

RowLayout {

    id: root

    required property PrefController controller
    readonly property int device: controller.device

    property Image backdrop: null
    property int activeKey: -1

    spacing: Style.mediumSpacing

    //
    // Controls
    //

    ColumnLayout {

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: Number.POSITIVE_INFINITY
        spacing: 0

        VSpacer { }

        JoystickVisualizer {

            id: joystickView
            controller: root.controller
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            Layout.bottomMargin: 16

        }

        VSpacer { }

        SiCheckBoxControl {

            r: "Disconnect emulation keys from keyboard"
            checked: Preferences.disconnectEmulationKeys
            onClicked: Preferences.disconnectEmulationKeys = !Preferences.disconnectEmulationKeys
        }
    }

    //
    // Info
    //

    ColumnLayout {

        // Even split, as on the left (see the note there for the maximumWidth).
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: Number.POSITIVE_INFINITY
        spacing: Style.tinySpacing

        Category {

            text: "PROPERTIES"
            Layout.topMargin: Style.mediumSpacing
            Layout.fillWidth: true
        }

        Pane {

            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: Style.mediumSpacing

            background: SiGlass {

                backdrop: root.backdrop
                tint: Qt.alpha(Palette.backgroundElevated, 0.25)
                radius: Style.radius
            }

            ColumnLayout {

                id: info
                readonly property var port: AppController.inputManager.port0Info

                anchors.fill: parent
                clip: true

                PrefKeyValue {

                    key: "Type:"
                    value: info.port.type
                }

                PrefKeyValue {

                    key: "Status:"
                    value: info.port.status
                }

                PrefKeyValue {

                    key: "SDL ID:"
                    visible: !!info.port.sdlid
                    value: info.port.sdlid ? String(info.port.sdlid) : ""
                }

                PrefKeyValue {

                    key: "GUID:"
                    visible: !!info.port.guid
                    value: info.port.guid ? String(info.port.guid).slice(0, 16) : ""
                }

                PrefKeyValue {

                    key: ""
                    visible: !!info.port.guid
                    value: info.port.guid ? String(info.port.guid).slice(-16) : ""
                }

                PrefKeyValue {

                    key: "Vendor ID:"
                    visible: !!info.port.vendorId
                    value: info.port.vendorId ? String(info.port.vendorId) : ""
                }

                PrefKeyValue {

                    key: "Product ID:"
                    visible: !!info.port.productId
                    value: info.port.productId ? String(info.port.productId) : ""
                }

                PrefKeyValue {

                    key: "Version:"
                    visible: !!info.port.productVersion
                    value: info.port.productVersion ? String(info.port.productVersion) : ""
                }

                //
                // SDL GamePad mapping
                //

                RowLayout {

                    visible: !!info.port.sdlid
                    spacing: 15
                    Layout.fillWidth: true

                    RowLayout {

                        Layout.fillWidth: false
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignTop
                        spacing: Style.tinySpacing

                        HSpacer { }

                        RowLayout {

                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            SiSymbolButton {

                                symbol: "delete"
                                size: Size.small
                                visible: !!info.port.customMapping
                                Layout.alignment: Qt.AlignVCenter

                                onClicked: root.controller.resetMapping()
                            }

                            SiText {

                                text: "Mapping:"
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                                color: Palette.secondary
                                elide: Text.ElideRight
                            }
                        }
                    }

                    TextArea {

                        text: info.port.mapping ? info.port.mapping : ""
                        placeholderText: "Enter mapping..."
                        wrapMode: TextEdit.WrapAnywhere
                        color: Palette.primary
                        font.bold: true

                        padding: 0
                        leftPadding: 0

                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: 48

                        background: Rectangle {

                            color: "transparent"
                            border.width: 0
                        }

                        Keys.onPressed: (event) => {

                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) {
                                root.controller.setMapping(text)
                                focus = false
                                event.accepted = true
                            }
                        }
                    }
                }

                VSpacer { }
            }
        }
    }
}
