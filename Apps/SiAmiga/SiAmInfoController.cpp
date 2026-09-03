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
            m_audioInfo[0] = core.paula.audioChannel0.getInfo();
            m_audioInfo[1] = core.paula.audioChannel1.getInfo();
            m_audioInfo[2] = core.paula.audioChannel2.getInfo();
            m_audioInfo[3] = core.paula.audioChannel3.getInfo();
            m_diskControllerInfo = core.paula.diskController.getInfo();
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

int
SiAmInfoController::serverState() const
{
    // The state of the worst-off server, which drives the color of the
    // statusbar icon. "Worst" ranks an error above a pending transition,
    // that above an established connection, and that above a server which
    // is simply switched off or waiting on its launch condition -- i.e. red
    // beats yellow beats green beats gray, matching the LED colors the
    // server popup shows per server.
    auto rank = [](SrvState s) {

        switch (s) {

            case SrvState::STOPPING:
            case SrvState::INVALID:   return 3;     // red
            case SrvState::STARTING:
            case SrvState::LISTENING: return 2;     // yellow
            case SrvState::CONNECTED: return 1;     // green
            default:                  return 0;     // gray (OFF, WAITING)
        }
    };

    auto &srv = SiAmController::core().remoteManager.getInfo();
    auto worst = SrvState::OFF;

    for (auto s : { srv.rshInfo.state, srv.rpcInfo.state,
                    srv.gdbInfo.state, srv.promInfo.state, srv.serInfo.state }) {

        if (rank(s) > rank(worst)) worst = s;
    }

    return int(worst);
}

QUrl
SiAmInfoController::serverStateLed(int state) const
{
    switch (SrvState(state)) {

        case SrvState::CONNECTED:
            return QUrl("qrc:/images/led-round-green.png");

        case SrvState::STARTING:
        case SrvState::LISTENING:
            return QUrl("qrc:/images/led-round-yellow.png");

        case SrvState::STOPPING:
        case SrvState::INVALID:
            return QUrl("qrc:/images/led-round-red.png");

        default:
            return QUrl("qrc:/images/led-round-gray.png"); // OFF, WAITING
    }
}

QString
SiAmInfoController::serverStateIcon(int state) const
{
    // A Phosphor wifi glyph: no bars while off/waiting, rising bars while
    // starting up / listening / connected, and a broken icon once a server
    // has stopped or gone invalid. Kept in step with serverStateLed()'s
    // grouping.
    switch (SrvState(state)) {

        case SrvState::CONNECTED:
            return "wifi-high";

        case SrvState::STARTING:
        case SrvState::LISTENING:
            return "wifi-medium";

        case SrvState::STOPPING:
        case SrvState::INVALID:
            return "wifi-x";

        default:
            return "wifi-slash"; // OFF, WAITING
    }
}

QString
SiAmInfoController::serverStateName(int state) const
{
    switch (SrvState(state)) {

        case SrvState::WAITING:   return "Waiting";
        case SrvState::STARTING:  return "Starting";
        case SrvState::LISTENING: return "Listening";
        case SrvState::CONNECTED: return "Connected";
        case SrvState::STOPPING:  return "Stopping";
        case SrvState::INVALID:   return "Halted";
        default:                  return "Off"; // OFF
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

int
SiAmInfoController::rshServerState() const
{
    return int(SiAmController::core().remoteManager.getInfo().rshInfo.state);
}

int
SiAmInfoController::rpcServerState() const
{
    return int(SiAmController::core().remoteManager.getInfo().rpcInfo.state);
}

int
SiAmInfoController::gdbServerState() const
{
    return int(SiAmController::core().remoteManager.getInfo().gdbInfo.state);
}

int
SiAmInfoController::promServerState() const
{
    return int(SiAmController::core().remoteManager.getInfo().promInfo.state);
}

int
SiAmInfoController::serServerState() const
{
    return int(SiAmController::core().remoteManager.getInfo().serInfo.state);
}
