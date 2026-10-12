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
#include "utl/chrono.h"
#include <QList>
#include <QMouseEvent>
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class VirtualMachine;
class QQuickWindow;

enum class KeyCombo {

    CtrlAltL,
    CtrlAltR,
    CtrlMetaL,
    CtrlMetaR
};

struct PortState {

    // Current mouse state
    float x = 0;
    float y = 0;
    float dx = 0;
    float dy = 0;
    bool mb[3] = {};

    // Current joystick state (up, down, left, right, fire)
    bool joy[5] = {};

    // The mouse has moved since the state was last dispatched
    bool moved = false;
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
    virtual void keyDown(QKeyEvent *event, KeyModifier modifiers) { }
    virtual void keyUp(QKeyEvent *event, KeyModifier modifiers) { }
    virtual void keyCombo(KeyCombo combo, int count) { }
    virtual void capsLock(bool down) { }

    // Gamepad events
    virtual void joystickMotion(int port, u64 timestamp, bool state[5], bool prev[5]) { }

    // Mouse events
    virtual void mouseXY(int port, u64 timestamp, float x, float y) { }
    virtual void mouseDxDy(int port, u64 timestamp, float dx, float dy) { }
    virtual void mouseButton(int port, u64 timestamp, int button, bool down) { }
    virtual void shakeDetected() { }

    // Requests
    virtual void warpToCenter() { }
    virtual bool detectShakeDxDy(float dx, float dy) { return false; }
};

class InputManager : public QObject, SiObject, SDLManagerDelegate {

    Q_OBJECT

    // Gateway to the SDL library
    SDLManager m_sdl = SDLManager(this);

    // Delegate
    InputManagerDelegate *m_delegate = nullptr;

    // The window whose cursor is blanked while the mouse is captured
    QQuickWindow *m_captureWindow = nullptr;

    // Indicates whether the input manager has been started
    bool m_running = false;

    // List of managed devices
    QList<Gamepad> m_devices;

    // Current port state, and the state the delegate was last told about
    PortState m_portState[2];
    PortState m_prevPortState[2];

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
    int m_ctrlAltL = 0;
    int m_ctrlAltR = 0;
    int m_ctrlMetaL = 0;
    int m_ctrlMetaR = 0;

    // Capture state
    bool m_captureMouse = false;
    bool m_captureKeyboard = false;

    // Polling
    QTimer m_pollTimer;
    utl::Time m_pollInterval;

    /* Returns the motion to rest.
     *
     * dx/dy hold the delta of the most recent motion event, so once the events
     * stop they keep describing a movement that is over. That happens when the
     * pointer leaves the window, and equally when it simply stops moving inside
     * it. Restarted on every motion event, so it only fires once the mouse has
     * gone quiet.
     */
    QTimer m_mouseRestTimer;


    //
    // Static methods
    //

  public:

    static u32 physicalKeyCode(QKeyEvent *event);
    static bool leftShift(QKeyEvent *event);
    static bool rightShift(QKeyEvent *event);
    static bool leftMeta(QKeyEvent *event);
    static bool rightMeta(QKeyEvent *event);
    static bool leftAlt(QKeyEvent *event);
    static bool rightAlt(QKeyEvent *event);
    static bool leftCtrl(QKeyEvent *event);
    static bool rightCtrl(QKeyEvent *event);


    //
    // Methods
    //

public:

    InputManager();

    void start();
    void stop();

    void setDelegate(InputManagerDelegate *ptr);
    void removeDelegate(InputManagerDelegate *ptr);
    void setCaptureWindow(QQuickWindow *window);


    //
    // Devices
    //

public:

    Q_PROPERTY(QVariantList deviceList READ deviceList NOTIFY devicesChanged)

    Q_PROPERTY(int port0 READ getPort0 WRITE setPort0 NOTIFY port0Changed)
    Q_PROPERTY(int port1 READ getPort1 WRITE setPort1 NOTIFY port1Changed)

    Q_PROPERTY(QVariantMap port0Info READ getPort0Info NOTIFY port0InfoChanged)
    Q_PROPERTY(QVariantMap port1Info READ getPort1Info NOTIFY port1InfoChanged)

    /* The latest mouse and joystick activity per control port, as lists of
     * two maps (index = port). Mouse: dx, dy, left, middle, right. Joystick:
     * up, down, left, right, fire. The dx and dy values are the latest motion
     * delta, not an accumulated position.
     */
    Q_PROPERTY(QVariantList mouseState READ getMouseState NOTIFY mouseStateChanged)
    Q_PROPERTY(QVariantList joystickState READ getJoystickState NOTIFY joystickStateChanged)

