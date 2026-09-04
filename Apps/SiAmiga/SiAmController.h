// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "VAmiga.h"
#include "Controller.h"
#include "AudioController.h"
#include "SVMFile.h"
#include "SiAmRenderer.h"
#include "SiAmActivityController.h"
#include "Config/SiAmConfigController.h"
#include "Keyboard/SiAmKeyboardController.h"
#include "Inspector/SiAmInspectorController.h"
#include "Inspector/SiAmCIAController.h"
#include "Inspector/SiAmEventController.h"
#include "Inspector/SiAmMemoryController.h"
#include "Inspector/SiAmCopperController.h"
#include "Inspector/SiAmBlitterController.h"
#include "Inspector/SiAmPaulaController.h"
#include "Inspector/SiAmBusController.h"
#include "Inspector/SiAmCPUController.h"
#include "Inspector/SiAmDeniseController.h"
#include "Inspector/SiAmPortController.h"
#include "SiAmInfoController.h"
#include <QUrl>

class QCoreApplication;
using vamiga::VAmiga;
using retro::vault::SVMFile;

class SiAmController : public Controller {

    Q_OBJECT

    // Command line arguments
    vector<string> execCommands;

    // Associated SVM file
    unique_ptr<SVMFile> svm;

    // Describes why the SVM file could not be opened, set by parseArguments()
    QString errorMessage;


    //
    // Components
    //

    // Video renderer
    class SiAmRenderer *m_renderer = nullptr;

    // Audio backend
    AudioController m_audio;

    // Subcontrollers
    unique_ptr<SiAmActivityController> m_activityController;
    unique_ptr<SiAmConfigController> m_configController;
    unique_ptr<SiAmKeyboardController> m_keyboardController;
    unique_ptr<SiAmInspectorController> m_inspectorController;
    unique_ptr<SiAmInfoController> m_infoController;
    unique_ptr<SiAmCIAController> m_ciaController;
    unique_ptr<SiAmEventController> m_eventController;
    unique_ptr<SiAmMemoryController> m_memoryController;
    unique_ptr<SiAmCopperController> m_copperController;
    unique_ptr<SiAmBlitterController> m_blitterController;
    unique_ptr<SiAmPaulaController> m_paulaController;
    unique_ptr<SiAmBusController> m_busController;
    unique_ptr<SiAmCPUController> m_cpuController;
    unique_ptr<SiAmDeniseController> m_deniseController;
    unique_ptr<SiAmPortController> m_portController;


    //
    // Virtual machine state
    //

    // Current state
    VMState m_state = VMState::HIBERNATED;

    // Indicates whether RetroShell is open
    bool m_retroShell = false;

    // Indicates whether the debug panel is visible
    bool m_debugPanel = false;

    // Game port mapping
    int m_port0 = 0;
    int m_port1 = 0;

    // Captured mouse state
    float m_dx       = 0;
    float m_dy       = 0;
    bool m_mb_left   = false;
    bool m_mb_middle = false;
    bool m_mb_right  = false;

    // Captured joystick state
    bool m_joy_up    = false;
    bool m_joy_down  = false;
    bool m_joy_left  = false;
    bool m_joy_right = false;
    bool m_joy_fire  = false;

    bool m_warping = false;

    //
    // Message and signal processing
    //

    // Coalescing update signals
    bool m_configIsDirty = false;
    bool m_infoIsDirty = false;
    bool m_retroShellIsDirty = false;


    //
    // Initializing
    //

public:

    SiAmController();

    static SiAmController &instance();
    static VAmiga &core();

    void initialize();

    // Parses the command line and collects any --exec (-e) commands into
    // execCommands, run once the window opens (see windowDidOpen()). Unlike
    // C64Controller::parseArguments, there is no SVM/workspace file to
    // require here, so this never fails.
    void parseArguments(const QCoreApplication &app);

    Q_PROPERTY(QString errorMessage READ getErrorMessage CONSTANT)
    const QString &getErrorMessage() const { return errorMessage; }


    //
    // Lifetime management
    //

    void start() override;
    Q_INVOKABLE void stop() override;


    //
    // Virtual machine properties
    //

    Q_PROPERTY(VMState state READ getState WRITE setState NOTIFY stateChanged)
    Q_PROPERTY(bool isPoweredOn READ isPoweredOn NOTIFY stateChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY stateChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY stateChanged)

