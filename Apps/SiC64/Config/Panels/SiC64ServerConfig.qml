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

SettingsPage {

    id: root

    required property C64Controller controller
    readonly property var config: controller.configController
    readonly property SiC64InfoController info: controller.info

    readonly property int labelWidth: 100
    readonly property int comboWidth: 220
    readonly property int sectionWidth: 320

    toolbar: ConfigToolbar {

        heading: "Server Settings"
        menuContent: [
            MenuItem {
                text: "Restore factory defaults..."
                onTriggered: config.restoreServerDefaults()
            }
        ]

        HSpacer { }

        ConfigLock {

            onClicked: controller.powerOnOrOff()
        }
    }

    component Server: GridLayout {

        id: server

        required property string name
        required property string description
        // SrvState of this server (see SiC64InfoController), drives row 2's
        // icon and label.
        required property int serverState
        property string endPoint

        property alias enable: checkBox.checked
        property alias transport: comboBox.currentIndex
        property alias model: comboBox.model
        property alias port: numberBox.intValue
        property alias isItemEnabled: comboBox.isItemEnabled

        // Forwarded from the port field. Write the port back from here rather
        // than from onPortChanged: 'port' is bound to a config option, and
        // assigning it would destroy that binding (see SiNumberInputControl).
        signal portEdited(int value)

        columns: 2
        columnSpacing: Style.mediumSpacing

        //
        // Row 1
        //

        SiCheckBoxControl {

            id: checkBox
            // Layout.preferredWidth: 150
            // Layout.fillWidth: false
            // Layout.alignment: Qt.AlignTop
            Layout.alignment: Qt.AlignVCenter
            r: name
            rwidth: 150
        }

        RowLayout {

            SiComboBoxControl {

                id: comboBox
                // Layout.fillWidth: false
                controlWidth: 96
                model: [ "STDIO", "TCP", "HTTP" ]
            }

            SiNumberInputControl {

                id: numberBox
                // Layout.fillWidth: false
                // Layout.alignment: Qt.AlignTop
                Layout.alignment: Qt.AlignVCenter
                l: "Port:"
                controlWidth: 48

                onValueEdited: (value) => server.portEdited(value)
            }

            SiText {

                visible: comboBox.model[comboBox.currentIndex] === "HTTP"
                text: "/ " + endPoint
            }

            HSpacer {}
        }

        //
        // Row 2
        //

        RowLayout {

            Layout.alignment: Qt.AlignTop

            SiSymbolButton {

                Layout.leftMargin: 20
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                phosphor: info.serverStateIcon(serverState)
                font.pixelSize: Style.large
            }

            SiText {

                Layout.fillWidth: false
                Layout.alignment: Qt.AlignVCenter
                text: info.serverStateName(serverState)
                font.bold: true
            }
        }

        TextArea {

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.leftMargin: 0
            leftInset: 0
            padding: 0
            readOnly: true
            background: null
            text: description
            wrapMode: TextEdit.Wrap
        }
    }

    ConfigSection {

        header: "REMOTE SERVERS"
        size: 2 * root.sectionWidth

        Server {

            name: "RPC Server"
            description: "Enables structured communication with RetroShell using RPC packages. Ideal for automation, scripting, or integrating external tools with the emulator’s internal APIs."
            isItemEnabled: function(itemText, index) {
                return true;
            }
            endPoint: "rpc"
            serverState: info.rpcServerState

            enable: config.SRV_RPC_ENABLE
            onEnableChanged: config.SRV_RPC_ENABLE = enable
            transport: config.SRV_RPC_TRANSPORT
            onTransportChanged: config.SRV_RPC_TRANSPORT = transport
            port: config.SRV_RPC_PORT
            onPortEdited: (value) => config.SRV_RPC_PORT = value
        }

        VSpacer { size: Style.largeSpacing }

        Server {

            name: "Remote Shell Server"
            description: "Provides TCP access to RetroShell for interactive command execution. Connect easily using Telnet or Netcat to control and monitor the emulator remotely."
            isItemEnabled: function(itemText, index) {
                return itemText === "STDIO" || itemText === "TCP";
            }

            serverState: info.rshServerState

            enable: config.SRV_RSH_ENABLE
            onEnableChanged: config.SRV_RSH_ENABLE = enable
            transport: config.SRV_RSH_TRANSPORT
            onTransportChanged: config.SRV_RSH_TRANSPORT = transport
            port: config.SRV_RSH_PORT
            onPortEdited: (value) => config.SRV_RSH_PORT = value
        }

        VSpacer { size: Style.largeSpacing }

        Server {

            name: "Prometheus Server"
            description: "Exposes real-time emulation metrics for Prometheus-compatible clients, allowing performance monitoring, visualization, and analysis through Grafana or similar tools."
            isItemEnabled: function(itemText, index) {
                return itemText === "HTTP";
            }
            endPoint: "metrics"
            serverState: info.promServerState

            enable: config.SRV_PROM_ENABLE
            onEnableChanged: config.SRV_PROM_ENABLE = enable
            transport: config.SRV_PROM_TRANSPORT
            onTransportChanged: config.SRV_PROM_TRANSPORT = transport
            port: config.SRV_PROM_PORT
            onPortEdited: (value) => config.SRV_PROM_PORT = value
        }

        VSpacer { size: Style.largeSpacing }

        Server {

            visible: false
            name: "DAP Adapter"
            description: "Offers a Debug Adapter Protocol interface for connecting external debug clients, enabling source-level debugging and runtime inspection of the emulated system."
            isItemEnabled: function(itemText, index) {
                return itemText === "STDIO" || itemText === "TCP";
            }
            serverState: info.dapServerState

            enable: config.SRV_DAP_ENABLE
            onEnableChanged: config.SRV_DAP_ENABLE = enable
            transport: config.SRV_DAP_TRANSPORT
            onTransportChanged: config.SRV_DAP_TRANSPORT = transport
            port: config.SRV_DAP_PORT
            onPortEdited: (value) => config.SRV_DAP_PORT = value
        }
    }
}
