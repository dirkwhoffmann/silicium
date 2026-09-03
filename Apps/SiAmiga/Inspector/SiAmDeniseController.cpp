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
    if (nr < 0 || nr >= 32) return QColor();

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

    m_bplcon0 = bplcon0;
    m_bplcon1 = bplcon1;
    m_bplcon2 = bplcon2;
    m_bpu = info.bpu;

    m_hires = bplcon0 & 0b1000000000000000;
    m_homod = bplcon0 & 0b0000100000000000;
    m_dbplf = bplcon0 & 0b0000010000000000;
    m_lace  = bplcon0 & 0b0000000000000100;
    m_shres = bplcon0 & 0b0000000001000000;

    auto rev = DeniseRev(SiAmController::core().get(Opt::DENISE_REVISION));
    m_shresEnabled = rev == DeniseRev::ECS;

    m_p1h = bplcon1 & 0b00001111;
    m_p2h = (bplcon1 & 0b11110000) >> 4;

    m_pf2pri = bplcon2 & 0b1000000;
    m_pf2p2  = bplcon2 & 0b0100000;
    m_pf2p1  = bplcon2 & 0b0010000;
    m_pf2p0  = bplcon2 & 0b0001000;
    m_pf1p2  = bplcon2 & 0b0000100;
    m_pf1p1  = bplcon2 & 0b0000010;
    m_pf1p0  = bplcon2 & 0b0000001;

    m_diwstrt = info.diwstrt;
    m_diwstop = info.diwstop;
    m_hstrt = (int)info.viewport.hstrt;
    m_vstrt = (int)info.viewport.vstrt;
    m_hstop = (int)info.viewport.hstop;
    m_vstop = (int)info.viewport.vstop;

    m_clxdat = info.clxdat;

    for (int i = 0; i < 32; i++) m_colorReg[i] = info.colorReg[i];

    for (int i = 0; i < 8; i++) m_spriteArmed[i] = info.sprite[i].height != 0;

    auto &sprite = info.sprite[m_selectedSprite];
    m_sprHStart = (int)sprite.hstrt;
    m_sprVStart = (int)sprite.vstrt;
    m_sprVStop = (int)sprite.vstop;
    m_sprAttach = sprite.attach;

    emit deniseChanged();
}
