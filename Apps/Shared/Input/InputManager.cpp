// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "InputManager.h"
#include "AppController.h"
#include "Assets.h"
#include "Logger.h"
#include <QCursor>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QTextStream>
#include <QTimer>
#include <SDL3/SDL.h>

#ifdef __APPLE__
#include <CoreGraphics/CoreGraphics.h>
#endif

bool
InputManager::leftShift(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 56;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0xA0;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFE1;

    return false;
}

bool
InputManager::rightShift(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 60;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0xA1;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFE2;

    return false;
}

bool
InputManager::leftMeta(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 59;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0xA2;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFE3;

    return false;
}

bool
InputManager::rightMeta(QKeyEvent *event)
{
    return false;
}

bool
InputManager::leftAlt(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 58;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0xA4;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFE9;

    return false;
}

bool
InputManager::rightAlt(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 61;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0xA5;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFEA;

    return false;
}

bool
InputManager::leftCtrl(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 55;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0x5B;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFEB;

    return false;
}

bool
InputManager::rightCtrl(QKeyEvent *event)
{
    if constexpr (OS_MACOS)   return event->nativeVirtualKey() == 54;
    if constexpr (OS_WINDOWS) return event->nativeVirtualKey() == 0x5C;
    if constexpr (OS_LINUX)   return event->nativeVirtualKey() == 0xFFEC;

    return false;
}

u32
InputManager::physicalKeyCode(QKeyEvent *event)
{
    if constexpr (OS_MACOS) {
        return event->nativeVirtualKey();
    } else {
        return event->nativeScanCode();
    }
}

InputManager::InputManager() : QObject()
{

}

void
InputManager::setDelegate(InputManagerDelegate *ptr)
{
    delegate = ptr;
}

void
InputManager::removeDelegate(InputManagerDelegate *ptr)
{
    if (delegate == ptr) delegate = nullptr;
}

Gamepad *
InputManager::getDevice(int index)
{
    if (index >= 0 && index < m_devices.size()) {
        return &m_devices[index];
    }
    return nullptr;
}

void
InputManager::setPort0(int index)
{
    if (m_port0 != index) {

        // Avoid double-mapings
        if (index != 0 && m_port1 == index) {
            printf("Double mapping detected on port 0\n");
            setPort1(0);
        }

        m_port0 = index;
        emit port0Changed();
        emit port0InfoChanged();
    }
}

void
InputManager::setPort1(int index)
{
    if (m_port1 != index) {

        // Avoid double-mapings
        if (index != 0 && m_port0 == index) {
            printf("Double mapping detected on port 0\n");
            setPort0(0);

        }

        m_port1 = index;
        emit port1Changed();
        emit port1InfoChanged();
    }
}

void
InputManager::setCaptureMouse(bool value)
{
    if (m_captureMouse != value) {

        m_captureMouse = value;

#ifdef __APPLE__
        // A Qt window/item cursor is not enough on macOS: QQuickWindow
        // recomputes the cursor on every mouse move (the hovered MouseArea
        // reclaims its own cursor, and warpToCenter()'s QCursor::setPos()
        // forces a recompute too), so a blanked Qt cursor reappears the
        // instant the mouse moves. CGDisplayHideCursor() hides the cursor
        // below Qt's cursor-rect layer via a hide-count that survives those
        // recomputes; it must be balanced 1:1 with CGDisplayShowCursor().
        if (value) {
            CGDisplayHideCursor(kCGDirectMainDisplay);
        } else {
            CGDisplayShowCursor(kCGDirectMainDisplay);
        }
#else
        if (m_captureWindow) {
            if (value) {
                m_captureWindow->setCursor(Qt::BlankCursor);
            } else {
                m_captureWindow->unsetCursor();
            }
        }
#endif

        emit captureMouseChanged();
    }
}

void
InputManager::setCaptureWindow(QQuickWindow *window)
{
    m_captureWindow = window;
}

