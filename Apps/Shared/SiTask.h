// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/concurrency.h"
#include <QObject>
#include <QString>
#include <QTimer>
#include <functional>

/* A utl::ProgressTask, as seen from QML.
 *
 * The work itself knows nothing about Qt and lives in utlib, so that the same
 * job can be driven from vAmiga's Cocoa front end. All this class does is make
 * one watchable: it republishes the task's progress as properties a progress
 * bar can bind to, and turns the task's callbacks into signals delivered on
 * this object's own thread.
 *
 * That last part is the whole point of the class. A ProgressTask calls its
 * hooks on the thread doing the work, which is the wrong thread for anything
 * that touches a window; the handover happens once here rather than in every
 * caller.
 *
 * Progress and the step description are sampled rather than forwarded. The
 * task reports progress after every chunk -- far more often than a window can
 * be redrawn -- so a signal each time would be work spent on frames nobody
 * sees, and reading the description on the same tick costs one uncontended
 * lock. The lifecycle hooks are rare and are passed straight through.
 */
class SiTask : public QObject {

    Q_OBJECT

    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(qreal progress READ progress NOTIFY changed)
    Q_PROPERTY(QString description READ description NOTIFY changed)
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY changed)

    utl::ProgressTask task;
    QTimer timer;
    QString m_text;

public:

    explicit SiTask(QObject *parent = nullptr);
    ~SiTask() override;

    bool running() const { return task.isRunning(); }
    qreal progress() const { return task.progress(); }

    // What the job is doing at the moment ("Copying...", "Persisting...")
    QString description() const { return QString::fromStdString(task.description()); }

    QString text() const { return m_text; }
    void setText(const QString &value);

    /* Starts the body on a thread of its own and returns at once.
     *
     * The body is handed the task, which is how it reports progress
     * (setProgress, or a toolbox call such as copy) and how it notices that
     * cancel() has been called (check).
     */
    void run(const QString &text, utl::ProgressTask::Body body);

    // Asks the job to stop. It ends as soon as its body notices.
    Q_INVOKABLE void cancel() { task.abort(); }

signals:

    void changed();

    // The job has begun, ended without finishing, or failed. All are
    // delivered on this object's thread.
    void started();
    void aborted();
    void failed(const QString &error);

    // Always last, whichever of the three came before it
    void finished();
};
