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
#include "VAmiga.h"
#include "InputManager.h"
#include "AmigaKeyModel.h"
#include <QQuickWindow>

using vamiga::VAmiga;
using vamiga::KeyboardAPI;

/* Port of SiC64KeyboardController, minus its symbolic mode.
 *
 * The C64 offers two mapping schemes: positional (physical key -> the key
 * sitting in the same spot on a C64 keyboard) and symbolic (physical key ->
 * whatever C64 key produces the same character, shift keys included). The
 * Amiga needs only the first one: its keyboard is laid out like a modern one,
 * and the core's keycodes are themselves defined positionally ("These are key
 * codes assigned to specific positions on the main body of the keyboard. The
 * letters on the tops of these keys are different for each country" -- Amiga
 * Hardware Reference), so a physical key maps to exactly one keycode and the
 * Amiga's own keymap does the rest. There is no scheme to choose, and no
 * key-sequence translation table.
 */
class SiAmKeyboardController : public Controller {

    Q_OBJECT

    class SiAmController *parent = nullptr;
    VAmiga &core;
    KeyboardAPI &keyboard;

protected:

    // Data model feeding the keyboard's Repeater
    AmigaKeyModel *m_keyModel = nullptr;

public:

    explicit SiAmKeyboardController(SiAmController *parent = nullptr);

    /* Maps physical keys to Amiga keycodes. Ported from vAmiga's own
     * isomac2amiga (GUI/Input/MacKey.swift), i.e. keyed by macOS virtual key
     * code -- which is what InputManager::physicalKeyCode() hands back there.
     *
     * Unlike the C64's map, this one is fixed: SiC64's counterpart is stored
     * in Preferences so the virtual keyboard's key-recording feature can
     * override single entries (see Preferences::setC64KeyMapping), and there
     * is no such editor on the Amiga side yet. Should one appear, this is the
     * table its factory defaults come from -- the same role
     * SiC64KeyboardController::defaultC64KeyMap() plays for the C64.
     */
    static const QHash<quint32, int> &defaultAmigaKeyMap();

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)
    Q_PROPERTY(AmigaKeyModel *keyModel MEMBER m_keyModel CONSTANT)


    //
    // Keyboard state changes
    //

public:

    // Called by SiAmController for every Msg::KB_PRESS / KB_RELEASE the core
    // reports. Fans the raw keycode out to keyChanged() below -- the
    // keyboard's own state changes don't go through the info controller's
    // coalesced refresh, since they must land immediately and individually to
    // keep the on-screen keyboard in step with the matrix. Routing every
    // change through the core (rather than emitting from press()/release()
    // directly) is also what lets physical typing move the on-screen keys.
    void kbChanged(int nr, bool pressed);


    //
    // Methods from InputManagerDelegate
    //

public:

    void keyDown(QKeyEvent *event, KeyModifier modifiers) override;
    void keyUp(QKeyEvent *event, KeyModifier modifiers) override;
    void keyCombo(KeyCombo combo, int count) override;


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
