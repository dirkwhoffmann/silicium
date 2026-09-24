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

        showError("Failed to insert disk.", e.what());
    }
}

void
SiAmMediaController::newDisk(int nr)
{
    try {

        SiAmController::core().df[nr]->insertBlankDisk(amiga::FSFormat::OFS, amiga::BootBlockId::AMIGADOS_13, "Empty");

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

    /* Report a failure once, for this drop. The signal arrives on this
     * thread even though the task raised it on its own (see SiTask), so
     * there is nothing to marshal here.
     */
    connect(m_task, &SiTask::failed, this, [this](const QString &error) {

        disconnect(m_task, &SiTask::failed, this, nullptr);
        emit showError("Failed to attach hard drive.", error);
    });
    connect(m_task, &SiTask::finished, this, [this] {

        disconnect(m_task, &SiTask::failed, this, nullptr);
        disconnect(m_task, &SiTask::finished, this, nullptr);
    });

    /* The whole operation runs on the task, not just the copy.
     *
     * Everything here is allowed off the main thread: the emulator's public
     * API asks only that the caller is not the emulator thread itself
     * (Thread::isUserThread), and the calls that suspend it -- attach,
     * loadIntoMemory, saveWorkspace -- are the only suspending calls in
     * flight, because what the window does every frame merely reads.
     */
    m_task->run(tr("Copying the hard drive into the virtual machine..."),
                [this, nr, src, dest](utl::ProgressTask &task) {

        auto &core = SiAmController::core();

        /* Let the drive that is there now go of the file.
         *
         * A hard drive reads its image lazily, straight from the file, so
         * overwriting the file underneath it would corrupt the drive still
         * using it. loadIntoMemory() takes the contents into RAM and drops
         * the file.
         */
        task.setDescription(tr("Releasing the current hard drive...").toStdString());

        std::error_code ec;
        if (fs::equivalent(core.hd[nr]->path(), dest, ec)) core.hd[nr]->loadIntoMemory();
        task.setProgress(0.02);

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
        task.check();
        task.setDescription(tr("Reading the disk image...").toStdString());
        auto image = std::make_unique<HDFFile>(src);
        task.check();

        // Writing the image is the long part, so it gets most of the bar.
        constexpr double copyShare = 0.88;
        constexpr isize chunk = 1024 * 1024;
        const auto total = image->getSize();

        task.setDescription(tr("Copying the disk image...").toStdString());

        std::ofstream os(dest, std::ios::binary);
        if (!os) throw utl::IOError(utl::IOError::FILE_CANT_CREATE, dest);

        try {
            for (isize offset = 0; offset < total; offset += chunk) {

                task.check();

                const auto len = std::min(chunk, total - offset);
                image->writeToStream(os, offset, len);
                task.setProgress(0.02 + copyShare * double(offset + len) / double(total));
            }

            os.close();
            if (!os) throw utl::IOError(utl::IOError::FILE_CANT_WRITE, dest);

            // The last chance to call it off. Past here the machine is being
            // rearranged, and stopping half way would leave it inconsistent.
            task.check();

        } catch (...) {

            // Leave no half-written image behind: it would look like one the
            // next launch could attach.
            os.close();
            fs::remove(dest, ec);
            throw;
        }
        image.reset();

        task.setDescription(tr("Attaching the hard drive...").toStdString());
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
        task.setProgress(0.95);

        task.setDescription(tr("Persisting the virtual machine...").toStdString());

        /* Write the machine out, so config.retrosh carries the attach line and
         * the drive is still there the next time the SVM is opened. The file
         * just written is left alone -- see Amiga::saveWorkspace(), which
         * keeps the image a drive is sitting on.
         */
        parent->saveWorkspace();
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
