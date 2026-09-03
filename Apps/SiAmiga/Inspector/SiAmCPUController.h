// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiAmInspectorController.h"
#include "SiAmInstructionModel.h"
#include "SiAmTraceModel.h"
#include "SiAmGuardModel.h"
#include "VAmiga.h"

//
// CPU inspector controller -- port of vAmiga's own GUI/Inspector/
// CPUPanel.swift and the Instr/Trace/Guard table views (InstrTableView.swift,
// TraceTableView.swift, GuardTableView.swift's BreakTableView/WatchTableView
// specializations). Mirrors SiC64CPUController's shape (disassembly window,
// recorded-instruction trace log, breakpoint/watchpoint guard lists) but
// against the 68000 rather than the 6510:
//
//   - instructions: a 256-entry disassembly window around the program
//     counter, built through CPUAPI::debugger's disassembleInstr/
//     disassembleWords/disassembleAddr (variable-length 68000 instructions,
//     unlike the 6510's fixed 1-3 byte opcodes -- the window still walks
//     forward by each instruction's actual byte length, same as SiC64's).
//   - trace: the CPU's recorded-instruction log (needs track mode, switched
//     on only while this panel is active -- see the activeChanged hook).
//   - breakpoints / watchpoints: reuses SiAmGuardModel, the same generic
//     guard-list model SiAmCopperController's Copper breakpoints already use
//     (vAmiga's CPUAPI::breakpoints/watchpoints are GuardsAPI instances, the
//     same type as AgnusAPI::copperBreakpoints).
//
// Register/flag/interrupt state (CPUInfo) is read from the shared info
// controller (SiAmInfoController), like every other panel controller, but
// several fields CPUPanel.swift needs (IRD/IRC/ISP/USP/MSP/VBR/SFC/DFC/
// CACR/CAAR, the individual SR/IPL/FC bits) aren't on SiAmInfoController's
// Q_PROPERTY surface yet -- exposed here instead, straight off the same
// cached CPUInfo struct, rather than growing the shared controller for a
// single panel's benefit.
//
// The shared active flag, tick throttle and hex/decimal toggle come from
// SiAmInspectorController.
//

class SiAmController;

class SiAmCPUController : public SiAmInspectorController {

    Q_OBJECT

    SiAmInstructionModel m_instructionModel;
    SiAmTraceModel m_traceModel;
    SiAmGuardModel m_breakpointsModel;
    SiAmGuardModel m_watchpointsModel;

    // Address of the first disassembled row (the window base); the row that
    // holds the program counter, or -1 while it's outside the window.
    quint32 m_instrBase = 0;
    int m_pcRow = -1;

    // The pc0 seen at the previous refresh, so the disassembly window only
    // snaps back to the PC when it actually moves (stepping/running) -- a
    // manual jumpTo then survives while the CPU is paused.
    qint64 m_lastPc0 = -1;

    // Register/flag/interrupt fields not yet on SiAmInfoController -- see
    // the class comment.
    quint16 m_ird = 0, m_irc = 0;
    quint32 m_isp = 0, m_usp = 0, m_msp = 0, m_vbr = 0;
    quint8 m_sfc = 0, m_dfc = 0, m_cacr = 0, m_caar = 0;
    quint16 m_sr = 0;
    quint8 m_ipl = 0, m_fc = 0;

  public:

    explicit SiAmCPUController(SiAmController *parent = nullptr);

    Q_PROPERTY(QObject* instructions READ instructions CONSTANT)
    Q_PROPERTY(int pcRow READ pcRow NOTIFY cpuChanged)
    Q_PROPERTY(QObject* trace READ trace CONSTANT)
    Q_PROPERTY(QObject* breakpoints READ breakpoints CONSTANT)
    Q_PROPERTY(QObject* watchpoints READ watchpoints CONSTANT)

    Q_PROPERTY(int ird READ ird NOTIFY cpuChanged)
    Q_PROPERTY(int irc READ irc NOTIFY cpuChanged)
    Q_PROPERTY(int isp READ isp NOTIFY cpuChanged)
    Q_PROPERTY(int usp READ usp NOTIFY cpuChanged)
    Q_PROPERTY(int msp READ msp NOTIFY cpuChanged)
    Q_PROPERTY(int vbr READ vbr NOTIFY cpuChanged)
    Q_PROPERTY(int sfc READ sfc NOTIFY cpuChanged)
    Q_PROPERTY(int dfc READ dfc NOTIFY cpuChanged)
    Q_PROPERTY(int cacr READ cacr NOTIFY cpuChanged)
    Q_PROPERTY(int caar READ caar NOTIFY cpuChanged)

    // Individual SR bits, matching CPUPanel.swift's bit masks.
    Q_PROPERTY(bool t1 READ t1 NOTIFY cpuChanged)
    Q_PROPERTY(bool t0 READ t0 NOTIFY cpuChanged)
    Q_PROPERTY(bool s  READ s  NOTIFY cpuChanged)
    Q_PROPERTY(bool m  READ m  NOTIFY cpuChanged)
    Q_PROPERTY(bool i2 READ i2 NOTIFY cpuChanged)
    Q_PROPERTY(bool i1 READ i1 NOTIFY cpuChanged)
    Q_PROPERTY(bool i0 READ i0 NOTIFY cpuChanged)
    Q_PROPERTY(bool x  READ x  NOTIFY cpuChanged)
    Q_PROPERTY(bool n  READ n  NOTIFY cpuChanged)
    Q_PROPERTY(bool z  READ z  NOTIFY cpuChanged)
    Q_PROPERTY(bool v  READ v  NOTIFY cpuChanged)
    Q_PROPERTY(bool c  READ c  NOTIFY cpuChanged)

