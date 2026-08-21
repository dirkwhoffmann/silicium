// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiC64InspectorController.h"
#include <QStringList>

//
// CIA inspector controller -- port of the old Swift-based emulator's CIA
// inspector (Inspector.swift's CIA tab / CIAPanel.swift). Samples CIA1 or
// CIA2 (see selectedCia) and exposes its ports, timers, ICR/IMR, TOD clock
// and idle statistics for SiC64CIAPanel.
//
// The shared active flag, tick throttle and beam-position readout live in the
// SiC64InspectorController base class; this class only adds the CIA-panel
// specifics and overrides refreshData() to sample them.
//

class C64Controller;

class SiC64CIAController : public SiC64InspectorController {

    Q_OBJECT

    int m_selectedCia = 0; // 0 = CIA1, 1 = CIA2

    QString m_title;

    // Port A / B. The register/direction values are raw so the panel's
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

    // TOD clock / alarm, as raw hour/min/sec/tenth components so the panel
    // can render each as its own byte view.
    int m_todHour = 0, m_todMin = 0, m_todSec = 0, m_todTenth = 0;
    int m_todAlarmHour = 0, m_todAlarmMin = 0, m_todAlarmSec = 0, m_todAlarmTenth = 0;
    bool m_todIntEnable = false;

    // Serial data / shift registers
    int m_sdr = 0, m_ssr = 0;

    // Idle statistics
    QString m_idleCycles;
    int m_idlePercentage = 0;
    QString m_idlePercentageText;

  public:

    explicit SiC64CIAController(C64Controller *parent = nullptr);

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

    Q_PROPERTY(int todHour READ todHour NOTIFY ciaChanged)
    Q_PROPERTY(int todMin READ todMin NOTIFY ciaChanged)
    Q_PROPERTY(int todSec READ todSec NOTIFY ciaChanged)
    Q_PROPERTY(int todTenth READ todTenth NOTIFY ciaChanged)
    Q_PROPERTY(int todAlarmHour READ todAlarmHour NOTIFY ciaChanged)
    Q_PROPERTY(int todAlarmMin READ todAlarmMin NOTIFY ciaChanged)
    Q_PROPERTY(int todAlarmSec READ todAlarmSec NOTIFY ciaChanged)
    Q_PROPERTY(int todAlarmTenth READ todAlarmTenth NOTIFY ciaChanged)
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

    int todHour() const { return m_todHour; }
    int todMin() const { return m_todMin; }
    int todSec() const { return m_todSec; }
    int todTenth() const { return m_todTenth; }
    int todAlarmHour() const { return m_todAlarmHour; }
    int todAlarmMin() const { return m_todAlarmMin; }
    int todAlarmSec() const { return m_todAlarmSec; }
    int todAlarmTenth() const { return m_todAlarmTenth; }
    bool todIntEnable() const { return m_todIntEnable; }

    int sdr() const { return m_sdr; }
    int ssr() const { return m_ssr; }

    QString idleCycles() const { return m_idleCycles; }
    int idlePercentage() const { return m_idlePercentage; }
    QString idlePercentageText() const { return m_idlePercentageText; }

  signals:

    void ciaChanged();
};
