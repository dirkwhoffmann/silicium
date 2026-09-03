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
#include <QVector>

//
// List model backing a future SiAmEventsPanel's event table. Port of
// SiC64EventTableModel -- no vAmiga/vc64-specific types anywhere in here,
// so this needed no adaptation beyond the class name. Kept as a single,
// long-lived instance so QML's ListView never sees the model identity
// change -- refreshData() calls setRows() on every tick, which updates the
// existing rows in place (dataChanged) instead of tearing the model down
// and rebuilding it, so the view's scroll position is never disturbed.
//

class SiAmEventTableModel : public QAbstractListModel {

    Q_OBJECT

  public:

    struct Row {

        QString slot;
        QString event;
        bool pending = false;
        bool due = false;
        QString trigger;
        QString frame;
        QString vpos;
        QString hpos;
        QString remark;
    };

    enum Role {

        SlotRole = Qt::UserRole + 1,
        EventRole,
        PendingRole,
        DueRole,
        TriggerRole,
        FrameRole,
        VposRole,
        HposRole,
        RemarkRole
    };

    explicit SiAmEventTableModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRows(const QVector<Row> &rows);

  private:

    QVector<Row> m_rows;
};
