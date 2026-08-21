// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QDataStream>
#include <QObject>
#include <QMetaType>
#include <QString>
#include <QtQml>

struct EmulationKey {

Q_GADGET
QML_NAMED_ELEMENT(emulationkey)

public:

    // Qt keycode (platform independent)
    int qKey;

    // Physical keycode (platform dependent)
    int pKey;

    Q_PROPERTY(int qKey MEMBER qKey)
    Q_PROPERTY(int pKey MEMBER pKey)
    Q_PROPERTY(QString name READ name)

    EmulationKey(int qKey = -1, int pKey = -1) : qKey(qKey), pKey(pKey) {}

    auto operator<=>(const EmulationKey &) const = default;

    QString name() const;

    Q_INVOKABLE QString toDisplayString() const { return name(); }
};

Q_DECLARE_METATYPE(EmulationKey)

inline QDataStream &operator<<(QDataStream &out, const EmulationKey &k)
{
    return out << k.qKey << k.pKey;
}

inline QDataStream &operator>>(QDataStream &in, EmulationKey &k)
{
    return in >> k.qKey >> k.pKey;
}