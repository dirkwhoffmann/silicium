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
#include "VirtualC64.h"
#include "InputManager.h"
#include "C64KeyModel.h"
#include <QQuickWindow>

using vc64::VirtualC64;
using vc64::C64Key;
using vc64::KeyboardAPI;

class SiC64KeyboardController : public Controller {

Q_OBJECT

    class C64Controller *parent = nullptr;
    VirtualC64 &core;
    KeyboardAPI &keyboard;

protected:

    // Data model feeding the keyboard's Repeater
    C64KeyModel *m_keyModel = nullptr;

public:

    explicit SiC64KeyboardController(C64Controller *parent = nullptr);
    ~SiC64KeyboardController();

    static std::vector<C64Key> keySequence(QKeyEvent *event, KeyModifier modifier);
    static QHash<quint32, int> defaultC64KeyMap();

    Q_PROPERTY(QQuickWindow *window MEMBER m_window)
    Q_PROPERTY(C64KeyModel *keyModel MEMBER m_keyModel CONSTANT)

    // Whether the Commodore key is currently held down (or locked). Shown as
    // a statusbar pictogram.
    Q_PROPERTY(bool commodore READ commodore NOTIFY commodoreChanged)


    //
    // Keyboard state changes
    //

public:

    // Called by C64Controller for every Msg::KB_PRESS / KB_RELEASE the core
    // reports. Fans the raw key number out to the signals below -- the
    // keyboard's own state changes don't go through the info controller's
    // coalesced infoChanged(), since they must land immediately and
    // individually to keep the on-screen keyboard in step with the matrix.
    void kbChanged(int nr, bool pressed);

    bool commodore() const;


    //
    // Methods from InputManagerDelegate
    //

public:

    void keyDown(QKeyEvent *even, KeyModifier modifiers) override;
    void keyUp(QKeyEvent *even, KeyModifier modifiers) override;
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

    Q_INVOKABLE void type(int key, bool shift = false, double duration = 0.05);
    Q_INVOKABLE void typeRunStopRestore(double duration = 0.1);
    Q_INVOKABLE void type(const QString &text);

private:

    void keyComboDown(int action);
    void keyComboUp(int action);
    void keyDownPositional(QKeyEvent *event, KeyModifier modifiers);
    void keyDownSymbolic(QKeyEvent *event, KeyModifier modifiers);
    void keyUpPositional(QKeyEvent *event, KeyModifier modifiers);
    void keyUpSymbolic(QKeyEvent *event, KeyModifier modifiers);


    //
    // Slots
    //

public slots:

    void activeChanged(bool state);


    //
    // Signals
    //

signals:

    // A single key changed state. 'nr' is a C64Key number, or -1 to signal
    // that the whole matrix was cleared.
    void keyChanged(int nr, bool pressed);

    // The Commodore key specifically changed state (filtered from the above).
    void commodoreChanged();
};
