// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmConfigController.h"
#include "Assets.h"
#include "SiAmController.h"
#include "RomFile.h"
#include "Roms/RomManager.h"
#include <QFileInfo>

using namespace vamiga;

SiAmConfigController::SiAmConfigController(SiAmController *parent)
    : Controller(parent), parent(parent)
{

}

SiAmConfigController::~SiAmConfigController()
{

}

bool
SiAmConfigController::isRom(const QUrl &url) const
{
    if (url.isLocalFile()) {

        auto path = fs::path(url.toLocalFile().toStdWString());
        return RomFile::isCompatible(path);
    }
    return false;
}

void
SiAmConfigController::loadKickRom(const QUrl &url)
{
    try {

        if (url.isLocalFile()) {

            auto path = fs::path(url.toLocalFile().toStdWString());
            SiAmController::core().mem.loadRom(url.toLocalFile().toStdWString());
            queryRoms();
            copyToLibrary(path);
        }

    } catch (std::exception &e) {

        emit showError("Failed to load Kickstart ROM.", e.what());
    }
}

void
SiAmConfigController::loadExtRom(const QUrl &url)
{
    try {

        if (url.isLocalFile()) {

            auto path = fs::path(url.toLocalFile().toStdWString());
            SiAmController::core().mem.loadExt(url.toLocalFile().toStdWString());
            queryRoms();
            copyToLibrary(path);
        }

    } catch (std::exception &e) {

        emit showError("Failed to load Extended ROM.", e.what());
    }
}

void
SiAmConfigController::deleteKickRom()
{
    try {

        SiAmController::core().mem.deleteRom();
        queryRoms();

    } catch (std::exception &e) {

        emit showError("Failed to delete Kickstart ROM.", e.what());
    }
}

void
SiAmConfigController::deleteExtRom()
{
    try {

        SiAmController::core().mem.deleteExt();
        queryRoms();

    } catch (std::exception &e) {

        emit showError("Failed to delete Extended ROM.", e.what());
    }
}

void
SiAmConfigController::queryRoms()
{
    auto &core = SiAmController::core();

    kickRom = core.mem.getRomTraits();
    extRom  = core.mem.getExtTraits();

    emit romConfigChanged();
}

QUrl
SiAmConfigController::getRomIcon(const RomTraits &traits) const
{
    auto hasRom = traits.crc != 0;

    if (traits.type == RomType::AMIGA_DEMO) return Assets::getIconUrl(Assets::Icon::RomDemo);
    if (traits.type == RomType::AMIGA_DIAG) return Assets::getIconUrl(Assets::Icon::RomDiag);

    switch (traits.vendor) {

        case RomVendor::COMMODORE: return Assets::getIconUrl(Assets::Icon::RomCommodore);
        case RomVendor::AROS:      return Assets::getIconUrl(Assets::Icon::RomAros);
        case RomVendor::HYPERION:  return Assets::getIconUrl(Assets::Icon::RomHyperion);
        case RomVendor::EMUTOS:    return Assets::getIconUrl(Assets::Icon::RomEmutos);
        default:                   return Assets::getIconUrl(hasRom ? Assets::Icon::RomUnknown : Assets::Icon::RomPlain);
    }
}

QString
SiAmConfigController::getRomVendor(const RomTraits &traits) const
{
    return QString::fromUtf8(RomVendorEnum::key(traits.vendor));
}

std::vector<RomTraits>
SiAmConfigController::availableRoms(bool extOnly) const
{
    auto &romManager = RomManager::shared();

    // Restrict to entries the folder scan actually found a file for -- the
    // database also knows about Roms the user doesn't have
    auto matches = romManager.getRoms([extOnly](const RomTraits &t) {

        if (t.platform != RomPlatform::Amiga) return false;
        return extOnly ? (t.type == RomType::AMIGA_EXTROM) : (t.type != RomType::AMIGA_EXTROM);
    });

    std::vector<RomTraits> result;
    for (auto &traits : matches) {
        if (romManager.getRom(traits)) result.push_back(traits);
    }

    return result;
}

QStringList
SiAmConfigController::availableRomNames(bool extOnly) const
{
    QStringList result;

    for (auto &traits : availableRoms(extOnly)) {

        auto name = QString::fromUtf8(traits.title);
        if (traits.revision && *traits.revision) name += " (" + QString::fromUtf8(traits.revision) + ")";
        result << name;
    }

    return result;
}

void
SiAmConfigController::installKickRom(int index)
{
    auto roms = availableRoms(false);
    if (index < 0 || index >= (int)roms.size()) return;

    auto path = RomManager::shared().getRom(roms[(size_t)index]);
    if (!path) return;

    loadKickRom(QUrl::fromLocalFile(QString::fromStdString(path->string())));
}

void
SiAmConfigController::installExtRom(int index)
{
    auto roms = availableRoms(true);
    if (index < 0 || index >= (int)roms.size()) return;

    auto path = RomManager::shared().getRom(roms[(size_t)index]);
    if (!path) return;

    loadExtRom(QUrl::fromLocalFile(QString::fromStdString(path->string())));
}

