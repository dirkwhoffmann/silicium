// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmActivityController.h"
#include "SiAmController.h"

SiAmActivityController::SiAmActivityController(SiAmController *parent)
    : Controller(parent), parent(parent)
{

}

void
SiAmActivityController::update(i64 cycle, i64 emuFrame, i64 gpuFrame)
{
    auto &core = SiAmController::core();
    auto now   = utl::Time::now();
    bool changed = false;

    counter++;

    if (counter % 16 == 0) {

        auto metrics     = core.getMetrics();
        auto ciaAMetrics = core.ciaA.getMetrics();
        auto ciaBMetrics = core.ciaB.getMetrics();
        auto &audioStats = core.audioPort.getStats();

        m_ciaA      = ciaAMetrics.idlePercentage;
        m_ciaB      = ciaBMetrics.idlePercentage;
        m_hostFps   = metrics.fps;
        m_hostLoad  = metrics.cpuLoad;
        m_audioFill = audioStats.fillLevel;

        changed = true;
    }

    if (counter % 16 == 0) {

        if (cycle >= latchedCpuCycle) {

            auto elapsedTime   = (now - latchedCpuCycleNow).asNanoseconds();
            auto elapsedCycles = double(cycle - latchedCpuCycle);
            auto alpha         = double(0.5);

            m_amigaMhz = alpha * (elapsedCycles / (elapsedTime / 1000.0)) + (1.0 - alpha) * m_amigaMhz;
        }

        latchedCpuCycleNow = now;
        latchedCpuCycle    = cycle;
        changed            = true;
    }

    if (counter % 32 == 0) {

        if (emuFrame >= latchedEmuFrame) {

            auto elapsedTime   = (now - latchedEmuFrameNow).asSeconds();
            auto elapsedFrames = double(emuFrame - latchedEmuFrame);
            auto alpha         = double(0.95);

            m_amigaFps = alpha * (elapsedFrames / elapsedTime) + (1.0 - alpha) * m_amigaFps;
        }

        latchedEmuFrameNow = now;
        latchedEmuFrame    = emuFrame;
        changed            = true;
    }

    if (changed) emit activityChanged();
}

QString
SiAmActivityController::ciaAString() const
{
    return QString("%1% CIA A").arg(static_cast<int>(m_ciaA));
}

QString
SiAmActivityController::ciaBString() const
{
    return QString("%1% CIA B").arg(static_cast<int>(m_ciaB));
}

QString
SiAmActivityController::amigaMhzString() const
{
    return QString("%1 MHz").arg(m_amigaMhz, 0, 'f', 2);
}

QString
SiAmActivityController::amigaFpsString() const
{
    return QString("%1 Hz").arg(static_cast<int>(m_amigaFps));
}

QString
SiAmActivityController::hostLoadString() const
{
    return QString("%1% CPU").arg(static_cast<int>(m_hostLoad * 100.0));
}

QString
SiAmActivityController::hostFpsString() const
{
    return QString("%1 FPS").arg(static_cast<int>(m_hostFps));
}

QString
SiAmActivityController::audioFillString() const
{
    return QString("Fill level %1%").arg(static_cast<int>(m_audioFill * 100.0));
}
