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

    /* The activity of the device in control port 1, which is where the
     * preview of the selected device is mapped (see
     * registerAsInputManagerDelegate()). The state itself is kept by the
     * input manager.
     */
    Q_PROPERTY(bool joyUp READ getUp NOTIFY joystickStateChanged)
    Q_PROPERTY(bool joyDown READ getDown NOTIFY joystickStateChanged)
    Q_PROPERTY(bool joyLeft READ getLeft NOTIFY joystickStateChanged)
    Q_PROPERTY(bool joyRight READ getRight NOTIFY joystickStateChanged)
    Q_PROPERTY(bool joyFire READ getFire NOTIFY joystickStateChanged)

    Q_PROPERTY(bool mbLeft READ getMbLeft NOTIFY mouseStateChanged)
    Q_PROPERTY(bool mbMiddle READ getMbMiddle NOTIFY mouseStateChanged)
    Q_PROPERTY(bool mbRight READ getMbRight NOTIFY mouseStateChanged)

    Q_PROPERTY(float dx READ getDx NOTIFY mouseStateChanged)
    Q_PROPERTY(float dy READ getDy NOTIFY mouseStateChanged)

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

    bool getUp() const { return inputManager.portState(0).joy[0]; }
    bool getDown() const { return inputManager.portState(0).joy[1]; }
    bool getLeft() const { return inputManager.portState(0).joy[2]; }
    bool getRight() const { return inputManager.portState(0).joy[3]; }
    bool getFire() const { return inputManager.portState(0).joy[4]; }

    bool getMbLeft() const { return inputManager.portState(0).mb[0]; }
    bool getMbMiddle() const { return inputManager.portState(0).mb[1]; }
    bool getMbRight() const { return inputManager.portState(0).mb[2]; }

    float getDx() const { return inputManager.portState(0).dx; }
    float getDy() const { return inputManager.portState(0).dy; }


    //
    // Methods from InputManagerDelegate
    //

private:

    void keyDown(QKeyEvent *even, KeyModifier modifiers) override { };
    void keyUp(QKeyEvent *even, KeyModifier modifiers) override { };
    void keyCombo(KeyCombo combo, int count) override { };
    void warpToCenter() override;


    //
    // Signals
    //

  signals:

    void windowChanged();
    void deviceChanged();
    void deviceInfoChanged();
    void mouseStateChanged();
    void joystickStateChanged();
    void recordingChanged();
    void selectedKeyChanged();
};