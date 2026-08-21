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

class C64Controller;

class SiC64StatusbarController : public Controller {

    Q_OBJECT

    C64Controller *parent = nullptr;

    // Speedometer
    int m_activityType = 0;
    QString m_activityInfo = "";
    float m_activity = 0.0;

  public:

    explicit SiC64StatusbarController(C64Controller *parent = nullptr);

    // The drive LED / disk, tape and cartridge icons, and the commodore /
    // halt / server / tracking / mute pictogram symbols, are now inlined in
    // SiC64Statusbar.qml. The warp indicator binds to SiC64InfoController's
    // 'warping' flag.

    Q_PROPERTY(int activityType READ activityType NOTIFY activityTypeChanged)
    Q_PROPERTY(QString activityInfo READ activityInfo NOTIFY activityInfoChanged)
    Q_PROPERTY(float activity READ activity NOTIFY activityChanged)

  private:

    int activityType() const { return m_activityType; }
    QString activityInfo() const { return m_activityInfo; }
    float activity() const { return m_activity; }

  signals:

    void activityTypeChanged();
    void activityInfoChanged();
    void activityChanged();
};
