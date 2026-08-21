// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64InspectorController.h"
#include "C64Controller.h"
#include "C64.h"

using namespace vc64;

SiC64InspectorController::SiC64InspectorController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}

void
SiC64InspectorController::setActive(bool value)
{
    if (m_active != value) {

        m_active = value;
        emit activeChanged();

        // Show up-to-date data the instant the window opens, rather than
        // waiting for the next throttled tick()
        if (m_active) refresh();
    }
}

void
SiC64InspectorController::tick()
{
    if (!m_active) return;

    auto now = utl::Time::now();

    if ((now - lastRefresh).asSeconds() < 0.25) return;

    lastRefresh = now;
    refresh();
}

void
SiC64InspectorController::refresh()
{
    // The beam position comes from the shared C64Info; sample it through the
    // info controller so every open inspector coalesces onto one query.
    auto *infoController = parent->getInfoController();
    infoController->requestUpdate(SiC64InfoController::C64, 0.25);
    auto &info = infoController->c64Info();

    // Mirrors the old Swift-based emulator's InspectorToolbar "progress"
    // item (frame:vpos:hpos) -- frame is never zero-padded (digits: 0),
    // vpos/hpos pad to 3 digits when the toolbar's format combo box has
    // padding on.
    m_beamPosition = QString("%1:%2:%3")
        .arg(formatNumber(info.frame, 0))
        .arg(formatNumber(info.vpos, 3))
        .arg(formatNumber(info.hpos, 3));
    emit beamPositionChanged();

    refreshData();
}

QString
SiC64InspectorController::formatNumber(qint64 value, int digits) const
{
    bool hex = parent->isHex();
    int width = parent->isPadded() ? digits : 0;

    return hex ? QString("%1").arg(value, width, 16, QChar('0')).toUpper()
               : QString("%1").arg(value, width, 10, QChar('0'));
}
