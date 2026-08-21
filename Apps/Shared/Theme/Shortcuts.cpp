// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Shortcuts.h"
#include <QKeySequence>

Shortcuts::Shortcuts(QObject *parent) : QObject(parent)
{

}

Shortcuts &
Shortcuts::instance()
{
    static Shortcuts inst;
    return inst;
}

QString
Shortcuts::nativeText(const QVariant &shortcut) const
{
    auto seq = shortcut.value<QKeySequence>();
    return seq.isEmpty() ? QString() : seq.toString(QKeySequence::NativeText);
}