    // IPL input pins and function-code pins, each 3 bits.
    Q_PROPERTY(bool ipl2 READ ipl2 NOTIFY cpuChanged)
    Q_PROPERTY(bool ipl1 READ ipl1 NOTIFY cpuChanged)
    Q_PROPERTY(bool ipl0 READ ipl0 NOTIFY cpuChanged)
    Q_PROPERTY(bool fc2 READ fc2 NOTIFY cpuChanged)
    Q_PROPERTY(bool fc1 READ fc1 NOTIFY cpuChanged)
    Q_PROPERTY(bool fc0 READ fc0 NOTIFY cpuChanged)

    // Re-anchors the disassembly window so 'addr' is its first row (used by
    // the "goto"/search field and by jumping from the breakpoint list or a
    // trace-log row).
    Q_INVOKABLE void jumpTo(int addr);

    // Breakpoint editing driven from the disassembly view. cycleBreakpoint
    // walks none -> set -> disabled -> enabled (single click on the marker
    // column); toggleBreakpoint sets or removes it outright (double click).
    Q_INVOKABLE void cycleBreakpoint(int addr);
    Q_INVOKABLE void toggleBreakpoint(int addr);

    // Breakpoint / watchpoint list editing (the guard tables), row-index
    // based -- matches SiAmCopperController's toggleGuardEnabled/removeGuard
    // convention rather than growing SiAmGuardModel with a "nr" role.
    Q_INVOKABLE void addBreakpoint(int addr);
    Q_INVOKABLE void toggleBreakpointRow(int row);
    Q_INVOKABLE void removeBreakpointRow(int row);
    Q_INVOKABLE void moveBreakpointRow(int row, int addr);
    Q_INVOKABLE void addWatchpoint(int addr);
    Q_INVOKABLE void toggleWatchpointRow(int row);
    Q_INVOKABLE void removeWatchpointRow(int row);
    Q_INVOKABLE void moveWatchpointRow(int row, int addr);

    // Empties the recorded-instruction trace log.
    Q_INVOKABLE void clearTrace();

  protected:

    void refreshData() override;

  private:

    QObject *instructions() const { return const_cast<SiAmInstructionModel *>(&m_instructionModel); }
    int pcRow() const { return m_pcRow; }
    QObject *trace() const { return const_cast<SiAmTraceModel *>(&m_traceModel); }
    QObject *breakpoints() const { return const_cast<SiAmGuardModel *>(&m_breakpointsModel); }
    QObject *watchpoints() const { return const_cast<SiAmGuardModel *>(&m_watchpointsModel); }

    int ird() const { return m_ird; }
    int irc() const { return m_irc; }
    int isp() const { return (int)m_isp; }
    int usp() const { return (int)m_usp; }
    int msp() const { return (int)m_msp; }
    int vbr() const { return (int)m_vbr; }
    int sfc() const { return m_sfc; }
    int dfc() const { return m_dfc; }
    int cacr() const { return (int)m_cacr; }
    int caar() const { return (int)m_caar; }

    bool t1() const { return m_sr & 0b1000000000000000; }
    bool t0() const { return m_sr & 0b0100000000000000; }
    bool s()  const { return m_sr & 0b0010000000000000; }
    bool m()  const { return m_sr & 0b0001000000000000; }
    bool i2() const { return m_sr & 0b0000010000000000; }
    bool i1() const { return m_sr & 0b0000001000000000; }
    bool i0() const { return m_sr & 0b0000000100000000; }
    bool x()  const { return m_sr & 0b0000000000010000; }
    bool n()  const { return m_sr & 0b0000000000001000; }
    bool z()  const { return m_sr & 0b0000000000000100; }
    bool v()  const { return m_sr & 0b0000000000000010; }
    bool c()  const { return m_sr & 0b0000000000000001; }

    bool ipl2() const { return m_ipl & 0b100; }
    bool ipl1() const { return m_ipl & 0b010; }
    bool ipl0() const { return m_ipl & 0b001; }
    bool fc2() const { return m_fc & 0b100; }
    bool fc1() const { return m_fc & 0b010; }
    bool fc0() const { return m_fc & 0b001; }

    // Disassembles 256 instructions starting at 'base', highlighting the row
    // whose address equals 'pc0' (returned in pcRow, or -1 if not present).
    QVector<SiAmInstructionModel::Row> disassembleWindow(quint32 base, quint32 pc0, int &pcRow) const;

    // Rebuilds the individual table models. rebuildInstructions re-anchors
    // the window to the PC only when allowReanchor is set (i.e. the PC
    // moved).
    void rebuildInstructions(quint32 pc0, bool allowReanchor);
    void rebuildTrace();
    void rebuildGuards();

  signals:

    void cpuChanged();
};
