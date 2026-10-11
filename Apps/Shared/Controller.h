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
#include <exception>
#include <QQuickWindow>


using QUUID = QString;

class Controller : public QObject, public SiObject, public InputManagerDelegate, public AudioControllerDelegate {

    Q_OBJECT

protected:

    // Quick references
    InputManager &inputManager = AppServices::inputManager;

    // Handle to the associated window
    QQuickWindow *m_window = nullptr;

    // Tells what the machine is busy with ("" if it is not)
    QString m_status;

    //
    // Methods
    //

  public:

    explicit Controller(QObject *parent = nullptr);

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

    // Indicates whether the machine is busy with a job that the user has to wait for
    virtual bool busy() const { return false; }

    // What the machine is busy with, to be shown to the user
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    QString status() const { return m_status; }

    Q_INVOKABLE virtual void start() { }
    Q_INVOKABLE virtual void stop() { }


    //
    // Signals
    //

signals:

    void busyChanged();
    void statusChanged();
    void showError(const QString &what, const QString &why);
    void showFatalError(const QString &what, const QString &why);
    void showNotification(const QString &title, const QString &message);

protected:

    // Describes an exception in words (for the user)
    static QString errorText(std::exception_ptr exception);

    void setStatus(const QString &status) {

        if (m_status == status) return;

        m_status = status;
        emit statusChanged();
    }

    // Re-emits what a subcontroller reports
    void adopt(Controller *child) {

        connect(child, &Controller::showError, this, &Controller::showError);
        connect(child, &Controller::showFatalError, this, &Controller::showFatalError);
        connect(child, &Controller::showNotification, this, &Controller::showNotification);
    }
};