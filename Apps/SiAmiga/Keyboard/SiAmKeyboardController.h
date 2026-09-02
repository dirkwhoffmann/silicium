// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "AmigaKeyModel.h"
#include <QQuickWindow>

// Port of SiC64KeyboardController, trimmed to what the virtual on-screen
// keyboard itself needs (press/release/toggle driven by mouse clicks on
// SiAmKeyboardPanel's keys). SiC64KeyboardController's physical-keyboard
// passthrough (translating real QKeyEvents into C64 key sequences,
// positional vs. symbolic mapping, key combos, ...) has no counterpart
// here yet -- that's a separate, substantial piece of work on top of this,
// not something the virtual keyboard window itself needs.
class SiAmKeyboardController : public Controller {

    Q_OBJECT

    class SiAmController *parent = nullptr;

protected:

    // Data model feeding the keyboard's Repeater
    AmigaKeyModel *m_keyModel = nullptr;

public:

    explicit SiAmKeyboardController(SiAmController *parent = nullptr);

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)
    Q_PROPERTY(AmigaKeyModel *keyModel MEMBER m_keyModel CONSTANT)


    //
    // Operating the keyboard via QML
    //

public:

    Q_INVOKABLE bool isPressed(int key) const;
    Q_INVOKABLE void press(int key);
    Q_INVOKABLE void release(int key);
    Q_INVOKABLE void toggle(int key);
    Q_INVOKABLE void resetKeyboardMatrix();


    //
    // Slots
    //

public slots:

    void activeChanged(bool state);


    //
    // Signals
    //

signals:

    // A single key changed state. 'nr' is an Amiga keycode, or -1 to signal
    // that the whole matrix was cleared.
    void keyChanged(int nr, bool pressed);
};
