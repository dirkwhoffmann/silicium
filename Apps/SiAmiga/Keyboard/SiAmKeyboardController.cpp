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

namespace {

/* macOS virtual key codes (Carbon's kVK_* constants, HIToolbox/Events.h).
 *
 * InputManager::physicalKeyCode() reports these on macOS, which is what the
 * map below is keyed by -- see the note there. Spelled out here rather than
 * pulled in from Carbon so the table stays readable next to vAmiga's own
 * isomac2amiga, which it is ported from.
 */
namespace mac {

constexpr quint32 ansiA = 0x00, ansiS = 0x01, ansiD = 0x02, ansiF = 0x03;
constexpr quint32 ansiH = 0x04, ansiG = 0x05, ansiZ = 0x06, ansiX = 0x07;
constexpr quint32 ansiC = 0x08, ansiV = 0x09, isoSection = 0x0A, ansiB = 0x0B;
constexpr quint32 ansiQ = 0x0C, ansiW = 0x0D, ansiE = 0x0E, ansiR = 0x0F;
constexpr quint32 ansiY = 0x10, ansiT = 0x11;
constexpr quint32 ansi1 = 0x12, ansi2 = 0x13, ansi3 = 0x14, ansi4 = 0x15;
constexpr quint32 ansi6 = 0x16, ansi5 = 0x17, ansiEqual = 0x18, ansi9 = 0x19;
constexpr quint32 ansi7 = 0x1A, ansiMinus = 0x1B, ansi8 = 0x1C, ansi0 = 0x1D;
constexpr quint32 ansiRightBracket = 0x1E, ansiO = 0x1F, ansiU = 0x20;
constexpr quint32 ansiLeftBracket = 0x21, ansiI = 0x22, ansiP = 0x23;
constexpr quint32 ret = 0x24, ansiL = 0x25, ansiJ = 0x26, ansiQuote = 0x27;
constexpr quint32 ansiK = 0x28, ansiSemicolon = 0x29, ansiBackslash = 0x2A;
constexpr quint32 ansiComma = 0x2B, ansiSlash = 0x2C, ansiN = 0x2D;
constexpr quint32 ansiM = 0x2E, ansiPeriod = 0x2F, tab = 0x30, space = 0x31;
constexpr quint32 ansiGrave = 0x32, del = 0x33, escape = 0x35;
constexpr quint32 rightCommand = 0x36, command = 0x37, shift = 0x38;
constexpr quint32 option = 0x3A, control = 0x3B, rightShift = 0x3C;
constexpr quint32 rightOption = 0x3D;
constexpr quint32 keypadDecimal = 0x41, keypadMultiply = 0x43, keypadPlus = 0x45;
constexpr quint32 keypadClear = 0x47, keypadDivide = 0x4B, keypadEnter = 0x4C;
constexpr quint32 keypadMinus = 0x4E, keypadEquals = 0x51;
constexpr quint32 keypad0 = 0x52, keypad1 = 0x53, keypad2 = 0x54, keypad3 = 0x55;
constexpr quint32 keypad4 = 0x56, keypad5 = 0x57, keypad6 = 0x58, keypad7 = 0x59;
constexpr quint32 keypad8 = 0x5B, keypad9 = 0x5C;
constexpr quint32 f5 = 0x60, f6 = 0x61, f7 = 0x62, f3 = 0x63, f8 = 0x64;
constexpr quint32 f9 = 0x65, f11 = 0x67, f10 = 0x6D;
constexpr quint32 forwardDelete = 0x75, f4 = 0x76, f2 = 0x78, f1 = 0x7A;
constexpr quint32 leftArrow = 0x7B, rightArrow = 0x7C;
constexpr quint32 downArrow = 0x7D, upArrow = 0x7E;

}

/* Amiga keycodes, i.e. what the core's KeyboardAPI takes (vamiga::KeyCode is
 * a plain u8, so there is no enum to reach for). Ported from vAmiga's
 * AmigaKeycode (GUI/Input/AmigaKey.swift); the same raw scancodes
 * AmigaKeyModel wires its on-screen keys to.
 */
namespace akey {

// 0x00 - 0x3F: positional keys (ANSI block)
constexpr int grave = 0x00;
constexpr int digit1 = 0x01, digit2 = 0x02, digit3 = 0x03, digit4 = 0x04;
constexpr int digit5 = 0x05, digit6 = 0x06, digit7 = 0x07, digit8 = 0x08;
constexpr int digit9 = 0x09, digit0 = 0x0A, minus = 0x0B, equal = 0x0C;
constexpr int backslash = 0x0D;
constexpr int keypad0 = 0x0F;
constexpr int q = 0x10, w = 0x11, e = 0x12, r = 0x13, t = 0x14, y = 0x15;
constexpr int u = 0x16, i = 0x17, o = 0x18, p = 0x19;
constexpr int lBracket = 0x1A, rBracket = 0x1B;
constexpr int keypad1 = 0x1D, keypad2 = 0x1E, keypad3 = 0x1F;
constexpr int a = 0x20, s = 0x21, d = 0x22, f = 0x23, g = 0x24, h = 0x25;
constexpr int j = 0x26, k = 0x27, l = 0x28, semicolon = 0x29, quote = 0x2A;
constexpr int keypad4 = 0x2D, keypad5 = 0x2E, keypad6 = 0x2F;
constexpr int z = 0x31, x = 0x32, c = 0x33, v = 0x34, b = 0x35, n = 0x36;
constexpr int m = 0x37, comma = 0x38, period = 0x39, slash = 0x3A;
constexpr int keypadDecimal = 0x3C, keypad7 = 0x3D, keypad8 = 0x3E, keypad9 = 0x3F;

// Extra key on international (ISO) Amigas, cut out of the left shift
constexpr int laceBrace = 0x30;

// 0x40 - 0x5F: codes common to all keyboards
constexpr int space = 0x40, backspace = 0x41, tab = 0x42, keypadEnter = 0x43;
constexpr int enter = 0x44, escape = 0x45, del = 0x46, keypadMinus = 0x4A;
constexpr int cursorUp = 0x4C, cursorDown = 0x4D;
constexpr int cursorRight = 0x4E, cursorLeft = 0x4F;
constexpr int f1 = 0x50, f2 = 0x51, f3 = 0x52, f4 = 0x53, f5 = 0x54;
constexpr int f6 = 0x55, f7 = 0x56, f8 = 0x57, f9 = 0x58, f10 = 0x59;
constexpr int keypadLBracket = 0x5A, keypadRBracket = 0x5B;
constexpr int keypadDivide = 0x5C, keypadMultiply = 0x5D, keypadPlus = 0x5E;
constexpr int help = 0x5F;

// 0x60 - 0x67: qualifier keys. Caps Lock (0x62) is deliberately missing:
// nothing maps to it, for the reason given in defaultAmigaKeyMap().
constexpr int leftShift = 0x60, rightShift = 0x61;
constexpr int control = 0x63, leftAlt = 0x64, rightAlt = 0x65;
constexpr int leftAmiga = 0x66, rightAmiga = 0x67;

}

}

