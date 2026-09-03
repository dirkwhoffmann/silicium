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
#include <QStringList>

//
// CIA inspector controller -- port of SiC64CIAController. Samples CIA A or
// CIA B (see selectedCia) and exposes its ports, timers, ICR/IMR, TOD clock
// and idle statistics for a future SiAmCIAPanel.
//
// The shared active flag, tick throttle and beam-position readout live in
// the SiAmInspectorController base class; this class only adds the
// CIA-panel specifics and overrides refreshData() to sample them.
//
// Two real differences from the C64 version, both hardware-driven rather
// than stylistic:
//
//  - vAmiga's two CIA chips are called CIA A / CIA B (not CIA1/CIA2), and
//    their port pins wire up to entirely different things than the C64's
//    joystick/serial-bus CIAs -- CIA A's ports drive the power LED, ROM
//    overlay bit and floppy status lines (port A) and the parallel port
//    (port B); CIA B's drive the serial port (port A) and the floppy
//    control lines -- step/side/motor/select (port B). See
//    Core/Components/CIA/CIA.cpp's own pin-out comments, which
//    portALabels/portBLabels below are transcribed from directly.
//
//  - The Amiga's CIA TOD is a plain 24-bit cycle counter (TODInfo's
//    value/latch/alarm), not the C64 CIA's BCD hour:min:sec.tenth clock
//    (vc64's TODInfo has separate hour/min/sec/tenth fields) -- so
//    todValue/todLatch/todAlarm are raw counters here instead of four
//    decoded time components each.
//

class SiAmController;

class SiAmCIAController : public SiAmInspectorController {

    Q_OBJECT

    int m_selectedCia = 0; // 0 = CIA A, 1 = CIA B

    QString m_title;

    // Port A / B. The register/direction values are raw so a future panel's
    // SiNumberView can format them per the shared display format.
    int m_portAPort = 0;
    int m_portBPort = 0;
    int m_portAReg = 0, m_portADir = 0;
    int m_portBReg = 0, m_portBDir = 0;
    // index i = bit i (index 0 = PA0, index 7 = PA7). Pre-populated with 8
    // placeholder entries (rather than left empty) so QML's Led Repeater
    // never indexes past the end before the first refresh() runs.
    QStringList m_portALabels { "", "", "", "", "", "", "", "" };
    QStringList m_portBLabels { "", "", "", "", "", "", "", "" };

    // Timer A / B
    int m_timerACount = 0, m_timerALatch = 0;
    bool m_timerARunning = false, m_timerAToggle = false, m_timerAPbout = false, m_timerAOneShot = false;
    int m_timerBCount = 0, m_timerBLatch = 0;
    bool m_timerBRunning = false, m_timerBToggle = false, m_timerBPbout = false, m_timerBOneShot = false;

    // Interrupts
    int m_icr = 0, m_imr = 0;
    bool m_intLineLow = false;
    QString m_intLineLabel;

    // TOD clock / alarm / latch -- raw 24-bit counters, see the class comment.
    qint64 m_todValue = 0, m_todLatch = 0, m_todAlarm = 0;
    bool m_todIntEnable = false;

    // Serial data / shift registers
    int m_sdr = 0, m_ssr = 0;

    // Idle statistics
    QString m_idleCycles;
    int m_idlePercentage = 0;
    QString m_idlePercentageText;

  public:

    explicit SiAmCIAController(SiAmController *parent = nullptr);

    Q_PROPERTY(int selectedCia READ selectedCia WRITE setSelectedCia NOTIFY ciaChanged)
    Q_PROPERTY(QString title READ title NOTIFY ciaChanged)

    Q_PROPERTY(int portAPort READ portAPort NOTIFY ciaChanged)
    Q_PROPERTY(int portBPort READ portBPort NOTIFY ciaChanged)
    Q_PROPERTY(int portAReg READ portAReg NOTIFY ciaChanged)
    Q_PROPERTY(int portADir READ portADir NOTIFY ciaChanged)
    Q_PROPERTY(int portBReg READ portBReg NOTIFY ciaChanged)
    Q_PROPERTY(int portBDir READ portBDir NOTIFY ciaChanged)
    Q_PROPERTY(QStringList portALabels READ portALabels NOTIFY ciaChanged)
    Q_PROPERTY(QStringList portBLabels READ portBLabels NOTIFY ciaChanged)

