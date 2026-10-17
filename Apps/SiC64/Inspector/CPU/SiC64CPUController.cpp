// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64CPUController.h"
#include "C64Controller.h"
#include "CPU.h"

using namespace vc64;

SiC64CPUController::SiC64CPUController(C64Controller *parent)
    : SiC64InspectorController(parent)
{
    // The CPU's recorded-instruction log (the Trace table) is only filled
    // while track mode is on. Mirror the old Swift-based emulator, which
    // enables it while the CPU inspector is open and disables it on close --
    // here keyed to this panel's active flag.
    connect(this, &SiC64InspectorController::activeChanged, this, [this]() {
        if (isActive()) C64Controller::core().trackOn();
        else C64Controller::core().trackOff();
    });
}

void
SiC64CPUController::refreshData()
{
    // The register / flag / interrupt state now lives on the shared info
    // controller (SiC64InfoController). This controller only owns the
    // inspector-specific list models below, but it still drives the shared
    // refresh: requestUpdate() keeps the info controller's cache fresh (and
    // coalesced across all open inspectors).
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::CPU, 0.25);

    int pc0 = infoController->cpuInfo().pc0;

    rebuildInstructions(pc0, pc0 != m_lastPc0);
    m_lastPc0 = pc0;
    rebuildTrace();
    rebuildGuards();

    emit cpuChanged();
}

QVector<SiC64InstructionModel::Row>
SiC64CPUController::disassembleWindow(int base, int pc0, int &pcRow) const
{
    auto &cpu = C64Controller::core().cpu;

    char addrStr[64], dataStr[64], instrStr[64];

    QVector<SiC64InstructionModel::Row> rows;
    rows.reserve(256);
    pcRow = -1;
    u16 addr = u16(base);

    for (int i = 0; i < 256; i++) {

        cpu.disassemble(addrStr, "%p", addr);
        cpu.disassemble(dataStr, "%b", addr);
        isize len = cpu.disassemble(instrStr, "%i", addr);

        // Breakpoint marker: 0 = none, 1 = enabled, 2 = disabled
        int bp = 0;
        if (auto *guard = cpu.breakpointAt(addr)) bp = guard->enabled ? 1 : 2;

        SiC64InstructionModel::Row row;
        row.addrValue = int(addr);
        row.addr = QString(addrStr);
        row.bytes = QString(dataStr);
        row.instr = QString(instrStr);
        row.breakpoint = bp;
        row.isPC = (int(addr) == pc0);
        rows.append(row);

        if (int(addr) == pc0) pcRow = i;

        addr += len > 0 ? u16(len) : 1;
    }

    return rows;
}

void
SiC64CPUController::rebuildInstructions(int pc0, bool allowReanchor)
{
    int pcRow = -1;
    auto rows = disassembleWindow(m_instrBase, pc0, pcRow);

    // If the program counter moved out of the current window, re-anchor the
    // window to it (matching the old Swift-based emulator's jumpTo behavior).
    // Suppressed while the PC is unchanged, so a manual jumpTo isn't yanked
    // back to the PC on the next refresh.
    if (pcRow < 0 && allowReanchor) {

        m_instrBase = pc0;
        rows = disassembleWindow(m_instrBase, pc0, pcRow);
    }

    m_instructionModel.setRows(rows);
    m_pcRow = pcRow;
}

void
SiC64CPUController::rebuildTrace()
{
    auto &cpu = C64Controller::core().cpu;

    char addrStr[64], flagsStr[64], instrStr[64];

    QVector<SiC64TraceModel::Row> rows;
    isize count = cpu.loggedInstructions();
    rows.reserve(int(count));

    for (isize i = 0; i < count; i++) {

        cpu.disassembleRecorded(addrStr, "%p", i);
        cpu.disassembleRecorded(flagsStr, "%f", i);
        cpu.disassembleRecorded(instrStr, "%i", i);

        SiC64TraceModel::Row row;
        row.addrValue = int(cpu.logEntry(i).pc);
        row.addr = QString(addrStr);
        row.flags = QString(flagsStr);
        row.instr = QString(instrStr);
        rows.append(row);
    }

    m_traceModel.setRows(rows);
}

