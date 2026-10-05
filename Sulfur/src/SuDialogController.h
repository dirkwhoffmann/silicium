// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <functional>

// Runs work for a SuDialog in the background. The work is handed over as a
// lambda; once it has finished, the controller reports back on the thread it
// lives in (normally the GUI thread), so the dialog can react safely.
class SuDialogController : public QObject {

    Q_OBJECT
    QML_ELEMENT

    // Whether a job is running
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

  public:

    explicit SuDialogController(QObject *parent = nullptr);

    bool busy() const { return m_busy; }

    // Runs the lambda on a pooled thread. Returns false if a job is already
    // running, in which case the lambda is not executed.
    bool run(std::function<void()> work);

  signals:

    void busyChanged();

    // The job has finished. Emitted from the controller's own thread.
    void finished();

    // The job has thrown. The message comes with it and finished() follows.
    void failed(const QString &message);

  private:

    bool m_busy = false;
};
