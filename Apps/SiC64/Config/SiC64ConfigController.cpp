// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64ConfigController.h"
#include "Assets.h"
#include "C64Controller.h"
#include "Preferences.h"
#include "RomFile.h"
#include <QFileInfo>

using namespace vc64;

SiC64ConfigController::SiC64ConfigController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}

SiC64ConfigController::~SiC64ConfigController()
{

}

bool
SiC64ConfigController::isRom(const QUrl &url, RomType type) const
{
    if (url.isLocalFile()) {

        auto path = fs::path(url.toLocalFile().toStdWString());
        return RomFile::romType(path) == type;
    }
    return false;
}

void
SiC64ConfigController::loadRom(const QUrl &url)
{
    try {

        if (url.isLocalFile()) {

            auto path = fs::path(url.toLocalFile().toStdWString());
            auto type = RomFile::romType(path);

            C64Controller::core().c64.loadRom(url.toLocalFile().toStdWString());
            queryRoms();

            if (type) rememberRomPath(url, *type);
        }

    } catch (IOError &) {

        emit showError("Failed to load ROM.",
                       "The file is not recognized as a ROM of the requested type.");

    } catch (std::exception &e) {

        emit showError("Failed to load ROM.", e.what());
    }
}

void
SiC64ConfigController::loadRom(const QUrl &url, RomType type)
{
    try {

        if (url.isLocalFile()) {
            C64Controller::core().c64.loadRom(url.toLocalFile().toStdWString(), type);
            queryRoms();
            rememberRomPath(url, type);
        }

    } catch (IOError &) {

        emit showError("Failed to load ROM.",
                       "The file is not recognized as a ROM of the requested type.");

    } catch (std::exception &e) {

        emit showError("Failed to load ROM.", e.what());
    }
}

void
SiC64ConfigController::rememberRomPath(const QUrl &url, RomType type)
{
    auto &prefs = Preferences::instance();

    switch (type) {

        case RomType::BASIC:  prefs.setBasicPath(url);  break;
        case RomType::CHAR:   prefs.setCharPath(url);   break;
        case RomType::KERNAL: prefs.setKernalPath(url); break;
        case RomType::VC1541: prefs.setVc1541Path(url); break;
    }
}

void
SiC64ConfigController::loadMostRecentRoms()
{
    auto &prefs = Preferences::instance();

    // Silently skips URLs that are empty or no longer point to an existing file
    auto loadIfPresent = [this](const QUrl &url, RomType type) {

        if (!url.isEmpty() && url.isLocalFile() && QFileInfo::exists(url.toLocalFile())) {
            loadRom(url, type);
        }
    };

    loadIfPresent(prefs.getBasicPath(),  RomType::BASIC);
    loadIfPresent(prefs.getCharPath(),   RomType::CHAR);
    loadIfPresent(prefs.getKernalPath(), RomType::KERNAL);
    loadIfPresent(prefs.getVc1541Path(), RomType::VC1541);
}

void
SiC64ConfigController::installOpenRoms()
{
    try {

        // Unlike loadRom(), there's no file behind these -- they're baked
        // into the core -- so there's no path worth remembering either.
        C64Controller::core().c64.installOpenRoms();
        queryRoms();

    } catch (std::exception &e) {

        emit showError("Failed to install the OpenROMs.", e.what());
    }
}

void
SiC64ConfigController::deleteRom(RomType type)
{
    try {

        C64Controller::core().c64.deleteRom(type);
        queryRoms();

    } catch (std::exception &e) {

        emit showError("Failed to delete ROM.", e.what());
    }
}

void
SiC64ConfigController::queryRoms()
{
    auto &core = C64Controller::core();

    basicRom  = core.c64.getRomTraits(RomType::BASIC);
    kernalRom = core.c64.getRomTraits(RomType::KERNAL);
    charRom   = core.c64.getRomTraits(RomType::CHAR);
    vc1541Rom = core.c64.getRomTraits(RomType::VC1541);

    emit romConfigChanged();
}

