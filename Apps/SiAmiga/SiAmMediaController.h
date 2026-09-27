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

public:

    Q_INVOKABLE bool driveHasDisk(int nr) const;
    Q_INVOKABLE bool driveWriteProtected(int nr) const;
    Q_INVOKABLE bool driveModified(int nr) const;
    Q_INVOKABLE bool driveMotor(int nr) const;
    Q_INVOKABLE bool driveWriting(int nr) const;
    Q_INVOKABLE int driveTrack(int nr) const;
    Q_INVOKABLE void insertDisk(int nr, const QUrl &url, bool wp = false);
    Q_INVOKABLE QString driveCapacity(int nr) const;
    Q_INVOKABLE bool driveHighDensity(int nr) const;

    Q_INVOKABLE void newDisk(int nr, int fsFormat, int bootBlock, const QString &name);
    Q_INVOKABLE void ejectDisk(int nr);
    Q_INVOKABLE void exportDisk(int nr, const QUrl &url);
    Q_INVOKABLE void toggleWriteProtection(int nr);


    //
    // Hard drives (hd0..hd3)
    //

public:

    Q_INVOKABLE bool hdHasDisk(int nr) const;

    // Checks whether the SVM contains an existing hard-drive image
    Q_INVOKABLE QString hdExistingImage(int nr) const;

    // Copies an existing hard drive into the SVM and attaches it
    Q_INVOKABLE void attachHdAsync(int nr, const QUrl &url);

    // Creates a new machine inside the SVM and attaches it
    Q_INVOKABLE void attachHdAsync(int nr, int mb, int fsFormat, const QString &name,
                                   const QUrl &importUrl = {});

    // Detaches a hard drive
    Q_INVOKABLE void detachHd(int nr);

    // Exports the current drive a file
    Q_INVOKABLE void exportHd(int nr, const QUrl &url);

private:

    // Creates a new image file and installes a file system if requested
    void createHd(int nr, int megabytes, int fsFormat, const QString &name, const QUrl &importUrl = {});

    // Attaches an image and lets the machine see it
    void attachHd(int nr, const QUrl &url);
    void attachHd(int nr, const fs::path &path);

public:

    //
    // Rom presets
    //

    // One-click installers for the bundled Rom images
    Q_INVOKABLE void installAros(quint32 crc32 = vamiga::CRC32_AROS_20260820);
    Q_INVOKABLE void installDiagRom(quint32 crc32 = vamiga::CRC32_DIAG13);
    Q_INVOKABLE void installEmuTOS();

private:

    // Reads an embedded Rom image into memory
    static QByteArray readRomResource(const QString &resourcePath);
};
