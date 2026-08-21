// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64EventController.h"
#include "C64Controller.h"
#include "C64.h"

using namespace vc64;

SiC64EventController::SiC64EventController(C64Controller *parent)
    : SiC64InspectorController(parent), m_eventModel(this)
{

}

void
SiC64EventController::refreshData()
{
    // Read the C64 info from the shared info controller. The base class has
    // already requested a C64 sample for the beam position, so this is
    // coalesced onto the same query.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::C64, 0.25);
    auto &info = infoController->c64Info();

    m_cpuProgress  = info.cpuProgress;
    m_vicProgress  = info.frame;
    m_cia1Progress = info.cia1Progress;
    m_cia2Progress = info.cia2Progress;

    QVector<SiC64EventTableModel::Row> rows;
    rows.reserve(SLOT_COUNT);

    for (isize i = 0; i < SLOT_COUNT; i++) {

        auto &slot = info.slotInfo[i];
        bool pending = slot.trigger != NEVER;

        SiC64EventTableModel::Row row;
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