void
SiC64CPUController::rebuildGuards()
{
    auto &cpu = C64Controller::core().cpu;

    auto collect = [&](auto guardAt) {

        QVariantList rows;
        for (long nr = 0; ; nr++) {

            auto *guard = guardAt(nr);
            if (!guard) break;

            QVariantMap row;
            row["nr"] = int(nr);
            row["addrValue"] = int(guard->addr);
            row["addr"] = formatNumber(guard->addr, 4);
            row["enabled"] = guard->enabled;
            rows.append(row);
        }
        return rows;
    };

    m_breakpoints = collect([&](long nr) { return cpu.breakpointNr(nr); });
    m_watchpoints = collect([&](long nr) { return cpu.watchpointNr(nr); });
}

void
SiC64CPUController::jumpTo(int addr)
{
    m_instrBase = addr & 0xFFFF;

    // Rebuild straight from the requested base without re-anchoring to the PC,
    // so a manual "goto" sticks even when the PC is elsewhere. The PC is read
    // only to keep the highlight correct if it happens to fall in view.
    int pc0 = parent->getInfoController()->cpuInfo().pc0;

    m_instructionModel.setRows(disassembleWindow(m_instrBase, pc0, m_pcRow));
    emit cpuChanged();
}

void
SiC64CPUController::cycleBreakpoint(int addr)
{
    auto &core = C64Controller::core();

    if (auto *guard = core.cpu.breakpointAt(u16(addr))) {
        core.put(guard->enabled ? Cmd::BP_DISABLE_AT : Cmd::BP_ENABLE_AT, addr);
    } else {
        core.put(Cmd::BP_SET_AT, addr);
    }
    refresh();
}

void
SiC64CPUController::toggleBreakpoint(int addr)
{
    auto &core = C64Controller::core();

    core.put(core.cpu.breakpointAt(u16(addr)) ? Cmd::BP_REMOVE_AT : Cmd::BP_SET_AT, addr);
    refresh();
}

void
SiC64CPUController::addBreakpoint(int addr)
{
    C64Controller::core().put(Cmd::BP_SET_AT, addr);
    refresh();
}

void
SiC64CPUController::toggleBreakpointNr(int nr)
{
    auto &core = C64Controller::core();

    if (auto *guard = core.cpu.breakpointNr(nr)) {
        core.put(guard->enabled ? Cmd::BP_DISABLE_NR : Cmd::BP_ENABLE_NR, nr);
        refresh();
    }
}

void
SiC64CPUController::removeBreakpointNr(int nr)
{
    C64Controller::core().put(Cmd::BP_REMOVE_NR, nr);
    refresh();
}

void
SiC64CPUController::moveBreakpointNr(int nr, int addr)
{
    C64Controller::core().put(Cmd::BP_MOVE_TO, nr, addr);
    refresh();
}

void
SiC64CPUController::addWatchpoint(int addr)
{
    C64Controller::core().put(Cmd::WP_SET_AT, addr);
    refresh();
}

void
SiC64CPUController::toggleWatchpointNr(int nr)
{
    auto &core = C64Controller::core();

    if (auto *guard = core.cpu.watchpointNr(nr)) {
        core.put(guard->enabled ? Cmd::WP_DISABLE_NR : Cmd::WP_ENABLE_NR, nr);
        refresh();
    }
}

void
SiC64CPUController::removeWatchpointNr(int nr)
{
    C64Controller::core().put(Cmd::WP_REMOVE_NR, nr);
    refresh();
}

void
SiC64CPUController::moveWatchpointNr(int nr, int addr)
{
    C64Controller::core().put(Cmd::WP_MOVE_TO, nr, addr);
    refresh();
}

void
SiC64CPUController::clearTrace()
{
    C64Controller::core().cpu.clearLog();
    refresh();
}
