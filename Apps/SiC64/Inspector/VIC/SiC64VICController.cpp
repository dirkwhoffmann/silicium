// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64VICController.h"
#include "C64Controller.h"
#include "SiC64ConfigController.h"

using namespace vc64;

SiC64VICController::SiC64VICController(C64Controller *parent)
    : SiC64InspectorController(parent)
{

}

namespace {

QString screenGeometryName(ScreenGeometry g)
{
    switch (g) {
        case ScreenGeometry::GEOMETRY_25_40: return "25 rows, 40 columns";
        case ScreenGeometry::GEOMETRY_25_38: return "25 rows, 38 columns";
        case ScreenGeometry::GEOMETRY_24_40: return "24 rows, 40 columns";
        case ScreenGeometry::GEOMETRY_24_38: return "24 rows, 38 columns";
    }
    return "???";
}

QString displayModeName(DisplayMode m)
{
    switch (m) {
        case DisplayMode::STANDARD_TEXT:       return "Standard Text";
        case DisplayMode::MULTICOLOR_TEXT:     return "Multicolor Text";
        case DisplayMode::STANDARD_BITMAP:     return "Standard Bitmap";
        case DisplayMode::MULTICOLOR_BITMAP:   return "Multicolor Bitmap";
        case DisplayMode::EXTENDED_BG_COLOR:   return "Extended BG Color";
        case DisplayMode::INVALID_TEXT:        return "Invalid Text";
        case DisplayMode::INV_STANDARD_BITMAP: return "Invalid Bitmap";
        case DisplayMode::INV_MULTICOL_BITMAP: return "Invalid Bitmap";
    }
    return "???";
}

}

void
SiC64VICController::refreshData()
{
    // Read the VICII info, the selected sprite's info and the palette colors
    // from the shared info controller rather than sampling the core directly;
    // requestUpdate() coalesces the sampling across all open inspectors.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::VIC, 0.25);

    auto &info = infoController->vicInfo();
    auto &spr = infoController->spriteInfo(m_selectedSprite);

    auto color = [&](u8 nr) {
        u32 v = infoController->vicColor(nr);
        return QColor(int((v >> 16) & 0xFF), int((v >> 8) & 0xFF), int(v & 0xFF));
    };

    m_yCounter = info.yCounter;
    m_xCounter = info.xCounter;
    m_vc       = info.vc;
    m_vcBase   = info.vcBase;
    m_rc       = info.rc;
    m_vmli     = info.vmli;

    m_ctrl1 = info.ctrl1;
    m_ctrl2 = info.ctrl2;
    m_dx    = info.dx;
    m_dy    = info.dy;
    m_denBit       = info.denBit;
    m_badLine      = info.badLine;
    m_displayState = info.displayState;
    m_vblank       = info.vblank;
    m_screenGeometry = screenGeometryName(info.screenGeometry);
    m_displayMode    = displayModeName(info.displayMode);
    m_vFlop = info.frameFF.vertical;
    m_hFlop = info.frameFF.main;
    m_borderColor = color(info.borderColor);
    m_bgColor0    = color(info.bgColor0);
    m_bgColor1    = color(info.bgColor1);
    m_bgColor2    = color(info.bgColor2);
    m_bgColor3    = color(info.bgColor3);

    m_memSelect       = info.memSelect;
    m_ultimax         = info.ultimax;
    m_memoryBankAddr  = formatNumber(info.memoryBankAddr, 4);
    m_screenMemoryAddr = formatNumber(info.screenMemoryAddr, 4);
    m_charMemoryAddr  = formatNumber(info.charMemoryAddr, 4);

    m_irqRasterline = info.irqLine;
    m_imr = info.imr;
    m_imrLP     = info.imr & 0b1000;
    m_imrSS     = info.imr & 0b0100;
    m_imrSB     = info.imr & 0b0010;
    m_imrRaster = info.imr & 0b0001;
    m_irr = info.irr;
    m_irrIrq    = info.irr & 0b10000000;
    m_irrLP     = info.irr & 0b1000;
    m_irrSS     = info.irr & 0b0100;
    m_irrSB     = info.irr & 0b0010;
    m_irrRaster = info.irr & 0b0001;

    m_latchedLPX = info.latchedLPX;
    m_latchedLPY = info.latchedLPY;
    m_lpLine = info.lpLine;
    m_lpIrqHasOccurred = info.lpIrqHasOccurred;

    m_sprX = spr.x;
    m_sprY = spr.y;
    m_sprEnabled     = spr.enabled;
    m_sprExpandX     = spr.expandX;
    m_sprExpandY     = spr.expandY;
    m_sprPriority    = spr.priority;
    m_sprMulticolor  = spr.multicolor;
    m_sprSSCollision = spr.ssCollision;
    m_sprSBCollision = spr.sbCollision;
    m_sprColor  = color(spr.color);
    m_sprExtra1 = color(spr.extraColor1);
    m_sprExtra2 = color(spr.extraColor2);

    emit vicChanged();

    // The cutter fields are read live from the config options, but a refresh
    // is a good moment to let any external change propagate.
    emit cutChanged();
}

void
SiC64VICController::setSelectedSprite(int value)
{
    value = qBound(0, value, 7);

    if (m_selectedSprite != value) {

        m_selectedSprite = value;
        refresh();
    }
}

int
SiC64VICController::cutLayers() const
{
    return parent->getConfigController()->vicCutLayers();
}

void
SiC64VICController::setLayer(int mask, bool on)
{
    int layers = cutLayers();
    int updated = on ? (layers | mask) : (layers & ~mask);

    if (updated != layers) {

        parent->getConfigController()->setVicCutLayers(updated);
        emit cutChanged();
    }
}

void
SiC64VICController::toggleCutSprite(int sprite)
{
    if (sprite < 0 || sprite > 7) return;
    setLayer(1 << sprite, !(cutLayers() & (1 << sprite)));
}

int
SiC64VICController::cutOpacity() const
{
    return parent->getConfigController()->vicCutOpacity();
}

void
SiC64VICController::setCutOpacity(int value)
{
    if (value != cutOpacity()) {

        parent->getConfigController()->setVicCutOpacity(value);
        emit cutChanged();
    }
}