    Q_PROPERTY(int timerACount READ timerACount NOTIFY ciaChanged)
    Q_PROPERTY(int timerALatch READ timerALatch NOTIFY ciaChanged)
    Q_PROPERTY(bool timerARunning READ timerARunning NOTIFY ciaChanged)
    Q_PROPERTY(bool timerAToggle READ timerAToggle NOTIFY ciaChanged)
    Q_PROPERTY(bool timerAPbout READ timerAPbout NOTIFY ciaChanged)
    Q_PROPERTY(bool timerAOneShot READ timerAOneShot NOTIFY ciaChanged)

    Q_PROPERTY(int timerBCount READ timerBCount NOTIFY ciaChanged)
    Q_PROPERTY(int timerBLatch READ timerBLatch NOTIFY ciaChanged)
    Q_PROPERTY(bool timerBRunning READ timerBRunning NOTIFY ciaChanged)
    Q_PROPERTY(bool timerBToggle READ timerBToggle NOTIFY ciaChanged)
    Q_PROPERTY(bool timerBPbout READ timerBPbout NOTIFY ciaChanged)
    Q_PROPERTY(bool timerBOneShot READ timerBOneShot NOTIFY ciaChanged)

    Q_PROPERTY(int icr READ icr NOTIFY ciaChanged)
    Q_PROPERTY(int imr READ imr NOTIFY ciaChanged)
    Q_PROPERTY(bool intLineLow READ intLineLow NOTIFY ciaChanged)
    Q_PROPERTY(QString intLineLabel READ intLineLabel NOTIFY ciaChanged)

    Q_PROPERTY(qint64 todValue READ todValue NOTIFY ciaChanged)
    Q_PROPERTY(qint64 todLatch READ todLatch NOTIFY ciaChanged)
    Q_PROPERTY(qint64 todAlarm READ todAlarm NOTIFY ciaChanged)
    Q_PROPERTY(bool todIntEnable READ todIntEnable NOTIFY ciaChanged)

    Q_PROPERTY(int sdr READ sdr NOTIFY ciaChanged)
    Q_PROPERTY(int ssr READ ssr NOTIFY ciaChanged)

    Q_PROPERTY(QString idleCycles READ idleCycles NOTIFY ciaChanged)
    Q_PROPERTY(int idlePercentage READ idlePercentage NOTIFY ciaChanged)
    Q_PROPERTY(QString idlePercentageText READ idlePercentageText NOTIFY ciaChanged)

    int selectedCia() const { return m_selectedCia; }
    void setSelectedCia(int value);

  protected:

    void refreshData() override;

  private:

    QString title() const { return m_title; }

    int portAPort() const { return m_portAPort; }
    int portBPort() const { return m_portBPort; }
    int portAReg() const { return m_portAReg; }
    int portADir() const { return m_portADir; }
    int portBReg() const { return m_portBReg; }
    int portBDir() const { return m_portBDir; }
    QStringList portALabels() const { return m_portALabels; }
    QStringList portBLabels() const { return m_portBLabels; }

    int timerACount() const { return m_timerACount; }
    int timerALatch() const { return m_timerALatch; }
    bool timerARunning() const { return m_timerARunning; }
    bool timerAToggle() const { return m_timerAToggle; }
    bool timerAPbout() const { return m_timerAPbout; }
    bool timerAOneShot() const { return m_timerAOneShot; }

    int timerBCount() const { return m_timerBCount; }
    int timerBLatch() const { return m_timerBLatch; }
    bool timerBRunning() const { return m_timerBRunning; }
    bool timerBToggle() const { return m_timerBToggle; }
    bool timerBPbout() const { return m_timerBPbout; }
    bool timerBOneShot() const { return m_timerBOneShot; }

    int icr() const { return m_icr; }
    int imr() const { return m_imr; }
    bool intLineLow() const { return m_intLineLow; }
    QString intLineLabel() const { return m_intLineLabel; }

    qint64 todValue() const { return m_todValue; }
    qint64 todLatch() const { return m_todLatch; }
    qint64 todAlarm() const { return m_todAlarm; }
    bool todIntEnable() const { return m_todIntEnable; }

    int sdr() const { return m_sdr; }
    int ssr() const { return m_ssr; }

    QString idleCycles() const { return m_idleCycles; }
    int idlePercentage() const { return m_idlePercentage; }
    QString idlePercentageText() const { return m_idlePercentageText; }

  signals:

    void ciaChanged();
};
