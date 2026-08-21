// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "utl/common.h"
#include "utl/chrono/Time.h"

//
// Base class for the inspector sub-controllers (SiC64EventController,
// SiC64CIAController, ...). Hosts everything they share:
//
//   - the "active" flag the owning inspector window sets as it shows/hides,
//   - the ~4 Hz tick() throttle, and
//   - the beam-position readout (frame:vpos:hpos) shown in every inspector's
//     toolbar (SiC64InspectorToolbar).
//
// Because every open inspector window keeps its own controller ticking, the
// toolbar binds to that window's controller and always sees a live beam
// position -- regardless of which panel (Events, CIA, ...) is showing. (A
// single shared readout owned by, say, the Events controller would go stale
// whenever the Events window was closed.)
//
// Derived controllers add their own panel-specific properties and override
// refreshData() to sample them; the base refresh() updates the shared beam
// position first, then calls refreshData().
//

class C64Controller;

class SiC64InspectorController : public Controller {

    Q_OBJECT

  protected:

    C64Controller *parent = nullptr;

    bool m_active = false;

    // frame:vpos:hpos readout, formatted per C64Controller::format
    QString m_beamPosition;

    // Wall-clock time of the last refresh, used to throttle tick() to ~4 Hz
    utl::Time lastRefresh = 0;

  public:

    explicit SiC64InspectorController(C64Controller *parent = nullptr);

    // Called once per rendered frame from SiC64Renderer::tick(). No-op
    // unless active; otherwise refreshes at most 4 times per second.
    void tick();

    // Updates the shared beam position, then the derived controller's own
    // data (refreshData()). Public so C64Controller::setFormat() can force
    // an immediate reformat.
    void refresh();

    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QString beamPosition READ beamPosition NOTIFY beamPositionChanged)

    bool isActive() const { return m_active; }
    void setActive(bool value);

    QString beamPosition() const { return m_beamPosition; }

  protected:

    // Samples the derived controller's own info and emits its change signal.
    // Called by refresh() after the shared beam position has been updated.
    virtual void refreshData() { };

    // Formats a value per C64Controller's shared format setting (hex/decimal,
    // zero-padded or not -- see SiC64InspectorToolbar's format combo box).
    // 'digits' is the field's natural width (e.g. 2 for a byte, 4 for a
    // word), used as the zero-padding width when padding is on and ignored
    // (unpadded) otherwise. Shared by every derived controller's
    // refreshData() so the format combo box affects every numeric field the
    // same way.
    QString formatNumber(qint64 value, int digits) const;

  signals:

    void activeChanged();
    void beamPositionChanged();
};
