// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmDeniseController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmDeniseController::SiAmDeniseController(SiAmController *parent)
    : SiAmInspectorController(parent)
{
    // DeniseDebugger only records sprite data while track mode is on -- see
    // Denise::hsyncHandler()'s "if (emulator.isTracking())
    // debugger.recordSprites(wasArmed)" guard. Without it, latchedSpriteInfo/
    // latchedSpriteData stay at their reset value (height 0, no data), so
    // SiAmSpriteView's cacheData() bails out early and the Sprites tab's
    // preview renders solid black even for an armed, visible sprite. Mirrors
    // SiAmCopperController's own tracking connection (see its own comment)
    // rather than the Swift reference's single shared Inspector window,
    // which calls emu.trackOn() once for any panel via dialogWillShow().
    connect(this, &SiAmInspectorController::activeChanged, this, [this]() {
        if (isActive()) SiAmController::core().trackOn();
        else SiAmController::core().trackOff();
    });
}

void
SiAmDeniseController::setSelectedSprite(int value)
{
    if (value < 0 || value > 7 || m_selectedSprite == value) return;

    m_selectedSprite = value;
    refresh();
}

QColor
SiAmDeniseController::colorAt(int nr) const
{
    if (nr < 0 || nr >= 128) return QColor();

    // Raw Amiga color register: 0x0RGB, 4 bits per channel. Each nibble is
    // replicated into the low bits to fill out an 8-bit channel (the
    // standard 4->8 bit expansion, e.g. 0xA -> 0xAA), rather than shifting
    // it left and leaving the low nibble black.
    u16 reg = m_colorReg[nr];
    int r4 = (reg >> 8) & 0xF;
    int g4 = (reg >> 4) & 0xF;
    int b4 = reg & 0xF;

    return QColor(r4 | (r4 << 4), g4 | (g4 << 4), b4 | (b4 << 4));
}