void
SiAmConfigController::copyToLibrary(const fs::path &path) const
{
    auto traits = RomManager::shared().resolve(path);
    if (!traits) return;

    auto checksum = traits->crc ? QString::number(traits->crc, 16) : QString::number(traits->fnv, 16);
    auto dest = fs::path(SiAmController::romLibraryDir().toStdString()) / (checksum.toStdString() + ".rom");

    // Already there -- e.g. installKickRom()/installExtRom() reinstalling a
    // library Rom, which loads straight from this same file
    if (path == dest) return;

    std::error_code ec;
    fs::copy_file(path, dest, fs::copy_options::overwrite_existing, ec);
}

i64
SiAmConfigController::get(vamiga::Opt opt) const
{
    try { return SiAmController::core().get(opt); } catch (...) { return 0; }
}

i64
SiAmConfigController::get(vamiga::Opt opt, long id) const
{
    try { return SiAmController::core().get(opt, id); } catch (...) { return 0; }
}

void
SiAmConfigController::set(vamiga::Opt opt, i64 newValue)
{
    try { SiAmController::core().set(opt, newValue); } catch (...) { }
}

void
SiAmConfigController::set(vamiga::Opt opt, i64 newValue, long id)
{
    try { SiAmController::core().set(opt, newValue, id); } catch (...) { }
}

void
SiAmConfigController::restoreDefaults(Opt opt, std::vector<isize> objids)
{
    auto &core = SiAmController::core();
    auto &defaults = VAmiga::defaults;

    // Erasing the user's entry makes get() report the factory fallback again.
    try {

        if (objids.empty()) defaults.remove(opt); else defaults.remove(opt, objids);

    } catch (...) { }

    // Applying that value keeps the running machine -- and the panel bound to
    // it -- in step with the storage. It's best-effort and guarded per item:
    // the core refuses some values depending on machine state, and one
    // refusal must not stop the remaining items from being restored.
    if (objids.empty()) {

        try { core.set(opt, defaults.get(opt)); } catch (...) { }

    } else {

        for (auto id : objids) {

            try { core.set(opt, defaults.get(opt, id), id); } catch (...) { }
        }
    }
}

void
SiAmConfigController::restoreHardwareDefaults()
{
    restoreDefaults(Opt::AMIGA_VIDEO_FORMAT);
    restoreDefaults(Opt::AGNUS_REVISION);
    restoreDefaults(Opt::AGNUS_PTR_DROPS);
    restoreDefaults(Opt::DENISE_REVISION);
    restoreDefaults(Opt::DENISE_SHRES_BLEND);
    restoreDefaults(Opt::DENISE_VIEWPORT_TRACKING);
    restoreDefaults(Opt::DENISE_FRAME_SKIPPING);
    restoreDefaults(Opt::CPU_REVISION);
    restoreDefaults(Opt::CPU_OVERCLOCKING);
    restoreDefaults(Opt::CPU_RESET_VAL);
    restoreDefaults(Opt::RTC_MODEL);
    restoreDefaults(Opt::MEM_BUS_WIDTH);
    restoreDefaults(Opt::MEM_CHIP_RAM);
    restoreDefaults(Opt::MEM_SLOW_RAM);
    restoreDefaults(Opt::MEM_FAST_RAM);
    restoreDefaults(Opt::MEM_EXT_START);
    restoreDefaults(Opt::MEM_SLOW_RAM_DELAY);
    restoreDefaults(Opt::MEM_SLOW_RAM_MIRROR);
    restoreDefaults(Opt::MEM_BANKMAP);
    restoreDefaults(Opt::MEM_UNMAPPING_TYPE);
    restoreDefaults(Opt::MEM_RAM_INIT_PATTERN);
    restoreDefaults(Opt::MEM_SAVE_ROMS);
    restoreDefaults(Opt::BLITTER_ACCURACY);
    restoreDefaults(Opt::CIA_REVISION, { CiaA, CiaB });
    restoreDefaults(Opt::DIAG_BOARD);

    emit configChanged();
}

void
SiAmConfigController::restoreDevicesDefaults()
{
    static const std::vector<isize> drives = { 0, 1, 2, 3 };
    static const std::vector<isize> hds    = { 0, 1, 2, 3 };
    static const std::vector<isize> cias   = { CiaA, CiaB };
    static const std::vector<isize> ports  = { Port1, Port2 };

    restoreDefaults(Opt::DRIVE_CONNECT, drives);
    restoreDefaults(Opt::DRIVE_TYPE, drives);
    restoreDefaults(Opt::DRIVE_MECHANICS, drives);
    restoreDefaults(Opt::HDC_CONNECT, hds);
    restoreDefaults(Opt::HDR_TYPE, hds);
    restoreDefaults(Opt::CIA_TODBUG, cias);
    restoreDefaults(Opt::SER_DEVICE);
    restoreDefaults(Opt::SER_VERBOSE);
    restoreDefaults(Opt::MIDI_DEVICE_OUT);
    restoreDefaults(Opt::MIDI_DEVICE_IN);
    restoreDefaults(Opt::KBD_ACCURACY);
    restoreDefaults(Opt::MOUSE_PULLUP_RESISTORS, ports);
    restoreDefaults(Opt::MOUSE_SHAKE_DETECTION, ports);
    restoreDefaults(Opt::MOUSE_VELOCITY, ports);
    restoreDefaults(Opt::JOY_AUTOFIRE, ports);
    restoreDefaults(Opt::JOY_AUTOFIRE_BURSTS, ports);
    restoreDefaults(Opt::JOY_AUTOFIRE_BULLETS, ports);
    restoreDefaults(Opt::JOY_AUTOFIRE_DELAY, ports);

    emit configChanged();
}

