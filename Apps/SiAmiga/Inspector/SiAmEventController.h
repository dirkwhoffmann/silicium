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
#include "SiAmEventTableModel.h"

//
// Event scheduler inspector controller -- port of SiC64EventController.
// Exposes the emulator's whole event queue (vAmiga's counterpart to the
// C64 core's SLOT_COUNT scheduler slots) for SiAmEventsPanel.
//
// vAmiga's scheduler is considerably larger than the C64's -- 39 slots
// across three tiers (primary/secondary/tertiary, see AgnusTypes.h's
// EventSlot) versus the C64's handful, covering things the C64 has no
// counterpart for at all (four floppy AND four hard-drive disk-change
// slots, three RetroShell instances, beam traps, alarms, ...). None of
// that changes the shape of this controller though -- it is still just
// "read AgnusInfo.slotInfo[SLOT_COUNT] into table rows" the same way
// SiC64EventController reads C64Info.slotInfo[SLOT_COUNT].
//
// The progress counters are the one real shape difference, following
// vAmiga's own reference GUI (GUI/Inspector/EventPanel.swift's
// refreshEvents()) rather than vc64's C64Info.cpuProgress/vicProgress/
// cia1Progress/cia2Progress: every counter there is read from
// AgnusInfo.eventInfo, and shown *twice* -- once as a raw master-cycle
// count, once converted to the pace the driving component actually runs
// at (CPU cycles = master/4, DMA cycles = master/8, CIA cycles =
// master/40) -- so each of the four progress fields below has a
// '...Progress' (master cycles) and a '...Progress2' (converted) sibling,
// matching evCpuProgress/evCpuProgress2/evDmaProgress/... in that Swift
// method one-for-one. There's no VIC/frame-progress counterpart on the
// Amiga side of this box row -- Agnus (the DMA controller) takes that
// slot instead of Denise (the video chip), since it's Agnus's own
// dmaClock being tracked, not a frame counter.
//

class SiAmController;

class SiAmEventController : public SiAmInspectorController {

    Q_OBJECT

    qint64 m_cpuProgress = 0, m_cpuProgress2 = 0;
    qint64 m_agnusProgress = 0, m_agnusProgress2 = 0;
    qint64 m_ciaAProgress = 0, m_ciaAProgress2 = 0;
    qint64 m_ciaBProgress = 0, m_ciaBProgress2 = 0;
    SiAmEventTableModel m_eventModel;

  public:

    explicit SiAmEventController(SiAmController *parent = nullptr);

    Q_PROPERTY(qint64 cpuProgress READ cpuProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 cpuProgress2 READ cpuProgress2 NOTIFY eventsChanged)
    Q_PROPERTY(qint64 agnusProgress READ agnusProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 agnusProgress2 READ agnusProgress2 NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaAProgress READ ciaAProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaAProgress2 READ ciaAProgress2 NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaBProgress READ ciaBProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaBProgress2 READ ciaBProgress2 NOTIFY eventsChanged)
    Q_PROPERTY(QObject* events READ events CONSTANT)

  protected:

    void refreshData() override;

  private:

    qint64 cpuProgress() const { return m_cpuProgress; }
    qint64 cpuProgress2() const { return m_cpuProgress2; }
    qint64 agnusProgress() const { return m_agnusProgress; }
    qint64 agnusProgress2() const { return m_agnusProgress2; }
    qint64 ciaAProgress() const { return m_ciaAProgress; }
    qint64 ciaAProgress2() const { return m_ciaAProgress2; }
    qint64 ciaBProgress() const { return m_ciaBProgress; }
    qint64 ciaBProgress2() const { return m_ciaBProgress2; }
    QObject *events() const { return const_cast<SiAmEventTableModel *>(&m_eventModel); }

  signals:

    void eventsChanged();
};
