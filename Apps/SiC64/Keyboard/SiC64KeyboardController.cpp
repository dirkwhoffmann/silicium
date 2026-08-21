// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64KeyboardController.h"
#include "C64Controller.h"

using namespace vc64;

SiC64KeyboardController::SiC64KeyboardController(C64Controller *parent)
        : Controller(parent), parent(parent), core(C64Controller::core()), keyboard(core.keyboard)
{
    m_keyModel = new C64KeyModel(this);
}

SiC64KeyboardController::~SiC64KeyboardController()
{

}

std::vector<C64Key>
SiC64KeyboardController::keySequence(QKeyEvent *event, KeyModifier modifier) {

    const bool shift = modifier.shift();

    switch (event->key()) {

        case Qt::Key_F1:            return { C64Key::F1F2 };
        case Qt::Key_F2:            return { C64Key::leftShift, C64Key::F1F2 };
        case Qt::Key_F3:            return { C64Key::F3F4 };
        case Qt::Key_F4:            return { C64Key::leftShift, C64Key::F3F4 };
        case Qt::Key_F5:            return { C64Key::F5F6 };
        case Qt::Key_F6:            return { C64Key::leftShift, C64Key::F5F6 };
        case Qt::Key_F7:            return { C64Key::F7F8 };
        case Qt::Key_F8:            return { C64Key::leftShift, C64Key::F7F8 };
        case Qt::Key_Udiaeresis:    return { C64Key::leftArrow };
        case Qt::Key_Left:          return { C64Key::leftShift, C64Key::curLeftRight };
        case Qt::Key_Right:         return { C64Key::curLeftRight };
        case Qt::Key_Up:            return { C64Key::leftShift, C64Key::curUpDown };
        case Qt::Key_Down:          return { C64Key::curUpDown };
        case Qt::Key_Tab:           return { C64Key::control };
        case Qt::Key_Backspace:     return { C64Key::del };
        case Qt::Key_Insert:        return { C64Key::leftShift, C64Key::del };
        case Qt::Key_section:       return { C64Key::pound };
        case Qt::Key_Space:         return C64Key::translate(' ');
        case Qt::Key_Exclam:        return C64Key::translate('!');
        case Qt::Key_QuoteDbl:      return C64Key::translate('"');
        case Qt::Key_NumberSign:    return C64Key::translate('#');
        case Qt::Key_Dollar:        return C64Key::translate('$');
        case Qt::Key_Percent:       return C64Key::translate('%');
        case Qt::Key_Ampersand:     return C64Key::translate('&');
        case Qt::Key_Apostrophe:    return C64Key::translate('\'');
        case Qt::Key_ParenLeft:     return C64Key::translate('(');
        case Qt::Key_ParenRight:    return C64Key::translate(')');
        case Qt::Key_Asterisk:      return C64Key::translate('*');
        case Qt::Key_Plus:          return C64Key::translate('+');
        case Qt::Key_Comma:         return C64Key::translate(',');
        case Qt::Key_Minus:         return C64Key::translate('-');
        case Qt::Key_Period:        return C64Key::translate('.');
        case Qt::Key_Slash:         return C64Key::translate('/');
        case Qt::Key_0:             return C64Key::translate('0');
        case Qt::Key_1:             return C64Key::translate('1');
        case Qt::Key_2:             return C64Key::translate('2');
        case Qt::Key_3:             return C64Key::translate('3');
        case Qt::Key_4:             return C64Key::translate('4');
        case Qt::Key_5:             return C64Key::translate('5');
        case Qt::Key_6:             return C64Key::translate('6');
        case Qt::Key_7:             return C64Key::translate('7');
        case Qt::Key_8:             return C64Key::translate('8');
        case Qt::Key_9:             return C64Key::translate('9');
        case Qt::Key_Colon:         return C64Key::translate(':');
        case Qt::Key_Semicolon:     return C64Key::translate(';');
        case Qt::Key_Less:          return C64Key::translate('<');
        case Qt::Key_Equal:         return C64Key::translate('=');
        case Qt::Key_Greater:       return C64Key::translate('>');
        case Qt::Key_Question:      return C64Key::translate('?');
        case Qt::Key_At:            return C64Key::translate('@');
        case Qt::Key_A:             return C64Key::translate(shift ? 'A' : 'a');
        case Qt::Key_B:             return C64Key::translate(shift ? 'B' : 'b');
        case Qt::Key_C:             return C64Key::translate(shift ? 'C' : 'c');
        case Qt::Key_D:             return C64Key::translate(shift ? 'D' : 'd');
        case Qt::Key_E:             return C64Key::translate(shift ? 'E' : 'e');
        case Qt::Key_F:             return C64Key::translate(shift ? 'F' : 'f');
        case Qt::Key_G:             return C64Key::translate(shift ? 'G' : 'g');
        case Qt::Key_H:             return C64Key::translate(shift ? 'H' : 'h');
        case Qt::Key_I:             return C64Key::translate(shift ? 'I' : 'i');
        case Qt::Key_J:             return C64Key::translate(shift ? 'J' : 'j');
        case Qt::Key_K:             return C64Key::translate(shift ? 'K' : 'k');
        case Qt::Key_L:             return C64Key::translate(shift ? 'L' : 'l');
        case Qt::Key_M:             return C64Key::translate(shift ? 'M' : 'm');
        case Qt::Key_N:             return C64Key::translate(shift ? 'N' : 'n');
        case Qt::Key_O:             return C64Key::translate(shift ? 'O' : 'o');
        case Qt::Key_P:             return C64Key::translate(shift ? 'P' : 'p');
        case Qt::Key_Q:             return C64Key::translate(shift ? 'Q' : 'q');
        case Qt::Key_R:             return C64Key::translate(shift ? 'R' : 'r');
        case Qt::Key_S:             return C64Key::translate(shift ? 'S' : 's');
        case Qt::Key_T:             return C64Key::translate(shift ? 'T' : 't');
        case Qt::Key_U:             return C64Key::translate(shift ? 'U' : 'u');
        case Qt::Key_V:             return C64Key::translate(shift ? 'V' : 'v');
        case Qt::Key_W:             return C64Key::translate(shift ? 'W' : 'w');
        case Qt::Key_X:             return C64Key::translate(shift ? 'X' : 'x');
        case Qt::Key_Y:             return C64Key::translate(shift ? 'Y' : 'y');
        case Qt::Key_Z:             return C64Key::translate(shift ? 'Z' : 'z');
        case Qt::Key_BracketLeft:   return C64Key::translate('[');
        case Qt::Key_Backslash:     return C64Key::translate('\\');
        case Qt::Key_BracketRight:  return C64Key::translate(']');
        case Qt::Key_AsciiCircum:   return C64Key::translate('^');
        case Qt::Key_Underscore:    return C64Key::translate('_');
        case Qt::Key_QuoteLeft:     return C64Key::translate('`');
        case Qt::Key_BraceLeft:     return C64Key::translate('{');
        case Qt::Key_Bar:           return C64Key::translate('|');
        case Qt::Key_BraceRight:    return C64Key::translate('}');
        case Qt::Key_AsciiTilde:    return C64Key::translate('~');
        case Qt::Key_Return:
        case Qt::Key_Enter:         return C64Key::translate('\n');

        default:
            return { };
    }
}

