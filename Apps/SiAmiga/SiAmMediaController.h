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
};
