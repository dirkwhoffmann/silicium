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
    Q_INVOKABLE void newDisk(int nr);
    Q_INVOKABLE void ejectDisk(int nr);
    Q_INVOKABLE void exportDisk(int nr, const QUrl &url);
    Q_INVOKABLE void toggleWriteProtection(int nr);


    //
    // Hard drives (hd0..hd3)
    //

    Q_INVOKABLE bool hdHasDisk(int nr) const;
    Q_INVOKABLE void attachHd(int nr, const QUrl &url);
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
