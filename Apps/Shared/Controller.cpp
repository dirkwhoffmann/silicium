// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Controller.h"
#include <QtConcurrent>
#include <cmath>

Controller::Controller(QObject *parent) : QObject(parent)
{
    m_ticker = new QTimer(this);
    m_ticker->setInterval(100);

    connect(m_ticker, &QTimer::timeout, this, [this] {

        // Compute the elapsed time
        m_elapsed = (utl::Time::now() - m_start).asSeconds();

        printf("Ticker: %f (%f %f)\n", m_elapsed, m_target_elapsed, m_target_percentage);

        // Estimate the bar position according to the target values
        auto perc = m_target_elapsed ? m_elapsed / m_target_elapsed * m_target_percentage : 0.0;
        // printf("perc: %f %f\n", perc, m_elapsed / m_target_elapsed);

        // The progress can't be less than what we've already achieved
        perc = std::max(m_percentage, perc);

        // Moves the bar along
        m_percentage = perc; // std::clamp(perc, 0.0, 1.0);

        emit elapsedChanged();
        emit progressChanged();
    });
}

bool
Controller::runTask(std::function<void()> body,
                    std::function<void()> done,
                    std::function<void()> failed)
{
    if (m_busy) return false;

    m_busy = true;
    m_elapsed = 0.0;
    m_percentage = 0.0;
    m_target_elapsed = 0.0;
    m_target_percentage = 0.0;
    m_start = utl::Time::now();

    m_ticker->start();
    emit busyChanged();

    /* The body says what went wrong itself, rather than letting the
     * exception travel: QFuture hands a foreign exception on wrapped in a
     * QUnhandledException, whose what() is the useless "std::exception".
     */
    auto error = std::make_shared<QString>();

    auto guarded = [body = std::move(body), error] {

        try { body(); }
        catch (const std::exception &e) { *error = QString::fromUtf8(e.what()); }
        catch (...) { *error = QStringLiteral("?"); }
    };

    /* The body runs on a pooled thread and the continuation back here, on
     * this object's thread, because what it touches -- the manifest, the
     * window -- belongs to it.
     */
    QtConcurrent::task(std::move(guarded)).spawn().then(this, [=, this] {

        m_ticker->stop();

        m_busy = false;
        m_elapsed = 0.0;
        m_percentage = 0.0;
        m_target_elapsed = 0.0;
        m_target_percentage = 0.0;

        emit elapsedChanged();
        emit progressChanged();
        emit busyChanged();

        /*
        // The display goes away with the job
        if (!m_progress.isEmpty() || m_percentage != 0.0) {

            m_progress = { };
            m_percentage = 0.0;
            m_currentProgress = m_currentElapsed = m_targetProgress = m_targetElapsed = 0.0;
            emit progressChanged();
        }
        */

        if (error->isEmpty()) {

            if (done) done();

        } else {

            emit showError(tr("The operation failed."), *error == "?" ? tr("Unknown error") : *error);

            if (failed) failed();
        }
    });

    return true;
}

void
Controller::report(const QString &what, qreal percentage, qreal estimate)
{
    // This functions is intended to be called in a worker thread.
    // Execute the body in the GUI thread...

    QMetaObject::invokeMethod(this, [this, what, percentage, estimate] {

        // A report that arrives after its job is over has nothing to show
        if (!m_busy) return;

        printf("Report: %f %f\n", percentage, estimate);

        m_target_elapsed = (utl::Time::now() - m_start).asSeconds() + estimate;
        m_target_percentage += percentage;
        m_progress = what;

        emit progressChanged();

        /*
        // if (what == m_progress && estimate == m_estimate && std::abs(percentage - m_goal) < 0.01) return;

        const auto now = std::chrono::duration<qreal>(Clock::now() - m_start).count();

        m_progress = what;
        m_currentProgress = m_percentage;
        m_currentElapsed = now;
        m_targetProgress = std::min(m_targetProgress + percentage, 1.0);
        m_targetElapsed = now + estimate;

        // Without an estimate the bar jumps, otherwise the ticker walks it there
        if (estimate <= 0.0) m_percentage = m_targetProgress;

        emit progressChanged();
        */

    }, Qt::QueuedConnection);
}