void
InputManager::setCaptureKeyboard(bool value)
{
    if (m_captureKeyboard != value) {

        m_captureKeyboard = value;
        emit captureKeyboardChanged();
    }
}

bool
InputManager::eventFilter(QObject *object, QEvent *event)
{
    switch (event->type()) {

        case QEvent::MouseMove:

            return mouseEventFilter(object, static_cast<QMouseEvent *>(event));

        case QEvent::MouseButtonPress:
        case QEvent::MouseButtonRelease:

            return mouseButtonEventFilter(object, static_cast<QMouseEvent *>(event));

        case QEvent::KeyPress:

            return keyDownEventFilter(object, static_cast<QKeyEvent *>(event));

        case QEvent::KeyRelease:

            return keyUpEventFilter(object, static_cast<QKeyEvent *>(event));

        default:
            break;
    }

    return QObject::eventFilter(object, event);
}

bool
InputManager::mouseEventFilter(QObject *object, QMouseEvent *event)
{
    static QPointF lastPos = event->globalPosition();

    if (delegate) {

        auto current = event->globalPosition();
        auto x       = static_cast<float>(current.x());
        auto y       = static_cast<float>(current.y());
        auto dx      = x - static_cast<float>(lastPos.x());
        auto dy      = y - static_cast<float>(lastPos.y());

        lastPos = current;

        if (delegate->detectShakeDxDy(dx, dy)) {
            delegate->shakeDetected();
        }

        /* Apply the sensitivity to the relative motion only.
         *
         * mouseXY() gets the unscaled position: it is an absolute screen
         * coordinate, and scaling it would displace the pointer rather than
         * speed it up. Shake detection above stays on the raw deltas too, so
         * the setting cannot make "shake to release the mouse" easier or
         * harder to trigger than it is with the pointer itself.
         */
        auto sens = preferences().getMouseSensitivity();
        auto sdx  = sens * dx;
        auto sdy  = sens * dy;

        if (auto *device = getPort0Device(); device->type == GamepadType::Mouse) {

            delegate->mouseXY(0, event->timestamp(), x, y);
            delegate->mouseDxDy(0, event->timestamp(), sdx, sdy);
        }

        if (auto *device = getPort1Device(); device->type == GamepadType::Mouse) {

            delegate->mouseXY(1, event->timestamp(), x, y);
            delegate->mouseDxDy(1, event->timestamp(), sdx, sdy);
        }

        if (m_captureMouse) {

            delegate->warpToCenter();
            return true;
        }
    }

    return QObject::eventFilter(object, event);
}

bool
InputManager::mouseButtonEventFilter(QObject *obj, QMouseEvent *event)
{
    if (delegate) {

        bool down = (event->type() == QEvent::MouseButtonPress);

        auto mappedButton = [](Qt::MouseButton btn) -> int {
            if (btn == Qt::LeftButton) return 0;
            if (btn == Qt::MiddleButton) return 1;
            if (btn == Qt::RightButton) return 2;
            return -1;
        };

        if (auto button = mappedButton(event->button()); button != -1) {

            if (auto *device = getPort0Device(); device->type == GamepadType::Mouse) {
                delegate->mouseButton(0, event->timestamp(), button, down);
            }
            if (auto *device = getPort1Device(); device->type == GamepadType::Mouse) {
                delegate->mouseButton(1, event->timestamp(), button, down);
            }

            if (m_captureMouse) return true;
        }
    }

    return QObject::eventFilter(obj, event);
}