void
SiAmDeniseController::refreshData()
{
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::DENISE, 0.25);
    auto &info = infoController->deniseInfo();

    int bplcon0 = info.bplcon0;
    int bplcon1 = info.bplcon1;
    int bplcon2 = info.bplcon2;
    int bplcon3 = info.bplcon3;
    int bplcon4 = info.bplcon4;

    m_bplcon0 = bplcon0;
    m_bplcon1 = bplcon1;
    m_bplcon2 = bplcon2;
    m_bplcon3 = bplcon3;
    m_bplcon4 = bplcon4;
    m_bpu = info.bpu;

    m_hires = bplcon0 & 0b1000000000000000;
    m_homod = bplcon0 & 0b0000100000000000;
    m_dbplf = bplcon0 & 0b0000010000000000;
    m_lace  = bplcon0 & 0b0000000000000100;
    m_shres = bplcon0 & 0b0000000001000000;

    // The remaining BPLCON0 bits -- see SiAmDeniseController's own field
    // comment for why these have no Denise:: accessor to mirror.
    m_color  = bplcon0 & 0b0000001000000000;
    m_gaud   = bplcon0 & 0b0000000100000000;
    m_uhres  = bplcon0 & 0b0000000010000000;
    m_bypass = bplcon0 & 0b0000000000100000;
    m_lpen   = bplcon0 & 0b0000000000001000;
    m_ersy   = bplcon0 & 0b0000000000000010;
    m_ecsena = bplcon0 & 0b0000000000000001;

    // Display Mode box -- same formulas as Denise::resolution()/hamMode6()/
    // hamMode8() (see the field comment). isOCS/isAGA come from the same
    // DENISE_REVISION option Denise::isOCS()/isAGA() read internally.
    auto rev = DeniseRev(SiAmController::core().get(Opt::DENISE_REVISION));
    bool isOCS = rev == DeniseRev::OCS;
    bool isAGA = rev == DeniseRev::AGA;
    bool lores = !m_hires;

    m_resolutionText = (m_shres && !isOCS) ? QStringLiteral("SHRES")
                      : m_hires ? QStringLiteral("Hires") : QStringLiteral("Lores");

    bool ham6 = m_homod && (lores || isAGA) && m_bpu < 7;
    bool ham8 = m_homod && (lores || isAGA) && m_bpu >= 7;

    if (ham8) m_modeText = QStringLiteral("HAM8");
    else if (ham6) m_modeText = QStringLiteral("HAM6");
    else m_modeText = QString("%1 Bitplane%2").arg(m_bpu).arg(m_bpu == 1 ? "" : "s");

    m_p1h = bplcon1 & 0b00001111;
    m_p2h = (bplcon1 & 0b11110000) >> 4;

    m_pf2pri = bplcon2 & 0b1000000;
    m_pf2p2  = bplcon2 & 0b0100000;
    m_pf2p1  = bplcon2 & 0b0010000;
    m_pf2p0  = bplcon2 & 0b0001000;
    m_pf1p2  = bplcon2 & 0b0000100;
    m_pf1p1  = bplcon2 & 0b0000010;
    m_pf1p0  = bplcon2 & 0b0000001;
    m_killehb = bplcon2 & 0b1000000000;
    m_rdram   = bplcon2 & 0b0100000000;
    m_sogen   = bplcon2 & 0b0000000010000000;

    // BPLCON2's remaining AGA ZD-pin bits -- see the field comment.
    m_zdbpsel = (bplcon2 >> 12) & 0b111;
    m_zdbpen  = bplcon2 & 0b0000100000000000;
    m_zdcten  = bplcon2 & 0b0000010000000000;

    // BPLCON3 (AGA), same bit positions as Denise::colorBank()/pf2of()/
    // loct()/brdrblnk()/brdsprt() -- see SiAmDeniseController's class
    // comment. SPRES/BRDNTRAN/EXTBLKEN have no Denise:: accessor to mirror
    // (see the field comment).
    m_colorBank = (bplcon3 >> 13) & 0b111;
    m_pf2of     = (bplcon3 >> 10) & 0b111;
    m_loct      = bplcon3 & 0b0000001000000000;
    m_brdrblnk  = bplcon3 & 0b0000000000100000;
    m_brdsprt   = bplcon3 & 0b0000000000000010;
    m_spres     = (bplcon3 >> 6) & 0b11;
    m_brdntran  = bplcon3 & 0b0000000000010000;
    m_extblken  = bplcon3 & 0b0000000000000001;

    // BPLCON3's three leftover, unassigned bits -- see the field comment.
    m_bplcon3Res8 = bplcon3 & 0b0000000100000000;
    m_bplcon3Res3 = bplcon3 & 0b0000000000001000;
    m_bplcon3Res2 = bplcon3 & 0b0000000000000100;

    // BPLCON4 (AGA), same bit positions as Denise::bplam()/esprm()/osprm().
    m_bplam = (bplcon4 >> 8) & 0xFF;
    m_esprm = (bplcon4 >> 4) & 0xF;
    m_osprm = bplcon4 & 0xF;

    m_diwstrt = info.diwstrt;
    m_diwstop = info.diwstop;
    m_diwhigh = info.diwhigh;
    m_hstrt = (int)info.viewport.hstrt;
    m_vstrt = (int)info.viewport.vstrt;
    m_hstop = (int)info.viewport.hstop;
    m_vstop = (int)info.viewport.vstop;

    m_clxdat = info.clxdat;
    m_clxcon = info.clxcon;
    m_clxcon2 = info.clxcon2;

    for (int i = 0; i < 128; i++) m_colorReg[i] = info.colorReg[i];
    for (int i = 0; i < 32; i++) m_colorRegPeek[i] = info.colorRegPeek[i];
    for (int i = 0; i < 8; i++) {
        m_sprData[i] = info.sprdata[i];
        m_sprDatb[i] = info.sprdatb[i];
        m_sprPos[i] = info.sprpos[i];
        m_sprCtl[i] = info.sprctl[i];
    }
    m_revision++;

    for (int i = 0; i < 8; i++) m_spriteArmed[i] = info.sprite[i].height != 0;

    auto &sprite = info.sprite[m_selectedSprite];
    m_sprHStart = (int)sprite.hstrt;
    m_sprVStart = (int)sprite.vstrt;
    m_sprVStop = (int)sprite.vstop;
    m_sprAttach = sprite.attach;

    emit deniseChanged();
}
