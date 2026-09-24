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

/* A long-running job, as seen from QML.
 *
 * The work itself is a utl::Task, which knows nothing about Qt and lives in
 * utlib so that the same job can be driven from vAmiga's Cocoa front end. All
 * this class adds is a way to watch one: it samples the task's progress on a
 * timer and republishes it as properties, which is enough for a progress bar
 * to bind to.
 *
 * Sampling rather than signalling from the worker is deliberate. The worker
 * reports progress after every chunk -- far more often than a window can be
 * redrawn -- and a signal per chunk would be both wasted work and a stream of
 * cross-thread events. A watcher that reads three atomics per frame costs
 * nothing and cannot fall behind.
 *
 * finished() is emitted on the thread that owns this object, so whatever has
 * to happen after the job -- installing the file that was just copied, say --
 * can be done there without further marshalling.
 */
class SiTask : public QObject {

    Q_OBJECT

    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(qreal fraction READ fraction NOTIFY changed)
    Q_PROPERTY(bool determinate READ determinate NOTIFY changed)
    Q_PROPERTY(qint64 done READ done NOTIFY changed)
    Q_PROPERTY(qint64 total READ total NOTIFY changed)
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY changed)

    utl::Task task;
    QTimer timer;
    QString m_text;

public:

    explicit SiTask(QObject *parent = nullptr);
    ~SiTask() override;

    bool running() const { return task.isRunning(); }
    qreal fraction() const { return task.progress().fraction(); }
    bool determinate() const { return task.progress().isKnown(); }
    qint64 done() const { return task.progress().done(); }
    qint64 total() const { return task.progress().total(); }

    QString text() const { return m_text; }
    void setText(const QString &value);

    /* Hands the body to a worker thread and returns at once.
     *
     * The body reports through the Progress it is given, and is expected to
     * call check() between chunks so that cancelling takes effect promptly.
     * Whatever it throws ends the job; the message reaches finished().
     */
    void run(const QString &text, std::function<void(utl::Progress &)> body);

    // Asks the job to stop. It ends as soon as its body notices.
    Q_INVOKABLE void cancel() { task.cancel(); }

signals:

    void changed();

    /* The job has ended. 'cancelled' tells a clean stop from a failure, and
     * 'error' is empty unless something went wrong.
     */
    void finished(bool ok, bool cancelled, const QString &error);

private:

    void poll();
};
