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
#include "VAmiga.h"
#include <QColor>

//
// Denise inspector controller -- port of vAmiga's own GUI/Inspector/
// DenisePanel.swift (the register/bitplane/sprite-armed/color-register half;
// SpriteTableView.swift's per-pixel bitmap preview is SiAmSpriteView, a
// QQuickPaintedItem in the same self-driving mold as SiAmLogicView, since
// that's a drawing job rather than a data-controller one).
//
// Register/bitplane/viewport/color state is read from the shared info
// controller's cached DeniseInfo (SiAmInfoController::deniseInfo(), already
// sampled for the DENISE component by other panels/the status bar) rather
// than querying the core directly -- this controller only decodes it into
// the individual bit/field properties DenisePanel.swift's outlets expose.
//
// Color registers are exposed via colorAt(n) rather than 32 named
// properties, the same Q_INVOKABLE(n) shape SiAmInfoController's own
// dReg(n)/aReg(n) and SiAmBlitterController's lfEnabled(n)/lfValue(n) use.
// Decoded straight from the raw 12-bit Amiga register value (colorReg[n],
// 0x0RGB) rather than DeniseInfo's already-gamma/adjustment-processed
// color[n] texels -- the inspector should show the register's actual
// content, not a display-pipeline-adjusted approximation of it.
//

class SiAmController;

class SiAmDeniseController : public SiAmInspectorController {

    Q_OBJECT

    int m_bplcon0 = 0, m_bplcon1 = 0, m_bplcon2 = 0;
    int m_bpu = 0;
    bool m_hires = false, m_homod = false, m_dbplf = false, m_lace = false, m_shres = false;
    bool m_shresEnabled = false;
    int m_p1h = 0, m_p2h = 0;
    bool m_pf2pri = false, m_pf2p2 = false, m_pf2p1 = false, m_pf2p0 = false;
    bool m_pf1p2 = false, m_pf1p1 = false, m_pf1p0 = false;

    int m_diwstrt = 0, m_diwstop = 0;
    int m_hstrt = 0, m_vstrt = 0, m_hstop = 0, m_vstop = 0;

    int m_clxdat = 0;

    quint16 m_colorReg[32] = {};

    bool m_spriteArmed[8] = {};
    int m_selectedSprite = 0;
    int m_sprHStart = 0, m_sprVStart = 0, m_sprVStop = 0;
    bool m_sprAttach = false;

  public:

    explicit SiAmDeniseController(SiAmController *parent = nullptr);

    Q_PROPERTY(int bplcon0 READ bplcon0 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon1 READ bplcon1 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon2 READ bplcon2 NOTIFY deniseChanged)
    Q_PROPERTY(int bpu READ bpu NOTIFY deniseChanged)
    Q_PROPERTY(bool hires READ hires NOTIFY deniseChanged)
    Q_PROPERTY(bool homod READ homod NOTIFY deniseChanged)
    Q_PROPERTY(bool dbplf READ dbplf NOTIFY deniseChanged)
    Q_PROPERTY(bool lace READ lace NOTIFY deniseChanged)
    Q_PROPERTY(bool shres READ shres NOTIFY deniseChanged)
    Q_PROPERTY(bool shresEnabled READ shresEnabled NOTIFY deniseChanged)
    Q_PROPERTY(int p1h READ p1h NOTIFY deniseChanged)
    Q_PROPERTY(int p2h READ p2h NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2pri READ pf2pri NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p2 READ pf2p2 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p1 READ pf2p1 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p0 READ pf2p0 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p2 READ pf1p2 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p1 READ pf1p1 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p0 READ pf1p0 NOTIFY deniseChanged)

    Q_PROPERTY(int diwstrt READ diwstrt NOTIFY deniseChanged)
    Q_PROPERTY(int diwstop READ diwstop NOTIFY deniseChanged)
    Q_PROPERTY(int hstrt READ hstrt NOTIFY deniseChanged)
    Q_PROPERTY(int vstrt READ vstrt NOTIFY deniseChanged)
    Q_PROPERTY(int hstop READ hstop NOTIFY deniseChanged)
    Q_PROPERTY(int vstop READ vstop NOTIFY deniseChanged)

    Q_PROPERTY(int clxdat READ clxdat NOTIFY deniseChanged)

    Q_PROPERTY(int selectedSprite READ selectedSprite WRITE setSelectedSprite NOTIFY deniseChanged)
    Q_PROPERTY(int sprHStart READ sprHStart NOTIFY deniseChanged)
    Q_PROPERTY(int sprVStart READ sprVStart NOTIFY deniseChanged)
    Q_PROPERTY(int sprVStop READ sprVStop NOTIFY deniseChanged)
    Q_PROPERTY(bool sprAttach READ sprAttach NOTIFY deniseChanged)

    Q_INVOKABLE bool spriteArmed(int nr) const { return nr >= 0 && nr < 8 && m_spriteArmed[nr]; }

    // 32-entry color-register palette, decoded to display QColors.
    Q_INVOKABLE QColor colorAt(int nr) const;

  protected:

    void refreshData() override;

  private:

    int bplcon0() const { return m_bplcon0; }
    int bplcon1() const { return m_bplcon1; }
    int bplcon2() const { return m_bplcon2; }
    int bpu() const { return m_bpu; }
    bool hires() const { return m_hires; }
    bool homod() const { return m_homod; }
    bool dbplf() const { return m_dbplf; }
    bool lace() const { return m_lace; }
    bool shres() const { return m_shres; }
    bool shresEnabled() const { return m_shresEnabled; }
    int p1h() const { return m_p1h; }
    int p2h() const { return m_p2h; }
    bool pf2pri() const { return m_pf2pri; }
    bool pf2p2() const { return m_pf2p2; }
    bool pf2p1() const { return m_pf2p1; }
    bool pf2p0() const { return m_pf2p0; }
    bool pf1p2() const { return m_pf1p2; }
    bool pf1p1() const { return m_pf1p1; }
    bool pf1p0() const { return m_pf1p0; }

    int diwstrt() const { return m_diwstrt; }
    int diwstop() const { return m_diwstop; }
    int hstrt() const { return m_hstrt; }
    int vstrt() const { return m_vstrt; }
    int hstop() const { return m_hstop; }
    int vstop() const { return m_vstop; }

    int clxdat() const { return m_clxdat; }

    int selectedSprite() const { return m_selectedSprite; }
    void setSelectedSprite(int value);
    int sprHStart() const { return m_sprHStart; }
    int sprVStart() const { return m_sprVStart; }
    int sprVStop() const { return m_sprVStop; }
    bool sprAttach() const { return m_sprAttach; }

  signals:

    void deniseChanged();
};