    const PortState &portState(int port) const { return m_portState[port]; }

    QVariantList deviceList() const;

    Gamepad *getDevice(int index);
    Gamepad *getPort0Device() { return getDevice(m_port0); }
    Gamepad *getPort1Device() { return getDevice(m_port1); }

    int getPort0() { return m_port0; }
    int getPort1() { return m_port1; }
    void setPort0(int index);
    void setPort1(int index);

    QVariantMap getPort0Info() { return getDeviceInfo(m_port0); }
    QVariantMap getPort1Info() { return getDeviceInfo(m_port1); }

    QVariantList getMouseState() const;
    QVariantList getJoystickState() const;


    //
    // Keyboard
    //

public:

    Q_PROPERTY(int mods READ mods NOTIFY keyChanged)
    Q_PROPERTY(uint qKey READ qKey NOTIFY keyChanged)
    Q_PROPERTY(uint pKey READ pKey NOTIFY keyChanged)
    Q_PROPERTY(QString sKey READ sKey NOTIFY keyChanged)

private:

    int mods() { return m_mods.bits(); }
    uint qKey() { return m_qKey ? *m_qKey : 0; }
    uint pKey() { return m_pKey ? *m_pKey : 0; }
    QString sKey() { return m_sKey ? *m_sKey : ""; }


    //
    // Polling
    //

public:

    // Starts polling the input devices at a fixed interval
    void poll(utl::Time interval);

    // Polls the input devices once and stops fixed-interval polling
    void poll();

private:

    // Polls SDL managed devices
    void pollGamepads();

    // Polls the current mouse motion and button states
    void pollMouse();


    //
    // Capturing the mouse and keyboard
    //

public:

    Q_PROPERTY(bool captureMouse READ getCaptureMouse WRITE setCaptureMouse NOTIFY captureMouseChanged)
    Q_PROPERTY(bool captureKeyboard READ getCaptureKeyboard WRITE setCaptureKeyboard NOTIFY captureKeyboardChanged)

    bool getCaptureMouse() { return m_captureMouse; }
    void setCaptureMouse(bool value);

    bool getCaptureKeyboard() { return m_captureKeyboard; }
    void setCaptureKeyboard(bool value);

    /* Whether the focused item is one that takes typed text.
     *
     * The second half of the capture question: m_captureKeyboard says the
     * machine may have the keyboard, this says whether something in the app
     * is being typed into right now. See the definition.
     */
    static bool editingText();

    // Updates the list of managed devices (m_devices)
    void updateDevices();

    // Rewrites the mapping logic of device nr and remembers it
    void updateMapping(int nr, const QString &mapping);

    // Drops a customized mapping, putting the device back on its own
    void resetMapping(int nr);

private:

    QVariantMap getDeviceInfo(int deviceIndex);


    //
    // Filtering events
    //

private:

    bool eventFilter(QObject *obj, QEvent *event) override;
    bool mouseEventFilter(QObject *obj, QMouseEvent *event);

    bool mouseButtonEventFilter(QObject *obj, QMouseEvent *event);
    bool keyDownEventFilter(QObject *obj, QKeyEvent *event);
    bool keyUpEventFilter(QObject *obj, QKeyEvent *event);
    bool emulationKeyFilter(int port, QKeyEvent *event, bool down);

    optional<KeyCombo> keyCombo(QKeyEvent *event) const;
    bool isRepeat(QKeyEvent *event) const;
    void rememberEvent(QKeyEvent *event);


    //
    // Recording and dispatching
    //

private:

    void recordMouseMotion(u64 timestamp, float x, float y, float dx, float dy);
    void recordMouseButtonEvent(int port, u64 timestamp, int button, bool down);
    void recordJoystickEvent(int port, u64 timestamp, const bool state[5]);

    // Tells the delegate what has changed since the last call
    void dispatch(u64 timestamp);


    //
    // Methods from SDLManagerDelegate
    //

private:

    void sdlAxisEvent(int id, u64 timestamp, int axis, int value, float normalize) override;
    void sdlMotionEvent(int id, u64 timestamp, char state[5]) override;
    void sdlButtonEvent(int id, u64 timestamp, int button, bool down) override;


    //
    // Signals
    //

signals:

    void devicesChanged();
    void port0Changed();
    void port1Changed();
    void port0InfoChanged();
    void port1InfoChanged();
    void captureMouseChanged();
    void captureKeyboardChanged();
    void keyChanged();
    void mouseStateChanged();
    void joystickStateChanged();
};