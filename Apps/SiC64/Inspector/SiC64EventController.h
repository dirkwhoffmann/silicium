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
#include "SiC64EventTableModel.h"

class C64Controller;

class SiC64EventController : public SiC64InspectorController {

    Q_OBJECT

    qint64 m_cpuProgress = 0;
    qint64 m_vicProgress = 0;
    qint64 m_cia1Progress = 0;
    qint64 m_cia2Progress = 0;
    SiC64EventTableModel m_eventModel;

  public:

    explicit SiC64EventController(C64Controller *parent = nullptr);

    Q_PROPERTY(qint64 cpuProgress READ cpuProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 vicProgress READ vicProgress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 cia1Progress READ cia1Progress NOTIFY eventsChanged)
    Q_PROPERTY(qint64 cia2Progress READ cia2Progress NOTIFY eventsChanged)
    Q_PROPERTY(QObject* events READ events CONSTANT)

  protected:

    void refreshData() override;

  private:

    qint64 cpuProgress() const { return m_cpuProgress; }
    qint64 vicProgress() const { return m_vicProgress; }
    qint64 cia1Progress() const { return m_cia1Progress; }
    qint64 cia2Progress() const { return m_cia2Progress; }
    QObject *events() const { return const_cast<SiC64EventTableModel *>(&m_eventModel); }

  signals:

    void eventsChanged();
};
