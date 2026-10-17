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
// List model backing SiC64MemoryPanel's hex/ASCII dump table. Kept as a
// single, long-lived instance so QML's ListView never sees the model
// identity change -- refreshData() calls setRows() on every tick, which
// updates the existing rows in place (dataChanged) instead of tearing the
// model down and rebuilding it, so the view's scroll position is never
// disturbed.
//

class SiC64MemDumpModel : public QAbstractListModel {

    Q_OBJECT

  public:

    struct Row {

        QString addr;
        QString hex;
        QString ascii;
    };

    enum Role {

        AddrRole = Qt::UserRole + 1,
        HexRole,
        AsciiRole
    };

    explicit SiC64MemDumpModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRows(const QVector<Row> &rows);

  private:

    QVector<Row> m_rows;
};
