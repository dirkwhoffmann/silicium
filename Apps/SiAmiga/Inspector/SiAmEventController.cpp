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
    // Read AmigaInfo (progress counters) and AgnusInfo (the event slot
    // table) from the shared info controller. The base class has already
    // requested an AMIGA sample for the beam position, so that half is
    // coalesced onto the same query; AGNUS is requested here for the first
    // time this tick.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::AMIGA | SiAmInfoController::AGNUS, 0.25);

    auto &amigaInfo = infoController->amigaInfo();
    auto &agnusInfo = infoController->agnusInfo();

    m_cpuProgress   = amigaInfo.cpuClock;
    m_agnusProgress = amigaInfo.dmaClock;
    m_ciaAProgress  = amigaInfo.ciaAClock;
    m_ciaBProgress  = amigaInfo.ciaBClock;

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
