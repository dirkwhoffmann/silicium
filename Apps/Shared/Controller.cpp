// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Controller.h"
#include <cmath>

/*
void
Controller::setWindow(QQuickWindow *ptr)
{
    if (m_window != ptr) {

        m_window = ptr;
        emit windowChanged();
    }
}
*/
Controller::Controller(QObject *parent) : QObject(parent), m_task(this)
{
    // The task samples itself on a timer; every tick is a chance that what it
    // is doing has changed (see SiTask).
    connect(&m_task, &SiTask::changed, this, &Controller::reportProgress);
}

bool
Controller::runTask(const QString &what,
                    const QString &failure,
                    utl::ProgressTask::Body body,
                    std::function<void()> done)
{
    if (m_task.running()) return false;

    /* Whether the job got all the way through. A failure is reported by the
     * task itself, before finished(); 'done' is the caller's follow-up work
     * and has no business running after a job that did not finish.
     */
    auto completed = std::make_shared<bool>(true);

    connect(&m_task, &SiTask::failed, this, [this, failure, completed](const QString &error) {

        *completed = false;
        emit showError(failure, error);

    }, Qt::SingleShotConnection);

    connect(&m_task, &SiTask::aborted, this, [completed] {

        *completed = false;

    }, Qt::SingleShotConnection);

    connect(&m_task, &SiTask::finished, this, [this, done, completed] {

        reportProgress();
        if (*completed && done) done();

    }, Qt::SingleShotConnection);

    m_task.run(what, std::move(body));
    reportProgress();

    return true;
}

void
Controller::reportProgress()
{
    /* A job that has not said anything about itself yet is described by the
     * text it was started with, and one that is over says nothing at all.
     */
    QString text;
    qreal percentage = 0.0;

    if (m_task.running()) {

        text = m_task.description();
        if (text.isEmpty()) text = m_task.text();
        percentage = m_task.progress();
    }

    /* Both are reported, because a step that takes a while keeps its text and
     * moves its bar. A hundredth of the bar is under a pixel wide, so
     * anything finer than that is not worth waking the window for.
     */
    if (text != m_progress || std::abs(percentage - m_percentage) >= 0.01) {

        m_progress = text;
        m_percentage = percentage;
        emit showProgress(text, percentage);
    }
}
