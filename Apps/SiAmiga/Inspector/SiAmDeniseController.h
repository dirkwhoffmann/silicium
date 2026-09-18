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
#include <QString>

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
// BPLCON3/BPLCON4 (AGA) are decoded the same way BPLCON0/1/2 already are --
// straight bitmasks matching the bit positions Denise's own colorBank()/
// pf2of()/loct()/brdrblnk()/brdsprt() (BPLCON3) and bplam()/esprm()/osprm()
// (BPLCON4) accessors use (see Denise.h's "BPLCON3"/"BPLCON4" blocks), which
// are the only fields of either register the core actually acts on.
// DeniseInfo didn't carry bplcon4 at all until this controller needed it --
// see DeniseTypes.h/DeniseInfo.cpp.
//
// Color registers are exposed via colorAt(n) rather than named properties,
// the same Q_INVOKABLE(n) shape SiAmInfoController's own dReg(n)/aReg(n) and
// SiAmBlitterController's lfEnabled(n)/lfValue(n) use. Decoded straight from
// the raw 12-bit Amiga register value (colorReg[n], 0x0RGB) rather than
// DeniseInfo's already-gamma/adjustment-processed color[n] texels -- the
// inspector should show the register's actual content, not a display-
// pipeline-adjusted approximation of it. n ranges over all 128 entries
// DeniseInfo now caches (4 AGA color banks of 32 registers each, selected
// by BPLCON3's BANK field -- see the Colors tab), not just the bank
// currently selected for rendering.
//

class SiAmController;

class SiAmDeniseController : public SiAmInspectorController {

    Q_OBJECT

    int m_bplcon0 = 0, m_bplcon1 = 0, m_bplcon2 = 0, m_bplcon3 = 0, m_bplcon4 = 0;
    int m_bpu = 0;
    bool m_hires = false, m_homod = false, m_dbplf = false, m_lace = false, m_shres = false;

    // Display Mode box -- resolutionText is "Lores"/"Hires"/"SHRES";
    // modeText is "N Bitplane(s)" or "HAM6"/"HAM8". Mirrors Denise's own
    // resolution()/hamMode6()/hamMode8() formulas (see Denise.h's "Derived
    // values" block) rather than calling them directly: those are private
    // methods on the live Denise object, and this controller otherwise
    // only ever decodes the cached raw register values, never reaches into
    // the core mid-frame. Single/dual playfield and interlace on/off reuse
    // the existing dbplf/lace bit properties directly, no separate field
    // needed for those.
    QString m_resolutionText, m_modeText;

    // The remaining BPLCON0 bits -- COLOR/GAUD/LPEN/ERSY are genlock/light-
    // pen pins the core doesn't act on (nothing drives or reads them), and
    // UHRES/BYPASS are AGA bits the core doesn't implement either (UHRES
    // was never used by any chipset revision; BYPASS's true-color bypass
    // mode isn't emulated) -- exposed here purely for the register's raw
    // bit pattern, same as ERSY/LPEN, rather than because the core reacts
    // to them. Bit positions per the Amiga Hardware Reference Manual, not
    // named accessors on Denise (unlike hires()/ham()/dbplf()/lace()/
    // shres()/ecsena() above, which the core does use).
    bool m_color = false, m_gaud = false, m_uhres = false, m_bypass = false;
    bool m_lpen = false, m_ersy = false, m_ecsena = false;

    int m_p1h = 0, m_p2h = 0;
    bool m_pf2pri = false, m_pf2p2 = false, m_pf2p1 = false, m_pf2p0 = false;
    bool m_pf1p2 = false, m_pf1p1 = false, m_pf1p0 = false;
    bool m_killehb = false, m_rdram = false;

    // BPLCON2's remaining AGA genlock/ZD-pin bits -- like BPLCON0's COLOR/
    // GAUD/etc. and BPLCON3's SPRES/BRDNTRAN/EXTBLKEN, these drive external
    // pins (the "ZD" line selects one bitplane's data to output on a
    // dedicated pin for genlock hardware; SOGEN enables sync-on-green) that
    // the core doesn't act on -- exposed for the register's raw bit
    // pattern only. Bit positions per the AHRM.
    int m_zdbpsel = 0;
    bool m_zdbpen = false, m_zdcten = false, m_sogen = false;

