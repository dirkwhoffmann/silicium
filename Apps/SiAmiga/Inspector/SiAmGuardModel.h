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
// List model backing a breakpoint/watchpoint table -- one row per guard
// currently set on a vamiga::GuardsAPI list (see SiAmCopperController's
// 'breakpoints' property, the first consumer). Generic on purpose: nothing
// here is Copper-specific, so a future CPU breakpoints/watchpoints panel
// can reuse this directly the same way SiAmMemDumpModel/
// SiAmCopperListModel are shared shapes rather than one-off models.
//

class SiAmGuardModel : public QAbstractListModel {

    Q_OBJECT

  public:

    struct Row {

        quint32 rawAddr = 0;
        QString addr;
        bool enabled = true;
    };

    enum Role {

        AddrRole = Qt::UserRole + 1,
        EnabledRole
    };

    explicit SiAmGuardModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRows(const QVector<Row> &rows);

    quint32 addrAt(int row) const;

  private:

    QVector<Row> m_rows;
};
