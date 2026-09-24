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
#include "SiTask.h"
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

    // The job this controller is running, if any (see runTask)
    SiTask m_task;

    // What was last said about it, so the same text is not said twice
    QString m_progress;


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

    // The job this controller is running, for a dialog that wants to watch it
    Q_PROPERTY(SiTask *task READ task CONSTANT)
    SiTask *task() { return &m_task; }

    /* Runs a job on a thread of its own, and says so.
     *
     * Anything that would hold up the window for longer than a frame belongs
     * here: saving a workspace, copying a disk image. While the job runs, what
     * it reports about itself (ProgressTask::setDescription) is published
     * through showProgress(), which is how the window's banner learns what to
     * say; the banner goes away when the job does. A job that throws is
     * reported through showError() under the given title, and 'done' then
     * does not run.
     *
     * 'done' is the part that has to happen on this thread once the work is
     * over -- touching the manifest, telling the world. Returns false if a
     * job is already running, in which case nothing is started: one at a
     * time, because they would be reporting over each other.
     */
    bool runTask(const QString &what,
                 const QString &failure,
                 utl::ProgressTask::Body body,
                 std::function<void()> done = {});


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

    // Publishes what the job is doing, and the end of it
    void reportProgress();

signals:

    void showError(const QString &what, const QString &why);
    void showFatalError(const QString &what, const QString &why);
    void showNotification(const QString &title, const QString &message);

    /* What this controller is busy with, and an empty string when it is done.
     * A window shows it in a banner for as long as it is not empty.
     */
    void showProgress(const QString &what);
};