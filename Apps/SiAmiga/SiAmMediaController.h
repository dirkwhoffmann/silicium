// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "VAmiga.h"
#include <QByteArray>
#include <QUrl>
#include <QVariantMap>

class SiAmController;

class SiAmMediaController : public Controller {

    Q_OBJECT

    SiAmController *parent = nullptr;

public:

    explicit SiAmMediaController(SiAmController *parent = nullptr);



    //
    // Floppy drives (df0..df3)
    //

    // 'nr' is 0-3 throughout this class' public API, matching the core's
    // df[] indexing (and SiAmConfigController's driveConnected(nr)/
    // setDriveConnected(nr,..)).
    Q_INVOKABLE bool driveHasDisk(int nr) const;
    Q_INVOKABLE bool driveWriteProtected(int nr) const;
    Q_INVOKABLE bool driveModified(int nr) const;
    Q_INVOKABLE bool driveMotor(int nr) const;
    Q_INVOKABLE bool driveWriting(int nr) const;
    Q_INVOKABLE int driveTrack(int nr) const;
    Q_INVOKABLE void insertDisk(int nr, const QUrl &url, bool wp = false);

    // What the drive's model makes of a blank disk. SiAmDiskCreator shows the
    // capacity and picks the disk icon from it -- the geometry itself isn't
    // ours to choose, the core derives it from the drive (FloppyDrive::
    // insertNew) exactly as vAmiga's own FloppyCreator reports it.
    Q_INVOKABLE QString driveCapacity(int nr) const;
    Q_INVOKABLE bool driveHighDensity(int nr) const;

    /* Formats a blank disk and inserts it.
     *
     * 'fsFormat' and 'bootBlock' are raw amiga::FSFormat / amiga::BootBlockId
     * values, which is what SiAmDiskCreator's combo box tags carry -- the
     * enums aren't registered with QML, and listing only the entries worth
     * offering means a position wouldn't identify one anyway.
     */
    Q_INVOKABLE void newDisk(int nr, int fsFormat, int bootBlock, const QString &name);
    Q_INVOKABLE void ejectDisk(int nr);
    Q_INVOKABLE void exportDisk(int nr, const QUrl &url);
    Q_INVOKABLE void toggleWriteProtection(int nr);


    //
    // Hard drives (hd0..hd3)
    //

    Q_INVOKABLE bool hdHasDisk(int nr) const;

    /* What this slot's image is called, and what it already holds.
     *
     * A drive the machine owns lives in the machine's own folder, under the
     * hdN name Amiga::saveWorkspace() uses, so that the image travels with
     * the SVM instead of the machine depending on a path outside it. 'nr'
     * picks the name; the two query calls let the caller warn before
     * anything is overwritten.
     */
    Q_INVOKABLE QString hdImageName(int nr, const QUrl &url) const;
    Q_INVOKABLE QString hdExistingImage(int nr) const;

    /* The largest drive this slot accepts, in MB (0 = no limit).
     *
     * The controller's own limit (Opt::HDC_MB_LIMIT) and nothing else. The
     * memory limit beside it (HDC_MEM_LIMIT) has no say here: it caps a disk
     * held in RAM, and a drive made here lives in a file.
     */
    Q_INVOKABLE int hdCapacityLimit(int nr) const;

    /* The largest drive OFS or FFS can describe, in MB.
     *
     * Past this a drive can still be created, but only without a file
     * system -- there is no Amiga file system that would span it. Nothing
     * else in the app knows this number, so the dialog asks for it rather
     * than carrying a copy.
     */
    Q_INVOKABLE int hdFileSystemLimit() const;

