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
#include "HDFFile.h"
#include <QFileInfo>
#include "SiAmController.h"
#include "Config/SiAmConfigController.h"
#include <QFile>
#include <fstream>
#include <unistd.h>

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

        showError("Failed to insert disk.", e.what());
    }
}

QString
SiAmMediaController::driveCapacity(int nr) const
{
    switch (SiAmController::core().df[nr]->getConfig().type) {

        case FloppyDriveType::DD_35:    return "3.5\" DD";
        case FloppyDriveType::HD_35:    return "3.5\" HD";
        case FloppyDriveType::DD_525:   return "5.25\" DD";
    }
    return "";
}

bool
SiAmMediaController::driveHighDensity(int nr) const
{
    return SiAmController::core().df[nr]->getConfig().type == FloppyDriveType::HD_35;
}

void
SiAmMediaController::newDisk(int nr, int fsFormat, int bootBlock, const QString &name)
{
    try {

        auto fs = amiga::FSFormat(fsFormat);
        auto bb = amiga::BootBlockId(bootBlock);

        SiAmController::core().df[nr]->insertBlankDisk(fs, bb, name.toStdString());

    } catch (const std::exception &e) {

        showError("Failed to create disk.", e.what());
    }
}

void
SiAmMediaController::ejectDisk(int nr)
{
    try {

        SiAmController::core().df[nr]->ejectDisk();

    } catch (const std::exception &e) {

        showError("Failed to eject disk.", e.what());
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

        showError("Failed to export disk.", e.what());
    }
}

void
SiAmMediaController::toggleWriteProtection(int nr)
{
    try {

        auto &drive = *SiAmController::core().df[nr];
        drive.setFlag(DiskFlags::PROTECTED, !drive.getFlag(DiskFlags::PROTECTED));

    } catch (const std::exception &e) {

        showError("Failed to change write protection.", e.what());
    }
}

bool
SiAmMediaController::hdHasDisk(int nr) const
{
    return SiAmController::core().hd[nr]->getInfo().hasDisk;
}

int
SiAmMediaController::hdCapacityLimit(int nr) const
{
    return (int)SiAmController::core().get(Opt::HDC_MB_LIMIT, nr);
}

int
SiAmMediaController::hdFileSystemLimit() const
{
    return 4096; // 4 GB
}

QString
SiAmMediaController::hdExistingImage(int nr) const
{
    try {

        auto name = QString("hd%1.hdf").arg(nr);
        auto folder = parent->workspaceFolder();

        if (fs::exists(folder / name.toStdString())) return name;

    } catch (...) { }

    return "";
}

/*
fs::path
SiAmMediaController::hdImagePath(int nr) const
{
    auto imageName = QString("hd%1.hdf").arg(nr);
    return parent->workspaceFolder() / imageName.toStdString();
}
*/

void
SiAmMediaController::attachHdAsync(int nr, const QUrl &url)
{
    if (!url.isLocalFile()) return;

    fs::path wspace = parent->workspaceFolder();
    fs::path source = url.toLocalFile().toStdWString();
    fs::path target = wspace / ("hd" + std::to_string(nr) + ".hdf");

    runTask(tr("Copying the hard drive into the virtual machine..."),
            tr("Failed to attach hard drive."),
            [this, nr, source, target] {

                // Copy the hard drive image into the virtual machine folder
                fs::copy_file(source, target, fs::copy_options::overwrite_existing);

                // Attach the copied image
                attachHd(nr, target);
            },
            [this, nr] {

                // Show warning if a large hard drive has been attached
                checkForLargeDrive(nr);
            });
}

void
SiAmMediaController::attachHdAsync(int nr, int megabytes, int fsFormat, const QString &name,
                                   const QUrl &importUrl)
{
    fs::path wspace = parent->workspaceFolder();
    fs::path target = wspace / ("hd" + std::to_string(nr) + ".hdf");

    runTask(tr("Creating the hard drive..."),
            tr("Failed to create hard drive."),
            [this, nr, megabytes, fsFormat, name, importUrl, target] {

                // Create new HDF
                createHd(nr, megabytes, fsFormat, name, importUrl);

                // Attach the copied image
                attachHd(nr, target);
            },
            [this, nr] {

                // Show warning if a large hard drive has been attached
                checkForLargeDrive(nr);
            });
}

void
SiAmMediaController::checkForLargeDrive(int nr)
{
    auto &core = SiAmController::core();
    auto &info = core.hd[nr]->getInfo();

    if (info.hasDisk && !info.snapshotable) {

        const auto limit = (int)SiAmController::core().get(Opt::HDR_SNAPSHOT_LIMIT, nr);
        showNotification(tr("Large hard drive attached"),
                         tr("hd%1 exceeds the %2 MB limits a snapshot stores. "
                             "It is kept in the virtual machine folder only.")
                         .arg(nr).arg(limit));
    }
}