QHash<quint32, int>
SiC64KeyboardController::defaultC64KeyMap() {

    QHash<quint32, int> map;

    map.insert(0x00, (int)C64Key::A.nr);
    map.insert(0x0B, (int)C64Key::B.nr);
    map.insert(0x08, (int)C64Key::C.nr);
    map.insert(0x02, (int)C64Key::D.nr);
    map.insert(0x0E, (int)C64Key::E.nr);
    map.insert(0x03, (int)C64Key::F.nr);
    map.insert(0x05, (int)C64Key::G.nr);
    map.insert(0x04, (int)C64Key::H.nr);
    map.insert(0x22, (int)C64Key::I.nr);
    map.insert(0x26, (int)C64Key::J.nr);
    map.insert(0x28, (int)C64Key::K.nr);
    map.insert(0x25, (int)C64Key::L.nr);
    map.insert(0x2E, (int)C64Key::M.nr);
    map.insert(0x2D, (int)C64Key::N.nr);
    map.insert(0x1F, (int)C64Key::O.nr);
    map.insert(0x23, (int)C64Key::P.nr);
    map.insert(0x0C, (int)C64Key::Q.nr);
    map.insert(0x0F, (int)C64Key::R.nr);
    map.insert(0x01, (int)C64Key::S.nr);
    map.insert(0x11, (int)C64Key::T.nr);
    map.insert(0x20, (int)C64Key::U.nr);
    map.insert(0x09, (int)C64Key::V.nr);
    map.insert(0x0D, (int)C64Key::W.nr);
    map.insert(0x07, (int)C64Key::X.nr);
    map.insert(0x10, (int)C64Key::Y.nr);
    map.insert(0x06, (int)C64Key::Z.nr);

    map.insert(0x12, (int)C64Key::digit1.nr);
    map.insert(0x13, (int)C64Key::digit2.nr);
    map.insert(0x14, (int)C64Key::digit3.nr);
    map.insert(0x15, (int)C64Key::digit4.nr);
    map.insert(0x17, (int)C64Key::digit5.nr);
    map.insert(0x16, (int)C64Key::digit6.nr);
    map.insert(0x1A, (int)C64Key::digit7.nr);
    map.insert(0x1C, (int)C64Key::digit8.nr);
    map.insert(0x19, (int)C64Key::digit9.nr);
    map.insert(0x1D, (int)C64Key::digit0.nr);
    map.insert(0x1B, (int)C64Key::plus.nr);
    map.insert(0x18, (int)C64Key::minus.nr);

    map.insert(0x31, (int)C64Key::space.nr);
    map.insert(0x24, (int)C64Key::ret.nr);
    map.insert(0x33, (int)C64Key::del.nr);
    map.insert(0x38, (int)C64Key::leftShift.nr);
    map.insert(0x3C, (int)C64Key::rightShift.nr);
    map.insert(0x2B, (int)C64Key::comma.nr);
    map.insert(0x2F, (int)C64Key::period.nr);
    map.insert(0x2C, (int)C64Key::slash.nr);
    map.insert(0x29, (int)C64Key::colon.nr);
    map.insert(0x27, (int)C64Key::semicolon.nr);
    map.insert(0x2A, (int)C64Key::equal.nr);
    map.insert(0x21, (int)C64Key::asterisk.nr);
    map.insert(0x1E, (int)C64Key::at.nr);
    map.insert(0x7D, (int)C64Key::curUpDown.nr);
    map.insert(0x7C, (int)C64Key::curLeftRight.nr);

    map.insert(0x7A, (int)C64Key::F1F2.nr); // F1
    map.insert(0x78, (int)C64Key::F1F2.nr); // F2
    map.insert(0x63, (int)C64Key::F3F4.nr); // F3
    map.insert(0x76, (int)C64Key::F3F4.nr); // F4
    map.insert(0x60, (int)C64Key::F5F6.nr); // F5
    map.insert(0x61, (int)C64Key::F5F6.nr); // F6
    map.insert(0x62, (int)C64Key::F7F8.nr); // F7
    map.insert(0x64, (int)C64Key::F7F8.nr); // F8

    return map;
}

