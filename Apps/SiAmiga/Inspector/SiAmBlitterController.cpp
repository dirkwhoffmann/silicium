// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmBlitterController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmBlitterController::SiAmBlitterController(SiAmController *parent)
    : SiAmInspectorController(parent)
{

}

QString
SiAmBlitterController::lfLabel(int n) const
{
    // Ascending binary order (lowercase = 0, uppercase = 1 for that
    // channel), matching the row order in vAmiga's own Minterm Generator
    // box.
    static const char *labels[8] = { "abc", "abC", "aBc", "aBC", "Abc", "AbC", "ABc", "ABC" };
    return n >= 0 && n < 8 ? QString(labels[n]) : QString();
}

void
SiAmBlitterController::refreshData()
{
    // Read the Blitter info from the shared info controller rather than
    // sampling the core directly; requestUpdate() coalesces the sampling
    // across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiAmInfoController::BLITTER, 0.25);
    auto &info = infoController->blitterInfo();

    int bltcon0 = info.bltcon0;
    int bltcon1 = info.bltcon1;

    m_bltcon0A = info.ash;
    m_bltcon0B = (bltcon0 >> 8) & 0xF;
    m_bltcon0C = bltcon0 & 0xFF;

    m_bltcon1A = info.bsh;
    m_bltcon1B = (bltcon1 >> 8) & 0xF;
    m_bltcon1C = bltcon1 & 0xFF;

    m_exclusiveFill = bltcon1 & 0x10;
    m_inclusiveFill = bltcon1 & 0x08;
    m_fillCarry     = bltcon1 & 0x04;
    m_descending    = bltcon1 & 0x02;
    m_lineMode      = bltcon1 & 0x01;
    m_bbusy         = info.bbusy;

    m_useA = bltcon0 & 0x800;
    m_useB = bltcon0 & 0x400;
    m_useC = bltcon0 & 0x200;
    m_useD = bltcon0 & 0x100;

    m_aHold = info.ahold;
    m_aOld  = info.aold;
    m_aNew  = info.anew;
    m_bHold = info.bhold;
    m_bOld  = info.bold;
    m_bNew  = info.bnew;
    m_cHold = info.chold;
    m_dHold = info.dhold;
    m_bzero = info.bzero;

    m_unmasked = info.anew;
    m_afwm     = info.bltafwm;
    m_alwm     = info.bltalwm;
    m_masked   = info.aold;
    m_firstWord = info.firstWord;
    m_lastWord  = info.lastWord;

    m_barrelAIn    = info.barrelAin;
    m_barrelAShift = info.ash;
    m_barrelAOut   = info.barrelAout;
    m_barrelBIn    = info.barrelBin;
    m_barrelBShift = info.bsh;
    m_barrelBOut   = info.barrelBout;

    m_fillIn  = info.fillIn;
    m_fillOut = info.fillOut;

    // Minterm generator: A/B/C are the three inputs (the hold registers),
    // D is the computed output written to the destination -- see the
    // class comment.
    int a = info.ahold;
    int b = info.bhold;
    int c = info.chold;

    m_mintermA = a;
    m_mintermB = b;
    m_mintermC = c;
    m_lfOut    = info.dhold;

    m_lfEnabled[0] = bltcon0 & 0x01; m_lfValue[0] = (~a & ~b & ~c) & 0xFFFF;
    m_lfEnabled[1] = bltcon0 & 0x02; m_lfValue[1] = (~a & ~b &  c) & 0xFFFF;
    m_lfEnabled[2] = bltcon0 & 0x04; m_lfValue[2] = (~a &  b & ~c) & 0xFFFF;
    m_lfEnabled[3] = bltcon0 & 0x08; m_lfValue[3] = (~a &  b &  c) & 0xFFFF;
    m_lfEnabled[4] = bltcon0 & 0x10; m_lfValue[4] = ( a & ~b & ~c) & 0xFFFF;
    m_lfEnabled[5] = bltcon0 & 0x20; m_lfValue[5] = ( a & ~b &  c) & 0xFFFF;
    m_lfEnabled[6] = bltcon0 & 0x40; m_lfValue[6] = ( a &  b & ~c) & 0xFFFF;
    m_lfEnabled[7] = bltcon0 & 0x80; m_lfValue[7] = ( a &  b &  c) & 0xFFFF;

    emit blitterChanged();
}