QUrl
SiC64ConfigController::getRomIcon(const RomTraits &traits) const
{
    auto hasRom          = traits.crc != 0;
    auto hasCommodoreRom = traits.vendor == RomVendor::COMMODORE;
    auto hasMega65Rom    = traits.vendor == RomVendor::MEGA65;

    return hasMega65Rom      ? Assets::getIconUrl(Assets::Icon::RomMega)
           : hasCommodoreRom ? Assets::getIconUrl(Assets::Icon::RomMos)
           : hasRom          ? Assets::getIconUrl(Assets::Icon::RomUnknown)
                             : Assets::getIconUrl(Assets::Icon::RomPlain);
}

QString
SiC64ConfigController::getRomVendor(const RomTraits &traits) const
{
    return QString::fromUtf8(RomVendorEnum::key(traits.vendor));
}

i64
SiC64ConfigController::get(vc64::Opt opt) const
{
    try { return C64Controller::core().get(opt); } catch (...) { return 0; }
}

i64
SiC64ConfigController::get(vc64::Opt opt, long id) const
{
    try { return C64Controller::core().get(opt, id); } catch (...) { return 0; }
}

void
SiC64ConfigController::set(vc64::Opt opt, i64 newValue)
{
    try { C64Controller::core().set(opt, newValue); } catch (...) { }
}

void
SiC64ConfigController::set(vc64::Opt opt, i64 newValue, long id)
{
    try { C64Controller::core().set(opt, newValue, id); } catch (...) { }
}

void
SiC64ConfigController::restoreDefaults(Opt opt, std::vector<isize> objids)
{
    auto &core = C64Controller::core();
    auto &defaults = VirtualC64::defaults;

    // Erasing the user's entry makes get() report the factory fallback again.
    try {

        if (objids.empty()) defaults.remove(opt); else defaults.remove(opt, objids);

    } catch (...) { }

    // Applying that value keeps the running machine -- and the panel bound to
    // it -- in step with the storage. It's best-effort and guarded per item:
    // the core refuses some values depending on machine state (connecting a
    // drive with no Floppy ROM installed, say), and one refusal must not stop
    // the remaining items from being restored.
    if (objids.empty()) {

        try { core.set(opt, defaults.get(opt)); } catch (...) { }

    } else {

        for (auto id : objids) {

            try { core.set(opt, defaults.get(opt, id), id); } catch (...) { }
        }
    }
}

void
SiC64ConfigController::restoreHardwareDefaults()
{
    // The options SiC64HardwareConfig.qml exposes, section by section. The
    // SID keys are registered per chip (see Defaults.cpp); the panel drives
    // the revision of the first SID and the enable/address pairs of the
    // three optional ones.
    restoreDefaults(Opt::VICII_REVISION);
    restoreDefaults(Opt::VICII_GRAY_DOT_BUG);
    restoreDefaults(Opt::SID_REV, { 0 });
    restoreDefaults(Opt::SID_ENABLE, { 1, 2, 3 });
    restoreDefaults(Opt::SID_ADDRESS, { 1, 2, 3 });
    restoreDefaults(Opt::CIA_REVISION);
    restoreDefaults(Opt::CIA_TIMER_B_BUG);
    restoreDefaults(Opt::GLUE_LOGIC);
    restoreDefaults(Opt::POWER_GRID);
    restoreDefaults(Opt::MEM_INIT_PATTERN);

    emit configChanged();
}

