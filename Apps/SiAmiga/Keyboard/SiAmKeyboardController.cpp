// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmKeyboardController.h"
#include "SiAmController.h"

using namespace vamiga;

SiAmKeyboardController::SiAmKeyboardController(SiAmController *parent)
    : Controller(parent), parent(parent)
{
    m_keyModel = new AmigaKeyModel(this);
}

bool
SiAmKeyboardController::isPressed(int key) const
{
    return SiAmController::core().keyboard.isPressed((KeyCode)key);
}

void
SiAmKeyboardController::press(int key)
{
    SiAmController::core().keyboard.press((KeyCode)key);
    emit keyChanged(key, true);
}

void
SiAmKeyboardController::release(int key)
{
    SiAmController::core().keyboard.release((KeyCode)key);
    emit keyChanged(key, false);
}

void
SiAmKeyboardController::toggle(int key)
{
    SiAmController::core().keyboard.toggle((KeyCode)key);
    emit keyChanged(key, isPressed(key));
}

void
SiAmKeyboardController::resetKeyboardMatrix()
{
    SiAmController::core().keyboard.releaseAll();
    emit keyChanged(-1, false);
}

void
SiAmKeyboardController::activeChanged(bool state)
{
    // No physical-keyboard passthrough registered yet -- see the header
    // comment. Once keyDown/keyUp translation exists, this is where it
    // would register/unregister with the InputManager the way
    // SiC64KeyboardController::activeChanged does.
}
