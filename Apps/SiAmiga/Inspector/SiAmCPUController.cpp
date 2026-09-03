// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmCPUController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmCPUController::SiAmCPUController(SiAmController *parent)
    : SiAmInspectorController(parent), m_instructionModel(this), m_traceModel(this),
      m_breakpointsModel(this), m_watchpointsModel(this)
{
    // The CPU's recorded-instruction log (the Trace table) is only filled
    // while track mode is on. Mirror the Swift reference, which enables it
    // while the CPU inspector is open and disables it on close -- here keyed
    // to this panel's active flag.
    connect(this, &SiAmInspectorController::activeChanged, this, [this]() {
        if (isActive()) SiAmController::core().trackOn();
        else SiAmController::core().trackOff();
    });
}

QVector<SiAmInstructionModel::Row>
SiAmCPUController::disassembleWindow(quint32 base, quint32 pc0, int &pcRow) const
{
    auto &debugger = SiAmController::core().cpu.debugger;
    auto &breakpoints = SiAmController::core().cpu.breakpoints;

    QVector<SiAmInstructionModel::Row> rows;
    rows.reserve(256);
    pcRow = -1;
    u32 addr = base;

    for (int i = 0; i < 256; i++) {

        isize len = 0;
        const char *instr = debugger.disassembleInstr(addr, &len);
        const char *words = debugger.disassembleWords(addr, len / 2);
        const char *addrStr = debugger.disassembleAddr(addr);

        int bp = 0;
        if (auto guard = breakpoints.guardAt(addr)) bp = guard->enabled ? 1 : 2;

        SiAmInstructionModel::Row row;
        row.addrValue = addr;
        row.addr = QString(addrStr);
        row.bytes = QString(words);
        row.instr = QString(instr);
        row.breakpoint = bp;
        row.isPC = (addr == pc0);
        rows.append(row);

        if (addr == pc0) pcRow = i;

        addr += len > 0 ? u32(len) : 2;
    }

    return rows;
}

void
SiAmCPUController::rebuildInstructions(quint32 pc0, bool allowReanchor)
{
    int pcRow = -1;
    auto rows = disassembleWindow(m_instrBase, pc0, pcRow);

    // If the program counter moved out of the current window, re-anchor the
    // window to it. Suppressed while the PC is unchanged, so a manual
    // jumpTo isn't yanked back to the PC on the next refresh.
    if (pcRow < 0 && allowReanchor) {

        m_instrBase = pc0;
        rows = disassembleWindow(m_instrBase, pc0, pcRow);
    }

    m_instructionModel.setRows(rows);
    m_pcRow = pcRow;
}

void
SiAmCPUController::rebuildTrace()
{
    auto &debugger = SiAmController::core().cpu.debugger;

    QVector<SiAmTraceModel::Row> rows;
    isize count = debugger.loggedInstructions();
    rows.reserve(int(count));

    for (isize i = 0; i < count; i++) {

        isize len = 0;
        const char *addrStr = debugger.disassembleRecordedPC(i);
        const char *instr = debugger.disassembleRecordedInstr(i, &len);
        const char *flags = debugger.disassembleRecordedFlags(i);

        SiAmTraceModel::Row row;
        row.addrValue = 0;
        row.addr = QString(addrStr);
        row.flags = QString(flags);
        row.instr = QString(instr);
        rows.append(row);
    }

    m_traceModel.setRows(rows);
}

void
SiAmCPUController::rebuildGuards()
{
    auto &breakpoints = SiAmController::core().cpu.breakpoints;
    auto &watchpoints = SiAmController::core().cpu.watchpoints;

    auto collect = [](auto &guards) {

        QVector<SiAmGuardModel::Row> rows;
        isize n = guards.elements();
        rows.reserve(int(n));

        for (isize i = 0; i < n; i++) {

            auto guard = guards.guardNr(i);
            if (!guard.has_value()) continue;

            SiAmGuardModel::Row row;
            row.rawAddr = guard->addr;
            row.addr = QString("%1").arg((unsigned)guard->addr, 6, 16, QChar('0')).toUpper();
            row.enabled = guard->enabled;
            rows.append(row);
        }
        return rows;
    };

    m_breakpointsModel.setRows(collect(breakpoints));
    m_watchpointsModel.setRows(collect(watchpoints));
}

