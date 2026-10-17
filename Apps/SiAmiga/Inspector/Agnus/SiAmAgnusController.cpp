// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmAgnusController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmAgnusController::SiAmAgnusController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

void
SiAmAgnusController::refreshData()
{
    // Read the Agnus (and Denise, for the current bitplane count) info from
    // the shared info controller rather than sampling the core directly;
    // requestUpdate() coalesces the sampling across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::AGNUS | SiAmInfoController::DENISE, 0.25);
    auto &info = infoController->agnusInfo();
    auto bpu = infoController->deniseInfo().bpu;

    m_vpos = int(info.vpos);
    m_hpos = int(info.hpos);

    int dmacon  = info.dmacon;
    int bltcon0 = info.bltcon0;

    m_dmacon  = dmacon;
    m_bplcon0 = info.bplcon0;
    m_fmode   = info.fmode;
    m_ddfstrt = info.ddfstrt;
    m_ddfstop = info.ddfstop;
    m_diwstrt = info.diwstrt;
    m_diwstop = info.diwstop;
    m_diwhigh = info.diwhigh;

    m_bltamod = info.bltamod;
    m_bltbmod = info.bltbmod;
    m_bltcmod = info.bltcmod;
    m_bltdmod = info.bltdmod;
    m_bpl1mod = info.bpl1mod;
    m_bpl2mod = info.bpl2mod;

    // Same gating chain as the Swift reference: DMAEN gates every category,
    // then each category's own enable bit gates its channels.
    bool dmaen  = dmacon & 0x0200;
    bool bplen  = (dmacon & 0x0100) && dmaen;
    bool copen  = (dmacon & 0x0080) && dmaen;
    bool blten  = (dmacon & 0x0040) && dmaen;
    bool spren  = (dmacon & 0x0020) && dmaen;
    bool dsken  = (dmacon & 0x0010) && dmaen;

    m_coppc      = int(info.coppc0);
    m_copEnabled = copen;
    m_dskpt      = int(info.dskpt);
    m_dskEnabled = dsken;

    m_bltPri = dmacon & 0x0400;
    m_bls    = info.bls;

    m_sprEnabled = spren;

    for (int i = 0; i < 8; i++) {
        m_bplPt[i]      = int(info.bplpt[i]);
        m_bplEnabled[i] = bplen && bpu >= i + 1;
    }

    for (int i = 0; i < 4; i++) {
        m_audPt[i]      = int(info.audpt[i]);
        m_audLc[i]      = int(info.audlc[i]);
        m_audEnabled[i] = (dmacon & (1 << i)) && dmaen;
    }

    static const int bltUseBit[4] = { 0x0800, 0x0400, 0x0200, 0x0100 };
    for (int i = 0; i < 4; i++) {
        m_bltPt[i]      = int(info.bltpt[i]);
        m_bltEnabled[i] = (bltcon0 & bltUseBit[i]) && blten;
    }

    for (int i = 0; i < 8; i++) {
        m_sprPt[i] = int(info.sprpt[i]);
    }

    emit agnusChanged();
}
