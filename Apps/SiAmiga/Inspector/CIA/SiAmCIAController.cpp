// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmCIAController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmCIAController::SiAmCIAController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

void
SiAmCIAController::setSelectedCia(int value)
{
    if (m_selectedCia != value) {

        m_selectedCia = value;
        refresh();
    }
}

void
SiAmCIAController::refreshData()
{
    // Read the CIA info/metrics from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::CIA, 0.25);

    bool ciaA = m_selectedCia == 0;

    auto &info = infoController->ciaInfo(m_selectedCia);
    auto &metrics = infoController->ciaMetrics(m_selectedCia);

    m_title = ciaA ? QString("CIA A") : QString("CIA B");

    m_portAPort = info.portA.port;
    m_portBPort = info.portB.port;
    m_portAReg  = info.portA.reg;
    m_portADir  = info.portA.dir;
    m_portBReg  = info.portB.reg;
    m_portBDir  = info.portB.dir;

    // Pin-outs transcribed from Core/Components/CIA/CIA.cpp's own comments
    // (CIAA::updatePA/updatePB and CIAB's equivalents) -- see the class
    // comment for what each port actually drives.
    m_portALabels = ciaA
        ? QStringList { "OVL", "/LED", "/CHNG", "/WPRO", "/TK0", "/RDY", "/FIR0", "/FIR1" }
        : QStringList { "BUSY", "POUT", "SEL/RI", "/DSR", "/CTS", "/CD", "/RTS", "/DTR" };

    m_portBLabels = ciaA
        ? QStringList { "Centronics 0", "Centronics 1", "Centronics 2", "Centronics 3",
                         "Centronics 4", "Centronics 5", "Centronics 6", "Centronics 7" }
        : QStringList { "/STEP", "DIR", "/SIDE", "/SEL0", "/SEL1", "/SEL2", "/SEL3", "/MTR" };

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
    m_intLineLow = info.irq;
    m_intLineLabel = QString("Interrupt line grounded");

    m_todValue = (qint64)info.tod.value;
    m_todLatch = (qint64)info.tod.latch;
    m_todAlarm = (qint64)info.tod.alarm;
    m_todIntEnable = info.todIrqEnable;

    m_sdr = info.sdr;
    m_ssr = info.ssr;

    m_idleCycles = QString("%1 cycles").arg(metrics.idleCycles);
    m_idlePercentage = int(metrics.idlePercentage * 100);
    m_idlePercentageText = QString("%1 %").arg(m_idlePercentage);

    emit ciaChanged();
}