void
SiAmCPUController::refreshData()
{
    // Register / flag / interrupt state comes off the shared info
    // controller's cached CPUInfo; requestUpdate() coalesces the sampling
    // across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::CPU, 0.25);
    auto &info = infoController->cpuInfo();

    m_ird = info.ird;
    m_irc = info.irc;
    m_isp = info.isp;
    m_usp = info.usp;
    m_msp = info.msp;
    m_vbr = info.vbr;
    m_sfc = info.sfc;
    m_dfc = info.dfc;
    m_cacr = info.cacr;
    m_caar = info.caar;
    m_sr = info.sr;
    m_ipl = info.ipl;
    m_fc = info.fc;

    quint32 pc0 = info.pc0;

    rebuildInstructions(pc0, (qint64)pc0 != m_lastPc0);
    m_lastPc0 = pc0;
    rebuildTrace();
    rebuildGuards();

    emit cpuChanged();
}

void
SiAmCPUController::jumpTo(int addr)
{
    m_instrBase = (quint32)addr;

    // Rebuild straight from the requested base without re-anchoring to the
    // PC, so a manual "goto" sticks even when the PC is elsewhere. The PC is
    // read only to keep the highlight correct if it happens to fall in view.
    quint32 pc0 = parent->getInfoController()->cpuInfo().pc0;

    m_instructionModel.setRows(disassembleWindow(m_instrBase, pc0, m_pcRow));
    emit cpuChanged();
}

void
SiAmCPUController::cycleBreakpoint(int addr)
{
    auto &breakpoints = SiAmController::core().cpu.breakpoints;

    if (auto guard = breakpoints.guardAt((u32)addr)) {
        if (guard->enabled) breakpoints.disableAt((u32)addr); else breakpoints.enableAt((u32)addr);
    } else {
        breakpoints.setAt((u32)addr);
    }
    refresh();
}

void
SiAmCPUController::toggleBreakpoint(int addr)
{
    auto &breakpoints = SiAmController::core().cpu.breakpoints;

    if (breakpoints.guardAt((u32)addr)) breakpoints.removeAt((u32)addr);
    else breakpoints.setAt((u32)addr);

    refresh();
}

void
SiAmCPUController::addBreakpoint(int addr)
{
    SiAmController::core().cpu.breakpoints.setAt((u32)addr);
    refresh();
}

void
SiAmCPUController::toggleBreakpointRow(int row)
{
    auto &breakpoints = SiAmController::core().cpu.breakpoints;
    quint32 addr = m_breakpointsModel.addrAt(row);

    if (auto guard = breakpoints.guardAt(addr)) {
        if (guard->enabled) breakpoints.disableAt(addr); else breakpoints.enableAt(addr);
        refresh();
    }
}

void
SiAmCPUController::removeBreakpointRow(int row)
{
    SiAmController::core().cpu.breakpoints.removeAt(m_breakpointsModel.addrAt(row));
    refresh();
}

void
SiAmCPUController::moveBreakpointRow(int row, int addr)
{
    SiAmController::core().cpu.breakpoints.moveTo(row, (u32)addr);
    refresh();
}

void
SiAmCPUController::addWatchpoint(int addr)
{
    SiAmController::core().cpu.watchpoints.setAt((u32)addr);
    refresh();
}

void
SiAmCPUController::toggleWatchpointRow(int row)
{
    auto &watchpoints = SiAmController::core().cpu.watchpoints;
    quint32 addr = m_watchpointsModel.addrAt(row);

    if (auto guard = watchpoints.guardAt(addr)) {
        if (guard->enabled) watchpoints.disableAt(addr); else watchpoints.enableAt(addr);
        refresh();
    }
}

void
SiAmCPUController::removeWatchpointRow(int row)
{
    SiAmController::core().cpu.watchpoints.removeAt(m_watchpointsModel.addrAt(row));
    refresh();
}

void
SiAmCPUController::moveWatchpointRow(int row, int addr)
{
    SiAmController::core().cpu.watchpoints.moveTo(row, (u32)addr);
    refresh();
}

void
SiAmCPUController::clearTrace()
{
    SiAmController::core().cpu.debugger.clearLog();
    refresh();
}