SiAmKeyboardController::SiAmKeyboardController(SiAmController *parent)
    : Controller(parent), parent(parent), core(SiAmController::core()), keyboard(core.keyboard)
{
    m_keyModel = new AmigaKeyModel(this);
}

const QHash<quint32, int> &
SiAmKeyboardController::defaultAmigaKeyMap()
{
    /* Built once, on first use. A straight port of vAmiga's isomac2amiga:
     * same pairs, same order, only the constants renamed. Note that the Mac's
     * Caps Lock is deliberately absent there as well -- this app gives it its
     * own job (see Preferences::getCapsLockAction and
     * SiAmController::capsLock).
     */
    static const QHash<quint32, int> map = {

        { mac::isoSection,       akey::grave },
        { mac::ansi1,            akey::digit1 },
        { mac::ansi2,            akey::digit2 },
        { mac::ansi3,            akey::digit3 },
        { mac::ansi4,            akey::digit4 },
        { mac::ansi5,            akey::digit5 },
        { mac::ansi6,            akey::digit6 },
        { mac::ansi7,            akey::digit7 },
        { mac::ansi8,            akey::digit8 },
        { mac::ansi9,            akey::digit9 },
        { mac::ansi0,            akey::digit0 },
        { mac::ansiMinus,        akey::minus },
        { mac::ansiEqual,        akey::equal },

        { mac::keypad0,          akey::keypad0 },

        { mac::ansiQ,            akey::q },
        { mac::ansiW,            akey::w },
        { mac::ansiE,            akey::e },
        { mac::ansiR,            akey::r },
        { mac::ansiT,            akey::t },
        { mac::ansiY,            akey::y },
        { mac::ansiU,            akey::u },
        { mac::ansiI,            akey::i },
        { mac::ansiO,            akey::o },
        { mac::ansiP,            akey::p },
        { mac::ansiLeftBracket,  akey::lBracket },
        { mac::ansiRightBracket, akey::rBracket },

        { mac::keypad1,          akey::keypad1 },
        { mac::keypad2,          akey::keypad2 },
        { mac::keypad3,          akey::keypad3 },

        { mac::ansiA,            akey::a },
        { mac::ansiS,            akey::s },
        { mac::ansiD,            akey::d },
        { mac::ansiF,            akey::f },
        { mac::ansiG,            akey::g },
        { mac::ansiH,            akey::h },
        { mac::ansiJ,            akey::j },
        { mac::ansiK,            akey::k },
        { mac::ansiL,            akey::l },
        { mac::ansiSemicolon,    akey::semicolon },
        { mac::ansiQuote,        akey::quote },

        { mac::keypad4,          akey::keypad4 },
        { mac::keypad5,          akey::keypad5 },
        { mac::keypad6,          akey::keypad6 },

        { mac::ansiZ,            akey::z },
        { mac::ansiX,            akey::x },
        { mac::ansiC,            akey::c },
        { mac::ansiV,            akey::v },
        { mac::ansiB,            akey::b },
        { mac::ansiN,            akey::n },
        { mac::ansiM,            akey::m },
        { mac::ansiComma,        akey::comma },
        { mac::ansiPeriod,       akey::period },
        { mac::ansiSlash,        akey::slash },

        { mac::keypadDecimal,    akey::keypadDecimal },
        { mac::keypad7,          akey::keypad7 },
        { mac::keypad8,          akey::keypad8 },
        { mac::keypad9,          akey::keypad9 },

        { mac::ansiBackslash,    akey::backslash },
        { mac::ansiGrave,        akey::laceBrace },

        { mac::space,            akey::space },
        { mac::del,              akey::backspace },
        { mac::tab,              akey::tab },
        { mac::keypadEnter,      akey::keypadEnter },
        { mac::ret,              akey::enter },
        { mac::escape,           akey::escape },
        { mac::forwardDelete,    akey::del },
        { mac::keypadMinus,      akey::keypadMinus },
        { mac::upArrow,          akey::cursorUp },
        { mac::downArrow,        akey::cursorDown },
        { mac::rightArrow,       akey::cursorRight },
        { mac::leftArrow,        akey::cursorLeft },
        { mac::f1,               akey::f1 },
        { mac::f2,               akey::f2 },
        { mac::f3,               akey::f3 },
        { mac::f4,               akey::f4 },
        { mac::f5,               akey::f5 },
        { mac::f6,               akey::f6 },
        { mac::f7,               akey::f7 },
        { mac::f8,               akey::f8 },
        { mac::f9,               akey::f9 },
        { mac::f10,              akey::f10 },
        { mac::keypadClear,      akey::keypadLBracket },
        { mac::keypadEquals,     akey::keypadRBracket },
        { mac::keypadDivide,     akey::keypadDivide },
        { mac::keypadMultiply,   akey::keypadMultiply },
        { mac::keypadPlus,       akey::keypadPlus },
        { mac::f11,              akey::help },

        { mac::shift,            akey::leftShift },
        { mac::rightShift,       akey::rightShift },

        { mac::control,          akey::control },
        { mac::option,           akey::leftAlt },
        { mac::rightOption,      akey::rightAlt },
        { mac::command,          akey::leftAmiga },
        { mac::rightCommand,     akey::rightAmiga }
    };

    return map;
}

