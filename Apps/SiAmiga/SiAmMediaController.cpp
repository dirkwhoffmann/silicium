// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmMediaController.h"
#include "SVMFile.h"
#include <QFileInfo>
#include "SiAmController.h"
#include "Config/SiAmConfigController.h"
#include <QFile>

using namespace vamiga;

SiAmMediaController::SiAmMediaController(SiAmController *parent)
    : Controller(parent), parent(parent)
{

}

bool
SiAmMediaController::driveHasDisk(int nr) const
{
    return SiAmController::core().df[nr]->getInfo().hasDisk;
}

bool
SiAmMediaController::driveWriteProtected(int nr) const
{
    return SiAmController::core().df[nr]->getInfo().hasProtectedDisk;
}

bool
SiAmMediaController::driveModified(int nr) const
{
    return SiAmController::core().df[nr]->getInfo().hasModifiedDisk;
}

bool
SiAmMediaController::driveMotor(int nr) const
{
    return SiAmController::core().df[nr]->getInfo().motor;
}

bool
SiAmMediaController::driveWriting(int nr) const
{
    return SiAmController::core().df[nr]->getInfo().writing;
}

int
SiAmMediaController::driveTrack(int nr) const
{
    return (int)SiAmController::core().df[nr]->getInfo().head.track();
}

void
SiAmMediaController::insertDisk(int nr, const QUrl &url, bool wp)
{
    try {

        if (url.isLocalFile()) {
            SiAmController::core().df[nr]->insert(url.toLocalFile().toStdWString(), wp);
        }

    } catch (const std::exception &e) {

        showError("Failed to insert the disk.", e.what());
    }
}

void
SiAmMediaController::newDisk(int nr)
{
    try {

        SiAmController::core().df[nr]->insertBlankDisk(amiga::FSFormat::OFS, amiga::BootBlockId::AMIGADOS_13, "Empty");

    } catch (const std::exception &e) {

        showError("Failed to create a new disk.", e.what());
    }
}

void
SiAmMediaController::ejectDisk(int nr)
{
    try {

        SiAmController::core().df[nr]->ejectDisk();

    } catch (const std::exception &e) {

        showError("Failed to eject the disk.", e.what());
    }
}

void
SiAmMediaController::exportDisk(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            SiAmController::core().df[nr]->writeToFile(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to export the disk.", e.what());
    }
}

void
SiAmMediaController::toggleWriteProtection(int nr)
{
    try {

        auto &drive = *SiAmController::core().df[nr];
        drive.setFlag(DiskFlags::PROTECTED, !drive.getFlag(DiskFlags::PROTECTED));

    } catch (const std::exception &e) {

        showError("Failed to change the write-protection status.", e.what());
    }
}

bool
SiAmMediaController::hdHasDisk(int nr) const
{
    return SiAmController::core().hd[nr]->getInfo().hasDisk;
}

void
SiAmMediaController::attachHd(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            SiAmController::core().hd[nr]->attach(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to attach the hard drive.", e.what());
    }
}

QString
SiAmMediaController::hdImageName(int nr, const QUrl &url) const
{
    /* The suffix follows the dropped file rather than being fixed to .hdf:
     * .hdz is a compressed image, and calling one .hdf would misdescribe it
     * to everything that later opens the SVM (Amiga::saveWorkspace() picks
     * between the same two suffixes for the same reason).
     */
    const QString suffix = QFileInfo(url.fileName()).suffix().toLower();
    return QString("hd%1.%2").arg(nr).arg(suffix == "hdz" ? "hdz" : "hdf");
}

QString
SiAmMediaController::hdExistingImage(int nr) const
{
    /* Both suffixes are checked, and neither is the one being dropped: what
     * this slot already holds was written by saveWorkspace(), which names it
     * .hdz or .hdf depending on WS_COMPRESSION (on by default). Asking only
     * about the incoming file's suffix would miss the existing image almost
     * every time, and the warning would never appear.
     */
    try {
        const auto folder = parent->workspaceFolder();

        for (const auto *suffix : { "hdf", "hdz" }) {

            const auto name = QString("hd%1.%2").arg(nr).arg(suffix);
            if (fs::exists(folder / name.toStdString())) return name;
        }
        return {};

    } catch (const std::exception &) {

        // No workspace means nothing to overwrite. The copy itself reports
        // the failure, so staying quiet here keeps one error per mishap.
        return {};
    }
}

