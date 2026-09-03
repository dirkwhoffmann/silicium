// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmEventController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmEventController::SiAmEventController(SiAmController *parent)
    : SiAmInspectorController(parent), m_eventModel(this)
{

}

void
SiAmEventController::refreshData()
{
    // Read AgnusInfo (both the progress counters, via its nested eventInfo,
    // and the event slot table) from the shared info controller. Mirrors
    // vAmiga's own GUI/Inspector/EventPanel.swift's refreshEvents(), which
    // sources every one of these from agnusInfo.eventInfo too.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::AGNUS, 0.25);

    auto &agnusInfo = infoController->agnusInfo();
    auto &eventInfo = agnusInfo.eventInfo;

    // Master-cycle counts, and the same four converted to the pace their
    // driving component runs at -- CPU: master/4, DMA (Agnus): master/8,
    // CIA: master/40 -- exactly as EventPanel.swift's refreshEvents() does.
    m_cpuProgress    = eventInfo.cpuClock;
    m_cpuProgress2   = eventInfo.cpuCycles;
    m_agnusProgress  = eventInfo.dmaClock;
    m_agnusProgress2 = eventInfo.dmaClock / 8;
    m_ciaAProgress   = eventInfo.ciaAClock;
    m_ciaAProgress2  = eventInfo.ciaAClock / 40;
    m_ciaBProgress   = eventInfo.ciaBClock;
    m_ciaBProgress2  = eventInfo.ciaBClock / 40;

    QVector<SiAmEventTableModel::Row> rows;
    rows.reserve(SLOT_COUNT);

    for (isize i = 0; i < SLOT_COUNT; i++) {

        auto &slot = agnusInfo.slotInfo[i];
        bool pending = slot.trigger != NEVER;

        SiAmEventTableModel::Row row;
        row.slot = QString(EventSlotEnum::key(EventSlot(i)));
        row.event = QString(slot.eventName);
        row.pending = pending;
        row.due = pending && slot.triggerRel <= 0;
        row.trigger = pending ? QString("%1").arg(slot.trigger) : QString("none");

        if (!pending) {
            row.frame = QString();
        } else if (slot.frameRel < 0) {
            row.frame = QString("previous");
        } else if (slot.frameRel == 0) {
            row.frame = QString("current");
        } else {
            row.frame = QString("current + %1").arg(slot.frameRel);
        }

        row.vpos = pending ? formatNumber(slot.vpos, 2) : QString();
        row.hpos = pending ? formatNumber(slot.hpos, 2) : QString();

        if (!pending) {
            row.remark = QString();
        } else if (slot.triggerRel > 0) {
            row.remark = QString("due in %1 cycles").arg(slot.triggerRel);
        } else if (slot.triggerRel < 0) {
            row.remark = QString("due since %1 cycles").arg(-slot.triggerRel);
        } else {
            row.remark = QString("due immediately");
        }

        rows.append(row);
    }

    m_eventModel.setRows(rows);

    emit eventsChanged();
}
