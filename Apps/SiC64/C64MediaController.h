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
#include <QStringList>
#include <QUrl>

class C64Controller;

class C64MediaController : public Controller {

    Q_OBJECT

    C64Controller *parent = nullptr;

    // Recent media
    QStringList m_recentDisks;
    QStringList m_recentTapes;
    QStringList m_recentCartridges;

public:

    explicit C64MediaController(C64Controller *parent = nullptr);


    //
    // Disks
    //

    // 'drive' is 8 or 9 throughout this class' public API (matching the UI's
    // drive numbers), converted to the core's 0/1 indexing internally.
    //
    // Q_INVOKABLE methods must stay in a public: section -- QML's method
    // dispatch silently ignores ones declared under private:/protected:
    // (calling them reports "is not a function" instead of erroring at
    // registration time), which is why this was moved out of the private
    // block below that still holds the plain C++ helpers.
    Q_INVOKABLE void insertDisk(int drive, const QUrl &url, bool wp = false);

    // Flashes a program file (PRG / P00 / T64) straight into the running
    // machine's RAM, making it immediately runnable -- the "Memory" drop zone.
    // Mirrors the old Swift-based emulator's MediaManager.flashFile(url:).
    Q_INVOKABLE void flash(const QUrl &url);

    // Creates and inserts a blank disk. 'fsFormat' is a retro::vault::cbm::FSFormat
    // value (0 = NODOS, 1 = CBM), matching the "File system" combo box in
    // SiC64DiskCreator.
    Q_INVOKABLE void newDisk(int drive, int fsFormat, const QString &name);

    // Whether the drive currently holds a disk with unsaved changes (see
    // SiC64Window's proceedWithUnsavedFloppyDisk).
    Q_INVOKABLE bool hasModifiedDisk(int drive) const;

    // Exports the current disk to an image file. Only D64 is supported by
    // the core's codec right now (see FloppyDisk::writeToFile), which is why
    // SiC64DiskExporter doesn't offer T64/PRG like the old Swift-based
    // emulator did.
    Q_INVOKABLE void exportDisk(int drive, const QUrl &url);

    // Exports the current disk's file system as a folder of plain files.
    Q_INVOKABLE void exportDiskFolder(int drive, const QUrl &url);

    // Ejects the current disk. Callers are expected to run this through
    // SiC64Window's proceedWithUnsavedFloppyDisk first, same as insert/new.
    Q_INVOKABLE void ejectDisk(int drive);

    // Toggles write-protection on the current disk.
    Q_INVOKABLE void toggleWriteProtection(int drive);

    // Toggles the modification flag ("unsaved changes") on the current disk.
    // Developer-only escape hatch for exercising the unsaved-state UI (the
    // eject/quit confirmation prompts) without having to actually modify a
    // disk's contents first.
    Q_INVOKABLE void toggleUnsavedState(int drive);

    // Toggles the drive's own power switch (independent of the disk).
    Q_INVOKABLE void toggleDrivePower(int drive);

    // Per-drive state for the Drive menu's Eject/Export/Write Protected/Power
    // items (enabled state and checkmarks). Two properties per state rather
    // than a parameterized getter, since Q_INVOKABLE methods aren't reactive
    // QML bindings and the menu needs to redraw as disks are
    // inserted/ejected/protected. Refreshed alongside the rest of the polled
    // "info" state -- see C64Controller::update().
    Q_PROPERTY(bool drive8HasDisk READ drive8HasDisk NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9HasDisk READ drive9HasDisk NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8WriteProtected READ drive8WriteProtected NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9WriteProtected READ drive9WriteProtected NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8Modified READ drive8Modified NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9Modified READ drive9Modified NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8PoweredOn READ drive8PoweredOn NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9PoweredOn READ drive9PoweredOn NOTIFY driveStateChanged)

    bool drive8HasDisk() const;
    bool drive9HasDisk() const;
    bool drive8WriteProtected() const;
    bool drive9WriteProtected() const;
    bool drive8Modified() const;
    bool drive9Modified() const;
    bool drive8PoweredOn() const;
    bool drive9PoweredOn() const;

    // Adds url to m_recentDisks if not already present, trimming the list to
    // maxRecentDisks. Called after every successful disk insertion (both
    // insertDisk and insertRecentDisk funnel through it).
    void noteRecentlyInsertedDisk(const QUrl &url);
    void noteRecentlyInsertedTape(const QUrl &url);
    void noteRecentlyAttachedCartridge(const QUrl &url);


