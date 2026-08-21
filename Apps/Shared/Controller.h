// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiObject.h"
#include "AppServices.h"
#include "AudioController.h"
#include <QObject>
#include <QQuickWindow>


using QUUID = QString;

class Controller : public QObject, public SiObject, public InputManagerDelegate, public AudioControllerDelegate {

    Q_OBJECT

protected:

    // Quick references
    InputManager &inputManager = AppServices::inputManager;

    // Handle to the associated window
    QQuickWindow *m_window = nullptr;


    //
    // Methods
    //

  public:

    explicit Controller(QObject *parent = nullptr) : QObject(parent) {}

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)

    Q_INVOKABLE virtual void start() { }
    Q_INVOKABLE virtual void stop() { }


    //
    // Signals
    //

signals:

    void showError(const QString &what, const QString &why);
    void showFatalError(const QString &what, const QString &why);
    void showNotification(const QString &title, const QString &message);
};