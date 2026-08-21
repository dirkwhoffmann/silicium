import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Rectangle {

    id: root

    required property C64Controller c64
    readonly property SiC64InfoController info: c64.info
    readonly property SiC64ConfigController config: c64.configController
    readonly property SiC64ActivityController activity: c64.activityController
    readonly property SiC64StatusbarController statusbar: c64.statusbarController
    readonly property SiC64KeyboardController keyboard: c64.keyboardController

    property int metric: 0

    //
    // Floppy-drive status icons, computed from the info controller's drive
    // state. Red/green LEDs light up when lit, else show the gray LED; the
    // disk icon reflects write protection, or is blank when no disk is in.
    //

    readonly property string ledRed:    "qrc:/images/led-round-red.png"
    readonly property string ledGreen:  "qrc:/images/led-round-green.png"
    readonly property string ledGray:   "qrc:/images/led-round-gray.png"
    readonly property string disk525:   "qrc:/icons/disk-525.png"
    readonly property string disk525wp: "qrc:/icons/disk-525-wp.png"

    // Remote-server state (LED, icon, label) is computed by the info
    // controller -- see SiC64InfoController::serverStateLed/Icon/Name --
    // so the statusbar and the server config panel render it identically.

    readonly property url redIcon8:   info.redLED8 ? ledRed : ledGray
    readonly property url greenIcon8: info.greenLED8 ? ledGreen : ledGray
    readonly property url diskIcon8:  info.hasDisk8 ? (info.hasProtectedDisk8 ? disk525wp : disk525) : ""

    readonly property url redIcon9:   info.redLED9 ? ledRed : ledGray
    readonly property url greenIcon9: info.greenLED9 ? ledGreen : ledGray
    readonly property url diskIcon9:  info.hasDisk9 ? (info.hasProtectedDisk9 ? disk525wp : disk525) : ""

    //
    // Tape / cartridge icons, computed from the info controller's media
    // state -- shown only while the media is inserted / attached.
    //

    readonly property url tapeIcon: info.hasTape ? "qrc:/icons/tape.png" : ""
    readonly property url crtIcon:  info.hasCrt ? "qrc:/icons/cartridge.png" : ""

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
    // Tape observer
    //

    component TapeObserver: Control {

        id: root

        required property string counter
        required property url icon
        required property bool busy

        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {

            id: layout

            Layout.alignment: Qt.AlignVCenter
            spacing: Style.smallSpacing

            SiText {

                text: counter
                font.pixelSize: Style.tiny
                color: Palette.icon
            }

            PictogramIcon {

                state: root.icon !== ""
                icon.source: root.icon
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
    // Cartridge observer
    //

    component CartridgeObserver: Control {

        id: root

        required property url icon

        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {

            id: layout

            Layout.alignment: Qt.AlignVCenter
            spacing: Style.smallSpacing

            PictogramIcon {

                state: root.icon !== ""
                icon.source: root.icon
            }
        }
    }


    //
    // Server row (one line of the server popup)
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
                                return activity.c64MhzString
                            case 1:
                                return activity.c64FpsString
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
                icon.source: config.C64_WARP_MODE === 0 // 0 = Warp.AUTO
                    ? (info.warping ? "qrc:/icons/hourglass-90.png" : "qrc:/icons/hourglass.png")
                    : (info.warping ? "qrc:/icons/warp-on.png" : "qrc:/icons/warp-off.png")
                onClicked: c64.toggleWarp()
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
                        value: activity.c64Mhz
                    }

                    SiBarGauge {

                        visible: metric === 1
                        maxValue: 120
                        value: activity.c64Fps
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

                            boundValue: config.C64_SPEED_BOOST
                            onMoved: config.C64_SPEED_BOOST = value
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
        // Peripherals
        //

        FloppyObserver {

            visible: config.DRIVE8_CONNECTED
            redIcon: root.redIcon8
            greenIcon: root.greenIcon8
            diskIcon: root.diskIcon8
            track: info.track8 ?? 0
            busy: info.spinning8 ?? false
        }

        HSpacer {
            size: Style.mediumSpacing
        }

        FloppyObserver {

            visible: config.DRIVE9_CONNECTED
            redIcon: root.redIcon9
            greenIcon: root.greenIcon9
            diskIcon: root.diskIcon9
            track: info.track9 ?? 0
            busy: info.spinning9 ?? false
        }

        HSpacer {
            size: Style.mediumSpacing
        }

        TapeObserver {

            visible: root.config.DAT_CONNECT && root.info.hasTape
            counter: info.tapeCounter
            icon: root.tapeIcon
            busy: info.tapeSpinning
        }

        HSpacer {
        }

        CartridgeObserver {

            visible: root.info.hasCrt
            icon: root.crtIcon
        }

        HSpacer {
        }

        //
        // Icons
        //

        PictogramIcon {
            state: keyboard.commodore
            icon.source: "qrc:/icons/chicken-lips.svg"
        }
        Pictogram {
            state: info.jammed
            symbol: "back_hand"
        }

        Pictogram {
            state: info.tracking
            symbol: "bug_report"
        }
        Pictogram {
            state: info.mute
            symbol: "volume_off"
        }

        HSpacer {
        }

        //
        // Activity
        //

        Speedometer { }
        // HSpacer { size: Style.tinySpacing }

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
                        label: "RPC Server"
                        srvState: info.rpcServerState
                        onToggled: config.SRV_RPC_ENABLE = !config.SRV_RPC_ENABLE
                    }
                    ServerRow {
                        label: "Remote Shell"
                        srvState: info.rshServerState
                        onToggled: config.SRV_RSH_ENABLE = !config.SRV_RSH_ENABLE
                    }
                    /*
                    ServerRow {
                        label: "Debug Adapter"
                        srvState: info.dapServerState
                        onToggled: config.SRV_DAP_ENABLE = !config.SRV_DAP_ENABLE
                    }
                    */
                    ServerRow {
                        label: "Prometheus Server"
                        srvState: info.promServerState
                        onToggled: config.SRV_PROM_ENABLE = !config.SRV_PROM_ENABLE
                    }
                }
            }
        }

        HSpacer {
            size: Style.smallSpacing
        }
    }
}