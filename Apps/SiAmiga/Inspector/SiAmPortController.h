// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiAmInspectorController.h"
#include "VAmiga.h"
#include <QString>

//
// Ports inspector controller -- port of vAmiga's own GUI/Inspector/
// PortPanel.swift: the two control ports (joystick/mouse quadrature +
// POTGO/POTGOR paddle-control bits) and the serial port (UART shift
// registers/buffers + modem control lines + the outgoing/incoming byte
// logs).
//
// Queried straight from the core each refresh (ControlPortAPI::getInfo(),
// SerialPortAPI::getInfo(), UARTAPI::getInfo()) rather than through the
// shared SiAmInfoController -- none of these are sampled by any other panel
// or the status bar yet, so there's nothing to coalesce.
//
// The serial logs (serialIn/serialOut) are drained from SerialPortAPI's
// byte queues (readIncomingPrintableByte()/readOutgoingPrintableByte(),
// -1-terminated) on every refresh rather than message-driven off
// Msg::SER_IN/SER_OUT the way MyController.swift does -- the queue is
// drained to empty either way, so polling it on this panel's own ~4 Hz
// tick loses nothing, it just doesn't react the instant a byte arrives.
// Truncated at 8192 characters, matching the Swift reference.
//

class SiAmController;

class SiAmPortController : public SiAmInspectorController {

    Q_OBJECT

    // Control ports (commons -- POTGO/POTGOR are shared registers, read
    // once off port 1, matching PortPanel.swift's own "Control port
    // commons" comment).
    int m_potgo = 0, m_potgor = 0;
    bool m_outry = false, m_datry = false, m_outrx = false, m_datrx = false;
    bool m_outly = false, m_datly = false, m_outlx = false, m_datlx = false;
    bool m_datryr = false, m_datrxr = false, m_datlyr = false, m_datlxr = false;

    // Per-port fields
    int m_joydat[2] = {};
    int m_potdat[2] = {};
    bool m_m0v[2] = {}, m_m0h[2] = {}, m_m1v[2] = {}, m_m1h[2] = {};

    // Serial port / UART
    int m_serper = 0;
    int m_baudRate = 0;
    bool m_long = false;
    bool m_txd = false, m_rxd = false, m_cts = false, m_dsr = false, m_cd = false, m_dtr = false;
    int m_receiveShiftReg = 0, m_receiveBuffer = 0;
    int m_transmitShiftReg = 0, m_transmitBuffer = 0;

    QString m_serialIn;
    QString m_serialOut;

  public:

    explicit SiAmPortController(SiAmController *parent = nullptr);

    Q_PROPERTY(int potgo READ potgo NOTIFY portsChanged)
    Q_PROPERTY(int potgor READ potgor NOTIFY portsChanged)
    Q_PROPERTY(bool outry READ outry NOTIFY portsChanged)
    Q_PROPERTY(bool datry READ datry NOTIFY portsChanged)
    Q_PROPERTY(bool outrx READ outrx NOTIFY portsChanged)
    Q_PROPERTY(bool datrx READ datrx NOTIFY portsChanged)
    Q_PROPERTY(bool outly READ outly NOTIFY portsChanged)
    Q_PROPERTY(bool datly READ datly NOTIFY portsChanged)
    Q_PROPERTY(bool outlx READ outlx NOTIFY portsChanged)
    Q_PROPERTY(bool datlx READ datlx NOTIFY portsChanged)
    Q_PROPERTY(bool datryr READ datryr NOTIFY portsChanged)
    Q_PROPERTY(bool datrxr READ datrxr NOTIFY portsChanged)
    Q_PROPERTY(bool datlyr READ datlyr NOTIFY portsChanged)
    Q_PROPERTY(bool datlxr READ datlxr NOTIFY portsChanged)

    // Per-port fields (nr: 0 or 1), Q_INVOKABLE the same way SiAmInfoController's
    // dReg(n)/aReg(n) expose an indexed set rather than doubling every
    // property.
    Q_INVOKABLE int joydat(int nr) const { return nr >= 0 && nr < 2 ? m_joydat[nr] : 0; }
    Q_INVOKABLE int potdat(int nr) const { return nr >= 0 && nr < 2 ? m_potdat[nr] : 0; }
    Q_INVOKABLE bool m0v(int nr) const { return nr >= 0 && nr < 2 && m_m0v[nr]; }
    Q_INVOKABLE bool m0h(int nr) const { return nr >= 0 && nr < 2 && m_m0h[nr]; }
    Q_INVOKABLE bool m1v(int nr) const { return nr >= 0 && nr < 2 && m_m1v[nr]; }
    Q_INVOKABLE bool m1h(int nr) const { return nr >= 0 && nr < 2 && m_m1h[nr]; }

    Q_PROPERTY(int serper READ serper NOTIFY portsChanged)
    Q_PROPERTY(int baudRate READ baudRate NOTIFY portsChanged)
    Q_PROPERTY(bool long_ READ long_ NOTIFY portsChanged)
    Q_PROPERTY(bool txd READ txd NOTIFY portsChanged)
    Q_PROPERTY(bool rxd READ rxd NOTIFY portsChanged)
    Q_PROPERTY(bool cts READ cts NOTIFY portsChanged)
    Q_PROPERTY(bool dsr READ dsr NOTIFY portsChanged)
    Q_PROPERTY(bool cd READ cd NOTIFY portsChanged)
    Q_PROPERTY(bool dtr READ dtr NOTIFY portsChanged)
    Q_PROPERTY(int receiveShiftReg READ receiveShiftReg NOTIFY portsChanged)
    Q_PROPERTY(int receiveBuffer READ receiveBuffer NOTIFY portsChanged)
    Q_PROPERTY(int transmitShiftReg READ transmitShiftReg NOTIFY portsChanged)
    Q_PROPERTY(int transmitBuffer READ transmitBuffer NOTIFY portsChanged)

    Q_PROPERTY(QString serialIn READ serialIn NOTIFY portsChanged)
    Q_PROPERTY(QString serialOut READ serialOut NOTIFY portsChanged)

    Q_INVOKABLE void clearSerialIn();
    Q_INVOKABLE void clearSerialOut();

  protected:

    void refreshData() override;

  private:

    int potgo() const { return m_potgo; }
    int potgor() const { return m_potgor; }
    bool outry() const { return m_outry; }
    bool datry() const { return m_datry; }
    bool outrx() const { return m_outrx; }
    bool datrx() const { return m_datrx; }
    bool outly() const { return m_outly; }
    bool datly() const { return m_datly; }
    bool outlx() const { return m_outlx; }
    bool datlx() const { return m_datlx; }
    bool datryr() const { return m_datryr; }
    bool datrxr() const { return m_datrxr; }
    bool datlyr() const { return m_datlyr; }
    bool datlxr() const { return m_datlxr; }

    int serper() const { return m_serper; }
    int baudRate() const { return m_baudRate; }
    bool long_() const { return m_long; }
    bool txd() const { return m_txd; }
    bool rxd() const { return m_rxd; }
    bool cts() const { return m_cts; }
    bool dsr() const { return m_dsr; }
    bool cd() const { return m_cd; }
    bool dtr() const { return m_dtr; }
    int receiveShiftReg() const { return m_receiveShiftReg; }
    int receiveBuffer() const { return m_receiveBuffer; }
    int transmitShiftReg() const { return m_transmitShiftReg; }
    int transmitBuffer() const { return m_transmitBuffer; }

    QString serialIn() const { return m_serialIn; }
    QString serialOut() const { return m_serialOut; }

  signals:

    void portsChanged();
};
