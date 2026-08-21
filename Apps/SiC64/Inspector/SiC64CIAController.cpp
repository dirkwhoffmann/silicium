// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64CIAController.h"
#include "C64Controller.h"
#include "CIA.h"

using namespace vc64;

SiC64CIAController::SiC64CIAController(C64Controller *parent)
    : SiC64InspectorController(parent)
{

}

void
SiC64CIAController::setSelectedCia(int value)
{
    if (m_selectedCia != value) {

        m_selectedCia = value;
        refresh();
    }
}

void
SiC64CIAController::refreshData()
{
    // Read the CIA info/stats from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::CIA, 0.25);

    bool cia1 = m_selectedCia == 0;

    auto &info = infoController->ciaInfo(m_selectedCia);
    auto &stats = infoController->ciaStats(m_selectedCia);

    m_title = cia1 ? QString("CIA 1") : QString("CIA 2");

    m_portAPort = info.portA.port;
    m_portBPort = info.portB.port;
    m_portAReg  = info.portA.reg;
    m_portADir  = info.portA.dir;
    m_portBReg  = info.portB.reg;
    m_portBDir  = info.portB.dir;

    m_portALabels = cia1
        ? QStringList { "C0,JB0", "C1,JB1", "C2,JB2", "C3,JB4", "C4,BTNB", "C5", "C6", "C7" }
        : QStringList { "VA14", "VA15", "User M", "ATN", "CLK", "DATA", "CLK", "DATA" };

    m_portBLabels = cia1
        ? QStringList { "R0, JOYA0", "R1, JOYA1", "R2, JOYA2", "R3, JOYA3", "R4, BTNA", "R5", "R6", "R7" }
        : QStringList { "User C", "User D", "User E", "User F", "User H", "User J", "User K", "User L" };

    m_timerACount  = info.timerA.count;
    m_timerALatch  = info.timerA.latch;
    m_timerARunning = info.timerA.running;
    m_timerAToggle  = info.timerA.toggle;
    m_timerAPbout   = info.timerA.pbout;
    m_timerAOneShot = info.timerA.oneShot;

    m_timerBCount  = info.timerB.count;
    m_timerBLatch  = info.timerB.latch;
    m_timerBRunning = info.timerB.running;
    m_timerBToggle  = info.timerB.toggle;
    m_timerBPbout   = info.timerB.pbout;
    m_timerBOneShot = info.timerB.oneShot;

    m_icr = info.icr;
    m_imr = info.imr;
    m_intLineLow = !info.intLine;
    m_intLineLabel = QString(cia1 ? "IRQ" : "NMI") + QString(" line grounded");

    m_todHour  = info.tod.time.hour;
    m_todMin   = info.tod.time.min;
    m_todSec   = info.tod.time.sec;
    m_todTenth = info.tod.time.tenth;

    m_todAlarmHour  = info.tod.alarm.hour;
    m_todAlarmMin   = info.tod.alarm.min;
    m_todAlarmSec   = info.tod.alarm.sec;
    m_todAlarmTenth = info.tod.alarm.tenth;

    m_todIntEnable = info.todIntEnable;

    m_sdr = info.sdr;
    m_ssr = info.ssr;

    m_idleCycles = QString("%1 cycles").arg(stats.idleSince);
    m_idlePercentage = int(stats.idlePercentage * 100);
    m_idlePercentageText = QString("%1 %").arg(m_idlePercentage);

    emit ciaChanged();
}