    // BPLCON3 (AGA), decoded via Denise's own colorBank()/pf2of()/loct()/
    // brdrblnk()/brdsprt() -- the only BPLCON3 fields the core actually acts
    // on (see Denise.h's "BPLCON3" accessor block). SPRES/BRDNTRAN/EXTBLKEN
    // are, like BPLCON0's COLOR/GAUD/UHRES/BYPASS/LPEN/ERSY above, bits the
    // core doesn't read via a named accessor (SPRES is only ever read
    // inline as (bplcon3 >> 6) & 0b11 in Denise::sprPixelWidth(); BRDNTRAN/
    // EXTBLKEN aren't read anywhere) -- bit positions per the AHRM.
    int m_colorBank = 0, m_pf2of = 0, m_spres = 0;
    bool m_loct = false, m_brdrblnk = false, m_brdsprt = false;
    bool m_brdntran = false, m_extblken = false;

    // BPLCON3's three leftover bits (8, 3, 2) carry no assigned function at
    // all -- not even an unimplemented genlock/ZD-pin role like BPLCON0's
    // COLOR/GAUD/etc. or BPLCON2's ZDBPSEL/ZDBPEN/ZDCTEN/SOGEN above.
    // Exposed only so the register's raw bit pattern is complete.
    bool m_bplcon3Res8 = false, m_bplcon3Res3 = false, m_bplcon3Res2 = false;

    // BPLCON4 (AGA), decoded via Denise's own bplam()/esprm()/osprm() (see
    // Denise.h's "BPLCON4" accessor block): bplam is the 8-bit playfield
    // color XOR mask, esprm/osprm the even/odd sprite color-bank selectors.
    int m_bplam = 0, m_esprm = 0, m_osprm = 0;

    int m_diwstrt = 0, m_diwstop = 0, m_diwhigh = 0;
    int m_hstrt = 0, m_vstrt = 0, m_hstop = 0, m_vstop = 0;

    // Collision detection: CLXDAT (latched result, cleared on read on real
    // hardware -- see DeniseInfo::clxdat's own comment) and its two enable
    // masks CLXCON/CLXCON2. All three live on the Sprites tab, not here --
    // a collision is inherently a sprite/playfield overlap, so it's sprite
    // state the same way CLXDAT already was.
    int m_clxdat = 0, m_clxcon = 0, m_clxcon2 = 0;

    // 4 banks of 32 entries each -- see the Colors tab's class comment.
    quint16 m_colorReg[128] = {};

    // What CPU/Copper reads of COLOR00..COLOR31 actually see right now --
    // see DeniseInfo::colorRegPeek's own comment (0 unless AGA + RDRAM).
    // Shown on the Colors tab's own "Registers" box.
    quint16 m_colorRegPeek[32] = {};

    // Bumped every refreshData() call. colorAt(n)/colorRegPeek(n) are
    // Q_INVOKABLE, not Q_PROPERTY, so QML's binding engine never learns the
    // Colors tab's `denise.colorAt(n)`/`denise.colorRegPeek(n)` bindings
    // depend on m_colorReg/m_colorRegPeek -- calling an invokable from
    // within a binding registers no dependency, unlike reading a NOTIFYing
    // property. Referencing this counter alongside the call in the binding
    // gives it something to depend on, so the swatches/register column
    // actually repaint when the palette changes. Same trick as
    // SiC64MemoryController::m_selectRevision.
    int m_colorRevision = 0;

    bool m_spriteArmed[8] = {};
    int m_selectedSprite = 0;
    int m_sprHStart = 0, m_sprVStart = 0, m_sprVStop = 0;
    bool m_sprAttach = false;

  public:

    explicit SiAmDeniseController(SiAmController *parent = nullptr);

