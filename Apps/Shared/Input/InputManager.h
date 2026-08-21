// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SDLManager.h"
#include "SiObject.h"
#include <QList>
#include <QMouseEvent>
#include <QObject>

class VirtualMachine;
class QQuickWindow;

enum class KeyCombo {

    CtrlAltL,
    CtrlAltR,
    CtrlMetaL,
    CtrlMetaR
};

struct KeyModifier {

    bool leftShift;
    bool rightShift;
    bool leftCtrl;
    bool rightCtrl;
    bool leftAlt;
    bool rightAlt;
    bool leftMeta;
    bool rightMeta;

    bool shift() { return leftShift | rightShift; }
    bool ctrl() { return leftCtrl | rightCtrl; }
    bool alt() { return leftAlt | rightAlt; }
    bool meta() { return leftMeta | rightMeta; }

    int bits() const
    {
        return !!leftShift << 7 | !!rightShift << 6 | !!leftCtrl << 5 | !!rightCtrl << 4 |
               !!leftAlt << 3 | !!rightAlt << 2 | !!leftMeta << 1 | !!rightMeta << 0;
    }

    bool operator==(const KeyModifier& other) const
    {
        return this->bits() == other.bits();
    }

    bool operator!=(const KeyModifier& other) const
    {
        return !(*this == other);
    }
};

class InputManagerDelegate {

  public:

    // Keyboard events
    virtual void keyDown(QKeyEvent *even, KeyModifier modifiers) { };
    virtual void keyUp(QKeyEvent *even, KeyModifier modifiers) { };
    virtual void keyCombo(KeyCombo combo, int count) { };
    virtual void capsLock(bool state) { };

    // Mouse events
    virtual void mouseXY(int port, u64 timestamp, float x, float y) { };
    virtual void mouseDxDy(int port, u64 timestamp, float dx, float dy) { };
    virtual void mouseButton(int port, u64 timestamp, int button, bool down) { };
    virtual void warpToCenter() { };
    virtual bool detectShakeDxDy(float dx, float dy) { return false; }
    virtual void shakeDetected() { };

    // Gamepad events
    virtual void joystickMotionEvent(int port, u64 timestamp, bool state[5]) { };
};

class InputManager : public QObject, SiObject, SDLManagerDelegate {

    Q_OBJECT

    SDLManager sdlManager = SDLManager(this);

    // Indicates whether the input manager is active
    bool m_running = false;

    // List of managed devices
    QList<Gamepad> m_devices;

    // Port mapping (gameport -> device number)
    int m_port0 = 0;
    int m_port1 = 0;

    // Current keyboard state
    KeyModifier m_mods {};
    optional<uint> m_qKey {};
    optional<uint> m_pKey {};
    optional<QString> m_sKey {};

    // Remembered portions of the latest key event
    QEvent::Type m_latestType {};
    u32 m_latestKey = {};

    // Key combo counters
    int ctrlAltL = 0;
    int ctrlAltR = 0;
    int ctrlMetaL = 0;
    int ctrlMetaR = 0;

    // Capturing modes
    bool m_captureMouse = false;
    bool m_captureKeyboard = false;

    // The window whose cursor is blanked while the mouse is captured (see
    // setCaptureMouse()). Set by whichever controller currently owns the
    // emulator window (see C64Controller::attachWindow()).
    QQuickWindow *m_captureWindow = nullptr;

    // Delegate
    InputManagerDelegate *delegate = nullptr;

    //
    // Static methods
    //

  public:

    static bool leftShift(QKeyEvent *event);
    static bool rightShift(QKeyEvent *event);
    static bool leftMeta(QKeyEvent *event);
    static bool rightMeta(QKeyEvent *event);
    static bool leftAlt(QKeyEvent *event);
    static bool rightAlt(QKeyEvent *event);
    static bool leftCtrl(QKeyEvent *event);
    static bool rightCtrl(QKeyEvent *event);

    static u32 physicalKeyCode(QKeyEvent *event);

    //
    // Methods
    //

public:

