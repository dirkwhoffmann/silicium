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

void
SiAmMediaController::attachHd(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            SiAmController::core().hd[nr]->attach(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to attach hard drive.", e.what());
    }
}

int
SiAmMediaController::hdCapacityLimit(int nr) const
{
    return (int)SiAmController::core().get(Opt::HDC_MB_LIMIT, nr);
}

int
SiAmMediaController::hdFileSystemLimit() const
{
    /* 4 GB, the largest volume OFS and FFS can address.
     *
     * Past it a drive is still created, just without a file system (see the
     * dialog). rvlib judges a volume's capacity for itself in
     * FSDescriptor::checkCompatibility() -- if that rule changes, this is
     * the number to bring back into step with it.
     */
    return 4096;
}

bool
SiAmMediaController::newHardDisk(int nr, int megabytes, int fsFormat, const QString &name,
                                 const QUrl &importUrl)
{
    const auto path = parent->workspaceFolder() / hdImageName(nr, {}).toStdString();
    bool written = false;

    try {

        auto &core = SiAmController::core();
        auto fs = amiga::FSFormat(fsFormat);
        auto geometry = retro::vault::GeometryDescriptor(isize(megabytes) * 1024 * 1024);

        /* Lay down the file the drive will live on.
         *
         * Written as a hole rather than as that many zero bytes: the file
         * system records the size and nothing else, so a 2 GB drive appears
         * at once and costs what is actually stored in it. An empty file
         * carries no rigid disk block, which is exactly right -- HDFFile
         * then takes the geometry from the size, and it is the geometry
         * computed above.
         */
        {
            std::ofstream os(path, std::ios::binary | std::ios::trunc);
            if (!os) throw utl::IOError(utl::IOError::FILE_CANT_CREATE, path);

            os.seekp(geometry.numBytes() - 1);
            os.put('\0');
            os.close();

            if (!os) throw utl::IOError(utl::IOError::FILE_CANT_WRITE, path);
            written = true;
        }

        /* Straight after writing it, so that a drive already sitting on this
         * very file reads from it for as short a time as possible -- the
         * attach replaces that drive outright, and the reset below sends the
         * machine round again regardless.
         */
        core.hd[nr]->attach(path);
        core.hd[nr]->format(fs, name.toStdString());

        if (fs != amiga::FSFormat::NODOS && importUrl.isLocalFile()) {
            core.hd[nr]->importFiles(fs::path(importUrl.toLocalFile().toStdWString()));
        }

        /* The file holds nothing but the hole until this. Formatting works on
         * the drive, and a drive only writes back when it is told to or when
         * HDR_WRITE_THROUGH says so -- which by default it does not.
         */
        core.hd[nr]->persist();

        /* Same two steps the drop path takes once an image is in place (see
         * copyAndAttachHd): plug the controller in, then send the machine
         * round again, because a drive that was not there at boot time is a
         * drive the Amiga has not seen.
         */
        if (!core.get(Opt::HDC_CONNECT, nr)) core.set(Opt::HDC_CONNECT, true, nr);
        core.hardReset();
        core.sync();

        // Write the machine out, so config.retrosh carries the attach line
        // and the drive is still there the next time the SVM is opened.
        parent->saveWorkspaceNow();

        /* A drive this large is the machine's alone.
         *
         * It lives in a file either way, and a disk in a file is stored in a
         * snapshot as its path (see HardDrive::snapshotable) -- but past
         * HDR_SNAPSHOT_LIMIT it would not be stored even if it were held in
         * memory, so a snapshot taken now is worth nothing without the SVM
         * beside it. Said once, here, rather than left to be discovered.
         */
        if (const auto limit = core.get(Opt::HDR_SNAPSHOT_LIMIT, nr); limit && megabytes > limit) {

            showNotification(tr("Hard drive too large for snapshots"),
                             tr("At %1 MB, hd%2 is past the %3 MB a snapshot stores. "
                                "It is kept in the virtual machine folder only.")
                                 .arg(megabytes).arg(nr).arg(limit));
        }

        return true;

    } catch (const std::exception &e) {

        /* Leave no image behind that nothing asked for.
         *
         * The file is laid down before the drive can be attached, let alone
         * formatted, so a failure past that point would otherwise leave the
         * whole requested size sitting in the machine's folder for a drive
         * the user never got.
         */
        if (written) {

            std::error_code ec;
            fs::remove(path, ec);
        }

        showError("Failed to create hard drive.", e.what());
        return false;
    }
}

