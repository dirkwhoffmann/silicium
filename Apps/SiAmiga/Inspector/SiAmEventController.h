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
// C64 core's SLOT_COUNT scheduler slots) for a future SiAmEventsPanel.
//
// vAmiga's scheduler is considerably larger than the C64's -- 39 slots
// across three tiers (primary/secondary/tertiary, see AgnusTypes.h's
// EventSlot) versus the C64's handful, covering things the C64 has no
// counterpart for at all (four floppy AND four hard-drive disk-change
// slots, three RetroShell instances, beam traps, alarms, ...). None of
// that changes the shape of this controller though -- it is still just
// "read AgnusInfo.slotInfo[SLOT_COUNT] into table rows" the same way
// SiC64EventController reads C64Info.slotInfo[SLOT_COUNT]. The four
// progress counters are the one field-level difference: vc64's C64Info
// carries cpuProgress/frame/cia1Progress/cia2Progress directly, while
// vAmiga splits the same four numbers (cpuClock/dmaClock/ciaAClock/
// ciaBClock) across AmigaInfo -- so refreshData() below requests AMIGA
// (for those) alongside AGNUS (for the slot table), coalesced through the
// same shared info controller SiC64EventController uses.
//

class SiAmController;

class SiAmEventController : public SiAmInspectorController {

    Q_OBJECT

    qint64 m_cpuProgress = 0;
    qint64 m_agnusProgress = 0;
    qint64 m_ciaAProgress = 0;
    qint64 m_ciaBProgress = 0;
    SiAmEventTableModel m_eventModel;

  public:

    explicit SiAmEventController(SiAmController *parent = nullptr);

    Q_PROPERTY(qint64 cpuProgress READ cpuProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 agnusProgress READ agnusProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaAProgress READ ciaAProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 ciaBProgress READ ciaBProgress NOTIFY eventsChanged)
    Q_PROPERTY(QObject* events READ events CONSTANT)

  protected:

    void refreshData() override;

  private:

    qint64 cpuProgress() const { return m_cpuProgress; }
    qint64 agnusProgress() const { return m_agnusProgress; }
    qint64 ciaAProgress() const { return m_ciaAProgress; }
    qint64 ciaBProgress() const { return m_ciaBProgress; }
    QObject *events() const { return const_cast<SiAmEventTableModel *>(&m_eventModel); }

  signals:

    void eventsChanged();
};
