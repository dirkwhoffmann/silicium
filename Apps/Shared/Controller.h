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
#include <functional>
#include <QQuickWindow>


using QUUID = QString;

class Controller : public QObject, public SiObject, public InputManagerDelegate, public AudioControllerDelegate {

    Q_OBJECT

protected:

    // Quick references
    InputManager &inputManager = AppServices::inputManager;

    // Handle to the associated window
    QQuickWindow *m_window = nullptr;

    // Whether a job is running (see runTask)
    bool m_busy = false;

    // What was last said about it, so the same thing is not said twice
    QString m_progress;
    qreal m_percentage = 0.0;


    //
    // Methods
    //

  public:

    explicit Controller(QObject *parent = nullptr);

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)

    Q_INVOKABLE virtual void start() { }
    Q_INVOKABLE virtual void stop() { }


    //
    // Running jobs in the background
    //

public:

    // Whether a job is running at the moment
    bool busy() const { return m_busy; }

    /* Runs a job on a thread of its own, and says so.
     *
     * Anything that would hold up the window for longer than a frame belongs
     * here: saving a workspace, copying a disk image. The body runs on a
     * QtConcurrent thread and says what it is doing through report(), which
     * reaches the window as showProgress(); the display goes away when the
     * job does. A body that throws is reported through showError() under the
     * given title, and 'done' then does not run.
     *
     * 'done' is the part that has to happen on this thread once the work is
     * over -- touching the manifest, telling the world. Returns false if a
     * job is already running, in which case nothing is started: one at a
     * time, because they would be reporting over each other.
     */
    bool runTask(const QString &what,
                 const QString &failure,
                 std::function<void()> body,
                 std::function<void()> done = {});

    /* Says what the job is doing now, and how far along it is.
     *
     * Called from the body, which is on a thread of its own, so the message
     * is handed to this object's own thread before anyone hears it.
     */
    void report(const QString &what, qreal percentage = 0.0);


    /* Re-emits what a sub-controller reports as our own.
     *
     * A machine is split over a main controller and several smaller ones
     * (media, config, ...), but the window only knows the one it was given.
     * Without this, a message from a sub-controller has no listener and is
     * lost -- an error dialog that never appears.
     */
    void adopt(Controller *child) {

        connect(child, &Controller::showError, this, &Controller::showError);
        connect(child, &Controller::showFatalError, this, &Controller::showFatalError);
        connect(child, &Controller::showNotification, this, &Controller::showNotification);
        connect(child, &Controller::showProgress, this, &Controller::showProgress);
    }


    //
    // Signals
    //

private:

    // Says it, on this object's thread, unless it has just been said
    void announce(const QString &what, qreal percentage);

signals:

    void showError(const QString &what, const QString &why);
    void showFatalError(const QString &what, const QString &why);
    void showNotification(const QString &title, const QString &message);

    /* What this controller is busy with and how far along it is, and an
     * empty string when it is done. A window shows it for as long as it is
     * not empty (see SiTicker).
     */
    void showProgress(const QString &what, qreal percentage);
};