QString
SiAmMediaController::hdImageName(int nr, const QUrl &url) const
{
    /* Always .hdf, whatever was dropped. A .hdz is unpacked on the way in
     * (see copyAndAttachHd), so what ends up in the workspace is a plain
     * image, which is what saveWorkspace() writes too.
     */
    (void)url;
    return QString("hd%1.hdf").arg(nr);
}

QString
SiAmMediaController::hdExistingImage(int nr) const
{
    /* Both suffixes are checked. New workspaces are written uncompressed, but
     * an SVM made before that carries .hdz images, and they still load -- so
     * what this slot holds may be either, whatever is being dropped on it.
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

    const auto src = fs::path(url.toLocalFile().toStdWString());
    const auto dest = parent->workspaceFolder() / hdImageName(nr, url).toStdString();

    /* The whole operation runs on the task, not just the copy.
     *
     * Everything here is allowed off the main thread: the emulator's public
     * API asks only that the caller is not the emulator thread itself
     * (Thread::isUserThread), and the calls that suspend it -- attach,
     * loadIntoMemory, saveWorkspace -- are the only suspending calls in
     * flight, because what the window does every frame merely reads.
     */
    runTask(tr("Copying the hard drive into the virtual machine..."),
            tr("Failed to attach hard drive."),
            [this, nr, src, dest] {

        auto &core = SiAmController::core();

        /* Let the drive that is there now go of the file.
         *
         * A hard drive reads its image lazily, straight from the file, so
         * overwriting the file underneath it would corrupt the drive still
         * using it. loadIntoMemory() takes the contents into RAM and drops
         * the file.
         */
        report(tr("Releasing the current hard drive..."));

        std::error_code ec;
        if (fs::equivalent(core.hd[nr]->path(), dest, ec)) core.hd[nr]->loadIntoMemory();

        /* Reading the image is what validates it: a file that turns out not
         * to be a hard drive image, or cannot be read, fails here, before
         * anything has been written. It is also what unpacks a .hdz, since
         * HDFFile puts a gzip backing under a compressed file.
         *
         * It is one opaque call with nowhere to report from, so the bar sits
         * where it is until this returns. For an image with a rigid disk
         * block that is no time at all; for one without, HDFLayout scans the
         * whole file looking for a root block, and it is the bulk of the job.
         */
        report(tr("Reading the disk image..."), 0.02);
        auto image = std::make_unique<HDFFile>(src);

        // Writing the image is the long part, so it gets most of the bar.
        constexpr double copyShare = 0.88;
        constexpr isize chunk = 1024 * 1024;
        const auto total = image->getSize();

        report(tr("Copying the disk image..."), 0.02);

        std::ofstream os(dest, std::ios::binary);
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
        image.reset();

        report(tr("Attaching the hard drive..."), 0.90);
        core.hd[nr]->attach(dest);

        /* Plug the controller in afterwards, not before: the drive is ready
         * by the time anything can look at it, and nothing done here to the
         * drive overlaps a command being drained on the emulator thread.
         */
        if (!core.get(Opt::HDC_CONNECT, nr)) core.set(Opt::HDC_CONNECT, true, nr);

        /* A hard reset rather than a power cycle. The machine has to go round
         * again to notice a drive that was not there when it booted, but it
         * does not have to be switched off to do that, and a reset is the
         * milder of the two.
         */
        core.hardReset();

        /* Wait for all of that to have happened before writing the machine
         * out. Option changes and the reset are handed to the emulator thread
         * and take effect a frame or so later, so without this the exported
         * configuration can still describe a machine with no hard drive
         * controller.
         */
        core.sync();

        report(tr("Persisting the virtual machine..."), 0.95);

        /* Write the machine out, so config.retrosh carries the attach line and
         * the drive is still there the next time the SVM is opened. The file
         * just written is left alone -- see Amiga::saveWorkspace(), which
         * keeps the image a drive is sitting on.
         */
        parent->saveWorkspaceNow();
    });
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
