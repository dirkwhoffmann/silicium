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
    Q_INVOKABLE void attachHd(int nr, const QUrl &url);

    /* Builds a hard drive of the given size and plugs it in.
     *
     * The three steps vAmiga's own HardDiskCreator performs (attach a
     * geometry, format it, import a folder), plus what a drive that was
     * never there before needs to be seen: the controller, and a reset for
     * the machine to walk the bus again. The disk lives in memory -- nothing
     * is written until the workspace is saved.
     *
     * The caller gives a capacity, not a geometry: deriving CHS from a size
     * is what GeometryDescriptor(isize) already does, and it does it better
     * than the dialog used to -- it grows the sector count before the head
     * count, so a size like 384 MB, which no doubling of heads alone can
     * describe, still lands on a legal geometry.
     *
     * 'fsFormat' is a raw amiga::FSFormat value, as in newDisk() above.
     * 'importUrl' may be empty; a folder is only imported into a formatted
     * drive, since there is nowhere to put it otherwise.
     *
     * Returns false when nothing was created, having reported why -- the
     * dialog stays open in that case rather than closing over an error.
     */
    Q_INVOKABLE bool newHardDisk(int nr, int megabytes, int fsFormat, const QString &name,
                                 const QUrl &importUrl = {});

    /* The largest drive this slot accepts, in MB (0 = no limit).
     *
     * Both of the controller's limits, whichever bites first: HDC_MB_LIMIT
     * caps the drive, HDC_MEM_LIMIT caps what a disk held in memory may be,
     * and a drive built here is held in memory. Worth showing rather than
     * leaving to be discovered -- the default memory limit is 256 MB, which
     * is below what a user may well type.
     *
     * A drive that is to carry a file system has a third ceiling: OFS and
     * FFS stop at 504 MB (FSDescriptor::checkCompatibility). It only bites
     * where the two controller limits have been lifted, but where it does,
     * the drive would attach and then fail to format.
     */
    Q_INVOKABLE int hdCapacityLimit(int nr, bool formatted = true) const;

    /* Taking a dropped hard drive image into the machine.
     *
     * attachHd() above attaches the file where it lies, which leaves the
     * machine depending on a path outside the SVM -- move or delete the
     * original and the drive is gone. These three copy it in instead, under
     * the hdN name Amiga::saveWorkspace() already uses, so the image travels
     * with the SVM. 'nr' picks the name, the dropped file picks the suffix
     * (.hdf or .hdz), and the two query calls let the caller warn before
     * anything is overwritten.
     */
    Q_INVOKABLE QString hdImageName(int nr, const QUrl &url) const;
    Q_INVOKABLE QString hdExistingImage(int nr) const;

    /* Starts the copy and returns at once.
     *
     * A large image takes seconds to unpack and write, which is far too long
     * to keep the window from redrawing, so the file work happens on a task
     * of its own (see 'task', which a progress dialog binds to). Everything
     * that touches the machine waits for that to finish and then happens
     * here, on this thread.
     */
    Q_INVOKABLE void copyAndAttachHd(int nr, const QUrl &url);

    // The copy above, for a progress dialog to watch
    // There's no direct "detach" call on the core's HardDriveAPI (unlike
    // FloppyDriveAPI::ejectDisk()) -- disconnecting the controller via
    // HDC_CONNECT is the closest equivalent, and it's what the menu's
    // "Detach" item does.
    Q_INVOKABLE void detachHd(int nr);
    Q_INVOKABLE void exportHd(int nr, const QUrl &url);


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
