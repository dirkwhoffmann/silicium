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
#include "SiAmCopperListModel.h"
#include "SiAmGuardModel.h"
#include "VAmiga.h"

//
// Copper inspector controller -- port of vAmiga's own GUI/Inspector/
// CopperPanel.swift, CopperTableView.swift and GuardTableView.swift's
// CopperBreakTableView (there is no C64 counterpart to port from; the
// Copper is Amiga-only). Exposes:
//
//   - list1/list2: disassembled Copper list 1/2, each with its own
//     Binary/Symbolic toggle and an extra-row count the user can grow or
//     shrink (the native list length is derived from the core's own
//     copList1Start/End; extraRows shows additional rows past that, for
//     lists that wrap or run short) -- see SiAmCopperListModel.
//   - registers: coppc0/cop1lc/cop2lc/cop1ins/cop2ins/cdang, straight off
//     CopperInfo.
//   - breakpoints: every currently-set Copper breakpoint, address only
//     (see SiAmGuardModel) -- vAmiga tracks these on their own GuardsAPI
//     instance (core().copperBreakpoints), independent of CPU
//     breakpoints/watchpoints.
//
// The Swift reference's per-row breakpoint editing (click a list row's
// break column to set/enable/disable, double-click to remove; edit an
// address directly into the Breakpoints table's own trailing "Add
// address" row) is simplified here to two affordances that fit this
// codebase's read-oriented ListView style (see the memory panel): tapping
// a list row's break indicator cycles none -> enabled -> disabled -> none
// (toggleBreakpoint()), and the Breakpoints box itself offers enable/
// disable and delete per row (toggleGuardEnabled()/removeGuard()) --
// there's no inline "type an address to add one" row.
//
// The shared active flag, tick throttle and beam-position readout come
// from SiAmInspectorController.
//

class SiAmController;

class SiAmCopperController : public SiAmInspectorController {

    Q_OBJECT

    // Registers
    quint32 m_cop1lc = 0, m_cop2lc = 0, m_coppc0 = 0;
    int m_cop1ins = 0, m_cop2ins = 0;
    bool m_cdang = false;

    // Per-list display state
    bool m_symbolic1 = true, m_symbolic2 = true;
    int m_extraRows1 = 0, m_extraRows2 = 0;

    SiAmCopperListModel m_list1Model;
    SiAmCopperListModel m_list2Model;
    SiAmGuardModel m_breakpointsModel;

  public:

    explicit SiAmCopperController(SiAmController *parent = nullptr);

    Q_PROPERTY(int cop1lc READ cop1lc NOTIFY copperChanged)
    Q_PROPERTY(int cop2lc READ cop2lc NOTIFY copperChanged)
    Q_PROPERTY(int coppc0 READ coppc0 NOTIFY copperChanged)
    Q_PROPERTY(int cop1ins READ cop1ins NOTIFY copperChanged)
    Q_PROPERTY(int cop2ins READ cop2ins NOTIFY copperChanged)
    Q_PROPERTY(bool cdang READ cdang NOTIFY copperChanged)

    Q_PROPERTY(bool symbolic1 READ symbolic1 WRITE setSymbolic1 NOTIFY copperChanged)
    Q_PROPERTY(bool symbolic2 READ symbolic2 WRITE setSymbolic2 NOTIFY copperChanged)
    Q_PROPERTY(int extraRows1 READ extraRows1 NOTIFY copperChanged)
    Q_PROPERTY(int extraRows2 READ extraRows2 NOTIFY copperChanged)

    Q_PROPERTY(QObject* list1 READ list1 CONSTANT)
    Q_PROPERTY(QObject* list2 READ list2 CONSTANT)
    Q_PROPERTY(QObject* breakpoints READ breakpoints CONSTANT)

    bool symbolic1() const { return m_symbolic1; }
    void setSymbolic1(bool value);
    bool symbolic2() const { return m_symbolic2; }
    void setSymbolic2(bool value);

    // Grows/shrinks the given list's extra-row count by one.
    Q_INVOKABLE void expandList1() { setExtraRows1(m_extraRows1 + 1); }
    Q_INVOKABLE void shrinkList1() { setExtraRows1(m_extraRows1 - 1); }
    Q_INVOKABLE void expandList2() { setExtraRows2(m_extraRows2 + 1); }
    Q_INVOKABLE void shrinkList2() { setExtraRows2(m_extraRows2 - 1); }

    // Cycles the breakpoint at the given row of list 1/2 through
    // none -> enabled -> disabled -> none.
    Q_INVOKABLE void toggleBreakpoint1(int row);
    Q_INVOKABLE void toggleBreakpoint2(int row);

    // Enables/disables or removes the breakpoint at the given row of the
    // Breakpoints box.
    Q_INVOKABLE void toggleGuardEnabled(int row);
    Q_INVOKABLE void removeGuard(int row);

    // Emitted by jumpToPC() with the list (1 or 2) and row index Copper's
    // PC currently sits on, so the panel can scroll that list into view.
    // No counterpart is needed for auto-highlighting -- every row already
    // carries its own 'current' flag (see SiAmCopperListModel::Row) --
    // this only drives the one-shot scroll a magnifying-glass click asks
    // for, mirroring copFindAction in the Swift reference.
    Q_INVOKABLE void jumpToPC();

  protected:

    void refreshData() override;

  private:

    int cop1lc() const { return int(m_cop1lc); }
    int cop2lc() const { return int(m_cop2lc); }
    int coppc0() const { return int(m_coppc0); }
    int cop1ins() const { return m_cop1ins; }
    int cop2ins() const { return m_cop2ins; }
    bool cdang() const { return m_cdang; }

    int extraRows1() const { return m_extraRows1; }
    void setExtraRows1(int value);
    int extraRows2() const { return m_extraRows2; }
    void setExtraRows2(int value);

    QObject *list1() const { return const_cast<SiAmCopperListModel *>(&m_list1Model); }
    QObject *list2() const { return const_cast<SiAmCopperListModel *>(&m_list2Model); }
    QObject *breakpoints() const { return const_cast<SiAmGuardModel *>(&m_breakpointsModel); }

    // Rebuilds one list's disassembly rows.
    void rebuildList(quint32 start, quint32 end, bool symbolic, int extraRows, SiAmCopperListModel &model);
    void rebuildBreakpoints();

  signals:

    void copperChanged();
    void jumpRequested(int list, int row);
};