    //
    // Datasette
    //

    Q_INVOKABLE void insertTape(const QUrl &url);
    Q_INVOKABLE void ejectTape();
    Q_INVOKABLE void exportTape(const QUrl &url);
    Q_INVOKABLE void rewindTape();

    // Presses the datasette's Play key, or Stop if it's already playing.
    Q_INVOKABLE void playOrStopTape();

    // Same rationale as the drive properties above: reused by the Datasette
    // menu's enabled state and the Play/Stop item's dynamic title.
    Q_PROPERTY(bool tapeInserted READ tapeInserted NOTIFY driveStateChanged)
    Q_PROPERTY(bool tapePlaying READ tapePlaying NOTIFY driveStateChanged)

    bool tapeInserted() const;
    bool tapePlaying() const;


    //
    // Cartridges
    //

    Q_INVOKABLE void attachCartridge(const QUrl &url);
    Q_INVOKABLE void detachCartridge();
    Q_INVOKABLE void attachReu(int capacity);
    Q_INVOKABLE void attachGeoRam(int capacity);
    Q_INVOKABLE void attachIsepic();
    Q_INVOKABLE void exportCartridge(const QUrl &url);

    // Presses the given cartridge button (1 or 2) briefly, then releases it.
    Q_INVOKABLE void pressCartridgeButton(int nr);

    // Sets the cartridge switch position: -1 = left, 0 = neutral, 1 = right.
    Q_INVOKABLE void setCartridgeSwitch(int pos);

    // Same rationale as the drive/tape properties above.
    Q_PROPERTY(bool cartridgeAttached READ cartridgeAttached NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsReu READ cartridgeIsReu NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsGeoRam READ cartridgeIsGeoRam NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsIsepic READ cartridgeIsIsepic NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeMemory READ cartridgeMemory NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeButtons READ cartridgeButtons NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeSwitches READ cartridgeSwitches NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeSwitchPos READ cartridgeSwitchPos NOTIFY driveStateChanged)

    bool cartridgeAttached() const;
    bool cartridgeIsReu() const;
    bool cartridgeIsGeoRam() const;
    bool cartridgeIsIsepic() const;
    // CartridgeTraits::memory is in bytes; the REU/GeoRam submenus compare
    // against KB capacities (128/256/512/...), matching attachReu/attachGeoRam's
    // own KB-based parameter.
    int cartridgeMemory() const;
    int cartridgeButtons() const;
    int cartridgeSwitches() const;
    int cartridgeSwitchPos() const;


    //
    // Recently used media -- see the Q_PROPERTY declarations further below;
    // these Q_INVOKABLE methods must stay public for the same reason
    // insertDisk/hasModifiedDisk were moved up here
    //

    // Inserts the recently used disk at the given position into the drive.
    // The list itself is shared by both drives; only the target drive
    // depends on which one's "Insert Recent" submenu was used.
    Q_INVOKABLE void insertRecentDisk(int drive, int index);

    // Clears the shared list of recently inserted disks
    Q_INVOKABLE void clearRecentlyInsertedDisks();

    // Inserts the recently used tape at the given position into the datasette
    Q_INVOKABLE void insertRecentTape(int index);

    // Clears the list of recently inserted tapes
    Q_INVOKABLE void clearRecentlyInsertedTapes();

    // Attaches the recently used cartridge at the given position
    Q_INVOKABLE void attachRecentCartridge(int index);

    // Clears the list of recently attached cartridges
    Q_INVOKABLE void clearRecentlyAttachedCartridges();


    //
    // Recently inserted disks (shared by both drives)
    //

    Q_PROPERTY(QStringList recentDisks READ recentDisks NOTIFY recentDisksChanged)

    QStringList recentDisks() const { return m_recentDisks; }


    //
    // Recently inserted tapes
    //

    Q_PROPERTY(QStringList recentTapes READ recentTapes NOTIFY recentTapesChanged)

    QStringList recentTapes() const { return m_recentTapes; }


    //
    // Recently attached cartridges
    //

    Q_PROPERTY(QStringList recentCartridges READ recentCartridges NOTIFY recentCartridgesChanged)

    QStringList recentCartridges() const { return m_recentCartridges; }

signals:

    void driveStateChanged();
    void recentDisksChanged();
    void recentTapesChanged();
    void recentCartridgesChanged();
};