void
SiAmConfigController::restorePerformanceDefaults()
{
    static const std::vector<isize> cias = { CiaA, CiaB };

    restoreDefaults(Opt::AMIGA_WARP_MODE);
    restoreDefaults(Opt::AMIGA_WARP_BOOT);
    restoreDefaults(Opt::AMIGA_VSYNC);
    restoreDefaults(Opt::AMIGA_SPEED_BOOST);
    restoreDefaults(Opt::AMIGA_RUN_AHEAD);
    restoreDefaults(Opt::CIA_IDLE_SLEEP, cias);
    restoreDefaults(Opt::CIA_ECLOCK_SYNCING, cias);
    restoreDefaults(Opt::DC_SPEED);
    restoreDefaults(Opt::DC_LOCK_DSKSYNC);
    restoreDefaults(Opt::DC_AUTO_DSKSYNC);

    emit configChanged();
}

void
SiAmConfigController::restoreAudioDefaults()
{
    static const std::vector<isize> drives = { 0, 1, 2, 3 };
    static const std::vector<isize> hds    = { 0, 1, 2, 3 };

    restoreDefaults(Opt::AUD_VOL0);
    restoreDefaults(Opt::AUD_VOL1);
    restoreDefaults(Opt::AUD_VOL2);
    restoreDefaults(Opt::AUD_VOL3);
    restoreDefaults(Opt::AUD_PAN0);
    restoreDefaults(Opt::AUD_PAN1);
    restoreDefaults(Opt::AUD_PAN2);
    restoreDefaults(Opt::AUD_PAN3);
    restoreDefaults(Opt::AUD_VOLL);
    restoreDefaults(Opt::AUD_VOLR);
    restoreDefaults(Opt::AUD_FILTER_TYPE);
    restoreDefaults(Opt::AUD_BUFFER_SIZE);
    restoreDefaults(Opt::AUD_SAMPLING_METHOD);
    restoreDefaults(Opt::AUD_ASR);
    restoreDefaults(Opt::AUD_FASTPATH);
    restoreDefaults(Opt::DRIVE_PAN, drives);
    restoreDefaults(Opt::DRIVE_STEP_VOLUME, drives);
    restoreDefaults(Opt::DRIVE_POLL_VOLUME, drives);
    restoreDefaults(Opt::DRIVE_INSERT_VOLUME, drives);
    restoreDefaults(Opt::DRIVE_EJECT_VOLUME, drives);
    restoreDefaults(Opt::HDR_PAN, hds);
    restoreDefaults(Opt::HDR_STEP_VOLUME, hds);

    emit configChanged();
}

void
SiAmConfigController::restoreVideoDefaults()
{
    restoreDefaults(Opt::MON_PALETTE);
    restoreDefaults(Opt::MON_BRIGHTNESS);
    restoreDefaults(Opt::MON_CONTRAST);
    restoreDefaults(Opt::MON_SATURATION);
    restoreDefaults(Opt::MON_CENTER);
    restoreDefaults(Opt::MON_HCENTER);
    restoreDefaults(Opt::MON_VCENTER);
    restoreDefaults(Opt::MON_ZOOM);
    restoreDefaults(Opt::MON_HZOOM);
    restoreDefaults(Opt::MON_VZOOM);

    emit configChanged();
}

void
SiAmConfigController::restoreServerDefaults()
{
    // Every server option is registered per server (ServerType: 0 = RSH,
    // 1 = RPC, 2 = GDB, 3 = PROM, 4 = SER), matching the per-server
    // accessors above.
    static const std::vector<isize> servers = { Rsh, Rpc, Gdb, Prom, Ser };

    restoreDefaults(Opt::SRV_ENABLE, servers);
    restoreDefaults(Opt::SRV_TRANSPORT, servers);
    restoreDefaults(Opt::SRV_PORT, servers);
    restoreDefaults(Opt::SRV_VERBOSE, servers);

    emit configChanged();
}

QColor
SiAmConfigController::dmaColor(Opt opt) const
{
    // vAmiga packs DMA_DEBUG_COLORx as r<<24 | g<<16 | b<<8 (see
    // RgbColor(u32 rgba) in Core/Components/Denise/Colors.h) -- a different
    // layout than SiC64ConfigController::dmaColor's r<<16 | g<<8 | b, so
    // that shift pattern can't be copied verbatim here.
    u32 v = (u32)get(opt);
    return QColor((v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF);
}

void
SiAmConfigController::setDmaColor(Opt opt, const QColor &c)
{
    set(opt, (i64(c.red()) << 24) | (i64(c.green()) << 16) | (i64(c.blue()) << 8));
}
