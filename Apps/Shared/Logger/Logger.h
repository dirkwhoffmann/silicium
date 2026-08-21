// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QAbstractListModel>
#include <QElapsedTimer>
#include <QLoggingCategory>
#include <QSortFilterProxyModel>
#include <QtQml>

Q_DECLARE_LOGGING_CATEGORY(siLog)

class LogFilter;

/* The application logbook.
 *
 * Every Qt log message is routed here by install() and appended to a capped
 * ring of entries, which is itself the model the log window displays. Two
 * things ride along with the plain text:
 *
 *   Nesting   A LogTask indents everything logged while it is alive, so the
 *             log reads as a tree of operations rather than a flat stream.
 *
 *   Tasks     A task's row is written when it starts and amended when it ends
 *             with how long it took and whether it threw.
 *
 * Everything reaches the logbook through a *queued* call, including tasks.
 * That is what keeps entries in the order they were emitted.
 */
class Logger : public QAbstractListModel {

    Q_OBJECT

  public:

    // Severity, ordered from most to least important
    enum Level { Critical, Warning, Info, Debug };
    Q_ENUM(Level)

    enum Roles {

        MessageRole = Qt::UserRole + 1,
        TimeRole,
        LevelRole,
        DepthRole,
        IsTaskRole,
        StatusRole,
        ElapsedRole
    };

  private:

    struct Entry {

        QString message;
        QString time;
        Level level = Info;
        int depth = 0;
        quint64 taskId = 0;
        bool completed = false;
        bool failed = false;
        qint64 elapsed = 0;

        bool isTask() const {
            return taskId != 0;
        }

        QString status() const {
            return !isTask() ? QString() : failed ? QString("FAILED") : completed ? QString("OK") : QString("...");
        }
    };

    // Oldest entries are dropped once this many are held
    static constexpr int capacity = 1024;

    // The log buffer
    QVector<Entry> m_entries;

    // Filtered view, handed to the log window
    LogFilter *m_filter;

  public:

    // Nesting level of the message currently being emitted
    int depth = 0;

    // Previous message handler, kept so non-Silicium messages still reach it
    static QtMessageHandler originalHandler;

    Q_PROPERTY(QAbstractItemModel *filtered READ filtered CONSTANT)
    Q_PROPERTY(int verbosity READ verbosity WRITE setVerbosity NOTIFY verbosityChanged)

    Logger();

    static Logger *instance();

    // Starts routing Qt's log messages into the logbook. Safe to call more
    // than once; anything logged beforehand goes to Qt's default handler.
    static void install();

    // Hands out a fresh task identifier
    static quint64 nextTaskId();


    //
    // Writing to the logbook (called on the logger's thread)
    //

    void log(const QString &message, Level level, int nesting);
    void beginTask(quint64 id, const QString &message, int nesting);
    void endTask(quint64 id, bool failed, qint64 elapsed);


    //
    // Methods from QAbstractListModel
    //

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

  private:

    QAbstractItemModel *filtered() const;

  public:

    int verbosity() const;
    void setVerbosity(int value);

  signals:

    void verbosityChanged();
};

class LogFilter : public QSortFilterProxyModel {

    Q_OBJECT

    int m_verbosity = 1;

  public:

    using QSortFilterProxyModel::QSortFilterProxyModel;

    int verbosity() const { return m_verbosity; }
    void setVerbosity(int value);

  protected:

    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
};

/* Logs the start of a task and, on destruction, how it went.
 * Both halves are posted through the same queue as ordinary log messages.
 */
class LogTask {

    quint64 id;
    QElapsedTimer timer;
    int exceptions;

  public:

    LogTask(QString msg);
    ~LogTask();

    LogTask(const LogTask &) = delete;
    LogTask &operator=(const LogTask &) = delete;
};