void
SiC64KeyboardController::kbChanged(int nr, bool pressed)
{
    emit keyChanged(nr, pressed);

    // nr == -1 means the entire matrix was cleared, which releases the
    // Commodore key along with everything else.
    if (nr == int(C64Key::commodore.nr) || nr == -1) emit commodoreChanged();
}

bool
SiC64KeyboardController::commodore() const
{
    return keyboard.isPressed(C64Key::commodore);
}

bool
SiC64KeyboardController::isPressed(int key) const
{
    return keyboard.isPressed(C64Key(key));
}

void
SiC64KeyboardController::press(int key)
{
    keyboard.press(key);
}

void
SiC64KeyboardController::release(int key)
{
    keyboard.release(key);
}

void
SiC64KeyboardController::toggle(int key)
{
    keyboard.toggle(key);
}

void
SiC64KeyboardController::resetKeyboardMatrix()
{
    keyboard.unlockAll();
    keyboard.releaseAll();
}

void
SiC64KeyboardController::type(int key, bool shift, double duration)
{
    if (shift) keyboard.press(C64Key::leftShift, 0.0, duration);
    keyboard.press(key, 0.0, duration);
}

void
SiC64KeyboardController::type(const QString &text)
{
    keyboard.autoType(text.toStdString());
}

void
SiC64KeyboardController::typeRunStopRestore(double duration)
{
    keyboard.press(C64Key::runStop, 0.0, duration);
    keyboard.press(C64Key::restore, 0.0, duration);
}

void
SiC64KeyboardController::keyDown(QKeyEvent *event, KeyModifier modifiers)
{
    switch (preferences().getC64KeyMapScheme()) {

        case 0: keyDownPositional(event, modifiers); break;
        case 1: keyDownSymbolic(event, modifiers); break;

        default:
            break;
    }
}

