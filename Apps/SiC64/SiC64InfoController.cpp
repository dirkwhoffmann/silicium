// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64InfoController.h"
#include "C64Controller.h"

using namespace vc64;

SiC64InfoController::SiC64InfoController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}

void
SiC64InfoController::requestUpdate(int components, double interval)
{
    // Sample each requested component only if its own cached copy has aged
    // past the interval. Independent per-component timers mean several
    // inspectors interested in different subsystems each get fresh data
    // without dragging in the others or resetting each other's throttle.
    static constexpr Component all[NumComponents] = { CPU, CIA, SID, AUDIO, C64, VIC, MEM, DRIVE, DATASETTE, CARTRIDGE };

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
SiC64InfoController::refresh()
{
    static constexpr Component all[NumComponents] = { CPU, CIA, SID, AUDIO, C64, VIC, MEM, DRIVE, DATASETTE, CARTRIDGE };

    auto now = utl::Time::now();
    for (int i = 0; i < NumComponents; i++) {
        m_lastUpdate[i] = now;
        grab(all[i]);
    }

    emit infoChanged();
}

void
SiC64InfoController::grab(Component component)
{
    auto &core = C64Controller::core();

    switch (component) {

        case CPU:

            m_cpuInfo = core.cpu.getInfo();
            break;

        case CIA:

            m_ciaInfo[0] = core.cia1.getInfo();
            m_ciaInfo[1] = core.cia2.getInfo();
            m_ciaStats[0] = core.cia1.getStats();
            m_ciaStats[1] = core.cia2.getStats();
            break;

        case SID:

            for (int i = 0; i < 4; i++) m_sidInfo[i] = core.sid.getInfo(i);
            break;

        case AUDIO:

            m_audioStats = core.audioPort.getStats();
            break;

        case C64:

            m_c64Info = core.c64.getInfo();
            break;

        case VIC:

            m_vicInfo = core.vicii.getInfo();
            for (int i = 0; i < 8; i++) m_spriteInfo[i] = core.vicii.getSpriteInfo(i);
            for (int i = 0; i < 16; i++) m_vicColor[i] = core.vicii.getColor(i);
            break;

        case MEM:

            m_memInfo = core.mem.getInfo();
            break;

        case DRIVE:

            m_driveInfo[0] = core.drive8.getInfo();
            m_driveInfo[1] = core.drive9.getInfo();
            break;

        case DATASETTE:

            m_datasetteInfo = core.datasette.getInfo();
            break;

        case CARTRIDGE:

            m_cartridgeInfo = core.expansionPort.getInfo();
            m_cartridgeAttached = core.expansionPort.getCartridgeTraits().type != CartridgeType::NONE;
            break;

        default:
            break;
    }
}

bool
SiC64InfoController::pcWarning() const
{
    return m_cpuInfo.next != 0 && !C64Controller::core().isRunning();
}

int
SiC64InfoController::serverState() const
{
    // The state of the worst-off server, which drives the color of the
    // statusbar icon. "Worst" ranks an error above a pending transition,
    // that above an established connection, and that above a server which is
    // simply switched off -- i.e. red beats yellow beats green beats gray,
    // matching the LED colors the server popup shows per server.
    auto rank = [](SrvState s) {

        switch (s) {

            case SrvState::STOPPING:
            case SrvState::INVALID:   return 3;     // red
            case SrvState::STARTING:
            case SrvState::LISTENING: return 2;     // yellow
            case SrvState::CONNECTED: return 1;     // green
            default:                  return 0;     // gray (OFF)
        }
    };

    auto &srv = C64Controller::core().remoteManager.getInfo();
    auto worst = SrvState::OFF;

    for (auto s : { srv.rshInfo.state, srv.rpcInfo.state,
                    srv.dapInfo.state, srv.promInfo.state }) {

        if (rank(s) > rank(worst)) worst = s;
    }

    return int(worst);
}

QUrl
SiC64InfoController::serverStateLed(int state) const
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
            return QUrl("qrc:/images/led-round-gray.png"); // OFF
    }
}

QString
SiC64InfoController::serverStateIcon(int state) const
{
    // A Phosphor wifi glyph: no bars while off, rising bars while starting
    // up / listening / connected, and a broken icon once a server has
    // stopped or gone invalid. Kept in step with serverStateLed()'s grouping.
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
            return "wifi-slash"; // OFF
    }
}

QString
SiC64InfoController::serverStateName(int state) const
{
    switch (SrvState(state)) {

        case SrvState::STARTING:  return "Starting";
        case SrvState::LISTENING: return "Listening";
        case SrvState::CONNECTED: return "Connected";
        case SrvState::STOPPING:  return "Stopping";
        case SrvState::INVALID:   return "Halted";
        default:                  return "Off"; // OFF
    }
}

bool
SiC64InfoController::tracking() const
{
    // Track mode is on (fills the CPU trace log while an inspector needs it).
    return C64Controller::core().isTracking();
}

bool
SiC64InfoController::mute() const
{
    // Audio is muted (both master volumes are zero).
    auto &core = C64Controller::core();
    return core.get(Opt::AUD_VOL_L) == 0 && core.get(Opt::AUD_VOL_R) == 0;
}

bool
SiC64InfoController::warping() const
{
    // The emulator is currently running in warp (turbo) mode.
    return C64Controller::core().isWarping();
}

int
SiC64InfoController::rshServerState() const
{
    return int(C64Controller::core().remoteManager.getInfo().rshInfo.state);
}

int
SiC64InfoController::rpcServerState() const
{
    return int(C64Controller::core().remoteManager.getInfo().rpcInfo.state);
}

int
SiC64InfoController::dapServerState() const
{
    return int(C64Controller::core().remoteManager.getInfo().dapInfo.state);
}

int
SiC64InfoController::promServerState() const
{
    return int(C64Controller::core().remoteManager.getInfo().promInfo.state);
}
