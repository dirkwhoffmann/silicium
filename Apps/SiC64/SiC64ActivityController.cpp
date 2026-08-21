// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64ActivityController.h"
#include "C64Controller.h"

SiC64ActivityController::SiC64ActivityController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}

void
SiC64ActivityController::update(i64 cycle, i64 emuFrame, i64 gpuFrame)
{
    auto &core = C64Controller::core();
    auto now   = utl::Time::now();
    bool changed = false;

    counter++;

    if (counter % 16 == 0) {

        auto &stats      = core.getStats();
        auto &cia1Stats  = core.cia1.getStats();
        auto &cia2Stats  = core.cia2.getStats();
        auto &audioStats = core.audioPort.getStats();

        m_cia1      = cia1Stats.idlePercentage;
        m_cia2      = cia2Stats.idlePercentage;
        m_hostFps   = stats.fps;
        m_hostLoad  = stats.cpuLoad;
        m_audioFill = audioStats.fillLevel;

        changed = true;
    }

    if (counter % 16 == 0) {

        if (cycle >= latchedC64Cycle) {

            auto elapsedTime   = (now - latchedC64CycleNow).asNanoseconds();
            auto elapsedCycles = double(cycle - latchedC64Cycle);
            auto alpha         = double(0.5);

            m_c64Mhz = alpha * (elapsedCycles / (elapsedTime / 1000.0)) + (1.0 - alpha) * m_c64Mhz;
        }

        latchedC64CycleNow = now;
        latchedC64Cycle    = cycle;
        changed            = true;
    }

    if (counter % 32 == 0) {

        if (emuFrame >= latchedEmuFrame) {

            auto elapsedTime   = (now - latchedEmuFrameNow).asSeconds();
            auto elapsedFrames = double(emuFrame - latchedEmuFrame);
            auto alpha         = double(0.95);

            m_c64Fps = alpha * (elapsedFrames / elapsedTime) + (1.0 - alpha) * m_c64Fps;
        }

        latchedEmuFrameNow = now;
        latchedEmuFrame    = emuFrame;
        changed            = true;
    }

    /*
    if (counter % 32 == 0) {

        if (gpuFrame >= latchedGpuFrame) {

            auto elapsedTime   = (now - latchedGpuFrameNow).asSeconds();
            auto elapsedFrames = double(gpuFrame - latchedGpuFrame);
            auto alpha         = 0.9;

            m_hostFps = alpha * (elapsedFrames / elapsedTime) + (1.0 - alpha) * m_hostFps;
        }

        latchedGpuFrameNow = now;
        latchedGpuFrame    = gpuFrame;
        changed            = true;
    }
    */

    if (changed) emit activityChanged();
}

QString
SiC64ActivityController::cia1String() const
{
    return QString("%1% CIA1").arg(static_cast<int>(m_cia1));
}

QString
SiC64ActivityController::cia2String() const
{
    return QString("%1% CIA2").arg(static_cast<int>(m_cia2));
}

QString
SiC64ActivityController::c64MhzString() const
{
    return QString("%1 MHz").arg(m_c64Mhz, 0, 'f', 2);
}

QString
SiC64ActivityController::c64FpsString() const
{
    return QString("%1 Hz").arg(static_cast<int>(m_c64Fps));
}

QString
SiC64ActivityController::hostLoadString() const
{
    return QString("%1% CPU").arg(static_cast<int>(m_hostLoad * 100.0));
}

QString
SiC64ActivityController::hostFpsString() const
{
    return QString("%1 FPS").arg(static_cast<int>(m_hostFps));
}

QString
SiC64ActivityController::audioFillString() const
{
    return QString("Fill level %1%").arg(static_cast<int>(m_audioFill * 100.0));
}