    Q_PROPERTY(int bplcon0 READ bplcon0 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon1 READ bplcon1 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon2 READ bplcon2 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon3 READ bplcon3 NOTIFY deniseChanged)
    Q_PROPERTY(int bplcon4 READ bplcon4 NOTIFY deniseChanged)
    Q_PROPERTY(int colorBank READ colorBank NOTIFY deniseChanged)
    Q_PROPERTY(int pf2of READ pf2of NOTIFY deniseChanged)
    Q_PROPERTY(bool loct READ loct NOTIFY deniseChanged)
    Q_PROPERTY(bool brdrblnk READ brdrblnk NOTIFY deniseChanged)
    Q_PROPERTY(bool brdsprt READ brdsprt NOTIFY deniseChanged)
    Q_PROPERTY(int spres READ spres NOTIFY deniseChanged)
    Q_PROPERTY(bool brdntran READ brdntran NOTIFY deniseChanged)
    Q_PROPERTY(bool extblken READ extblken NOTIFY deniseChanged)
    Q_PROPERTY(bool bplcon3Res8 READ bplcon3Res8 NOTIFY deniseChanged)
    Q_PROPERTY(bool bplcon3Res3 READ bplcon3Res3 NOTIFY deniseChanged)
    Q_PROPERTY(bool bplcon3Res2 READ bplcon3Res2 NOTIFY deniseChanged)
    Q_PROPERTY(int bplam READ bplam NOTIFY deniseChanged)
    Q_PROPERTY(int esprm READ esprm NOTIFY deniseChanged)
    Q_PROPERTY(int osprm READ osprm NOTIFY deniseChanged)
    Q_PROPERTY(int bpu READ bpu NOTIFY deniseChanged)
    Q_PROPERTY(bool hires READ hires NOTIFY deniseChanged)
    Q_PROPERTY(bool homod READ homod NOTIFY deniseChanged)
    Q_PROPERTY(bool dbplf READ dbplf NOTIFY deniseChanged)
    Q_PROPERTY(bool lace READ lace NOTIFY deniseChanged)
    Q_PROPERTY(bool shres READ shres NOTIFY deniseChanged)
    Q_PROPERTY(QString resolutionText READ resolutionText NOTIFY deniseChanged)
    Q_PROPERTY(QString modeText READ modeText NOTIFY deniseChanged)
    Q_PROPERTY(bool color READ color NOTIFY deniseChanged)
    Q_PROPERTY(bool gaud READ gaud NOTIFY deniseChanged)
    Q_PROPERTY(bool uhres READ uhres NOTIFY deniseChanged)
    Q_PROPERTY(bool bypass READ bypass NOTIFY deniseChanged)
    Q_PROPERTY(bool lpen READ lpen NOTIFY deniseChanged)
    Q_PROPERTY(bool ersy READ ersy NOTIFY deniseChanged)
    Q_PROPERTY(bool ecsena READ ecsena NOTIFY deniseChanged)
    Q_PROPERTY(int p1h READ p1h NOTIFY deniseChanged)
    Q_PROPERTY(int p2h READ p2h NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2pri READ pf2pri NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p2 READ pf2p2 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p1 READ pf2p1 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf2p0 READ pf2p0 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p2 READ pf1p2 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p1 READ pf1p1 NOTIFY deniseChanged)
    Q_PROPERTY(bool pf1p0 READ pf1p0 NOTIFY deniseChanged)
    Q_PROPERTY(bool killehb READ killehb NOTIFY deniseChanged)
    Q_PROPERTY(bool rdram READ rdram NOTIFY deniseChanged)
    Q_PROPERTY(int zdbpsel READ zdbpsel NOTIFY deniseChanged)
    Q_PROPERTY(bool zdbpen READ zdbpen NOTIFY deniseChanged)
    Q_PROPERTY(bool zdcten READ zdcten NOTIFY deniseChanged)
    Q_PROPERTY(bool sogen READ sogen NOTIFY deniseChanged)

    Q_PROPERTY(int diwstrt READ diwstrt NOTIFY deniseChanged)
    Q_PROPERTY(int diwstop READ diwstop NOTIFY deniseChanged)
    Q_PROPERTY(int diwhigh READ diwhigh NOTIFY deniseChanged)
    Q_PROPERTY(int hstrt READ hstrt NOTIFY deniseChanged)
    Q_PROPERTY(int vstrt READ vstrt NOTIFY deniseChanged)
    Q_PROPERTY(int hstop READ hstop NOTIFY deniseChanged)
    Q_PROPERTY(int vstop READ vstop NOTIFY deniseChanged)

    Q_PROPERTY(int clxdat READ clxdat NOTIFY deniseChanged)
    Q_PROPERTY(int clxcon READ clxcon NOTIFY deniseChanged)
    Q_PROPERTY(int clxcon2 READ clxcon2 NOTIFY deniseChanged)

    Q_PROPERTY(int selectedSprite READ selectedSprite WRITE setSelectedSprite NOTIFY deniseChanged)
    Q_PROPERTY(int sprHStart READ sprHStart NOTIFY deniseChanged)
    Q_PROPERTY(int sprVStart READ sprVStart NOTIFY deniseChanged)
    Q_PROPERTY(int sprVStop READ sprVStop NOTIFY deniseChanged)
    Q_PROPERTY(bool sprAttach READ sprAttach NOTIFY deniseChanged)

