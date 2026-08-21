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
#include "SiC64InstructionModel.h"
#include "SiC64TraceModel.h"
#include <QVariantList>

//
// CPU inspector controller -- port of the old Swift-based emulator's CPU
// inspector (Inspector.swift's CPU tab / CPUPanel.swift and the
// Instr/Trace/Break/Watch table views). Exposes the 6510's registers, status
// flags, interrupt lines and processor port, plus four list models:
//
//   - instructions: a 256-entry disassembly window around the program counter
//   - trace:        the CPU's recorded-instruction log (needs track mode)
//   - breakpoints / watchpoints: the guard lists
//
// Numeric fields honour the shared format setting (C64Controller::format);
// the disassembler picks it up from the core's DASM_NUMBERS option, which
// C64Controller::setFormat keeps in sync. Track mode (which fills the trace
// log) is switched on only while this panel is active -- see the activeChanged
// hook wired up in the constructor.
//
// The shared active flag, tick throttle and beam-position readout come from
// SiC64InspectorController.
//

class C64Controller;

class SiC64CPUController : public SiC64InspectorController {

    Q_OBJECT

    // Table models. The disassembly and trace lists are kept as long-lived
    // QAbstractListModel instances (updated in place via setRows()) so
    // scrolling survives the periodic refresh -- see SiC64InstructionModel /
    // SiC64TraceModel and SiC64MemDumpModel for the same pattern used by the
    // memory inspector.
    SiC64InstructionModel m_instructionModel;
    SiC64TraceModel m_traceModel;
    QVariantList m_breakpoints;
    QVariantList m_watchpoints;

    // Address of the first disassembled row (m_instructions[0]); the row that
    // holds the program counter, or -1 while it's outside the window
    int m_instrBase = 0;
    int m_pcRow = -1;

    // The pc0 seen at the previous refresh, so the disassembly window only
    // snaps back to the PC when it actually moves (stepping/running) -- a
    // manual jumpTo then survives while the CPU is paused.
    int m_lastPc0 = -1;

  public:

    explicit SiC64CPUController(C64Controller *parent = nullptr);

    Q_PROPERTY(QObject* instructions READ instructions CONSTANT)
    Q_PROPERTY(int pcRow READ pcRow NOTIFY cpuChanged)
    Q_PROPERTY(QObject* trace READ trace CONSTANT)
    Q_PROPERTY(QVariantList breakpoints READ breakpoints NOTIFY cpuChanged)
    Q_PROPERTY(QVariantList watchpoints READ watchpoints NOTIFY cpuChanged)

    // Re-anchors the disassembly window so 'addr' is its first row (used by
    // the "goto" field and by jumping from the breakpoint list).
    Q_INVOKABLE void jumpTo(int addr);

    // Breakpoint editing driven from the disassembly view. cycleBreakpoint
    // walks none -> set -> disabled -> enabled (single click on the marker
    // column); toggleBreakpoint sets or removes it outright (double click).
    Q_INVOKABLE void cycleBreakpoint(int addr);
    Q_INVOKABLE void toggleBreakpoint(int addr);

    // Breakpoint / watchpoint list editing (the guard tables).
    Q_INVOKABLE void addBreakpoint(int addr);
    Q_INVOKABLE void toggleBreakpointNr(int nr);
    Q_INVOKABLE void removeBreakpointNr(int nr);
    Q_INVOKABLE void moveBreakpointNr(int nr, int addr);
    Q_INVOKABLE void addWatchpoint(int addr);
    Q_INVOKABLE void toggleWatchpointNr(int nr);
    Q_INVOKABLE void removeWatchpointNr(int nr);
    Q_INVOKABLE void moveWatchpointNr(int nr, int addr);

    // Empties the recorded-instruction trace log.
    Q_INVOKABLE void clearTrace();

  protected:

    void refreshData() override;

  private:

    QObject *instructions() const { return const_cast<SiC64InstructionModel *>(&m_instructionModel); }
    int pcRow() const { return m_pcRow; }
    QObject *trace() const { return const_cast<SiC64TraceModel *>(&m_traceModel); }
    QVariantList breakpoints() const { return m_breakpoints; }
    QVariantList watchpoints() const { return m_watchpoints; }

    // Disassembles 256 instructions starting at 'base', highlighting the row
    // whose address equals 'pc0' (returned in pcRow, or -1 if not present).
    QVector<SiC64InstructionModel::Row> disassembleWindow(int base, int pc0, int &pcRow) const;

    // Rebuilds the individual table models. rebuildInstructions re-anchors the
    // window to the PC only when allowReanchor is set (i.e. the PC moved).
    void rebuildInstructions(int pc0, bool allowReanchor);
    void rebuildTrace();
    void rebuildGuards();

  signals:

    void cpuChanged();
};
