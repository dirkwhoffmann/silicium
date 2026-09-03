// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmInfoController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmInfoController::SiAmInfoController(SiAmController *parent)
    : Controller(parent), parent(parent)
{

}

void
SiAmInfoController::requestUpdate(int components, double interval)
{
    // Sample each requested component only if its own cached copy has aged
    // past the interval. Independent per-component timers mean several
    // inspectors interested in different subsystems each get fresh data
    // without dragging in the others or resetting each other's throttle.
    static constexpr Component all[NumComponents] = { CPU, CIA, AGNUS, DENISE, PAULA, MEMORY, DRIVE, HD, AMIGA, COPPER, BLITTER };

    auto now = utl::Time::now();
    bool changed = false;

    for (int i = 0; i < NumComponents; i++) {

        if (!(components & all[i])) continue;
        if ((now - m_lastUpdate[i]).asSeconds() < interval) continue;

        m_lastUpdate[i] = now;
        grab(all[i]);
        changed = true;
    }

    if (changed) emit infoChanged();
}

void
SiAmInfoController::refresh()
{
    static constexpr Component all[NumComponents] = { CPU, CIA, AGNUS, DENISE, PAULA, MEMORY, DRIVE, HD, AMIGA, COPPER, BLITTER };

    auto now = utl::Time::now();
    for (int i = 0; i < NumComponents; i++) {
        m_lastUpdate[i] = now;
        grab(all[i]);
    }

    emit infoChanged();
}

void
SiAmInfoController::grab(Component component)
{
    auto &core = SiAmController::core();

    switch (component) {

        case CPU:

            m_cpuInfo = core.cpu.getInfo();
            break;

        case CIA:

            m_ciaInfo[0] = core.ciaA.getInfo();
            m_ciaInfo[1] = core.ciaB.getInfo();
            m_ciaMetrics[0] = core.ciaA.getMetrics();
            m_ciaMetrics[1] = core.ciaB.getMetrics();
            break;

        case AGNUS:

            m_agnusInfo = core.agnus.getInfo();
            break;

        case DENISE:

            m_deniseInfo = core.denise.getInfo();
            break;

        case PAULA:

            m_paulaInfo = core.paula.getInfo();
            break;

        case MEMORY:

            m_memInfo = core.mem.getInfo();
            m_memConfig = core.mem.getConfig();
            break;

        case DRIVE:

            for (int i = 0; i < 4; i++) m_driveInfo[i] = core.df[i]->getInfo();
            break;

        case HD:

            for (int i = 0; i < 4; i++) m_hdInfo[i] = core.hd[i]->getInfo();
            break;

        case AMIGA:

            m_amigaInfo = core.amiga.getInfo();
            break;

        case COPPER:

            m_copperInfo = core.agnus.copper.getInfo();
            break;

        case BLITTER:

            m_blitterInfo = core.agnus.blitter.getInfo();
            break;

        default:
            break;
    }
}

bool
SiAmInfoController::tracking() const
{
    // Track mode is on (fills the CPU trace log while an inspector needs it).
    return SiAmController::core().isTracking();
}

bool
SiAmInfoController::mute() const
{
    // Audio is muted (both master volumes are zero).
    auto &core = SiAmController::core();
    return core.get(Opt::AUD_VOLL) == 0 && core.get(Opt::AUD_VOLR) == 0;
}

bool
SiAmInfoController::warping() const
{
    // The emulator is currently running in warp (turbo) mode.
    return SiAmController::core().isWarping();
}