void
SiC64ConfigController::restoreDevicesDefaults()
{
    // The drive options are registered per drive, the datasette / mouse /
    // autofire ones aren't (see Defaults.cpp) -- the objid lists below have to
    // mirror that exactly, since remove() rejects an unregistered key.
    restoreDefaults(Opt::DRV_CONNECT,     { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_AUTO_CONFIG, { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_TYPE,        { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_RAM,         { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_PARCABLE,    { Drive8, Drive9 });
    restoreDefaults(Opt::DAT_CONNECT);
    restoreDefaults(Opt::DAT_MODEL);
    restoreDefaults(Opt::MOUSE_MODEL);
    restoreDefaults(Opt::AUTOFIRE);
    restoreDefaults(Opt::AUTOFIRE_BURSTS);
    restoreDefaults(Opt::AUTOFIRE_BULLETS);
    restoreDefaults(Opt::AUTOFIRE_DELAY);

    emit configChanged();
}

void
SiC64ConfigController::restorePerformanceDefaults()
{
    restoreDefaults(Opt::DRV_POWER_SAVE, { Drive8, Drive9 });
    restoreDefaults(Opt::VICII_POWER_SAVE);
    restoreDefaults(Opt::SID_POWER_SAVE, { 0, 1, 2, 3 });
    restoreDefaults(Opt::VICII_SS_COLLISIONS);
    restoreDefaults(Opt::VICII_SB_COLLISIONS);
    restoreDefaults(Opt::C64_WARP_MODE);
    restoreDefaults(Opt::C64_WARP_BOOT);
    restoreDefaults(Opt::C64_VSYNC);
    restoreDefaults(Opt::C64_SPEED_BOOST);
    restoreDefaults(Opt::C64_RUN_AHEAD);

    emit configChanged();
}

void
SiC64ConfigController::restoreAudioDefaults()
{
    restoreDefaults(Opt::SID_ENGINE,   { 0, 1, 2, 3 });
    restoreDefaults(Opt::SID_SAMPLING, { 0, 1, 2, 3 });
    restoreDefaults(Opt::SID_FILTER,   { 0, 1, 2, 3 });
    restoreDefaults(Opt::AUD_VOL0);
    restoreDefaults(Opt::AUD_VOL1);
    restoreDefaults(Opt::AUD_VOL2);
    restoreDefaults(Opt::AUD_VOL3);
    restoreDefaults(Opt::AUD_PAN0);
    restoreDefaults(Opt::AUD_PAN1);
    restoreDefaults(Opt::AUD_PAN2);
    restoreDefaults(Opt::AUD_PAN3);
    restoreDefaults(Opt::AUD_VOL_L);
    restoreDefaults(Opt::AUD_VOL_R);
    restoreDefaults(Opt::DRV_STEP_VOL,   { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_INSERT_VOL, { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_EJECT_VOL,  { Drive8, Drive9 });
    restoreDefaults(Opt::DRV_PAN,        { Drive8, Drive9 });

    emit configChanged();
}

void
SiC64ConfigController::restoreServerDefaults()
{
    // Every server option is registered per server (ServerType: 0 = RSH,
    // 1 = RPC, 2 = DAP, 3 = PROM), matching the per-server accessors above.
    // DAP is included even though its panel row is hidden -- the panel still
    // binds its options, so leaving it out would strand stale settings.
    static const std::vector<isize> servers = { 0, 1, 2, 3 };

    restoreDefaults(Opt::SRV_ENABLE,    servers);
    restoreDefaults(Opt::SRV_TRANSPORT, servers);
    restoreDefaults(Opt::SRV_PORT,      servers);

    emit configChanged();
}

void
SiC64ConfigController::restoreVideoDefaults()
{
    restoreDefaults(Opt::MON_PALETTE);
    restoreDefaults(Opt::MON_BRIGHTNESS);
    restoreDefaults(Opt::MON_CONTRAST);
    restoreDefaults(Opt::MON_SATURATION);
    restoreDefaults(Opt::MON_HCENTER);
    restoreDefaults(Opt::MON_VCENTER);
    restoreDefaults(Opt::MON_HZOOM);
    restoreDefaults(Opt::MON_VZOOM);

    emit configChanged();
}

QColor
SiC64ConfigController::dmaColor(Opt opt) const
{
    u32 v = (u32)get(opt);
    return QColor((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
}

void
SiC64ConfigController::setDmaColor(Opt opt, const QColor &c)
{
    set(opt, (i64(c.red()) << 16) | (i64(c.green()) << 8) | i64(c.blue()));
}