bool
InputManager::keyDownEventFilter(QObject *obj, QKeyEvent *event)
{
    if (delegate && !isRepeat(event)) {

        rememberEvent(event);

        if (event->key() == Qt::Key_CapsLock) {

            delegate->capsLock(true);
            return true;
        }

        optional<uint> newQKey = event->key();
        optional<uint> newPKey = physicalKeyCode(event);
        auto newMods = m_mods;

        newMods.leftShift |= leftShift(event);
        newMods.rightShift |= rightShift(event);
        newMods.leftCtrl |= leftCtrl(event);
        newMods.rightCtrl |= rightCtrl(event);
        newMods.leftAlt |= leftAlt(event);
        newMods.rightAlt |= rightAlt(event);
        newMods.leftMeta |= leftMeta(event);
        newMods.rightMeta |= rightMeta(event);

        m_qKey = newQKey;
        m_pKey = newPKey;
        m_sKey = event->text();
        m_mods = newMods;
        emit keyChanged();

        // printf("Key down event filter: %x %x %x\n", m_qKey, m_pKey, m_mods.bits());

        if (auto combo = keyCombo(event)) {

            switch (*combo) {

                case KeyCombo::CtrlAltL:

                    delegate->keyCombo(KeyCombo::CtrlAltL, ++ctrlAltL);
                    break;

                case KeyCombo::CtrlAltR:

                    delegate->keyCombo(KeyCombo::CtrlAltR, ++ctrlAltR);
                    break;

                case KeyCombo::CtrlMetaL:

                    delegate->keyCombo(KeyCombo::CtrlMetaL, ++ctrlMetaL);
                    break;

                case KeyCombo::CtrlMetaR:

                    delegate->keyCombo(KeyCombo::CtrlMetaR, ++ctrlMetaR);
                    break;

                default:
                    break;
            }

        } else if (m_captureKeyboard) {

            /* Only while the emulator owns the keyboard.
             *
             * m_captureKeyboard decides who a keystroke belongs to, and it has
             * to gate this as well as the consumption below -- the two are the
             * same question asked twice. Gating only the consumption would let
             * a keystroke reach the app *and* the virtual machine: typing a
             * RetroShell command would type it into the running C64 too, and
             * WASD in any text field would nudge the joystick.
             */

            // Check if the pressed key is an emulation key
            bool isEmuKey = emulationKeyFilter(0, event, true) || emulationKeyFilter(1, event, true);

            if (!isEmuKey || !preferences().getDisconnectEmulationKeys()) {

                delegate->keyDown(event, m_mods);
            }
        }
    }

    return m_captureKeyboard || QObject::eventFilter(obj, event);
}

optional<KeyCombo>
InputManager::keyCombo(QKeyEvent *event) const
{
    if (event->modifiers() & Qt::ControlModifier) {

        if (leftAlt(event)) return KeyCombo::CtrlAltL;
        if (rightAlt(event)) return KeyCombo::CtrlAltR;
        if (leftMeta(event)) return KeyCombo::CtrlMetaL;
        if (rightMeta(event)) return KeyCombo::CtrlMetaR;
    }

    return { };
}