void
SiAmKeyboardController::kbChanged(int nr, bool pressed)
{
    emit keyChanged(nr, pressed);
}

bool
SiAmKeyboardController::isPressed(int key) const
{
    return keyboard.isPressed((KeyCode)key);
}

void
SiAmKeyboardController::press(int key)
{
    // No keyChanged() from here: the core answers every state change with a
    // Msg::KB_PRESS, which comes back as kbChanged() -- see its comment.
    keyboard.press((KeyCode)key);
}

void
SiAmKeyboardController::release(int key)
{
    keyboard.release((KeyCode)key);
}

void
SiAmKeyboardController::toggle(int key)
{
    keyboard.toggle((KeyCode)key);
}

void
SiAmKeyboardController::resetKeyboardMatrix()
{
    // Releases every key one by one inside the core, so the on-screen
    // keyboard is brought up to date by the resulting Msg::KB_RELEASEs.
    // (KeyboardAPI exposes no unlockAll(), unlike VirtualC64's -- nothing
    // locks Amiga keys here, so there is nothing to unlock either.)
    keyboard.releaseAll();
}

void
SiAmKeyboardController::keyDown(QKeyEvent *event, KeyModifier modifiers)
{
    /* Positional mapping, the Amiga's only scheme (see the class comment).
     *
     * Modifiers are not consulted: the physical key alone picks the keycode,
     * and Shift/Alt are keys in their own right -- they travel to the Amiga
     * as their own key events and its keymap combines them there.
     */
    auto scanCode = InputManager::physicalKeyCode(event);
    const auto &map = defaultAmigaKeyMap();

    if (auto it = map.constFind(scanCode); it != map.constEnd()) {

        keyboard.press((KeyCode)it.value());
    }
}