    VMState getState() const { return m_state; }
    void setState(VMState state);
    bool isPoweredOn() const { return m_state == VMState::PAUSED || m_state == VMState::RUNNING; }
    bool isRunning() { return m_state == VMState::RUNNING; }
    bool isPaused() { return m_state == VMState::PAUSED; }

    // Sampled once per rendered frame (see update()) rather than read
    // straight off the core, so the status bar's warp icon gets a change
    // notification instead of having to poll.
    Q_PROPERTY(bool warping READ warping NOTIFY warpingChanged)

    bool warping() const { return m_warping; }

    // Toggled by the Debug menu's "Debug Panel" item (see SiAmMenu.qml);
    // shown when both this and Preferences.developerMode are true (see
    // SiAmWindow.qml's SiAmDevPanel instantiation).
    Q_PROPERTY(bool debugPanel READ getDebugPanel WRITE setDebugPanel NOTIFY debugPanelChanged)

    bool getDebugPanel() const { return m_debugPanel; }
    void setDebugPanel(bool value);
    Q_INVOKABLE void toggleDebugPanel() { setDebugPanel(!m_debugPanel); }


    //
    // RetroShell
    //

    Q_PROPERTY(bool retroShell READ getRetroShell WRITE setRetroShell NOTIFY retroShellChanged)
    Q_PROPERTY(QString retroShellText READ getRetroShellText NOTIFY retroShellTextChanged)
    Q_PROPERTY(int cursorPos READ getCursorPos NOTIFY retroShellTextChanged)

    bool getRetroShell() const { return m_retroShell; }
    void setRetroShell(bool value);

    QString getRetroShellText();
    int getCursorPos();

    Q_INVOKABLE void pressRetroShellKey(int key, int modifiers, const QString &text);


    //
    // Controlling the emulator
    //

    Q_INVOKABLE void run();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void runOrPause() { isPaused() ? run() : pause(); }
    Q_INVOKABLE void reset();
    Q_INVOKABLE void powerOn();
    Q_INVOKABLE void powerOff();
    Q_INVOKABLE void powerOnOrOff() { isPoweredOn() ? powerOff() : powerOn(); }

    // Additional emulator control actions (see SiAmMenu.qml's Edit menu).
    Q_INVOKABLE void softReset();
    Q_INVOKABLE void brk();
    Q_INVOKABLE void stepOver();
    Q_INVOKABLE void stepInto();
    Q_INVOKABLE void finishLine();
    Q_INVOKABLE void finishFrame();
    Q_INVOKABLE void toggleWarp();

    //
    // Controlling the mouse
    //

    Q_PROPERTY(bool mouseCaptured READ mouseCaptured NOTIFY captureChanged)

    Q_INVOKABLE void captureMouse();
    Q_INVOKABLE void releaseMouse();
    Q_INVOKABLE void captureOrReleaseMouse() { mouseCaptured() ? releaseMouse() : captureMouse(); }

    bool mouseCaptured();


    //
    // Floppy drives (df0..df3)
    //

    // 'nr' is 0-3 throughout this section, matching the core's df[] indexing
    // (and SiAmConfigController's driveConnected(nr)/setDriveConnected(nr,..)).
    Q_INVOKABLE bool driveHasDisk(int nr) const;
    Q_INVOKABLE bool driveWriteProtected(int nr) const;
    Q_INVOKABLE bool driveModified(int nr) const;
    Q_INVOKABLE bool driveMotor(int nr) const;
    Q_INVOKABLE bool driveWriting(int nr) const;
    Q_INVOKABLE int driveTrack(int nr) const;
    Q_INVOKABLE void insertDisk(int nr, const QUrl &url, bool wp = false);
    Q_INVOKABLE void newDisk(int nr);
    Q_INVOKABLE void ejectDisk(int nr);
    Q_INVOKABLE void exportDisk(int nr, const QUrl &url);
    Q_INVOKABLE void toggleWriteProtection(int nr);


    //
    // Hard drives (hd0..hd3)
    //

    Q_INVOKABLE bool hdHasDisk(int nr) const;
    Q_INVOKABLE void attachHd(int nr, const QUrl &url);
    // There's no direct "detach" call on the core's HardDriveAPI (unlike
    // FloppyDriveAPI::ejectDisk()) -- disconnecting the controller via
    // HDC_CONNECT is the closest equivalent, and it's what the menu's
    // "Detach" item does.
    Q_INVOKABLE void detachHd(int nr);
    Q_INVOKABLE void exportHd(int nr, const QUrl &url);


