// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmPortController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmPortController::SiAmPortController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

void
SiAmPortController::clearSerialIn()
{
    m_serialIn.clear();
    emit portsChanged();
}

void
SiAmPortController::clearSerialOut()
{
    m_serialOut.clear();
    emit portsChanged();
}

void
SiAmPortController::refreshData()
{
    auto &core = SiAmController::core();

    ControlPortInfo port1Info {}, port2Info {};
    SerialPortInfo serInfo {};
    UARTInfo uartInfo {};

    try {

        port1Info = core.controlPort1.getInfo();
        port2Info = core.controlPort2.getInfo();
        serInfo = core.serialPort.getInfo();
        uartInfo = core.paula.uart.getInfo();

    } catch (...) { return; }

    int potgo = port1Info.potgo;
    int potgor = port1Info.potgor;

    m_potgo = potgo;
    m_outry = potgo & 0x8000;
    m_datry = potgo & 0x4000;
    m_outrx = potgo & 0x2000;
    m_datrx = potgo & 0x1000;
    m_outly = potgo & 0x0800;
    m_datly = potgo & 0x0400;
    m_outlx = potgo & 0x0200;
    m_datlx = potgo & 0x0100;

    m_potgor = potgor;
    m_datryr = potgor & 0x4000;
    m_datrxr = potgor & 0x1000;
    m_datlyr = potgor & 0x0400;
    m_datlxr = potgor & 0x0100;

    m_joydat[0] = port1Info.joydat;
    m_potdat[0] = port1Info.potdat;
    m_m0v[0] = port1Info.m0v;
    m_m0h[0] = port1Info.m0h;
    m_m1v[0] = port1Info.m1v;
    m_m1h[0] = port1Info.m1h;

    m_joydat[1] = port2Info.joydat;
    m_potdat[1] = port2Info.potdat;
    m_m0v[1] = port2Info.m0v;
    m_m0h[1] = port2Info.m0h;
    m_m1v[1] = port2Info.m1v;
    m_m1h[1] = port2Info.m1h;

    m_serper = uartInfo.serper;
    m_baudRate = (int)uartInfo.baudRate;
    m_long = uartInfo.serper & 0x8000;
    m_receiveShiftReg = uartInfo.receiveShiftReg;
    m_receiveBuffer = uartInfo.receiveBuffer;
    m_transmitShiftReg = uartInfo.transmitShiftReg;
    m_transmitBuffer = uartInfo.transmitBuffer;

    m_txd = serInfo.txd;
    m_rxd = serInfo.rxd;
    m_cts = serInfo.cts;
    m_dsr = serInfo.dsr;
    m_cd = serInfo.cd;
    m_dtr = serInfo.dtr;

    // Drain the incoming/outgoing byte queues, matching MyController.swift's
    // Msg::SER_IN/SER_OUT handlers -- see the class comment on why this is
    // polled here instead.
    for (int c = core.serialPort.readIncomingPrintableByte(); c != -1;
         c = core.serialPort.readIncomingPrintableByte()) {
        m_serialIn += QChar((char)c);
    }
    if (m_serialIn.size() > 8192) m_serialIn = "...\n" + m_serialIn.sliced(m_serialIn.size() - 8000);

    for (int c = core.serialPort.readOutgoingPrintableByte(); c != -1;
         c = core.serialPort.readOutgoingPrintableByte()) {
        m_serialOut += QChar((char)c);
    }
    if (m_serialOut.size() > 8192) m_serialOut = "...\n" + m_serialOut.sliced(m_serialOut.size() - 8000);

    emit portsChanged();
}