/*
void
SiAmMediaController::copyHd(int nr, const QUrl &url)
{
    auto &core = SiAmController::core();

    const auto src = fs::path(url.toLocalFile().toStdWString());
    const auto dest = hdImagePath(nr);

    report(tr("Releasing the current hard drive..."));

    std::error_code ec;
    if (fs::equivalent(core.hd[nr]->path(), dest, ec)) core.hd[nr]->loadIntoMemory();

    report(tr("Reading the disk image..."), 0.02);
    auto image = std::make_unique<HDFFile>(src);

    // Writing the image is the long part, so it gets most of the bar.
    constexpr double copyShare = 0.85;
    constexpr isize chunk = 1024 * 1024;
    const auto total = image->getSize();

    report(tr("Copying the disk image..."), 0.02);

    std::ofstream os(dest, std::ios::binary | std::ios::trunc);
    if (!os) throw utl::IOError(utl::IOError::FILE_CANT_CREATE, dest);

    try {
        for (isize offset = 0; offset < total; offset += chunk) {

            const auto len = std::min(chunk, total - offset);
            image->writeToStream(os, offset, len);

            report(tr("Copying the disk image..."),
                   0.02 + copyShare * double(offset + len) / double(total));
        }

        os.close();
        if (!os) throw utl::IOError(utl::IOError::FILE_CANT_WRITE, dest);

    } catch (...) {

        // Leave no half-written image behind: it would look like one the
        // next launch could attach.
        os.close();
        fs::remove(dest, ec);
        throw;
    }
}
*/

void
SiAmMediaController::createHd(int nr, int megabytes, int fsFormat, const QString &name,
                              const QUrl &importUrl)
{
    auto &core = SiAmController::core();
    auto fsType = amiga::FSFormat(fsFormat);
    auto geometry = retro::vault::GeometryDescriptor(isize(megabytes) * 1024 * 1024);

    report(tr("Creating the disk image..."), 0.05);

    fs::path wspace = parent->workspaceFolder();
    fs::path target = wspace / ("hd" + std::to_string(nr) + ".hdf");

    if (!utl::createEmptyFile(target, geometry.numBytes())) {
        throw utl::IOError(utl::IOError::FILE_CANT_CREATE, target);
    }

    try {

        report(tr("Attaching the hard drive..."), 0.15);
        core.hd[nr]->attach(target);

        report(tr("Creating the file system..."), 0.25);
        core.hd[nr]->format(fsType, name.toStdString());

        if (fsType != amiga::FSFormat::NODOS && importUrl.isLocalFile()) {

            report(tr("Importing files..."), 0.45);
            core.hd[nr]->importFiles(fs::path(importUrl.toLocalFile().toStdWString()));
        }

        report(tr("Writing the disk image..."), 0.60);
        core.hd[nr]->persist();

    } catch (...) {

        // Remove file if anything went wrong
        std::error_code ec;
        fs::remove(target, ec);
        throw;
    }
}

void
SiAmMediaController::attachHd(int nr, const QUrl &url)
{
    attachHd(nr, fs::path(url.toLocalFile().toStdWString()));
}

void
SiAmMediaController::attachHd(int nr, const fs::path &path)
{
    auto &core = SiAmController::core();

    report(tr("Attaching the hard drive..."), 0.90);
    core.hd[nr]->attach(path);

    /* Plug the controller in afterwards, not before: the drive is ready by
     * the time anything can look at it, and nothing done here to the drive
     * overlaps a command being drained on the emulator thread.
     */
    if (!core.get(Opt::HDC_CONNECT, nr)) core.set(Opt::HDC_CONNECT, true, nr);

    /* A hard reset rather than a power cycle. The machine has to go round
     * again to notice a drive that was not there when it booted, but it does
     * not have to be switched off to do that, and a reset is the milder of
     * the two.
     */
    core.hardReset();

    /* Wait for all of that to have happened before writing the machine out.
     * Option changes and the reset are handed to the emulator thread and take
     * effect a frame or so later, so without this the exported configuration
     * can still describe a machine with no hard drive controller.
     */
    core.sync();

    report(tr("Persisting the virtual machine..."), 0.95);

    /* Write the machine out, so config.retrosh carries the attach line and the
     * drive is still there the next time the SVM is opened. The image itself
     * is left alone -- see Amiga::saveWorkspace(), which keeps the file a
     * drive is sitting on.
     */
    parent->saveWorkspaceNow();
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

        showError("Failed to export hard drive.", e.what());
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
    // REMOVE ASAP
    runTask(tr("Hello, world..."),
            tr("Failed"),
            [this] {
                report(tr("Some task..."));
                sleep(3);
                report(tr("Another task..."));
                sleep(2);
                report(tr("Yet another task..."));
                sleep(2);
            });

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