void
SiAmMediaController::copyAndAttachHd(int nr, const QUrl &url)
{
    if (!url.isLocalFile()) return;

    try {
        const auto src = fs::path(url.toLocalFile().toStdWString());
        const auto dest = parent->workspaceFolder() / hdImageName(nr, url).toStdString();

        /* Power off first. A hard drive is not hot-pluggable on a real Amiga
         * either, and the machine may hold unwritten changes to the drive
         * this is about to replace. The dialog that leads here says as much,
         * so the user has already agreed to it.
         */
        SiAmController::core().powerOff();

        /* Copying a file onto itself is an error, not a no-op: re-attaching
         * an image already living in the workspace is a perfectly reasonable
         * thing to drop, and it needs no copy at all.
         */
        std::error_code ec;
        if (!fs::equivalent(src, dest, ec)) {

            fs::copy_file(src, dest, fs::copy_options::overwrite_existing);
        }

        /* Drop whatever this slot held before. Without this a leftover
         * hd0.hdz would sit next to the hd0.hdf just written, and which one
         * the machine picked up next time would come down to the compression
         * setting rather than to what was actually dropped.
         */
        for (const auto *suffix : { "hdf", "hdz" }) {

            const auto stale = parent->workspaceFolder() / ("hd" + std::to_string(nr) + "." + suffix);
            if (!fs::equivalent(stale, dest, ec)) fs::remove(stale, ec);
        }

        /* Plug the controller in if this slot has none. A drive is of no use
         * without one, and the drop zones no longer ask the user to arrange
         * that first. This has to happen while the machine is off, which it
         * now is. It mirrors what 'hdN attach' does in RetroShell.
         */
        auto *config = parent->getConfigController();
        if (!config->hdConnected(nr)) config->setHdConnected(nr, true);

        /* Attach memory-backed, unlike attachHd() above.
         *
         * The image now lives inside the SVM, and saveWorkspace() below
         * rebuilds that folder from scratch (fs::remove_all) before writing
         * the drives back into it. A file-backed drive would be sitting on a
         * file that its own save is about to delete. Floppies are
         * memory-backed for the same reason. The cost is that the image has
         * to fit HDC_MEM_LIMIT (256 MB by default), which reports itself
         * clearly if it does not.
         */
        SiAmController::core().hd[nr]->attach(dest, StorageMode::MEMORY_BACKED);

        /* Write the machine back out. This is what rewrites config.retrosh
         * with the 'hdN attach' line, so the drive is still there the next
         * time the SVM is opened rather than only for this session.
         */
        parent->saveWorkspace();

        // Everything is copied and configured, so bring the machine back up.
        SiAmController::core().powerOn();

    } catch (const std::exception &e) {

        showError("Failed to copy the hard drive.", e.what());
    }
}

void
SiAmMediaController::detachHd(int nr)
{
    parent->getConfigController()->setHdConnected(nr, false);
}

void
SiAmMediaController::exportHd(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            SiAmController::core().hd[nr]->writeToFile(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to export the hard drive.", e.what());
    }
}

QByteArray
SiAmMediaController::readRomResource(const QString &resourcePath)
{
    QFile file(resourcePath);

    if (!file.open(QIODevice::ReadOnly)) {
        throw std::runtime_error(("Missing Rom resource: " + resourcePath).toStdString());
    }

    return file.readAll();
}

void
SiAmMediaController::installAros(quint32 crc32)
{
    try {

        // Ext(ension) is the second half of the pair -- both come from the
        // same AROS build and neither works without the other.
        QString rom, ext;

        switch (crc32) {

            case CRC32_AROS_54705:    rom = "aros-svn54705-rom";  ext = "aros-svn54705-ext";  break; // UAE, May 2017
            case CRC32_AROS_55696:    rom = "aros-svn55696-rom";  ext = "aros-svn55696-ext";  break; // SAE, Feb 2019
            case CRC32_AROS_20250219: rom = "aros-20250219-rom";  ext = "aros-20250219-ext";  break; // Feb 2025
            case CRC32_AROS_20260820: rom = "aros-20260820-rom";  ext = "aros-20260820-ext";  break; // newest

            default:
                throw std::runtime_error("No bundled AROS Rom matches this version.");
        }

        auto romData = readRomResource(":/Roms/" + rom + ".bin");
        auto extData = readRomResource(":/Roms/" + ext + ".bin");
        auto &core = SiAmController::core();

        core.mem.loadRom((const u8 *)romData.constData(), romData.size());
        core.mem.loadExt((const u8 *)extData.constData(), extData.size());

        auto *config = parent->getConfigController();

        // Configure the location of the extension Rom
        config->setExtStart(0xE0);

        // Make sure the machine has enough Ram to run Aros
        if (config->chipRam() + config->slowRam() + config->fastRam() < 1024) {
            config->setSlowRam(512);
        }

        config->queryRoms();

    } catch (const std::exception &e) {

        showError("Failed to install AROS.", e.what());
    }
}

void
SiAmMediaController::installDiagRom(quint32 crc32)
{
    try {

        QString rom;

        switch (crc32) {

            case CRC32_DIAG121: rom = "diagrom-121"; break; // v1.2.1, Jul 2020
            case CRC32_DIAG13:  rom = "diagrom-13";  break; // v1.3, Apr 2023 (newest)

            default:
                throw std::runtime_error("No bundled DiagROM matches this version.");
        }

        auto data = readRomResource(":/Roms/" + rom + ".bin");
        SiAmController::core().mem.loadRom((const u8 *)data.constData(), data.size());

        parent->getConfigController()->queryRoms();

    } catch (const std::exception &e) {

        showError("Failed to install DiagROM.", e.what());
    }
}

void
SiAmMediaController::installEmuTOS()
{
    try {

        // Version 1.3 (March 2024); the only version bundled here.
        auto rom = readRomResource(":/Roms/emutos-13.rom");
        auto &core = SiAmController::core();

        core.mem.loadRom((const u8 *)rom.constData(), rom.size());

        parent->getConfigController()->queryRoms();

    } catch (const std::exception &e) {

        showError("Failed to install EmuTOS.", e.what());
    }
}
