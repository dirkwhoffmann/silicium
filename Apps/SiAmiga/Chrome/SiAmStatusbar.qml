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

//
// Port of SiC64Statusbar.qml. SiAmiga has no SiC64InfoController counterpart
// yet -- that's what fed the C64 status bar's drive LEDs, tape/cartridge
// icons, jammed/tracking/mute pictograms and server-state popup from a
// single polled snapshot. Rather than invent that whole subsystem for a
// status bar, the floppy indicators below call SiAmController's per-drive
// getters (driveMotor/driveWriting/driveTrack/...) directly and re-evaluate
// them off a local Timer tick (see 'tick' below) instead of a real change
// notification. The tape, cartridge, pictogram row and server popup have no
// Amiga equivalent or backing state at all yet, so they're dropped rather
// than wired to nothing -- same trim SiAmMenu.qml and SiAmToolbar.qml made.
//

Rectangle {

    id: root

    required property SiAmController amiga
    readonly property SiAmConfigController config: amiga.configController
    readonly property SiAmActivityController activity: amiga.activityController

    property int metric: 0

    // SiAmController's per-drive getters (driveMotor(nr), driveTrack(nr), ...)
    // are plain Q_INVOKABLE calls, not NOTIFY-backed properties, so nothing
    // tells QML to re-evaluate a binding that calls them. This tick forces
    // periodic re-evaluation instead -- referencing it inside a binding is
    // what makes that binding re-run every time it changes.
    property int tick: 0

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    readonly property string ledRed:   "qrc:/images/led-round-red.png"
    readonly property string ledGreen: "qrc:/images/led-round-green.png"
    readonly property string ledGray:  "qrc:/images/led-round-gray.png"
    readonly property string disk35:   "qrc:/images/media-35-dd-amiga.png"
    readonly property string disk35wp: "qrc:/images/media-35-dd-amiga-wp.png"

    function redIcon(nr)   { tick; return amiga.driveMotor(nr) ? ledRed : ledGray }
    function greenIcon(nr) { tick; return amiga.driveWriting(nr) ? ledGreen : ledGray }
    function diskIcon(nr)  { tick; return amiga.driveHasDisk(nr) ? (amiga.driveWriteProtected(nr) ? disk35wp : disk35) : "" }
    function track(nr)     { tick; return amiga.driveTrack(nr) }
    function busy(nr)      { tick; return amiga.driveMotor(nr) }

    //
    // Pictogram
    //

    component PictogramIcon: SiImageButton {

        property bool state: true

        visible: state || Preferences.qtDebug
        icon.color: Palette.tertiary
    }

    //
    // Floppy observer
    //

    component LED: ToolButton {

        implicitHeight: 22
        implicitWidth: 22
        padding: 0
        icon.width: 16
        icon.height: 16
        background: Rectangle { color: "transparent" }
    }

    component FloppyObserver: Control {

        id: root

        required property url redIcon
        required property url greenIcon
        required property url diskIcon
        required property int track
        required property bool busy

        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {

            id: layout

            Layout.alignment: Qt.AlignVCenter
            spacing: Style.smallSpacing

            Row {

                spacing: 0

                LED {

                    padding: 0
                    icon.source: redIcon ? redIcon : ""
                }

                LED {

                    padding: 0
                    icon.source: greenIcon ? greenIcon : ""
                }
            }

            SiText {

                text: track ? track : ""
                font.pixelSize: Style.small
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                color: Palette.tertiary
                DebugRect{}
            }

            PictogramIcon {

                state: diskIcon !== ""
                icon.source: diskIcon ? diskIcon : ""
            }

            BusyIndicator {

                implicitHeight: 22
                implicitWidth: 22
                padding: 3
                running: busy
            }
        }
    }

    //
    // Speedometer
    //

    component Speedometer: Control {

        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {

            id: layout

            Layout.alignment: Qt.AlignVCenter

            RowLayout {

                spacing: 0

                SiText {

                    Layout.preferredWidth: 64
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Style.tiny
                    DebugRect {}

                    text: {
                        switch (metric) {
                            case 0:
                                return activity.amigaMhzString
                            case 1:
                                return activity.amigaFpsString
                            case 2:
                                return activity.hostLoadString
                            case 3:
                                return activity.hostFpsString
                            case 4:
                                return activity.audioFillString
                            default:
                                return "";
                        }
                    }
                }

                Button {

                    id: menuButton
                    flat: true
                    implicitWidth: 16
                    implicitHeight: 22
                    padding: 0
                    text: "unfold_more"
                    font.family: Fonts.symbols
                    font.bold: true
                    onClicked: contextMenu.open()
                    background: Rectangle { color: "transparent" }

                    SiMenu {

                        id: contextMenu
                        y: menuButton.height

                        SiMenuItem {
                            text: "Emulator Frequency"
                            checkable: true
                            checked: metric === 0
                            onClicked: metric = 0
                        }
                        SiMenuItem {
                            text: "Emulator Refresh Rate"
                            checkable: true
                            checked: metric === 1
                            onClicked: metric = 1
                        }
                        MenuSeparator {
                        }
                        SiMenuItem {
                            text: "Host CPU Load"
                            checkable: true
                            checked: metric === 2
                            onClicked: metric = 2
                        }
                        SiMenuItem {
                            text: "Host Refresh Rate"
                            checkable: true
                            checked: metric === 3
                            onClicked: metric = 3
                        }
                        MenuSeparator {
                        }
                        SiMenuItem {
                            text: "Audio Buffer Fill Level"
                            checkable: true
                            checked: metric === 4
                            onClicked: metric = 4
                        }
                    }
                }
            }

            PictogramIcon {

                // In AUTO mode the hourglass reflects whether the emulator is
                // currently warping; otherwise the warp on/off icon mirrors the
                // fixed NEVER / ALWAYS setting. Clicking cycles the warp mode
                // (AUTO -> NEVER -> ALWAYS -> AUTO).
                icon.source: config.AMIGA_WARP_MODE === 0 // 0 = Warp.AUTO
                    ? (amiga.warping ? "qrc:/icons/hourglass-90.png" : "qrc:/icons/hourglass.png")
                    : (amiga.warping ? "qrc:/icons/warp-on.png" : "qrc:/icons/warp-off.png")
                onClicked: amiga.toggleWarp()
            }

            Item {

                id: gaugeArea

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: gaugeRow.implicitWidth
                implicitHeight: gaugeRow.implicitHeight

                RowLayout {

                    id: gaugeRow
                    anchors.fill: parent

                    SiBarGauge {

                        visible: metric === 0
                        maxValue: 2.0
                        value: activity.amigaMhz
                    }

                    SiBarGauge {

                        visible: metric === 1
                        maxValue: 120
                        value: activity.amigaFps
                    }

                    SiBarGauge {

                        visible: metric === 2
                        value: activity.hostLoad
                        stops: [
                            { pos: 0.00, color: "#009900" },
                            { pos: 0.50, color: "#CCCC00" },
                            { pos: 1.00, color: "#990000" }
                        ]
                    }

                    SiBarGauge {

                        visible: metric === 3
                        maxValue: 120
                        value: activity.hostFps
                        stops: [
                            { pos: 0.00, color: "#990000" },
                            { pos: 0.25, color: "#CCCC00" },
                            { pos: 0.50, color: "#009900" },
                            { pos: 1.00, color: "#009900" }
                        ]
                    }

                    SiBarGauge {

                        visible: metric === 4
                        maxValue: 1.0
                        value: activity.audioFill
                    }
                }

                MouseArea {

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: speedPopup.open()
                }

                Popup {

                    id: speedPopup

                    y: -height - Style.smallSpacing
                    x: (gaugeArea.width - width) / 2
                    padding: Style.mediumSpacing
                    modal: true
                    dim: false
                    focus: true
                    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                    background: Rectangle {

                        color: Qt.alpha(Palette.background, 0.96)
                        radius: Style.radius
                        border.color: Palette.border
                        border.width: 1
                    }

                    contentItem: ColumnLayout {

                        spacing: Style.smallSpacing

                        SiSlider {

                            id: speedSlider

                            orientation: Qt.Vertical
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 180
                            from: 50
                            to: 200
                            stepSize: 5
                            snapMode: Slider.SnapAlways

                            boundValue: config.AMIGA_SPEED_BOOST
                            onMoved: config.AMIGA_SPEED_BOOST = value
                        }

                        SiText {
                            // Fixed width -- and centered within it -- so the
                            // digit count changing (e.g. "50" vs "200") doesn't
                            // reflow the popup and jitter the slider under the
                            // cursor while dragging.
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 72
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Style.tiny
                            text: `Speed: ${speedSlider.value} %`
                        }
                    }
                }
            }
        }
    }

    //
    // Main
    //

    implicitHeight: 26
    color: Palette.background

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Palette.background.darker(1.8)
    }

    RowLayout {

        anchors.fill: parent
        Layout.alignment: Qt.AlignVCenter

        HSpacer {
            size: Style.smallSpacing
        }

        //
        // Floppy drives
        //

        Repeater {

            model: 4

            RowLayout {

                required property int index

                visible: config.driveConnected(index)

                FloppyObserver {

                    redIcon: root.redIcon(index)
                    greenIcon: root.greenIcon(index)
                    diskIcon: root.diskIcon(index)
                    track: root.track(index)
                    busy: root.busy(index)
                }

                HSpacer {
                    size: Style.mediumSpacing
                }
            }
        }

        HSpacer {
        }

        //
        // Activity
        //

        Speedometer { }

        HSpacer {
            size: Style.smallSpacing
        }
    }
}
