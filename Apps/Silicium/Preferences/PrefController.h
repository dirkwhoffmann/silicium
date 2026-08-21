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
#include "InputManager.h"
#include "C64KeyModel.h"
#include <QQuickWindow>
#include <QTimer>

class PrefController : public Controller {

    Q_OBJECT

protected:

    // Selected device in the devices panel
    int m_device = 1;

    // Data model feeding the standalone key recorder's key grid
    C64KeyModel *m_keyModel = nullptr;

    // Set while the user is recording a scancode for a C64 key
    bool m_recording = false;

    // C64 key (nr) currently awaiting a physical key press, or -1 if none
    int m_selectedKey = -1;

    // Active joystick axis / buttons
    bool m_up = false;
    bool m_down = false;
    bool m_left = false;
    bool m_right = false;
    bool m_fire = false;

    // Active mouse buttons
    bool m_mb_left = false;
    bool m_mb_middle = false;
    bool m_mb_right = false;

    // Captured mouse coordinates
    float m_dx = 0;
    float m_dy = 0;

    /* Returns the captured coordinates to rest.
     *
     * dx/dy hold the delta of the most recent motion event, so once the events
     * stop they keep describing a movement that is over and the axis readout
     * stays lit. That happens when the pointer leaves the window, and equally
     * when it simply stops moving inside it. Restarted on every motion event,
     * so it only ever fires once the mouse has gone quiet.
     */
    QTimer m_restTimer;


    //
    // Methods
    //

  public:

    PrefController();
    ~PrefController();

    Q_INVOKABLE void registerAsInputManagerDelegate();

    Q_PROPERTY(QQuickWindow *window READ getWindow WRITE setWindow NOTIFY windowChanged)


    //
    // Standalone positional-keymap recorder (opened from the Controls prefs page)
    //
    // Lets the user map an arbitrary physical key to a C64 key without a
    // running emulator instance: click a key in the recorder window (it
    // highlights), then press the physical key. Rather than registering as
    // an InputManagerDelegate, the recorder window watches
    // AppController.inputManager's pKey/keyChanged directly and forwards the
    // scancode to captureKey().
    //

public:

    Q_PROPERTY(C64KeyModel *keyModel MEMBER m_keyModel CONSTANT)
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
    Q_PROPERTY(int selectedKey READ selectedKey NOTIFY selectedKeyChanged)

    bool recording() const { return m_recording; }
    int selectedKey() const { return m_selectedKey; }

    Q_INVOKABLE void toggleRecording();
    Q_INVOKABLE void selectKey(int nr);
    Q_INVOKABLE void revertKeyMap();

    // Persists 'scancode' as the physical key mapped to the currently
    // selected C64 key, then clears the selection. A no-op if no key is
    // currently selected (e.g. called for the key-up half of a press, or
    // while the recorder isn't awaiting a key at all).
    Q_INVOKABLE void captureKey(uint scancode);

    Q_INVOKABLE QString mappingInfo(int nr) const { return preferences().mappingInfo(nr); }
    Q_INVOKABLE bool isMapped(int nr) const { return preferences().isMapped(nr); }


    //
    // Platform-specific strings
    //

public:

    // Returns a platform-specific character for a key in Qt nomenclature
    Q_PROPERTY(QString ctrlSymbol READ ctrlSymbol CONSTANT)
    Q_PROPERTY(QString metaSymbol READ metaSymbol CONSTANT)
    Q_PROPERTY(QString altSymbol READ altSymbol CONSTANT)

private:

    QString ctrlSymbol() const;
    QString altSymbol() const;
    QString metaSymbol() const;


    //
    // Devices
    //

public:

    Q_PROPERTY(int device READ getDevice WRITE setDevice NOTIFY deviceChanged)
    Q_PROPERTY(int keymap READ getKeymap NOTIFY deviceChanged)

    Q_PROPERTY(bool joyUp READ getUp WRITE setUp NOTIFY upChanged)
    Q_PROPERTY(bool joyDown READ getDown WRITE setDown NOTIFY downChanged)
    Q_PROPERTY(bool joyLeft READ getLeft WRITE setLeft NOTIFY leftChanged)
    Q_PROPERTY(bool joyRight READ getRight WRITE setRight NOTIFY rightChanged)
    Q_PROPERTY(bool joyFire READ getFire WRITE setFire NOTIFY fireChanged)

    Q_PROPERTY(bool mbLeft READ getMbLeft WRITE setMbLeft NOTIFY mbLeftChanged)
    Q_PROPERTY(bool mbMiddle READ getMbMiddle WRITE setMbMiddle NOTIFY mbMiddleChanged)
    Q_PROPERTY(bool mbRight READ getMbRight WRITE setMbRight NOTIFY mbRightChanged)

    Q_PROPERTY(float dx READ getDx WRITE setDx NOTIFY dxChanged)
    Q_PROPERTY(float dy READ getDy WRITE setDy NOTIFY dyChanged)

    Q_INVOKABLE void setJoyKeyset0(int nr, int key, int virtualKey);
    Q_INVOKABLE void setJoyKeyset1(int nr, int key, int virtualKey);
    Q_INVOKABLE void setJoyKeyset(int joyNr, int nr, int key, int virtualKey);
    Q_INVOKABLE void setMouseKeyset(int nr, int key, int virtualKey);
    Q_INVOKABLE void setMapping(const QString &mapping);
    Q_INVOKABLE void resetMapping();

private:

    QQuickWindow *getWindow() const { return m_window; }
    void setWindow(QQuickWindow *window);

    int getDevice() const { return m_device; }
    void setDevice(int value);

    int getKeymap() const { return m_device == 2 ? 0 : m_device == 3 ? 1 : -1; }

    bool getUp() const { return m_up; }
    void setUp(bool value);

    bool getDown() const { return m_down; }
    void setDown(bool value);

    bool getLeft() const { return m_left; }
    void setLeft(bool value);

    bool getRight() const { return m_right; }
    void setRight(bool value);

    bool getFire() const { return m_fire; }
    void setFire(bool value);

    bool getMbLeft() const { return m_mb_left; }
    void setMbLeft(bool value);

    bool getMbMiddle() const { return m_mb_middle; }
    void setMbMiddle(bool value);

    bool getMbRight() const { return m_mb_right; }
    void setMbRight(bool value);

    float getDx() const { return m_dx; }
    void setDx(float value);

    float getDy() const { return m_dy; }
    void setDy(float value);


    //
    // Methods from InputManagerDelegate
    //

private:

    void keyDown(QKeyEvent *even, KeyModifier modifiers) override { };
    void keyUp(QKeyEvent *even, KeyModifier modifiers) override { };
    void keyCombo(KeyCombo combo, int count) override { };
    void mouseDxDy(int port, u64 timestamp, float dx, float dy) override;
    void mouseButton(int port, u64 timestamp, int button, bool down) override;
    void warpToCenter() override;
    void joystickMotionEvent(int port, u64 timestamp, bool state[5]) override;


    //
    // Signals
    //

  signals:

    void windowChanged();
    void deviceChanged();
    void upChanged();
    void downChanged();
    void leftChanged();
    void rightChanged();
    void fireChanged();
    void mbLeftChanged();
    void mbMiddleChanged();
    void mbRightChanged();
    void deviceInfoChanged();
    void dxChanged();
    void dyChanged();
    void recordingChanged();
    void selectedKeyChanged();
};