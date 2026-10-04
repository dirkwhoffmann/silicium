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
#include <QVariant>

// Exposed to QML as the "Shortcuts" singleton (see Sulfur). Formats
// Action.shortcut values for display, translating Qt's portable modifier
// names (Ctrl, Meta, Alt, ...) into the labels/symbols the current platform
// actually shows in its native menus -- e.g. on macOS "Ctrl+G" (Qt's
// portable name for the key users see as Cmd) is displayed as "⌘G", not
// the literal string "Ctrl+G", which would be read as the physical Control
// key and confuse users.
class Shortcuts : public QObject {

    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:

    static Shortcuts &instance();

    // The factory QML uses to get hold of the singleton
    static Shortcuts *create(QQmlEngine *, QJSEngine *);

    Shortcuts(const Shortcuts&) = delete;
    Shortcuts& operator=(const Shortcuts&) = delete;

    // Converts an Action.shortcut value into the platform-native display text
    Q_INVOKABLE QString nativeText(const QVariant &shortcut) const;

  private:

    explicit Shortcuts(QObject *parent = nullptr);
};
