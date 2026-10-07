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
#include "utl/chrono.h"
#include <QObject>
#include <functional>
#include <QQuickWindow>
#include <chrono>
#include <QTimer>
#include <algorithm>


using QUUID = QString;

class Controller : public QObject, public SiObject, public InputManagerDelegate, public AudioControllerDelegate {

    Q_OBJECT

protected:

    // Quick references
    InputManager &inputManager = AppServices::inputManager;

    // Handle to the associated window
    QQuickWindow *m_window = nullptr;

    //
    // Async tasks
    //

    // Indicates whether a job is running
    bool m_busy = false;

    // Elapsed time and progress
    qreal m_elapsed = 0.0;
    qreal m_percentage = 0.0;

    // Current task description
    QString m_progress;

    // Update timer
    QTimer *m_ticker = nullptr;

    // Time stamps
    utl::Time m_start;

    // Target time and percentage
    qreal m_target_elapsed = 0.0;
    qreal m_target_percentage = 0.0;

    /* The current step runs the bar from m_currentProgress to m_targetProgress
     * while the job's elapsed time goes from m_currentElapsed to
     * m_targetElapsed (see report). m_percentage is where the bar is at the
     * moment. Progress is a fraction of the whole job, elapsed times are in
     * seconds since the job started.
     */
    /*
    qreal m_currentProgress = 0.0;
    qreal m_currentElapsed = 0.0;
    qreal m_targetProgress = 0.0;
    qreal m_targetElapsed = 0.0;
    */

    //
    // Methods
    //

  public:

    explicit Controller(QObject *parent = nullptr);

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

    /* How long the running job has been going, in seconds; 0 when there is
     * none. It is updated every ELAPSED_TICK milliseconds, which lets a view
     * hold back until a job has lasted long enough to deserve one, e.g.
     * "visible: elapsed > 0.25".
     */
    Q_PROPERTY(qreal elapsed READ elapsed NOTIFY elapsedChanged)

    // What the running job last reported (see report), and how far along it is
    Q_PROPERTY(QString progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY progressChanged)


    /* Like busy(), these cover the sub-controllers: the window is handed the
     * machine's controller only, but its media controller's jobs report, too.
     */
    QString progress() const { return reporter()->m_progress; }
    qreal percentage() const { return reporter()->m_percentage; }

    Q_INVOKABLE virtual void start() { }
    Q_INVOKABLE virtual void stop() { }


    //
    // Running jobs in the background
    //

public:

    /* Whether a job is running: this controller's own, or one belonging to
     * a sub-controller it adopted.
     *
     * The window is handed the machine's controller and nothing else, so
     * what its media controller is busy with has to count as the machine
     * being busy -- the same reason their messages are passed on (see
     * adopt, which also forwards busyChanged).
     */
    bool busy() const {

        if (m_busy) return true;

        for (auto *child : findChildren<Controller *>(Qt::FindDirectChildrenOnly)) {
            if (child->m_busy) return true;
        }
        return false;
    }

    qreal elapsed() const {

        qreal result = m_elapsed;

        for (auto *child : findChildren<Controller *>(Qt::FindDirectChildrenOnly)) {
            result = std::max(result, child->m_elapsed);
        }
        return result;
    }

    // The controller whose report is the one to show: this one, or a child with something to say
    const Controller *reporter() const {

        if (!m_progress.isEmpty()) return this;

        for (auto *child : findChildren<Controller *>(Qt::FindDirectChildrenOnly)) {
            if (!child->m_progress.isEmpty()) return child;
        }
        return this;
    }

    /* Runs a job on a thread of its own, and says so.
     *
     * Anything that would hold up the window for longer than a frame belongs
     * here: saving a workspace, copying a disk image. The body runs on a
     * QtConcurrent thread and says what it is doing through report(), which
     * reaches the window as progress and percentage; the display goes away when the
     * job does. A body that throws is reported through showError(), and
     * 'done' then does not run.
     *
     * 'done' is the part that has to happen on this thread once the work is
     * over -- touching the manifest, telling the world. 'failed' runs instead
     * of it, after the error was reported, if the body threw. Returns false
     * if a job is already running, in which case nothing is started (and
     * 'failed' does not run): one at a time, because they would be reporting
     * over each other.
     */
    bool runTask(std::function<void()> body,
                 std::function<void()> done = {},
                 std::function<void()> failed = {});

    /* Says what the job is doing now: 'what', and 'percentage', the part of
     * the whole job (0.0 to 1.0) that is done once this step is. The parts add
     * up over the steps. 'estimate' is how long the step takes, in seconds. If
     * it is given, the bar is moved ahead gradually, from where it stands, by
     * the ticker (see elapsed); without it, it jumps.
     *
     * Called from the body, which is on a thread of its own, so the message
     * is handed to this object's own thread before anyone hears it.
     */
    void report(const QString &what, qreal percentage = 0.0, qreal estimate = 0.0);


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
        connect(child, &Controller::progressChanged, this, &Controller::progressChanged);
        connect(child, &Controller::showTicker, this, &Controller::showTicker);
        connect(child, &Controller::busyChanged, this, &Controller::busyChanged);
        connect(child, &Controller::elapsedChanged, this, &Controller::elapsedChanged);
    }


    //
    // Signals
    //

signals:

    void busyChanged();
    void elapsedChanged();
    void progressChanged();
    void showError(const QString &what, const QString &why);
    void showFatalError(const QString &what, const QString &why);
    void showNotification(const QString &title, const QString &message);
    void showTicker(const QString &what);
};