bool
InputManager::keyUpEventFilter(QObject *obj, QKeyEvent *event)
{
    if (delegate && !isRepeat(event)) {

        rememberEvent(event);

        if (event->key() == Qt::Key_CapsLock) {

            delegate->capsLock(false);
            return true;
        }

        optional<uint> newQKey = { };
        optional<uint> newPKey = { };
        auto newMods = m_mods;

        if ((event->modifiers() & Qt::ShiftModifier) == 0)
            newMods.leftShift = newMods.rightShift = false;
        if ((event->modifiers() & Qt::ControlModifier) == 0)
            newMods.leftCtrl = newMods.rightCtrl = false;
        if ((event->modifiers() & Qt::AltModifier) == 0)
            newMods.leftAlt = newMods.rightAlt = false;
        if ((event->modifiers() & Qt::MetaModifier) == 0)
            newMods.leftMeta = newMods.rightMeta = false;

        m_qKey = newQKey;
        m_pKey = newPKey;
        m_sKey = "";
        m_mods = newMods;
        emit keyChanged();

        // printf("Key up event filter: %x %x %x\n", m_qKey, m_pKey, m_mods.bits());

        if (ctrlAltL || ctrlAltR || ctrlMetaL || ctrlMetaR) {

            if (ctrlAltL && !m_mods.ctrl() && !m_mods.leftAlt) {
                delegate->keyCombo(KeyCombo::CtrlAltL, (ctrlAltL = 0));
            } else if (ctrlAltR && !m_mods.ctrl() && !m_mods.rightAlt) {
                delegate->keyCombo(KeyCombo::CtrlAltR, (ctrlAltR = 0));
            } else if (ctrlMetaL && !m_mods.ctrl() && !m_mods.leftMeta) {
                delegate->keyCombo(KeyCombo::CtrlMetaL, (ctrlMetaL = 0));
            } else if (ctrlMetaR && !m_mods.ctrl() && !m_mods.rightMeta) {
                delegate->keyCombo(KeyCombo::CtrlMetaR, (ctrlMetaR = 0));
            }

        } else {

            /* Deliberately NOT gated on m_captureKeyboard, unlike the matching
             * block in keyDownEventFilter.
             *
             * Capture can be withdrawn between a press and its release -- open
             * RetroShell with a key held down and that is exactly what happens.
             * Swallowing the release would leave that key stuck down in the
             * virtual machine with nothing to ever lift it. Releasing a key the
             * machine never saw pressed is harmless by comparison, so the
             * asymmetry falls on the safe side.
             */

            // Check if the pressed key is an emulation key
            bool isEmuKey = emulationKeyFilter(0, event, false) || emulationKeyFilter(1, event, false);

            if (!isEmuKey || !preferences().getDisconnectEmulationKeys()) {

                delegate->keyUp(event, m_mods);
            }
        }
    }

    return m_captureKeyboard || QObject::eventFilter(obj, event);
}

bool
InputManager::isRepeat(QKeyEvent *event) const
{
    return event->type() == m_latestType && m_latestKey == physicalKeyCode(event);
}

void
InputManager::rememberEvent(QKeyEvent *event)
{
    m_latestType = event->type();
    m_latestKey = physicalKeyCode(event);
}

bool
InputManager::emulationKeyFilter(int port, QKeyEvent *event, bool down)
{
    if (auto *device = port == 0 ? getPort0Device() : getPort1Device()) {

        auto qKey = event->key();
        auto pKey = physicalKeyCode(event);
        auto time = event->timestamp();

        if (auto nr = device->isEmulationKey(qKey, pKey)) {

            switch (device->type) {

                case GamepadType::Mouse:

                    // printf("MOUSE EMULATION KEY %d hit\n", *nr);

                    if (*nr < 3) {
                        if (delegate) delegate->mouseButton(port, time, *nr, down);
                    }
                    break;

                case GamepadType::Joystick:

                    // printf("JOYSTICK EMULATION KEY %d hit\n", *nr);

                    assert(*nr <= 4);
                    device->state[*nr] = down;
                    if (delegate) delegate->joystickMotionEvent(port, time, device->state);
                    break;

                default:
                    break;
            }

            return true;
        }
    }
    return false;
}