    Q_PROPERTY(QVariantList deviceList READ deviceList NOTIFY devicesChanged)
    Q_PROPERTY(int port0 READ getPort0 WRITE setPort0 NOTIFY port0Changed)
    Q_PROPERTY(int port1 READ getPort1 WRITE setPort1 NOTIFY port1Changed)
    /* These need their own notify signals.
     *
     * A Q_PROPERTY takes exactly one NOTIFY, and these used to name two
     * (port0Changed and devicesChanged); moc silently kept the last and dropped
     * the other, so swapping the device in a port never refreshed the info and
     * the UI kept describing the previous one. The info depends on both which
     * device sits in the port and on the device list itself, so both places
     * emit these.
     */
    Q_PROPERTY(QVariantMap port0Info READ getPort0Info NOTIFY port0InfoChanged)
    Q_PROPERTY(QVariantMap port1Info READ getPort1Info NOTIFY port1InfoChanged)

    Q_PROPERTY(bool captureMouse READ getCaptureMouse WRITE setCaptureMouse NOTIFY captureMouseChanged)
    Q_PROPERTY(bool captureKeyboard READ getCaptureKeyboard WRITE setCaptureKeyboard NOTIFY captureKeyboardChanged)

    //
    // Keyboard
    //

    Q_PROPERTY(int mods READ mods NOTIFY keyChanged)
    Q_PROPERTY(uint qKey READ qKey NOTIFY keyChanged)
    Q_PROPERTY(uint pKey READ pKey NOTIFY keyChanged)
    Q_PROPERTY(QString sKey READ sKey NOTIFY keyChanged)

    InputManager();
    // ~InputManager();

    void setDelegate(InputManagerDelegate *ptr);
    void removeDelegate(InputManagerDelegate *ptr);

    Gamepad *getDevice(int index);
    Gamepad *getPort0Device() { return getDevice(m_port0); }
    Gamepad *getPort1Device() { return getDevice(m_port1); }

    int getPort0() { return m_port0; }
    int getPort1() { return m_port1; }
    void setPort0(int index);
    void setPort1(int index);

    QVariantMap getPort0Info() { return getDeviceInfo(m_port0); }
    QVariantMap getPort1Info() { return getDeviceInfo(m_port1); }

    bool getCaptureMouse() { return m_captureMouse; }
    void setCaptureMouse(bool value);

    // Tells the input manager which window's cursor to blank/restore when
    // the mouse is captured/released. See C64Controller::attachWindow().
    void setCaptureWindow(QQuickWindow *window);

    bool getCaptureKeyboard() { return m_captureKeyboard; }
    void setCaptureKeyboard(bool value);

    int mods() { return m_mods.bits(); }
    uint qKey() { return m_qKey ? *m_qKey : 0; }
    uint pKey() { return m_pKey ? *m_pKey : 0; }
    QString sKey() { return m_sKey ? *m_sKey : ""; }

    void start();
    void stop();

    // Updates the list of managed devices (m_devices)
    void updateDevices();

    // Rewrites the mapping logic of device nr and remembers it
    void updateMapping(int nr, const QString &mapping);

    // Drops a customized mapping, putting the device back on its own
    void resetMapping(int nr);

  private:

    QVariantMap getDeviceInfo(int deviceIndex);

    bool eventFilter(QObject *obj, QEvent *event) override;
    bool mouseEventFilter(QObject *obj, QMouseEvent *event);
    bool mouseButtonEventFilter(QObject *obj, QMouseEvent *event);
    bool keyDownEventFilter(QObject *obj, QKeyEvent *event);
    bool keyUpEventFilter(QObject *obj, QKeyEvent *event);

    optional<KeyCombo> keyCombo(QKeyEvent *event) const;

    bool emulationKeyFilter(int port, QKeyEvent *event, bool down);
    // bool emulationKeyFilter(int port, u64 timestamp, int key, int vkey, bool down);

    bool isRepeat(QKeyEvent *event) const;
    void rememberEvent(QKeyEvent *event);


    //
    // Methods from SDLManagerDelegate
    //

    void sdlAxisEvent(int id, u64 timestamp, int axis, int value, float normalize) override;
    void sdlMotionEvent(int id, u64 timestamp, char state[5]) override;
    void sdlButtonEvent(int id, u64 timestamp, int button, bool down) override;

  public:

    QVariantList deviceList() const;

  signals:

    void devicesChanged();
    void port0Changed();
    void port1Changed();
    void port0InfoChanged();
    void port1InfoChanged();
    void captureMouseChanged();
    void captureKeyboardChanged();
    void keyChanged();
};