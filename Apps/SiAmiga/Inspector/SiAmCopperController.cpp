// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmCopperController.h"
#include "SiAmController.h"
#include <algorithm>

using namespace vamiga;

SiAmCopperController::SiAmCopperController(SiAmController *parent)
    : SiAmInspectorController(parent), m_list1Model(this), m_list2Model(this), m_breakpointsModel(this)
{

}

void
SiAmCopperController::setSymbolic1(bool value)
{
    if (m_symbolic1 != value) {

        m_symbolic1 = value;
        refresh();
    }
}

void
SiAmCopperController::setSymbolic2(bool value)
{
    if (m_symbolic2 != value) {

        m_symbolic2 = value;
        refresh();
    }
}

void
SiAmCopperController::setExtraRows1(int value)
{
    value = std::max(0, value);

    if (m_extraRows1 != value) {

        m_extraRows1 = value;
        refresh();
    }
}

void
SiAmCopperController::setExtraRows2(int value)
{
    value = std::max(0, value);

    if (m_extraRows2 != value) {

        m_extraRows2 = value;
        refresh();
    }
}

void
SiAmCopperController::rebuildList(quint32 start, quint32 end, bool symbolic, int extraRows, SiAmCopperListModel &model)
{
    auto &core = SiAmController::core();
    auto &breakpoints = core.copperBreakpoints;

    int nativeLength = std::min(int((end - start) / 4), 500);
    int actualLength = nativeLength + extraRows;

    QVector<SiAmCopperListModel::Row> rows;
    rows.reserve(actualLength);

    u32 addr = start;

    for (int i = 0; i < actualLength; i++) {

        SiAmCopperListModel::Row row;
        row.rawAddr = addr;
        row.addr = formatNumber(addr, 6);
        row.instr = QString::fromStdString(core.agnus.copper.disassemble(addr, symbolic));
        row.illegal = core.agnus.copper.isIllegalInstr(addr);
        row.current = addr == m_coppc0;
        row.extra = i >= nativeLength;

        auto guard = breakpoints.guardAt(addr);
        row.breakState = !guard.has_value() ? 0 : (guard->enabled ? 1 : 2);

        rows.append(row);
        addr += 4;
    }

    model.setRows(rows);
}

void
SiAmCopperController::rebuildBreakpoints()
{
    auto &breakpoints = SiAmController::core().copperBreakpoints;

    QVector<SiAmGuardModel::Row> rows;
    isize n = breakpoints.elements();
    rows.reserve(int(n));

    for (isize i = 0; i < n; i++) {

        auto guard = breakpoints.guardNr(i);
        if (!guard.has_value()) continue;

        SiAmGuardModel::Row row;
        row.rawAddr = guard->addr;
        row.addr = formatNumber(guard->addr, 6);
        row.enabled = guard->enabled;
        rows.append(row);
    }

    m_breakpointsModel.setRows(rows);
}

void
SiAmCopperController::refreshData()
{
    // Read the Copper info from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::COPPER, 0.25);
    auto &info = infoController->copperInfo();

    m_cop1lc  = info.cop1lc;
    m_cop2lc  = info.cop2lc;
    m_coppc0  = info.coppc0;
    m_cop1ins = info.cop1ins;
    m_cop2ins = info.cop2ins;
    m_cdang   = info.cdang;

    rebuildList(info.copList1Start, info.copList1End, m_symbolic1, m_extraRows1, m_list1Model);
    rebuildList(info.copList2Start, info.copList2End, m_symbolic2, m_extraRows2, m_list2Model);
    rebuildBreakpoints();

    emit copperChanged();
}

void
SiAmCopperController::toggleBreakpoint1(int row)
{
    quint32 addr = m_list1Model.addrAt(row);
    auto &breakpoints = SiAmController::core().copperBreakpoints;
    auto guard = breakpoints.guardAt(addr);

    if (!guard.has_value()) breakpoints.setAt(addr);
    else if (!guard->enabled) breakpoints.enableAt(addr);
    else breakpoints.disableAt(addr);

    refresh();
}

void
SiAmCopperController::toggleBreakpoint2(int row)
{
    quint32 addr = m_list2Model.addrAt(row);
    auto &breakpoints = SiAmController::core().copperBreakpoints;
    auto guard = breakpoints.guardAt(addr);

    if (!guard.has_value()) breakpoints.setAt(addr);
    else if (!guard->enabled) breakpoints.enableAt(addr);
    else breakpoints.disableAt(addr);

    refresh();
}

void
SiAmCopperController::toggleGuardEnabled(int row)
{
    quint32 addr = m_breakpointsModel.addrAt(row);
    auto &breakpoints = SiAmController::core().copperBreakpoints;
    auto guard = breakpoints.guardAt(addr);

    if (!guard.has_value()) return;

    if (guard->enabled) breakpoints.disableAt(addr);
    else breakpoints.enableAt(addr);

    refresh();
}

void
SiAmCopperController::removeGuard(int row)
{
    quint32 addr = m_breakpointsModel.addrAt(row);
    SiAmController::core().copperBreakpoints.removeAt(addr);

    refresh();
}

void
SiAmCopperController::jumpToPC()
{
    auto &info = parent->getInfoController()->copperInfo();
    u32 pc = info.coppc0;

    if (pc >= info.copList1Start && pc < info.copList1End) {

        emit jumpRequested(1, int((pc - info.copList1Start) / 4));

    } else if (pc >= info.copList2Start && pc < info.copList2End) {

        emit jumpRequested(2, int((pc - info.copList2Start) / 4));
    }
}
