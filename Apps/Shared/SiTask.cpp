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
    /* Fast enough to look continuous, slow enough to be free. The task
     * advances its own counter far more often than this; what is shown is
     * simply wherever it had got to when the timer last looked.
     */
    timer.setInterval(40);
    connect(&timer, &QTimer::timeout, this, [this]() { emit changed(); });
}

SiTask::~SiTask()
{
    // The body reports through this object, so it has to be gone first.
    task.abort();
    task.join();
}

void
SiTask::setText(const QString &value)
{
    if (m_text != value) { m_text = value; emit changed(); }
}

void
SiTask::run(const QString &text, utl::ProgressTask::Body body)
{
    if (task.isRunning()) return;

    m_text = text;

    /* Each hook hands itself to this object's thread before touching
     * anything. They arrive on the task's thread, where emitting a signal
     * that a window is connected to would be undefined.
     */
    auto post = [this](std::function<void()> action) {

        QMetaObject::invokeMethod(this, std::move(action), Qt::QueuedConnection);
    };

    task.run({
        .started = [this, post] {
            post([this] { timer.start(); emit changed(); emit started(); });
        },
        .progressed = { },      // sampled by the timer instead, see SiTask.h
        .described = { },       // likewise
        .aborted = [this, post] {
            post([this] { emit aborted(); });
        },
        .failed = [this, post] (const std::string &error) {
            post([this, error] { emit failed(QString::fromStdString(error)); });
        },
        .finished = [this, post] {
            post([this] { timer.stop(); emit changed(); emit finished(); });
        }
    }, std::move(body));

    emit changed();
}
