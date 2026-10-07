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
#include <QThread>
#include <cmath>

Controller::Controller(QObject *parent) : QObject(parent)
{
    m_ticker = new QTimer(this);
    m_ticker->setInterval(100);

    connect(m_ticker, &QTimer::timeout, this, [this] {

        // Compute the elapsed time
        m_elapsed = (utl::Time::now() - m_start).asSeconds();

        printf("Ticker: %f\n", m_elapsed);

        emit elapsedChanged();
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

        emit elapsedChanged();
        emit progressChanged();
        emit busyChanged();

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
Controller::report(const QString &what, qreal percentage)
{
    // This functions is intended to be called in a worker thread.
    // Execute the body in the GUI thread...

    QMetaObject::invokeMethod(this, [this, what, percentage] {

        // A report that arrives after its job is over has nothing to show
        if (!m_busy) return;

        printf("Report: %f\n", percentage);

        m_percentage = percentage;
        m_progress = what;

        emit progressChanged();

    }, Qt::QueuedConnection);
}

void
Controller::block(double elapsed)
{
    const auto remaining = elapsed - (utl::Time::now() - m_start).asSeconds();
    if (remaining > 0.0) QThread::msleep(quint32(std::ceil(remaining * 1000.0)));
}
