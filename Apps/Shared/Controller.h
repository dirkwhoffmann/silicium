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
    QString m_task;
    QString m_subtask;

    // Update timer
    QTimer *m_ticker = nullptr;

    // Time stamps
    utl::Time m_start;

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
    Q_PROPERTY(QString task READ task NOTIFY progressChanged)
    Q_PROPERTY(QString subtask READ subtask NOTIFY progressChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY progressChanged)


    QString task() const { return m_task; }
    QString subtask() const { return m_subtask; }
    qreal percentage() const { return m_percentage; }

    Q_INVOKABLE virtual void start() { }
    Q_INVOKABLE virtual void stop() { }


    //
    // Running jobs in the background
    //

public:

    // Indicates whether a job is running
    bool busy() const { return m_busy; }

    // Returns the elapsed time in seconds
    qreal elapsed() const { return m_elapsed; }

    // Runs a job in another thread
    bool runTask(std::function<void()> body, std::function<void()> done = {}, std::function<void()> failed = {});


    //
    // Background job helpers (supposed to be caled within body())
    //

    // Describes the subtask (the task stays as it is)
    void report(const QString &subtask, qreal percentage = 0.0);

    // Describes the task and the subtask
    void report(const QString &task, const QString &subtask, qreal percentage = 0.0);

    /* Blocks the calling job until at least 'elapsed' seconds have passed since it
     * started, which keeps a quick step on screen long enough to be read. Returns
     * at once if that time is already over. Call it from the body only.
     */
    void block(double elapsed);


    //
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

protected:

    // Re-emits what a subcontroller reports
    void adopt(Controller *child) {

        connect(child, &Controller::showError, this, &Controller::showError);
        connect(child, &Controller::showFatalError, this, &Controller::showFatalError);
        connect(child, &Controller::showNotification, this, &Controller::showNotification);
    }
};