void
InputManager::updateDevices()
{
    m_devices.clear();

    //
    // Add default devices
    //

    Gamepad pad;

    // Add a device that represents an unconnected port
    pad.name = "None";
    pad.type = GamepadType::None;
    m_devices.push_back(pad);

    // Add mouse
    pad.name = "Mouse";
    pad.type = GamepadType::Mouse;
    pad.keys[0] = preferences().getMButton1Key();
    pad.keys[1] = preferences().getMButton2Key();
    pad.keys[2] = preferences().getMButton3Key();
    m_devices.push_back(pad);

    // Add first keyboard joystick
    pad.name = "Keymap 1";
    pad.type = GamepadType::Joystick;
    pad.keys[0] = preferences().getKeyset1Up();
    pad.keys[1] = preferences().getKeyset1Down();
    pad.keys[2] = preferences().getKeyset1Left();
    pad.keys[3] = preferences().getKeyset1Right();
    pad.keys[4] = preferences().getKeyset1Fire();
    m_devices.push_back(pad);

    // Add second keyboard joystick
    pad.name = "Keymap 2";
    pad.type = GamepadType::Joystick;
    pad.keys[0] = preferences().getKeyset2Up();
    pad.keys[1] = preferences().getKeyset2Down();
    pad.keys[2] = preferences().getKeyset2Left();
    pad.keys[3] = preferences().getKeyset2Right();
    pad.keys[4] = preferences().getKeyset2Fire();
    m_devices.push_back(pad);

    //
    // Add SDL devices
    //

    /* Reconcile SDL with the stored mappings first, so the copies taken
     * below carry the right one. This runs on every device change and on
     * every devicesPrefsChanged, which is what makes an edit made in the Hub
     * land in the SiC64 instances: the Hub broadcasts the settings group,
     * each instance reloads it, and ends up here.
     */
    sdlManager.applyStoredMappings();

    const QMap<int, Gamepad> &sdlPads = sdlManager.m_gamePads;

    for (auto it = sdlPads.begin(); it != sdlPads.end(); ++it) {
        m_devices.append(it.value());
    }

    // Notify the UI. The port info is derived from these devices, so it has
    // to be announced as well -- devicesChanged alone does not cover it.
    emit devicesChanged();
    emit port0InfoChanged();
    emit port1InfoChanged();
}

void
InputManager::updateMapping(int nr, const QString &mappingLogic)
{
    Gamepad *dev = getDevice(nr);
    if (!dev || dev->sdlid == -1) return;

    // Assemble the full mapping string: [GUID],[Name],[Mapping-Logic]
    const QString mapping =
        QString("%1,%2,%3").arg(dev->guidString, dev->sdlName, mappingLogic);

    /* Persist rather than apply. Writing the preference emits
     * devicesPrefsChanged, which brings our own SDL database in line (see
     * updateDevices) and, in the Hub, is broadcast to every running SiC64 so
     * each of them does the same. A mapping edited here therefore reaches
     * the emulators and survives a restart through one and the same path.
     */
    preferences().setGamepadMapping(dev->guidString, mapping);
}

void
InputManager::resetMapping(int nr)
{
    Gamepad *dev = getDevice(nr);
    if (!dev || dev->sdlid == -1) return;

    // Dropping the override puts the device back on its own mapping
    preferences().setGamepadMapping(dev->guidString, "");
}

QVariantMap
InputManager::getDeviceInfo(int deviceIndex)
{
    QVariantMap info;

    if (Gamepad *dev = getDevice(deviceIndex)) {

        info["type"] = dev->typeString();

        if (!dev || dev->type == GamepadType::None) {
            info["status"] = "Disconnected";
            return info;
        }

        info["status"] = "Connected";
        info["name"] = dev->name;
        info["sdlName"] = dev->sdlName;

        if (dev->sdlid != -1) {

            info["sdlid"] = dev->sdlid;
            info["vendorId"] = dev->vendorId;
            info["productId"] = dev->productId;
            info["productVersion"] = dev->productVersion;
            info["guid"] = dev->guidString;
            info["mapping"] = dev->mappingLogic();

            // Lets the UI mark an edited mapping and offer to undo it
            info["customMapping"] =
                !preferences().getGamepadMapping(dev->guidString).isEmpty();
        }

        for (int i = 0; i < 5; ++i) {

            /* An engaged optional is not proof of an assignment: the slots are
             * filled from the preferences, which may well hold an unassigned
             * key -- (-1,-1) fresh, or (0,0) in a settings file written by an
             * older build. Reporting those verbatim made the UI show a keycode
             * of 0 with a blank name. Qt::Key values are all positive, so that
             * is the test for "really assigned".
             */
            const auto &key = dev->keys[i];

            if (key && key->qKey > 0) {

                auto qKey = key->qKey;
                auto pKey = key->pKey;

                info[QString("key%1").arg(i)] = qKey;
                info[QString("virtualkey%1").arg(i)] = pKey;
                info[QString("keyname%1").arg(i)] = key->name();
                info[QString("keycodename%1").arg(i)] = pKey != -1 ? pKey : qKey;

            } else {

                info[QString("key%1").arg(i)] = -1;
                info[QString("virtualkey%1").arg(i)] = -1;
                info[QString("keyname%1").arg(i)] = "NONE";
                info[QString("keycodename%1").arg(i)] = -1;
            }
        }
    }

    return info;
}

