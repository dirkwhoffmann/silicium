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

Rectangle {

    id: root

    required property SiAmController amiga
    readonly property SiAmConfigController config: amiga.configController
    readonly property SiAmActivityController activity: amiga.activityController
    // SiAmInfoController isn't registered via qmlRegisterType (unlike
    // SiC64InfoController), so it's referenced as 'var' here too, matching
    // every other SiAmiga panel that reads controller.info.
    readonly property var info: amiga.info

    property int metric: 0

    // Status icons
    readonly property string ledRed:   "qrc:/images/led-red.png"
    readonly property string ledGreen: "qrc:/images/led-green.png"
    readonly property string ledGray:  "qrc:/images/led-gray.png"
    readonly property string disk35:   "qrc:/icons/disk-35.png"
    readonly property string disk35wp: "qrc:/icons/disk-35-wp.png"

    /* Drive state comes from the info controller, which the core tells when
     * something moves (Msg::DRIVE_MOTOR and friends) and which samples the
     * machine the way it is safe to: a snapshot taken by the emulator thread,
     * not a reading made on this one (see SiAmInfoController::grab).
     *
     * Each of these is a NOTIFY-backed property per drive, named rather than
     * indexed, so the switch is what registers the binding on the one drive
     * that matters -- the same reason the 'visible' switch below spells out
     * DF0_CONNECTED..DF3_CONNECTED.
     */
    function spinning(nr) {

        switch (nr) {
            case 0: return info.spinning0
            case 1: return info.spinning1
            case 2: return info.spinning2
            case 3: return info.spinning3
        }
        return false
    }

    function writing(nr) {

        switch (nr) {
            case 0: return info.writing0
            case 1: return info.writing1
            case 2: return info.writing2
            case 3: return info.writing3
        }
        return false
    }

    function hasDisk(nr) {

        switch (nr) {
            case 0: return info.hasDisk0
            case 1: return info.hasDisk1
            case 2: return info.hasDisk2
            case 3: return info.hasDisk3
        }
        return false
    }

    function diskProtected(nr) {

        switch (nr) {
            case 0: return info.hasProtectedDisk0
            case 1: return info.hasProtectedDisk1
            case 2: return info.hasProtectedDisk2
            case 3: return info.hasProtectedDisk3
        }
        return false
    }

    function track(nr) {

        switch (nr) {
            case 0: return info.track0
            case 1: return info.track1
            case 2: return info.track2
            case 3: return info.track3
        }
        return 0
    }

    function redIcon(nr)   { return spinning(nr) ? ledRed : ledGray }
    function greenIcon(nr) { return writing(nr) ? ledGreen : ledGray }
    function diskIcon(nr)  { return hasDisk(nr) ? (diskProtected(nr) ? disk35wp : disk35) : "" }

    Component.onCompleted: {

        myTicker.show("Initializing...", 2000)
        myTicker.hide()
    }

    //
    // Pictogram
    //

    component Pictogram: SiSymbolButton {

        property bool state: true

        visible: state || Preferences.qtDebug
        color: Palette.tertiary
    }

    component PictogramIcon: SiImageButton {

        property bool state: true

        visible: state || Preferences.qtDebug
        icon.color: Palette.tertiary
    }

    //
    // Floppy observer
    //

    component LED: ToolButton {

        implicitWidth: 28
        implicitHeight: 22
        padding: 0
        icon.width: 24
        icon.height: 20
        background: Rectangle { color: "transparent" }
    }

    component FloppyObserver: Control {

        id: root

        required property url redIcon
        required property url greenIcon
        required property url diskIcon
        required property int track
        required property bool spinning

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
                running: root.spinning && amiga.isRunning
            }
        }
    }

    //
    // Server status
    //

    component ServerRow: Rectangle {

        required property string label
        property int srvState: 0

        signal toggled()

        implicitWidth: Math.max(180, rowLayout.implicitWidth + 2 * Style.mediumSpacing)
        implicitHeight: 28
        radius: Style.radius
        color: rowMouse.containsMouse ? Qt.alpha(Palette.accent, 0.15) : "transparent"

        RowLayout {

            id: rowLayout

            anchors.fill: parent
            anchors.leftMargin: Style.mediumSpacing
            anchors.rightMargin: Style.mediumSpacing
            spacing: Style.smallSpacing

            Image {

                source: info.serverStateLed(srvState)
                sourceSize.width: 12
                sourceSize.height: 12
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
            }

            SiText {

                text: label
                font.pixelSize: Style.small
                color: Palette.primary
                Layout.fillWidth: true
            }

            SiText {

                text: info.serverStateName(srvState)
                font.pixelSize: Style.tiny
                color: Palette.tertiary
            }
        }

        MouseArea {

            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggled()
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
                        maxValue: 2.0 * 7.0 * activity.overclocking
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
        // Ticker
        //

        RowLayout {

            visible: myTicker.text !== ""
            Layout.fillWidth: true

            BusyIndicator {

                visible: root.amiga.busy
                implicitHeight: 22
                implicitWidth: 22
                padding: 3
                running: myTicker.text !== ""
            }

            SiTicker {

                id: myTicker
                Layout.fillWidth: true
                size: Size.small

                Connections {

                    target: amiga
                    function onShowProgress(what, percentage) { myTicker.show(what) }
                    function onShowTicker(what) { myTicker.show(what) }
                }
            }
        }

        //
        // LEDs / Peripherals
        //

        RowLayout {

            visible: myTicker.text === ""

            //
            // Floppy drives
            //

            Repeater {

                model: 4

                RowLayout {

                    required property int index

                    // driveConnected(nr) is a Q_INVOKABLE, not a Q_PROPERTY, so
                    // reading it here wouldn't register as a binding dependency
                    // and 'visible' would go stale -- see the DF0_CONNECTED..
                    // _CONNECTED comment in SiAmConfigController.h. index is
                    // fixed per delegate, so the matching named property keeps
                    // this reactive.
                    visible: {
                        switch (index) {
                            case 0:
                                return config.DF0_CONNECTED
                            case 1:
                                return config.DF1_CONNECTED
                            case 2:
                                return config.DF2_CONNECTED
                            case 3:
                                return config.DF3_CONNECTED
                        }
                        return false
                    }

                    FloppyObserver {

                        redIcon: root.redIcon(index)
                        greenIcon: root.greenIcon(index)
                        diskIcon: root.diskIcon(index)
                        track: root.track(index)
                        spinning: root.spinning(index)
                    }

                    HSpacer {
                        size: Style.mediumSpacing
                    }
                }
            }
        }

        HSpacer {
        }

        //
        // Activity
        //

        Speedometer { }

        //
        // Server status
        //

        Pictogram {

            id: serverButton

            state: true
            phosphor: info.serverStateIcon(info.serverState)
            onClicked: serverPopup.open()

            Popup {

                id: serverPopup

                y: -height - Style.smallSpacing
                x: serverButton.width - width
                padding: Style.smallSpacing
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

                    spacing: 0

                    ServerRow {
                        label: "Remote Shell"
                        srvState: info.rshServerState
                        onToggled: config.SRV_RSH_ENABLE = !config.SRV_RSH_ENABLE
                    }
                    ServerRow {
                        label: "RPC Server"
                        srvState: info.rpcServerState
                        onToggled: config.SRV_RPC_ENABLE = !config.SRV_RPC_ENABLE
                    }
                    ServerRow {
                        label: "GDB Server"
                        srvState: info.gdbServerState
                        onToggled: config.SRV_GDB_ENABLE = !config.SRV_GDB_ENABLE
                    }
                    ServerRow {
                        label: "Prometheus Server"
                        srvState: info.promServerState
                        onToggled: config.SRV_PROM_ENABLE = !config.SRV_PROM_ENABLE
                    }
                    ServerRow {
                        label: "Serial Port Server"
                        srvState: info.serServerState
                        onToggled: config.SRV_SER_ENABLE = !config.SRV_SER_ENABLE
                    }
                }
            }
        }

        HSpacer {
            size: Style.smallSpacing
        }
    }
}
