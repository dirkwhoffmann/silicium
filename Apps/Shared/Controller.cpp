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
Controller::Controller(QObject *parent) : QObject(parent)
{

}

bool
Controller::runTask(const QString &what,
                    const QString &failure,
                    std::function<void()> body,
                    std::function<void()> done)
{
    if (m_busy) return false;

    m_busy = true;
    announce(what, 0.0);

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
    QtConcurrent::task(std::move(guarded)).spawn().then(this, [this, failure, error, done] {

        m_busy = false;
        announce({ }, 0.0);

        if (error->isEmpty()) {

            if (done) done();

        } else {

            emit showError(failure, *error == "?" ? tr("Unknown error") : *error);
        }
    });

    return true;
}

void
Controller::report(const QString &what, qreal percentage)
{
    // Off this object's thread, so the message is queued rather than said
    QMetaObject::invokeMethod(this, [this, what, percentage] {

        announce(what, percentage);

    }, Qt::QueuedConnection);
}

void
Controller::announce(const QString &what, qreal percentage)
{
    /* A step that takes a while keeps its text and moves its bar, so both
     * are compared. A hundredth of a bar is under a pixel wide; anything
     * finer than that is not worth waking the window for.
     */
    if (what == m_progress && std::abs(percentage - m_percentage) < 0.01) return;

    m_progress = what;
    m_percentage = percentage;

    emit showProgress(what, percentage);
}