void
SiAmKeyboardController::keyUp(QKeyEvent *event, KeyModifier modifiers)
{
    auto scanCode = InputManager::physicalKeyCode(event);
    const auto &map = defaultAmigaKeyMap();

    if (auto it = map.constFind(scanCode); it != map.constEnd()) {

        keyboard.release((KeyCode)it.value());
    }
}

void
SiAmKeyboardController::keyCombo(KeyCombo combo, int count)
{
    /* Ctrl+Alt and Ctrl+Cmd chords never reach keyDown(): the InputManager
     * peels them off and reports them here instead (see
     * InputManager::keyCombo). On the C64 that is how the Commodore key is
     * reached, since no Mac key corresponds to it. The Amiga has no such
     * orphan -- Alt is Alt and Cmd is the Amiga key, both already in the map
     * above -- so all this has to do is press the very key the chord's second
     * half stands for, which keeps those chords working like any other
     * keystroke. Ctrl+Amiga+Amiga, the Amiga's own reset combo, is reachable
     * exactly because of this (the core watches for it and answers with
     * Msg::CTRL_AMIGA_AMIGA -- see SiAmController::process).
     *
     * 'count' counts the chords currently held: non-zero means pressed, zero
     * means the user let go.
     */
    auto key = [&]() -> std::optional<int> {

        switch (combo) {

            case KeyCombo::CtrlAltL:  return akey::leftAlt;
            case KeyCombo::CtrlAltR:  return akey::rightAlt;
            case KeyCombo::CtrlMetaL: return akey::leftAmiga;
            case KeyCombo::CtrlMetaR: return akey::rightAmiga;

            default:
                return { };
        }
    }();

    if (!key) return;

    count ? keyboard.press((KeyCode)*key) : keyboard.release((KeyCode)*key);
}

void
SiAmKeyboardController::activeChanged(bool state)
{
    /* Claim the input delegate while the virtual keyboard window is up
     * front, mirroring SiC64KeyboardController::activeChanged(). Both
     * delegates end up in the same place -- SiAmController::keyDown() just
     * forwards here -- so this only shortens the path; what actually decides
     * whether a keystroke reaches the Amiga is the keyboard capture state
     * (see SiAmController::updateKeyboardCapture).
     */
    if (state) inputManager.setDelegate(this);
}
