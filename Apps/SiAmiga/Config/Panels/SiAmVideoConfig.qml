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
import Silicium.Preferences
import Silicium.Theme

// Port of vAmiga's own GUI/Settings/ViewControllers/VideoSettings.swift --
// the Monitor section only (palette/brightness/contrast/saturation, zoom,
// center), matching the scope SiC64VideoConfig.qml already settled on for
// the C64 side. VideoSettingsViewController's Effects section (enhancer/
// upscaler/blur/bloom/flicker/dotmask/scanlines/misalignment -- a whole
// shader pipeline) has no counterpart on the C64 side either, so it's left
// out here too rather than introduced as an Amiga-only one-off.
//
// The one real difference from SiC64VideoConfig.qml: vAmiga's Palette enum
// has an extra RGB entry the C64 side doesn't (Core/Peripherals/Monitor/
// MonitorTypes.h: COLOR, RGB, BLACK_WHITE, PAPER_WHITE, GREEN, AMBER, SEPIA)
// -- selecting it bypasses the monitor's color processing entirely, so
// VideoSettingsViewController.refresh() disables the brightness/contrast/
// saturation sliders while it's active ('adjustable = palette != .RGB').
// Reproduced here via the knobs' own 'enabled' binding.
SettingsPage {

    id: root

    required property SiAmController controller
    readonly property var config: controller.configController

    readonly property int labelWidth: 100
    readonly property int comboWidth: 220
    readonly property int sectionWidth: 320
    readonly property int knobWidth: 75

    // Palette::RGB, see the class comment.
    readonly property bool colorAdjustable: config.MON_PALETTE !== 1

    toolbar: ConfigToolbar {

        heading: "Video Settings"

        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreVideoDefaults()
            }
        ]

        HSpacer { }

        ConfigLock {

            onClicked: controller.powerOnOrOff()
        }
    }

    component VideoKnob: SiKnob {

        id: knob

        // The knob's caption is its bottom label.
        property alias text: knob.b

        Layout.topMargin: 13
        Layout.preferredWidth: root.knobWidth
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    }

    ConfigSection {

        header: "MONITOR"
        size: 2 * root.sectionWidth

        GridLayout {

            // First column holds the combo box; the remaining columns hold
            // the knobs, so knobs line up vertically across the three rows.
            // Empty trailing cells are filled with a spacer to keep the
            // grid flow.
            columns: 4
            columnSpacing: Style.largeSpacing
            rowSpacing: Style.largeSpacing

            //
            // Row 1: Palette
            //

            SiComboBoxControl {

                Layout.alignment: Qt.AlignVCenter

                l: "Palette:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth

                model: [
                    "Standard Colors",
                    "RGB",
                    "Black and White",
                    "Paper White",
                    "Green",
                    "Amber",
                    "Sepia"
                ]

                currentIndex: config.MON_PALETTE
                onCurrentIndexChanged: config.MON_PALETTE = currentIndex;
            }

            VideoKnob {

                text: "BRIGHTNESS"
                enabled: root.colorAdjustable
                from: 0
                to: 100
                value: config.MON_BRIGHTNESS
                onMoved: (value) => config.MON_BRIGHTNESS = value
            }

            VideoKnob {

                text: "CONTRAST"
                enabled: root.colorAdjustable
                from: 0
                to: 100
                value: config.MON_CONTRAST
                onMoved: (value) => config.MON_CONTRAST = value
            }

            VideoKnob {

                text: "COLOR"
                enabled: root.colorAdjustable
                from: 0
                to: 100
                value: config.MON_SATURATION
                onMoved: (value) => config.MON_SATURATION = value
            }

            //
            // Row 2: Zoom
            //

            SiComboBoxControl {

                Layout.alignment: Qt.AlignVCenter

                l: "Zoom:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth

                model: [
                    "Custom"
                ]
            }

            VideoKnob {

                text: "H ZOOM"
                from: 0
                to: 200
                value: config.MON_HZOOM
                onMoved: (value) => config.MON_HZOOM = value
            }

            VideoKnob {

                text: "V ZOOM"
                from: 0
                to: 200
                value: config.MON_VZOOM
                onMoved: (value) => config.MON_VZOOM = value
            }

            Item { }

            //
            // Row 3: Center
            //

            SiComboBoxControl {

                Layout.alignment: Qt.AlignVCenter

                l: "Center:"
                lwidth: root.labelWidth
                controlWidth: root.comboWidth

                model: [
                    "Custom"
                ]
            }

            VideoKnob {

                text: "H CENTER"
                from: 0
                to: 1000
                value: config.MON_HCENTER
                onMoved: (value) => config.MON_HCENTER = value
            }

            VideoKnob {

                text: "V CENTER"
                from: 0
                to: 1000
                value: config.MON_VCENTER
                onMoved: (value) => config.MON_VCENTER = value
            }

            Item { }
        }
    }
}
