// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmMediaController.h"
#include "SiTask.h"
#include "SVMFile.h"
#include "HDFFile.h"
#include <QFileInfo>
#include "SiAmController.h"
#include "Config/SiAmConfigController.h"
#include <QFile>

using namespace vamiga;

SiAmMediaController::SiAmMediaController(SiAmController *parent)
    : Controller(parent), parent(parent)
{
    m_task = new SiTask(this);
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

QObject *
SiAmMediaController::task() const
{
    return m_task;
}

void
SiAmMediaController::copyAndAttachHd(int nr, const QUrl &url)
{
    if (!url.isLocalFile()) return;
    if (m_task->running()) return;

    const auto src = fs::path(url.toLocalFile().toStdWString());
    const auto dest = parent->workspaceFolder() / hdImageName(nr, url).toStdString();

    auto core = SiAmController::core();

    try {
        // Power off the emulator
        printf("Powering off (%d)...\n", core.isPoweredOff());
        core.powerOff();
        printf("Power(0) = %d\n", core.isPoweredOff());

        // Wait for the emulator to power off
        core.sync();
        printf("Power(1) = %d\n", core.isPoweredOff());

        // Copy HDF into the SVM
        printf("Copying file");
        std::error_code ec;
        if (!fs::copy_file(src, dest, fs::copy_options::overwrite_existing, ec)) {
            printf("COPY FAILED\n");
        }

        // Make sure a hard-drive controller is installed
        printf("Connecting hard-drive controller\n");
        core.set(Opt::HDC_CONNECT, true, nr);

        // Attach hard drive
        printf("Attaching hard drive...\n");
        core.hd[nr]->attach(dest);

        // Relaunch
        printf("Run...\n");
        core.run();
        printf("After run...\n");

    } catch (const std::exception &e) {

        printf("EXCEPTION: %s\n", e.what());
    }

#if 0
    /* Let the drive that is there now go of the file before the worker starts
     * on it.
     *
     * A hard drive reads its image lazily, straight from the file, so
     * overwriting the file underneath it would corrupt the drive that is
     * still using it. loadIntoMemory() takes the contents into RAM and drops
     * the file. It happens here rather than in the worker because it touches
     * the machine, and the machine belongs to this thread.
     */
    try {
        std::error_code ec;
        if (fs::equivalent(SiAmController::core().hd[nr]->path(), dest, ec)) {
            SiAmController::core().hd[nr]->loadIntoMemory();
        }

    } catch (const std::exception &e) {

        showError("Failed to copy the hard drive.", e.what());
        return;
    }

    connect(m_task, &SiTask::finished, this,
            [this, nr, dest](bool ok, bool cancelled, const QString &error) {

        // One shot: the next drop connects its own handler
        disconnect(m_task, &SiTask::finished, this, nullptr);

        if (cancelled) return;

        if (!ok) {
            showError("Failed to copy the hard drive.", error);
            return;
        }
        installCopiedHd(nr, dest);
    });

    m_task->run(tr("Copying the hard drive into the virtual machine..."),
                [src, dest](utl::Progress &progress) {

        /* Reading the image is what validates it: a file that turns out not
         * to be a hard drive image, or cannot be read, fails here, before
         * anything has been written. It is also what unpacks a .hdz, since
         * HDFFile puts a gzip backing under a compressed file -- which is why
         * the total is only known afterwards, and the bar runs indeterminate
         * until then.
         */
        auto image = std::make_unique<HDFFile>(src);
        progress.check();

        const auto total = image->getSize();
        progress.setTotal(total);

        /* Written a chunk at a time rather than in one call, so that there is
         * something to report and somewhere to stop.
         */
        constexpr isize chunk = 1024 * 1024;

        std::ofstream os(dest, std::ios::binary);
        if (!os) throw utl::IOError(utl::IOError::FILE_CANT_CREATE, dest);

        try {
            for (isize offset = 0; offset < total; offset += chunk) {

                progress.check();

                const auto len = std::min(chunk, total - offset);
                image->writeToStream(os, offset, len);
                progress.advance(len);
            }

            os.close();
            if (!os) throw utl::IOError(utl::IOError::FILE_CANT_WRITE, dest);

        } catch (...) {

            // Leave no half-written image behind: it would look like one the
            // next launch could attach.
            os.close();
            std::error_code ec;
            fs::remove(dest, ec);
            throw;
        }
    });
#endif
}

void
SiAmMediaController::installCopiedHd(int nr, const fs::path &dest)
{
    try {
        auto &core = SiAmController::core();

        core.hd[nr]->attach(dest);

        /* Plug the controller in afterwards, not before: the drive is ready
         * by the time anything can look at it, and nothing this thread does
         * to the drive overlaps a command being drained on the other one.
         * Suspending would not help with that -- it stops frames from
         * running, not commands from being processed.
         */
        auto *config = parent->getConfigController();
        if (!config->hdConnected(nr)) config->setHdConnected(nr, true);

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

        /* Write the machine out, so config.retrosh carries the attach line and
         * the drive is still there the next time the SVM is opened. The file
         * just written is left alone -- see Amiga::saveWorkspace(), which
         * keeps the image a drive is sitting on.
         */
        parent->saveWorkspace();

    } catch (const std::exception &e) {

        showError("Failed to attach the hard drive.", e.what());
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
