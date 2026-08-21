// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "Logger.h"
#include "AppController.h"

Q_LOGGING_CATEGORY(siLog, "silicium")

QtMessageHandler Logger::originalHandler = nullptr;

//
// Message handler (global scope)
//

void
messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    auto *logger = Logger::instance();

    // Map the Qt message type to out log level
    const auto level =
        type == QtDebugMsg   ? Logger::Debug :
        type == QtInfoMsg    ? Logger::Info  :
        type == QtWarningMsg ? Logger::Warning : Logger::Critical;

    // Get the current depth
    const auto nesting = logger->depth;

    QMetaObject::invokeMethod(
        logger,
        [logger, msg, level, nesting]() { logger->log(msg, level, nesting); },
        Qt::QueuedConnection);

    const bool ours = context.category && qstrcmp(context.category, "silicium") == 0;

    if (Logger::originalHandler && !ours) {
        Logger::originalHandler(type, context, msg);
    } else if constexpr (debugBuild) {
        printf("SILICIUM: %s\n", msg.toStdString().c_str());
    }
}

//
// Logger
//

Logger::Logger() : m_filter(new LogFilter(this))
{
    m_filter->setSourceModel(this);

    log(QString("Silicium Retro Emulator %1").arg(AppController::version()), Info, 0);
    log(QString("(C)opyright Dirk W. Hoffmann, www.dirkwhoffmann.de"), Info, 0);
    log(QString(""), Info, 0);
}

Logger *
Logger::instance()
{
    static Logger *inst = new Logger();
    return inst;
}

void
Logger::install()
{
    static bool installed = false;

    if (!installed) {

        installed = true;

        // Build the logger
        (void) instance();

        // Let Qt route messages into it
        originalHandler = qInstallMessageHandler(messageHandler);
    }
}

quint64
Logger::nextTaskId()
{
    static std::atomic<quint64> counter { 0 };
    return ++counter;
}

void
Logger::log(const QString &message, Level level, int nesting)
{
    Entry entry;

    entry.message = message;
    entry.time    = QDateTime::currentDateTime().toString("hh:mm:ss");
    entry.level   = level;
    entry.depth   = nesting < 0 ? depth : nesting;

    // Remove trailing newlines
    while (entry.message.endsWith('\n') || entry.message.endsWith('\r'))
        entry.message.chop(1);

    // Drop the oldest entries
    if (m_entries.size() >= capacity) {

        const int excess = m_entries.size() - capacity + 1;

        beginRemoveRows({}, 0, excess - 1);
        m_entries.remove(0, excess);
        endRemoveRows();
    }

    const int row = m_entries.size();

    beginInsertRows({}, row, row);
    m_entries.append(entry);
    endInsertRows();
}

void
Logger::beginTask(quint64 id, const QString &message, int nesting)
{
    log(message, Info, nesting);
    m_entries.last().taskId = id;
}

void
Logger::endTask(quint64 id, bool failed, qint64 elapsed)
{
    // Searched from the back since a task finishes near where it started
    for (int row = m_entries.size() - 1; row >= 0; row--) {

        if (m_entries[row].taskId != id) continue;

        m_entries[row].completed = true;
        m_entries[row].failed    = failed;
        m_entries[row].elapsed   = elapsed;

        const auto idx = index(row);
        emit dataChanged(idx, idx);
        return;
    }
}

//
// Methods from QAbstractListModel
//

int
Logger::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_entries.size());
}

QVariant
Logger::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_entries.size()) return {};

    const auto &e = m_entries[index.row()];

    switch (role) {

        case MessageRole: return e.message;
        case TimeRole:    return e.time;
        case LevelRole:   return e.level;
        case DepthRole:   return e.depth;
        case IsTaskRole:  return e.isTask();
        case StatusRole:  return e.status();
        case ElapsedRole: return QString("%1 ms").arg(e.elapsed);
    }
    return {};
}

QHash<int, QByteArray>
Logger::roleNames() const
{
    return {
        { MessageRole, "message" },
        { TimeRole,    "time"    },
        { LevelRole,   "level"   },
        { DepthRole,   "depth"   },
        { IsTaskRole,  "isTask"  },
        { StatusRole,  "status"  },
        { ElapsedRole, "elapsed" }
    };
}

QAbstractItemModel *
Logger::filtered() const
{
    return m_filter;
}

int
Logger::verbosity() const
{
    return m_filter->verbosity();
}

void
Logger::setVerbosity(int value)
{
    if (m_filter->verbosity() != value) {

        m_filter->setVerbosity(value);
        emit verbosityChanged();
    }
}

//
// LogFilter
//

void
LogFilter::setVerbosity(int value)
{
    if (m_verbosity != value) {

        beginFilterChange();
        m_verbosity = value;
        endFilterChange();
    }
}

bool
LogFilter::filterAcceptsRow(int row, const QModelIndex &parent) const
{
    // Verbisity 0 : Problems only
    // Verbosity 1 : Standard log
    // Verbosity 2 : All messages

    const Logger::Level limit = m_verbosity <= 0 ? Logger::Warning :
                                m_verbosity == 1 ? Logger::Info : Logger::Debug;

    auto idx = sourceModel()->index(row, 0, parent);
    return idx.data(Logger::LevelRole).toInt() <= limit;
}

//
// LogTask
//

LogTask::LogTask(QString msg) : id(Logger::nextTaskId()), exceptions(std::uncaught_exceptions())
{
    auto *logger = Logger::instance();

    const quint64 taskId = id;
    const int nesting = logger->depth;

    QMetaObject::invokeMethod(
        logger,
        [logger, taskId, msg, nesting]() { logger->beginTask(taskId, msg, nesting); },
        Qt::QueuedConnection);

    logger->depth++;
    timer.start();
}

LogTask::~LogTask()
{
    auto *logger = Logger::instance();

    logger->depth--;

    const quint64 taskId = id;
    const bool failed    = std::uncaught_exceptions() > exceptions;
    const qint64 elapsed = timer.elapsed();

    QMetaObject::invokeMethod(
        logger,
        [logger, taskId, failed, elapsed]() { logger->endTask(taskId, failed, elapsed); },
        Qt::QueuedConnection);
}
