// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "utl/common.h"
#include "utl/chrono/Time.h"

//
// Port of Silicium's C64ActivityController. update(cycle, emuFrame, gpuFrame)
// -- called once per rendered frame by SiC64Renderer::tick() -- samples
// C64Controller::core() and smooths the results into the properties below.
//

class C64Controller;

class SiC64ActivityController : public Controller {

    Q_OBJECT

    C64Controller *parent = nullptr;

    // Activity
    double m_cia1      = 0.0; // CIA1 activity
    double m_cia2      = 0.0; // CIA2 activity
    double m_c64Mhz    = 0.0; // Emulator frequency
    double m_c64Fps    = 0.0; // Emulator refresh rate
    double m_hostLoad  = 0.0; // Host CPU load
    double m_hostFps   = 0.0; // Host refresh rate
    double m_audioFill = 0.0; // Audio fill level

    // Latched values
    i64 latchedC64Cycle = 0xffffff;
    i64 latchedEmuFrame = 0xffffff;
    i64 latchedGpuFrame = 0xffffff;
    utl::Time latchedC64CycleNow = 0;
    utl::Time latchedEmuFrameNow = 0;
    utl::Time latchedGpuFrameNow = 0;

    // Update counter
    i64 counter = 0;

  public:

    explicit SiC64ActivityController(C64Controller *parent = nullptr);

    // Samples C64Controller::core() and smooths cia/fps/load/audio-fill
    // metrics. Called once per rendered frame from SiC64Renderer::tick().
    void update(i64 cycle, i64 emuFrame, i64 gpuFrame);

    Q_PROPERTY(double cia1 READ cia1 NOTIFY activityChanged)
    Q_PROPERTY(double cia2 READ cia2 NOTIFY activityChanged)
    Q_PROPERTY(double c64Mhz READ c64Mhz NOTIFY activityChanged)
    Q_PROPERTY(double c64Fps READ c64Fps NOTIFY activityChanged)
    Q_PROPERTY(double hostLoad READ hostLoad NOTIFY activityChanged)
    Q_PROPERTY(double hostFps READ hostFps NOTIFY activityChanged)
    Q_PROPERTY(double audioFill READ audioFill NOTIFY activityChanged)

    Q_PROPERTY(QString cia1String READ cia1String NOTIFY activityChanged)
    Q_PROPERTY(QString cia2String READ cia2String NOTIFY activityChanged)
    Q_PROPERTY(QString c64MhzString READ c64MhzString NOTIFY activityChanged)
    Q_PROPERTY(QString c64FpsString READ c64FpsString NOTIFY activityChanged)
    Q_PROPERTY(QString hostLoadString READ hostLoadString NOTIFY activityChanged)
    Q_PROPERTY(QString hostFpsString READ hostFpsString NOTIFY activityChanged)
    Q_PROPERTY(QString audioFillString READ audioFillString NOTIFY activityChanged)

  private:

    double cia1() const { return m_cia1; }
    double cia2() const { return m_cia2; }
    double c64Mhz() const { return m_c64Mhz; }
    double c64Fps() const { return m_c64Fps; }
    double hostLoad() const { return m_hostLoad; }
    double hostFps() const { return m_hostFps; }
    double audioFill() const { return m_audioFill; }

    QString cia1String() const;
    QString cia2String() const;
    QString c64MhzString() const;
    QString c64FpsString() const;
    QString hostLoadString() const;
    QString hostFpsString() const;
    QString audioFillString() const;

  signals:

    void activityChanged();
};
