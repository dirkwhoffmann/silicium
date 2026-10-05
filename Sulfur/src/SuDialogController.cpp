// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SuDialogController.h"
#include <QtConcurrent>
#include <memory>

SuDialogController::SuDialogController(QObject *parent) : QObject(parent)
{

}

bool
SuDialogController::run(std::function<void()> work)
{
    if (m_busy || !work) return false;

    m_busy = true;
    emit busyChanged();

    /* The work reports a failure itself, rather than letting the exception
     * travel: QFuture hands a foreign exception on wrapped in a
     * QUnhandledException, whose what() is the useless "std::exception".
     */
    auto error = std::make_shared<QString>();

    auto guarded = [work = std::move(work), error] {

        try { work(); }
        catch (const std::exception &e) { *error = QString::fromUtf8(e.what()); }
        catch (...) { *error = QStringLiteral("?"); }
    };

    // The body runs on a pooled thread, the continuation on this object's
    QtConcurrent::task(std::move(guarded)).spawn().then(this, [this, error] {

        m_busy = false;
        emit busyChanged();

        if (!error->isEmpty()) {
            emit failed(*error == "?" ? tr("Unknown error") : *error);
        }
        emit finished();
    });

    return true;
}