    Q_INVOKABLE bool spriteArmed(int nr) const { return nr >= 0 && nr < 8 && m_spriteArmed[nr]; }

    // 128-entry color-register palette (4 banks of 32), decoded to display
    // QColors.
    Q_INVOKABLE QColor colorAt(int nr) const;

    // Raw value of COLORnn (0x0RGB) as it currently reads back to the
    // CPU/Copper -- see m_colorRegPeek's own comment.
    Q_INVOKABLE int colorRegPeek(int nr) const { return nr >= 0 && nr < 32 ? m_colorRegPeek[nr] : 0; }

    // See m_colorRevision's own comment -- read this alongside colorAt(n)/
    // colorRegPeek(n) in a QML binding to make it re-evaluate when the
    // palette changes.
    Q_PROPERTY(int colorRevision READ colorRevision NOTIFY deniseChanged)
    int colorRevision() const { return m_colorRevision; }

  protected:

    void refreshData() override;

  private:

    int bplcon0() const { return m_bplcon0; }
    int bplcon1() const { return m_bplcon1; }
    int bplcon2() const { return m_bplcon2; }
    int bplcon3() const { return m_bplcon3; }
    int bplcon4() const { return m_bplcon4; }
    int colorBank() const { return m_colorBank; }
    int pf2of() const { return m_pf2of; }
    bool loct() const { return m_loct; }
    bool brdrblnk() const { return m_brdrblnk; }
    bool brdsprt() const { return m_brdsprt; }
    int spres() const { return m_spres; }
    bool brdntran() const { return m_brdntran; }
    bool extblken() const { return m_extblken; }
    bool bplcon3Res8() const { return m_bplcon3Res8; }
    bool bplcon3Res3() const { return m_bplcon3Res3; }
    bool bplcon3Res2() const { return m_bplcon3Res2; }
    int bplam() const { return m_bplam; }
    int esprm() const { return m_esprm; }
    int osprm() const { return m_osprm; }
    int bpu() const { return m_bpu; }
    bool hires() const { return m_hires; }
    bool homod() const { return m_homod; }
    bool dbplf() const { return m_dbplf; }
    bool lace() const { return m_lace; }
    bool shres() const { return m_shres; }
    QString resolutionText() const { return m_resolutionText; }
    QString modeText() const { return m_modeText; }
    bool color() const { return m_color; }
    bool gaud() const { return m_gaud; }
    bool uhres() const { return m_uhres; }
    bool bypass() const { return m_bypass; }
    bool lpen() const { return m_lpen; }
    bool ersy() const { return m_ersy; }
    bool ecsena() const { return m_ecsena; }
    int p1h() const { return m_p1h; }
    int p2h() const { return m_p2h; }
    bool pf2pri() const { return m_pf2pri; }
    bool pf2p2() const { return m_pf2p2; }
    bool pf2p1() const { return m_pf2p1; }
    bool pf2p0() const { return m_pf2p0; }
    bool pf1p2() const { return m_pf1p2; }
    bool pf1p1() const { return m_pf1p1; }
    bool pf1p0() const { return m_pf1p0; }
    bool killehb() const { return m_killehb; }
    bool rdram() const { return m_rdram; }
    int zdbpsel() const { return m_zdbpsel; }
    bool zdbpen() const { return m_zdbpen; }
    bool zdcten() const { return m_zdcten; }
    bool sogen() const { return m_sogen; }

    int diwstrt() const { return m_diwstrt; }
    int diwstop() const { return m_diwstop; }
    int diwhigh() const { return m_diwhigh; }
    int hstrt() const { return m_hstrt; }
    int vstrt() const { return m_vstrt; }
    int hstop() const { return m_hstop; }
    int vstop() const { return m_vstop; }

    int clxdat() const { return m_clxdat; }
    int clxcon() const { return m_clxcon; }
    int clxcon2() const { return m_clxcon2; }

    int selectedSprite() const { return m_selectedSprite; }
    void setSelectedSprite(int value);
    int sprHStart() const { return m_sprHStart; }
    int sprVStart() const { return m_sprVStart; }
    int sprVStop() const { return m_sprVStop; }
    bool sprAttach() const { return m_sprAttach; }

  signals:

    void deniseChanged();
};
