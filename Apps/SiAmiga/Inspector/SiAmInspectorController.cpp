// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmInspectorController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmInspectorController::SiAmInspectorController(SiAmController *parent)
    : Controller(parent), parent(parent)
{

}

void
SiAmInspectorController::setActive(bool value)
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
SiAmInspectorController::setHex(bool value)
{
    if (m_hex != value) {

        m_hex = value;
        emit formatChanged();
        refresh();
    }
}

void
SiAmInspectorController::setPadded(bool value)
{
    if (m_padded != value) {

        m_padded = value;
        emit formatChanged();
        refresh();
    }
}

void
SiAmInspectorController::tick()
{
    if (!m_active) return;

    auto now = utl::Time::now();

    if ((now - lastRefresh).asSeconds() < 0.25) return;

    lastRefresh = now;
    refresh();
}

void
SiAmInspectorController::refresh()
{
    refreshData();
}

QString
SiAmInspectorController::formatNumber(qint64 value, int digits) const
{
    int width = m_padded ? digits : 0;

    return m_hex ? QString("%1").arg(value, width, 16, QChar('0')).toUpper()
                 : QString("%1").arg(value, width, 10, QChar('0'));
}
