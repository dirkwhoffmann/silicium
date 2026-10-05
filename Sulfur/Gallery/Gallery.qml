// -----------------------------------------------------------------------------
// This file is part of Sulfur, the Silicium UI toolkit
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Sulfur

/* The Sulfur gallery: one page with the controls, grouped by what they do.
 *
 * Nothing in here imports anything but Qt and Sulfur. The theme controls at
 * the top change the settings Sulfur is given (SulfurSettings), which is what
 * an application does with its own preferences.
 */
ApplicationWindow {

    id: root

    width: 980
    height: 760
    minimumWidth: 640
    minimumHeight: 400
    visible: true
    title: "Sulfur Gallery"

    Palette.appearance: SulfurSettings.appearance
    Palette.theme: SulfurSettings.colorTheme
    color: Palette.background

    // A value the controls below share, so that they visibly belong together
    property real level: 0.4

    //
    // A titled group of controls
    //

    component Section: ColumnLayout {

        id: section

        property string title: ""
        default property alias content: body.data

        Layout.fillWidth: true
        spacing: Style.mediumSpacing

        SuText {
            text: section.title
            font.bold: true
            font.pixelSize: Style.large
            Layout.topMargin: Style.largeSpacing
        }

        HLine { }

        Flow {

            id: body
            Layout.fillWidth: true
            spacing: Style.largeSpacing
        }
    }

    // A control with a caption underneath
    component Sample: ColumnLayout {

        id: sample

        property string caption: ""
        default property alias content: slot.data

        spacing: Style.smallSpacing

        RowLayout {

            id: slot
            Layout.alignment: Qt.AlignHCenter
        }

        SuText {
            text: sample.caption
            font.pixelSize: Style.small
            color: Palette.secondary
            Layout.alignment: Qt.AlignHCenter
        }
    }

    //
    // Layout
    //

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        // The settings an application hands to Sulfur
        Rectangle {

            Layout.fillWidth: true
            implicitHeight: settingsRow.implicitHeight + 2 * Style.mediumSpacing
            color: Palette.toolbar

            Flow {

                id: settingsRow
                anchors.fill: parent
                anchors.margins: Style.mediumSpacing
                spacing: Style.largeSpacing

                SuText { text: "Appearance"; anchors.verticalCenter: undefined }

                SuSegmentedControl {
                    model: ["Auto", "Light", "Dark"]
                    currentIndex: SulfurSettings.appearance
                    onActivated: (index) => SulfurSettings.appearance = index
                }

                SuText { text: "Colors" }

                SuSegmentedControl {
                    model: ["Default", "Solaris"]
                    currentIndex: SulfurSettings.colorTheme
                    onActivated: (index) => SulfurSettings.colorTheme = index
                }

                SuText { text: "Font" }

                SuSegmentedControl {
                    model: ["System", "Inter", "Saira", "DejaVu"]
                    currentIndex: SulfurSettings.fontTheme
                    onActivated: (index) => SulfurSettings.fontTheme = index
                }

                SuCheckBox {
                    text: "Layout debug aids"
                    checked: SulfurSettings.debug
                    onToggled: SulfurSettings.debug = checked
                }
            }
        }

        ScrollView {

            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {

                width: scroll.availableWidth
                spacing: Style.mediumSpacing

                // Margins on the sides, without squeezing the sections
                Item { Layout.preferredHeight: 0 }

                //
                // Colors
                //

                Section {

                    title: "Palette"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Repeater {

                        model: [
                            { name: "background", color: Palette.background },
                            { name: "toolbar", color: Palette.toolbar },
                            { name: "widget", color: Palette.widget },
                            { name: "control", color: Palette.control },
                            { name: "accent", color: Palette.accent },
                            { name: "primary", color: Palette.primary },
                            { name: "secondary", color: Palette.secondary },
                            { name: "disabled", color: Palette.disabled }
                        ]

                        Sample {

                            required property var modelData
                            caption: modelData.name

                            Rectangle {
                                implicitWidth: 72
                                implicitHeight: 32
                                radius: Style.radius
                                color: parent.parent.modelData.color
                                border.color: Palette.surfaceBorder
                            }
                        }
                    }
                }

                //
                // Buttons
                //

                Section {

                    title: "Buttons"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Sample { caption: "SuButton"; SuButton { text: "Button" } }
                    Sample { caption: "accented"; SuButton { text: "Accented"; accented: true } }
                    Sample { caption: "disabled"; SuButton { text: "Disabled"; enabled: false } }
                    Sample {
                        caption: "icon buttons"
                        SuButton { symbol: "settings" }
                        SuButton { phosphor: "clipboard"; checkable: true; checked: true }
                        SuButton { symbol: "folder"; enabled: false }
                    }
                    Sample { caption: "sizes"; SuButton { text: "Small"; size: Size.small } SuButton { text: "Large"; size: Size.large } }

                    Sample {
                        caption: "SuSymbolButton"
                        SuSymbolButton { phosphor: "gear" }
                        SuSymbolButton { phosphor: "magnifying-glass" }
                        SuSymbolButton { phosphor: "bug-beetle"; checkable: true }
                    }

                    Sample {
                        caption: "SuBarButton"
                        SuBarButton {
                            phosphor: "terminal-window"
                            text: "Shell"
                            checkable: true
                            SuToolTip { text: "Hover for a tooltip" }
                        }
                    }

                    Sample { caption: "SuHelpButton"; SuHelpButton { checkable: true } }
                    Sample { caption: "SuOverlayButton"; SuOverlayButton { symbol: "play_circle"; size: 48 } }
                }

                //
                // Text
                //

                Section {

                    title: "Text and fields"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Sample {
                        caption: "SuText"
                        ColumnLayout {
                            SuText { text: "Heading"; font.pixelSize: Style.heading }
                            SuText { text: "Regular text" }
                            SuText { text: "Small text"; font.pixelSize: Style.small }
                        }
                    }

                    Sample { caption: "SuLabel"; SuLabel { text: "A label" } }
                    Sample { caption: "SuTextField"; SuTextField { placeholderText: "Type here"; implicitWidth: 160 } }
                    Sample { caption: "SuNumberInput"; SuNumberInput { text: "42"; implicitWidth: 80 } }
                }

                //
                // Choices
                //

                Section {

                    title: "Choices"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Sample { caption: "SuCheckBox"; SuCheckBox { text: "Check me"; checked: true } }
                    Sample { caption: "bit style"; SuCheckBox { bitStyle: true; checked: true } }

                    Sample {
                        caption: "SuSegmentedControl"
                        SuSegmentedControl {
                            id: segments
                            model: ["One", "Two", "Three"]
                            onActivated: (index) => currentIndex = index
                        }
                    }

                    Sample {
                        caption: "icon segments"
                        SuSegmentedControl {
                            minSegmentWidth: 34
                            currentIndex: -1
                            model: [
                                { symbol: "info", tooltip: "Info" },
                                { phosphor: "clipboard", tooltip: "Logger" },
                                { symbol: "settings", tooltip: "Disabled", enabled: false }
                            ]
                            // A second click on the selected segment deselects it
                            onActivated: (index) => currentIndex = currentIndex === index ? -1 : index
                        }
                    }

                    Sample {
                        caption: "SuComboBox"
                        SuComboBox { model: ["Amiga", "Commodore 64", "Atari ST"]; implicitWidth: 160 }
                    }

                    Sample {
                        caption: "SuMenu"
                        SuButton {
                            id: menuButton
                            text: "Open menu"
                            onClicked: demoMenu.popup(0, height)

                            SuMenu {
                                id: demoMenu
                                SuMenuItem { text: "Open..." }
                                SuMenuItem { text: "Checkable"; checkable: true; checked: true }
                                SuMenuSeparator { }
                                SuMenuItem { text: "Disabled"; enabled: false }
                            }
                        }
                    }
                }

                //
                // Values
                //

                Section {

                    title: "Values"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Sample {
                        caption: "SuSlider"
                        SuSlider { value: root.level; onMoved: root.level = value; implicitWidth: 160 }
                    }
                    Sample {
                        caption: "SuProgressBar"
                        SuProgressBar { value: root.level; implicitWidth: 160 }
                    }
                    Sample {
                        caption: "SuBarGauge"
                        SuBarGauge { value: root.level; implicitWidth: 160; implicitHeight: 16 }
                    }
                    Sample {
                        caption: "SuKnob"
                        SuKnob { value: root.level; from: 0; to: 1; onMoved: (v) => root.level = v }
                    }
                    Sample {
                        caption: "SuMinMaxSlider"
                        SuMinMaxSlider {
                            topText: "1"
                            bottomText: "0"
                            from: 0
                            to: 1
                            value: root.level
                            length: 90
                            onMoved: (v) => root.level = v
                        }
                    }
                    Sample {
                        caption: "SuColorWell"
                        SuColorWell { value: "#3366cc"; onPicked: (v) => value = v }
                    }
                }

                //
                // Labeled controls
                //

                Section {

                    title: "Labeled controls"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    ColumnLayout {

                        spacing: Style.smallSpacing

                        SuLabeledTextBox { l: "Name:"; lwidth: 110; controlWidth: 180; text: "Workbench" }
                        SuLabeledNumberInput { l: "Memory:"; lwidth: 110; controlWidth: 80; r: "KB"; intValue: 512 }
                        SuLabeledCheckBox { l: "Fast RAM:"; lwidth: 110; checkBoxText: "Enabled"; checked: true }
                        SuLabeledComboBox { l: "Model:"; lwidth: 110; controlWidth: 180; model: ["A500", "A1000", "A2000"]; currentIndex: 0 }
                        SuLabeledSlider { l: "Volume:"; lwidth: 110; controlWidth: 180; from: 0; to: 100; value: root.level * 100; onMoved: (v) => root.level = v / 100 }
                        SuLabeledProgressBar { l: "Progress:"; lwidth: 110; controlWidth: 180; from: 0; to: 1; value: root.level }
                    }
                }

                //
                // Messages
                //

                Section {

                    title: "Dialogs and messages"
                    Layout.leftMargin: Style.largeSpacing
                    Layout.rightMargin: Style.largeSpacing

                    Sample {
                        caption: "SuUserDialog"
                        SuButton { text: "Show dialog"; onClicked: messageDialog.open() }
                    }

                    Sample {
                        caption: "SuProgressDialog"
                        SuButton {
                            text: "Show progress"
                            onClicked: {
                                progressDialog.progress = 0
                                progressDialog.open()
                                progressAnimation.restart()
                            }
                        }
                    }

                    Sample {
                        caption: "NotificationCenter"
                        SuButton { text: "Notify"; onClicked: notifications.show("Sulfur", "A notification, shown by the notification center.", notifications.info) }
                    }

                    Sample {
                        caption: "SuBanner"
                        SuButton { text: "Show banner"; onClicked: banner.show("A message that takes itself away", 500, 3000) }
                    }
                }

                Item { Layout.preferredHeight: Style.largeSpacing }
            }
        }
    }

    //
    // Things that float
    //

    SuBanner {

        id: banner
        anchors.fill: parent
        z: 2
        alignment: Qt.AlignBottom
    }

    NotificationCenter {

        id: notifications
        maxWidth: root.width - 2 * Style.largeSpacing
        maxHeight: root.height - 2 * Style.largeSpacing
        watchdog: 0
        z: 999
    }

    SuUserDialog {

        id: messageDialog
        titleText: "Hello from Sulfur"
        bodyText: "This is a message dialog. Its icon and badge come from the application, through SulfurSettings."
        buttons: Dialog.Cancel | Dialog.Ok
    }

    SuProgressDialog {

        id: progressDialog
        text: "Working..."

        NumberAnimation {

            id: progressAnimation
            target: progressDialog
            property: "progress"
            from: 0
            to: 1
            duration: 2500
            onFinished: progressDialog.close()
        }
    }
}