void
SiC64KeyboardController::keyCombo(KeyCombo combo, int count)
{
    auto exec = [&](int action) {
        count ? keyComboDown(action) : keyComboUp(action);
    };

    switch (combo) {

        case KeyCombo::CtrlAltL: exec(preferences().getC64CtrlLeftAlt()); break;
        case KeyCombo::CtrlAltR: exec(preferences().getC64CtrlRightAlt()); break;
        case KeyCombo::CtrlMetaL: exec(preferences().getC64CtrlLeftMeta()); break;
        case KeyCombo::CtrlMetaR: exec(preferences().getC64CtrlRightMeta()); break;

        default:
            break;
    }
}

void
SiC64KeyboardController::keyComboDown(int action)
{
    switch (action) {

        case 1: // Press Commodore key

            keyboard.press(C64Key::commodore);
            break;

        case 2: // Hold Commodore key

            if (keyboard.isPressed(C64Key::commodore)) {

                keyboard.unlock(C64Key::commodore);
                keyboard.release(C64Key::commodore);

            } else {

                keyboard.press(C64Key::commodore);
                keyboard.lock(C64Key::commodore);
            }

        default:
            break;
    }
}

void
SiC64KeyboardController::keyComboUp(int action)
{
    switch (action) {

        case 1: // Press Commodore key

            keyboard.release(C64Key::commodore);
            break;

        default:
            break;
    }
}

void
SiC64KeyboardController::keyDownPositional(QKeyEvent *event, KeyModifier modifiers)
{
    auto scanCode = InputManager::physicalKeyCode(event);
    auto &map = preferences().getC64KeyMap();

    if (auto it = map.constFind(scanCode); it != map.constEnd()) {

        keyboard.press(C64Key(it.value()));
    }
}

void
SiC64KeyboardController::keyDownSymbolic(QKeyEvent *event, KeyModifier modifiers)
{
    // Ignore everything when the Ctrl key is pressed
    if (modifiers.ctrl()) return;

    auto keys = keySequence(event, modifiers);

    /* Note: Fast typists often press the next key before releasing the
     * previous one. On a real C64, multiple simultaneously pressed keys can
     * produce phantom key detections due to the keyboard matrix design.
     * To avoid this, all currently pressed keys are released before the new
     * key sequence is pressed.
     */
    keyboard.releaseAll();

    /* Press all keys. In auto-release mode, each key press is scheduled to be
     * released automatically after a short delay. Any physical key release by
     * the user is ignored. Otherwise, keys remain pressed until the user
     * releases them.
     *
     * Note: Without auto-release, very short key presses may be missed by the
     * emulated C64 if the host user types faster than the machine scans the
     * keyboard matrix.
     */
    if (preferences().getC64AutoReleaseKeys()) {
        for (auto &k: keys) keyboard.press(k, 0.0, 0.05);
    } else {
        for (auto &k: keys) keyboard.press(k, 0.0);
    }
}

void
SiC64KeyboardController::keyUp(QKeyEvent *event, KeyModifier modifiers)
{
    // Ignore everything when the Ctrl key is pressed
    if (modifiers.ctrl()) return;

    if (keyboard.isLocked(C64Key::commodore)) {

        keyboard.unlock(C64Key::commodore);
        keyboard.release(C64Key::commodore);
    }

    keyboard.unlockAll();

    switch (preferences().getC64KeyMapScheme()) {

        case 0: keyUpPositional(event, modifiers); break;
        case 1: keyUpSymbolic(event, modifiers); break;

        default:
            break;
    }
}

void
SiC64KeyboardController::keyUpPositional(QKeyEvent *event, KeyModifier modifiers)
{
    auto scanCode = InputManager::physicalKeyCode(event);
    auto &map = preferences().getC64KeyMap();

    if (auto it = map.constFind(scanCode); it != map.constEnd()) {

        keyboard.release(C64Key(it.value()));
    }
}

void
SiC64KeyboardController::keyUpSymbolic(QKeyEvent *event, KeyModifier modifiers)
{
    if (!preferences().getC64AutoReleaseKeys()) {
        keyboard.releaseAll();
    }
}

void
SiC64KeyboardController::activeChanged(bool state)
{
    if (state) inputManager.setDelegate(this);
}
