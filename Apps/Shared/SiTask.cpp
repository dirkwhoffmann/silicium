// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiTask.h"

SiTask::SiTask(QObject *parent) : QObject(parent)
{
    /* Fast enough to look continuous, slow enough to be free. The worker
     * advances its counters far more often than this; what is shown is
     * simply wherever it had got to when the timer last looked.
     */
    timer.setInterval(40);
    connect(&timer, &QTimer::timeout, this, &SiTask::poll);
}

SiTask::~SiTask()
{
    // The body holds a reference to this object's task, so it has to be gone
    // before the task is.
    task.cancel();
    task.join();
}

void
SiTask::setText(const QString &value)
{
    if (m_text != value) { m_text = value; emit changed(); }
}

void
SiTask::run(const QString &text, std::function<void(utl::Progress &)> body)
{
    if (task.isRunning()) return;

    m_text = text;
    task.start(std::move(body));

    emit changed();
    timer.start();
}

void
SiTask::poll()
{
    emit changed();

    if (task.isRunning()) return;

    /* The job has ended. Stop looking, collect the thread, and say how it
     * went -- on this thread, so a handler can go straight on with whatever
     * had to wait for the job.
     */
    timer.stop();
    task.join();

    const auto state = task.state();
    const bool cancelled = state == utl::Task::State::Cancelled;
    const bool ok = state == utl::Task::State::Completed;

    emit changed();
    emit finished(ok, cancelled, QString::fromStdString(task.error()));
}
