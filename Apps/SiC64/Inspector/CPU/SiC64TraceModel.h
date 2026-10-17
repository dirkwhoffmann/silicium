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
// List model backing SiC64CPUTraceView's recorded-instruction table. Kept as
// a single, long-lived instance so QML's ListView never sees the model
// identity change -- refreshData() calls setRows() on every tick, which
// updates the existing rows in place (dataChanged) instead of tearing the
// model down and rebuilding it, so the view's scroll position is never
// disturbed.
//

class SiC64TraceModel : public QAbstractListModel {

    Q_OBJECT

  public:

    struct Row {

        int addrValue = 0;
        QString addr;
        QString flags;
        QString instr;
    };

    enum Role {

        AddrValueRole = Qt::UserRole + 1,
        AddrRole,
        FlagsRole,
        InstrRole
    };

    explicit SiC64TraceModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRows(const QVector<Row> &rows);

  private:

    QVector<Row> m_rows;
};
