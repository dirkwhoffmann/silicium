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

// Skeleton counterpart to SiC64InspectorController. SiC64's version is the
// shared base for a whole family of derived, per-panel controllers
// (SiC64EventController, SiC64CIAController, ...), each sampling its own
// slice of the core and each getting its own inspector window. SiAmiga
// doesn't have that per-panel data plumbing yet -- SiAmInspectorWindow.qml
// hosts every panel (CPU, Bus, CIA, Memory, Agnus, Copper, Blitter, Paula,
// Denise, Port, Events) as stub content behind one sidebar instead of one
// window per panel -- so for now there is exactly one instance of this
// class, owned by SiAmController and shared by every panel, rather than one
// per panel. It carries just the two things every future panel controller
// will need regardless of what it samples: the "is any inspector panel
// currently visible" flag driving a throttled tick(), and the hex/decimal
// number-format toggle the shared toolbar exposes. Panel-specific data
// controllers (an eventual SiAmCPUController, SiAmAgnusController, ...) are
// expected to derive from this the way SiC64's do from SiC64InspectorController,
// once a given panel grows real content.
class SiAmInspectorController : public Controller {

    Q_OBJECT

  protected:

    class SiAmController *parent = nullptr;

    bool m_active = false;

    // Number format shown by every panel, toggled from SiAmInspectorToolbar's
    // format menu. Unlike SiC64 (which routes this through a shared
    // C64Actions object), SiAmiga's toolbars call controllers directly (see
    // SiAmToolbar.qml), so these live here as plain properties instead.
    bool m_hex = true;
    bool m_padded = false;

    // Wall-clock time of the last refresh, used to throttle tick() to ~4 Hz
    utl::Time lastRefresh = 0;

  public:

    explicit SiAmInspectorController(SiAmController *parent = nullptr);

    // Called once per rendered frame (see SiAmRenderer::tick()). No-op
    // unless active; otherwise refreshes at most 4 times per second.
    void tick();

    // Refreshes shared state, then the derived controller's own data
    // (refreshData()). Public so a future format-change action can force an
    // immediate reformat, mirroring SiC64InspectorController::refresh().
    void refresh();

    Q_PROPERTY(bool active READ isActive WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool hex READ isHex WRITE setHex NOTIFY formatChanged)
    Q_PROPERTY(bool padded READ isPadded WRITE setPadded NOTIFY formatChanged)

    bool isActive() const { return m_active; }
    void setActive(bool value);

    bool isHex() const { return m_hex; }
    void setHex(bool value);

    bool isPadded() const { return m_padded; }
    void setPadded(bool value);

  protected:

    // Samples the derived controller's own info and emits its change
    // signal. Called by refresh() after any shared state has been updated.
    // No-op here -- there is no shared data source yet to sample (see the
    // class comment).
    virtual void refreshData() { }

    // Formats a value per the hex/padded properties above. 'digits' is the
    // field's natural width (e.g. 2 for a byte, 4 for a word), used as the
    // zero-padding width when padding is on and ignored (unpadded)
    // otherwise. Mirrors SiC64InspectorController::formatNumber(), shared
    // here so every future derived controller's refreshData() formats
    // numbers the same way.
    QString formatNumber(qint64 value, int digits) const;

  signals:

    void activeChanged();
    void formatChanged();
};