    //
    // Keyboard
    //

    Q_INVOKABLE void resetKeyboardMatrix();

    // Starts the emulator core once the window's scene graph is ready, and
    // halts it when the window is destroyed (see attachWindow() below).
    void windowDidOpen();
    void windowDidClose();

    void startRenderer();
    void stopRenderer();

    // Associates this controller with its emulator window and wires up the
    // sceneGraphInitialized/destroyed signals to windowDidOpen()/windowDidClose().
    void attachWindow(QQuickWindow *window);

    Q_PROPERTY(SiAmRenderer *renderer READ getRenderer WRITE setRenderer NOTIFY rendererChanged)

    class SiAmRenderer *getRenderer() const { return m_renderer; }
    void setRenderer(class SiAmRenderer *ptr);

    Q_PROPERTY(SiAmActivityController *activityController READ getActivityController CONSTANT)

    SiAmActivityController *getActivityController() const { return m_activityController.get(); }

    Q_PROPERTY(SiAmConfigController *configController READ getConfigController CONSTANT)

    SiAmConfigController *getConfigController() const { return m_configController.get(); }

    Q_PROPERTY(SiAmKeyboardController *keyboardController READ getKeyboardController CONSTANT)

    SiAmKeyboardController *getKeyboardController() const { return m_keyboardController.get(); }

    Q_PROPERTY(SiAmInspectorController *inspectorController READ getInspectorController CONSTANT)

    SiAmInspectorController *getInspectorController() const { return m_inspectorController.get(); }

    Q_PROPERTY(SiAmInfoController *info READ getInfoController CONSTANT)

    SiAmInfoController *getInfoController() const { return m_infoController.get(); }

    Q_PROPERTY(SiAmCIAController *ciaController READ getCIAController CONSTANT)

    SiAmCIAController *getCIAController() const { return m_ciaController.get(); }

    Q_PROPERTY(SiAmEventController *eventController READ getEventController CONSTANT)

    SiAmEventController *getEventController() const { return m_eventController.get(); }

    Q_PROPERTY(SiAmMemoryController *memoryController READ getMemoryController CONSTANT)

    SiAmMemoryController *getMemoryController() const { return m_memoryController.get(); }

    Q_PROPERTY(SiAmCopperController *copperController READ getCopperController CONSTANT)

    SiAmCopperController *getCopperController() const { return m_copperController.get(); }

    Q_PROPERTY(SiAmBlitterController *blitterController READ getBlitterController CONSTANT)

    SiAmBlitterController *getBlitterController() const { return m_blitterController.get(); }

    Q_PROPERTY(SiAmPaulaController *paulaController READ getPaulaController CONSTANT)

    SiAmPaulaController *getPaulaController() const { return m_paulaController.get(); }

    Q_PROPERTY(SiAmBusController *busController READ getBusController CONSTANT)

    SiAmBusController *getBusController() const { return m_busController.get(); }

    Q_PROPERTY(SiAmCPUController *cpuController READ getCPUController CONSTANT)

    SiAmCPUController *getCPUController() const { return m_cpuController.get(); }

    Q_PROPERTY(SiAmDeniseController *deniseController READ getDeniseController CONSTANT)

    SiAmDeniseController *getDeniseController() const { return m_deniseController.get(); }

    Q_PROPERTY(SiAmPortController *portController READ getPortController CONSTANT)

    SiAmPortController *getPortController() const { return m_portController.get(); }


    //
    // Methods from AudioControllerDelegate
    //

    void linkAudioSink(QAudioSink *sink, QAudioFormat &format) override;


    //
    // Managing the emulator state
    //

    // Called within the message receiver
    void didPowerOn();
    void didPowerOff();
    void didRun();
    void didPause();
    void didShutdown();


    //
    // Processing methods
    //

    // Receives messages from the emulator thread (see initialize()) and
    // marshals them onto the GUI thread.
    void process(const vamiga::Message &msg, const string &attachment = "");
    void update();

signals:

    void stateChanged();
    void rendererChanged();
    void shutdown();
    void captureChanged();
    void mouseWasCaptured();
    void warpingChanged();
    void debugPanelChanged();
    void retroShellChanged();
    void retroShellTextChanged();
};