    /* Puts a hard drive into the machine, and returns at once.
     *
     * Two ways in, one ending: an image the user dropped is copied into the
     * machine's folder (copyHd), a new drive is laid down there and
     * formatted (createHd), and either way the image is then attached and
     * the machine sent round again to notice it (attachHd).
     *
     * Both run as a background job (see Controller::runTask), because
     * writing gigabytes to a file is not something to do on the thread that
     * redraws the window. What the job is doing shows up wherever progress
     * shows up -- the status bar's ticker -- and a failure arrives as an
     * error afterwards, by which time the image it was writing has been
     * removed again.
     *
     * Nothing is started, and nothing touched, while another job of this
     * controller's is still running; the caller is told so.
     *
     * The second form takes a capacity rather than a geometry: deriving CHS
     * from a size is what GeometryDescriptor(isize) already does, and it
     * does it better than a dialog could -- it grows the sector count before
     * the head count, so a size like 384 MB, which no doubling of heads
     * alone can describe, still lands on a legal geometry. 'fsFormat' is a
     * raw amiga::FSFormat value, as in newDisk() above, and 'importUrl' may
     * be empty; a folder is only imported into a formatted drive, since
     * there is nowhere to put it otherwise.
     */
    Q_INVOKABLE void attachHdAsync(int nr, const QUrl &url);
    Q_INVOKABLE void attachHdAsync(int nr, int megabytes, int fsFormat, const QString &name,
                                   const QUrl &importUrl = {});

    // There's no direct "detach" call on the core's HardDriveAPI (unlike
    // FloppyDriveAPI::ejectDisk()) -- disconnecting the controller via
    // HDC_CONNECT is the closest equivalent, and it's what the menu's
    // "Detach" item does.
    Q_INVOKABLE void detachHd(int nr);
    Q_INVOKABLE void exportHd(int nr, const QUrl &url);

private:

    /* The three steps the two entry points above are made of.
     *
     * All of them run on the job's thread, not this one. That is allowed:
     * the emulator's public API asks only that the caller is not the
     * emulator thread itself (Thread::isUserThread), and the calls here that
     * suspend it -- attach, loadIntoMemory, format, saveWorkspace -- are the
     * only suspending calls in flight, because what the window does every
     * frame merely reads.
     *
     * The first two leave a finished image in the machine's folder and touch
     * the machine no more than they must; the third is what the machine
     * notices. Each reports its progress as it goes.
     */

    // Copies a dropped image into the machine's folder
    void copyHd(int nr, const QUrl &url);

    // Lays down a new image there and puts a file system on it
    void createHd(int nr, int megabytes, int fsFormat, const QString &name,
                  const QUrl &importUrl = {});

    // Attaches an image and lets the machine see it
    void attachHd(int nr, const QUrl &url);

    // Where this slot's image lives
    std::filesystem::path hdImagePath(int nr) const;

    // Says that a job could not be started, rather than failing silently
    void reportBusy(const QString &failure);

public:

    //
    // Rom presets
    //

    // One-click installers for the Rom images bundled under Shared/Assets/Roms.
    // That folder is embedded into both apps as Qt resources (see the
    // ASSET_RESOURCES glob in Apps/CMakeLists.txt), so "Shared/Assets/Roms/
    // foo.bin" is reachable at runtime as ":/Roms/foo.bin" -- no separate
    // packaging step needed.
    //
    // Port of vAmiga's own MediaManager.installAros()/installDiagRom()
    // (GUI/MediaManager.swift) and, further out, its RomSettingsViewController's
    // preset popup -- the "older version" entries that popup offers. Each
    // takes the CRC32 of the bundled version to install (see VACore's
    // RomFileTypes.h), defaulting to the newest; SiAmRomConfig.qml's burger
    // menu is what actually offers the older ones, one item per bundled
    // version, in place of vAmiga's own popup. Only bundles this app actually
    // ships under Shared/Assets/Roms are accepted -- passing any other CRC32
    // (including ones VACore knows about but this app has no Rom file for,
    // like CRC32_AROS_1ED13DE6E3 or CRC32_DIAG20) throws.
    Q_INVOKABLE void installAros(quint32 crc32 = vamiga::CRC32_AROS_20260820);
    Q_INVOKABLE void installDiagRom(quint32 crc32 = vamiga::CRC32_DIAG13);

    // No Swift counterpart (MediaManager.swift has no EmuTOS preset), and
    // only one version is bundled here, so there is nothing to parameterize.
    Q_INVOKABLE void installEmuTOS();

private:

    // Reads an embedded Rom image (e.g. ":/Roms/aros-20260820-rom.bin") into
    // memory. Throws if the resource is missing -- callers are expected to
    // wrap installAros()/installDiagRom() in a try/catch, same as every
    // other media operation in this class.
    static QByteArray readRomResource(const QString &resourcePath);
};