QVariantList
InputManager::deviceList() const
{
    QVariantList list;

    auto icon = [](GamepadType type) {
        switch (type) {
            case GamepadType::None:
                return "block";
            case GamepadType::Mouse:
                return "mouse";
            case GamepadType::Joystick:
                return "joystick";
            case GamepadType::Paddle:
                return "handheld_controller";
            default:
                return "stadia_controller";
        }
    };

    for (const auto &pad : m_devices) {

        QVariantMap map;
        map["name"] = pad.name;
        map["type"] = int(pad.type);
        map["icon"] = icon(pad.type);
        list.append(map);
    }
    return list;
}

void
InputManager::start()
{
    if (!m_running) {

        LogTask subtask("Starting InputManager...");

        // Install event filter
        QGuiApplication::instance()->installEventFilter(this);

        // Initial population
        updateDevices();

        // Rebuild the device list when SDL reports a device change
        connect(&sdlManager, &SDLManager::countChanged, this, &InputManager::updateDevices);

        // Rebuild the device list when the device preferences change
        connect(&preferences(), &Preferences::devicesPrefsChanged, this, &InputManager::updateDevices);

        // Register as delegate
        sdlManager.setDelegate(this);
        sdlManager.start();

        m_running = true;
    }
}

void
InputManager::stop()
{
    if (m_running) {

        LogTask task("Stopping InputManager...");
        sdlManager.stop();

        m_running = false;
    }
}

void
InputManager::sdlAxisEvent(int sdlid, u64 timestamp, int axis, int value, float normalize)
{
    // printf("axisEvent: %llu axis: %d value: %d normalized: %f\n", timestamp, axis, value, normalize);

    if (auto *dev = getDevice(sdlid); dev) {

        if (axis == 1) {

            if (normalize < -0.5) {
                // printf("JOY UP\n");
                dev->state[0] = true;

            } else if (normalize > 0.5) {
                // printf("JOY DOWN\n");
                dev->state[1] = true;

            } else {
                // printf("JOY RELEASE Y\n");
                dev->state[0] = dev->state[1] = false;
            }
        }

        if (axis == 0) {

            if (normalize < -0.5) {
                // printf("JOY LEFT\n");
                dev->state[2] = true;

            } else if (normalize > 0.5) {
                // printf("JOY RIGHT\n");
                dev->state[3] = true;

            } else {
                // printf("JOY RELEASE X\n");
                dev->state[2] = dev->state[3] = false;
            }
        }

        /*
        printf("%p: ", dev);
        for (isize i = 0; i < 5; ++i) {
            printf("%d ", dev->state[i]);
        }
        printf("\n");
        */

        if (delegate) {

            if (auto *device = getPort0Device(); device->sdlid == sdlid)
                delegate->joystickMotionEvent(0, timestamp, dev->state);

            if (auto *device = getPort1Device(); device->sdlid == sdlid)
                delegate->joystickMotionEvent(1, timestamp, dev->state);
        }
    }
}

void
InputManager::sdlMotionEvent(int id, u64 timestamp, char state[5])
{
}

void
InputManager::sdlButtonEvent(int sdlid, u64 timestamp, int button, bool down)
{
    printf("buttonEvent: %llu button: %d down: %d\n", timestamp, button, down);

    if (auto *dev = getDevice(sdlid); dev) {

        dev->state[4] = down;

        if (delegate) {

            if (auto *device = getPort0Device(); device->sdlid == sdlid)
                delegate->joystickMotionEvent(0, timestamp, dev->state);

            if (auto *device = getPort1Device(); device->sdlid == sdlid)
                delegate->joystickMotionEvent(1, timestamp, dev->state);
        }
    }
}
