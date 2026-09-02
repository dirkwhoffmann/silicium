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
// Port of Silicium's SiC64ActivityController. update(cycle, emuFrame, gpuFrame)
// -- called once per rendered frame by SiAmRenderer::tick() -- samples
// SiAmController::core() and smooths the results into the properties below.
//

class SiAmController;

class SiAmActivityController : public Controller {

    Q_OBJECT

    SiAmController *parent = nullptr;

    // Activity
    double m_ciaA      = 0.0; // CIA A activity
    double m_ciaB      = 0.0; // CIA B activity
    double m_amigaMhz  = 0.0; // Emulator frequency
    double m_amigaFps  = 0.0; // Emulator refresh rate
    double m_hostLoad  = 0.0; // Host CPU load
    double m_hostFps   = 0.0; // Host refresh rate
    double m_audioFill = 0.0; // Audio fill level

    // Latched values
    i64 latchedCpuCycle = 0xffffff;
    i64 latchedEmuFrame = 0xffffff;
    i64 latchedGpuFrame = 0xffffff;
    utl::Time latchedCpuCycleNow = 0;
    utl::Time latchedEmuFrameNow = 0;
    utl::Time latchedGpuFrameNow = 0;

    // Update counter
    i64 counter = 0;

  public:

    explicit SiAmActivityController(SiAmController *parent = nullptr);

    // Samples SiAmController::core() and smooths cia/fps/load/audio-fill
    // metrics. Called once per rendered frame from SiAmRenderer::tick().
    void update(i64 cycle, i64 emuFrame, i64 gpuFrame);

    Q_PROPERTY(double ciaA READ ciaA NOTIFY activityChanged)
    Q_PROPERTY(double ciaB READ ciaB NOTIFY activityChanged)
    Q_PROPERTY(double amigaMhz READ amigaMhz NOTIFY activityChanged)
    Q_PROPERTY(double amigaFps READ amigaFps NOTIFY activityChanged)
    Q_PROPERTY(double hostLoad READ hostLoad NOTIFY activityChanged)
    Q_PROPERTY(double hostFps READ hostFps NOTIFY activityChanged)
    Q_PROPERTY(double audioFill READ audioFill NOTIFY activityChanged)

    Q_PROPERTY(QString ciaAString READ ciaAString NOTIFY activityChanged)
    Q_PROPERTY(QString ciaBString READ ciaBString NOTIFY activityChanged)
    Q_PROPERTY(QString amigaMhzString READ amigaMhzString NOTIFY activityChanged)
    Q_PROPERTY(QString amigaFpsString READ amigaFpsString NOTIFY activityChanged)
    Q_PROPERTY(QString hostLoadString READ hostLoadString NOTIFY activityChanged)
    Q_PROPERTY(QString hostFpsString READ hostFpsString NOTIFY activityChanged)
    Q_PROPERTY(QString audioFillString READ audioFillString NOTIFY activityChanged)

  private:

    double ciaA() const { return m_ciaA; }
    double ciaB() const { return m_ciaB; }
    double amigaMhz() const { return m_amigaMhz; }
    double amigaFps() const { return m_amigaFps; }
    double hostLoad() const { return m_hostLoad; }
    double hostFps() const { return m_hostFps; }
    double audioFill() const { return m_audioFill; }

    QString ciaAString() const;
    QString ciaBString() const;
    QString amigaMhzString() const;
    QString amigaFpsString() const;
    QString hostLoadString() const;
    QString hostFpsString() const;
    QString audioFillString() const;

  signals:

    void activityChanged();
};
