// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "VirtualC64.h"
#include "Controller.h"
#include "AudioController.h"
#include "SVMFile.h"
#include "SiC64ConfigController.h"
#include "SiC64InfoController.h"
#include "SiC64ActivityController.h"
#include "SiC64StatusbarController.h"
#include "C64MediaController.h"
#include "SiC64Renderer.h"
#include "Keyboard/SiC64KeyboardController.h"
#include "Inspector/SiC64EventController.h"
#include "Inspector/SiC64CIAController.h"
#include "Inspector/SiC64BusController.h"
#include "Inspector/SiC64CPUController.h"
#include "Inspector/SiC64MemoryController.h"
#include "Inspector/SiC64VICController.h"
#include "Inspector/SiC64SIDController.h"

class QCoreApplication;
using vc64::VirtualC64;
using retro::vault::SVMFile;

class C64Controller : public Controller {

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
    class SiC64Renderer *m_renderer = nullptr;

    // Audio backend
    AudioController m_audio;

    // Subcontrollers
    unique_ptr<SiC64ActivityController> m_activityController;
    unique_ptr<SiC64BusController> m_busController;
    unique_ptr<SiC64CIAController> m_ciaController;
    unique_ptr<SiC64CPUController> m_cpuController;
    unique_ptr<SiC64MemoryController> m_memoryController;
    unique_ptr<SiC64VICController> m_vicController;
    unique_ptr<SiC64SIDController> m_sidController;
    unique_ptr<SiC64ConfigController> m_configController;
    unique_ptr<SiC64EventController> m_eventController;
    unique_ptr<SiC64InfoController> m_infoController;
    unique_ptr<SiC64KeyboardController> m_keyboardController;
    unique_ptr<SiC64StatusbarController> m_statusbarController;
    unique_ptr<C64MediaController> m_mediaController;


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


    //
    // Shared inspector state
    //

    // Display format (shared by every open inspector window
    // 0 = hex, 1 = hex zero-padded, 2 = decimal, 3 = decimal zero-padded.
    int m_format = 0;


    //
    // Message and signal processing
    //

    // Coalescing update signals
    bool m_configIsDirty = false;
    bool m_infoIsDirty = false;
    bool m_retroShellIsDirty = false;


    //
    // Constructing and initializing
    //

public:

    C64Controller();

    static C64Controller &instance();
    static VirtualC64 &core();

    void initialize();

    // Parses the command line, opens the SVM file it names into 'svm', and
    // collects any --exec (-e) commands into execCommands. Returns false if
    // no SVM file was given or it could not be opened, in which case
    // errorMessage describes the failure.
    bool parseArguments(const QCoreApplication &app);

    Q_PROPERTY(QString errorMessage READ getErrorMessage CONSTANT)
    const QString &getErrorMessage() const { return errorMessage; }


    //
    // Managing lifetime
    //

public:

    Q_PROPERTY(VMState state READ getState WRITE setState NOTIFY stateChanged)
    VMState getState() const { return m_state; }
    void setState(VMState state);

    void start() override;
    Q_INVOKABLE void stop() override;

    // Starts the emulator core once the window's scene graph is ready, and
    // halts it when the window is destroyed (see attachWindow() below).
    void windowDidOpen();
    void windowDidClose();

    void startRenderer();
    void stopRenderer();

    // Associates this controller with its emulator window and wires up the
    // sceneGraphInitialized/destroyed signals to windowDidOpen()/windowDidClose().
    void attachWindow(QQuickWindow *window);


    //
    // Managing the emulator state
    //

public:

    Q_PROPERTY(bool isPoweredOn READ isPoweredOn NOTIFY stateChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY stateChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY stateChanged)
    Q_PROPERTY(bool readOnly READ getReadOnly CONSTANT)

    Q_PROPERTY(QString uuid READ getUUID CONSTANT)
    Q_PROPERTY(QString name READ getName CONSTANT)

    bool isPoweredOn() const { return m_state == VMState::PAUSED || m_state == VMState::RUNNING; }
    bool isRunning() { return m_state == VMState::RUNNING; }
    bool isPaused() { return m_state == VMState::PAUSED; }
    bool getReadOnly() const;
    QString getUUID() const;
    QString getName() const;

    Q_INVOKABLE void powerOn();
    Q_INVOKABLE void powerOff();
    Q_INVOKABLE void powerOnOrOff() { isPoweredOn() ? powerOff() : powerOn(); }
    Q_INVOKABLE void run();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void runOrPause() { isPaused() ? run() : pause(); }
    Q_INVOKABLE void hibernate(bool hibernateSnapshot, bool hibernateWorkspace);

    Q_INVOKABLE void reset();
    Q_INVOKABLE void softReset();
    Q_INVOKABLE void brk();
    Q_INVOKABLE void stopAndGo(); // DEPRECATED
    Q_INVOKABLE void stepOver();
    Q_INVOKABLE void stepInto();
    Q_INVOKABLE void stepCycle();
    Q_INVOKABLE void finishLine();
    Q_INVOKABLE void finishFrame();
    Q_INVOKABLE void toggleWarp();


    //
    // Handling subcomponents
    //

    Q_PROPERTY(bool retroShell READ getRetroShell WRITE setRetroShell NOTIFY retroShellChanged)
    Q_PROPERTY(bool debugPanel READ getDebugPanel WRITE setDebugPanel NOTIFY debugPanelChanged)

    bool getRetroShell() const { return m_retroShell; }
    void setRetroShell(bool value);

    bool getDebugPanel() const { return m_debugPanel; }
    void setDebugPanel(bool value);

    Q_INVOKABLE void toggleDebugPanel() { setDebugPanel(!m_debugPanel); }

    Q_INVOKABLE void openConfigurator() {}
    Q_INVOKABLE void openInspector() {}
    Q_INVOKABLE void openKeyboard() {}

    Q_INVOKABLE void saveWorkspace();
    Q_INVOKABLE void saveSnapshot();
    Q_INVOKABLE void revertSnapshot();

    Q_PROPERTY(SiC64ActivityController *activityController READ getActivityController CONSTANT)
    Q_PROPERTY(SiC64BusController *busController READ getBusController CONSTANT)
    Q_PROPERTY(SiC64CIAController *ciaController READ getCIAController CONSTANT)
    Q_PROPERTY(SiC64CPUController *cpuController READ getCPUController CONSTANT)
    Q_PROPERTY(SiC64MemoryController *memoryController READ getMemoryController CONSTANT)
    Q_PROPERTY(SiC64VICController *vicController READ getVICController CONSTANT)
    Q_PROPERTY(SiC64SIDController *sidController READ getSIDController CONSTANT)
    Q_PROPERTY(SiC64ConfigController *configController READ getConfigController CONSTANT)
    Q_PROPERTY(SiC64EventController *eventController READ getEventController CONSTANT)
    Q_PROPERTY(SiC64InfoController *info READ getInfoController CONSTANT)
    Q_PROPERTY(SiC64KeyboardController *keyboardController READ getKeyboardController CONSTANT)
    Q_PROPERTY(SiC64StatusbarController *statusbarController READ getStatusbarController CONSTANT)
    Q_PROPERTY(SiC64Renderer *renderer READ getRenderer WRITE setRenderer NOTIFY rendererChanged)
    Q_PROPERTY(C64MediaController *media READ media CONSTANT)

    SiC64ActivityController *getActivityController() const { return m_activityController.get(); }
    SiC64BusController *getBusController() const { return m_busController.get(); }
    SiC64CIAController *getCIAController() const { return m_ciaController.get(); }
    SiC64CPUController *getCPUController() const { return m_cpuController.get(); }
    SiC64MemoryController *getMemoryController() const { return m_memoryController.get(); }
    SiC64VICController *getVICController() const { return m_vicController.get(); }
    SiC64SIDController *getSIDController() const { return m_sidController.get(); }
    SiC64ConfigController *getConfigController() const { return m_configController.get(); }
    SiC64EventController *getEventController() const { return m_eventController.get(); }
    SiC64InfoController *getInfoController() const { return m_infoController.get(); }
    SiC64KeyboardController *getKeyboardController() const { return m_keyboardController.get(); }
    SiC64StatusbarController *getStatusbarController() const { return m_statusbarController.get(); }

    class SiC64Renderer *getRenderer() const { return m_renderer; }
    void setRenderer(class SiC64Renderer *ptr);

    C64MediaController *media() const { return m_mediaController.get(); }


    //
    // Controlling input devices
    //

public:

    Q_PROPERTY(int port0 READ getPort0 WRITE setPort0 NOTIFY port0Changed)
    Q_PROPERTY(int port1 READ getPort1 WRITE setPort1 NOTIFY port1Changed)

    int getPort0() const { return m_port0; }
    void setPort0(int value);

    int getPort1() const { return m_port1; }
    void setPort1(int value);

    Q_PROPERTY(bool keyboardCaptured READ keyboardCaptured NOTIFY captureChanged)
    Q_PROPERTY(bool mouseCaptured READ mouseCaptured NOTIFY captureChanged)

    Q_INVOKABLE void captureMouse();
    Q_INVOKABLE void releaseMouse();
    Q_INVOKABLE void captureOrReleaseMouse() { mouseCaptured() ? releaseMouse() : captureMouse(); }

    bool mouseCaptured();
    bool keyboardCaptured();

    Q_PROPERTY(float dx READ getDx WRITE setDx NOTIFY dxChanged)
    Q_PROPERTY(float dy READ getDy WRITE setDy NOTIFY dyChanged)
    Q_PROPERTY(bool mbLeft READ getMbLeft WRITE setMbLeft NOTIFY mbLeftChanged)
    Q_PROPERTY(bool mbMiddle READ getMbMiddle WRITE setMbMiddle NOTIFY mbMiddleChanged)
    Q_PROPERTY(bool mbRight READ getMbRight WRITE setMbRight NOTIFY mbRightChanged)
    Q_PROPERTY(bool joyUp READ getJoyUp WRITE setJoyUp NOTIFY joyUpChanged)
    Q_PROPERTY(bool joyDown READ getJoyDown WRITE setJoyDown NOTIFY joyDownChanged)
    Q_PROPERTY(bool joyLeft READ getJoyLeft WRITE setJoyLeft NOTIFY joyLeftChanged)
    Q_PROPERTY(bool joyRight READ getJoyRight WRITE setJoyRight NOTIFY joyRightChanged)
    Q_PROPERTY(bool joyFire READ getJoyFire WRITE setJoyFire NOTIFY joyFireChanged)

    float getDx() const { return m_dx; }
    void setDx(float value);

    float getDy() const { return m_dy; }
    void setDy(float value);

    bool getMbLeft() const { return m_mb_left; }
    void setMbLeft(bool value);

    bool getMbMiddle() const { return m_mb_middle; }
    void setMbMiddle(bool value);

    bool getMbRight() const { return m_mb_right; }
    void setMbRight(bool value);

    bool getJoyUp() const { return m_joy_up; }
    void setJoyUp(bool value);

    bool getJoyDown() const { return m_joy_down; }
    void setJoyDown(bool value);

    bool getJoyLeft() const { return m_joy_left; }
    void setJoyLeft(bool value);

    bool getJoyRight() const { return m_joy_right; }
    void setJoyRight(bool value);

    bool getJoyFire() const { return m_joy_fire; }
    void setJoyFire(bool value);


    //
    // Managing the shared display state
    //

public:

    // Hands the keyboard to the virtual machine or back to the app, from the
    // window's focus and whether RetroShell is up. Call after either changes.
    void updateKeyboardCapture();

    // Shared inspector display format (see m_format above)
    Q_PROPERTY(int format READ format WRITE setFormat NOTIFY formatChanged)

    int format() const { return m_format; }
    void setFormat(int value);

    bool isHex() const { return m_format == 0 || m_format == 1; }
    bool isPadded() const { return m_format == 1 || m_format == 3; }


    //
    // Working with RetroShell
    //

public:

    Q_PROPERTY(QString retroShellText READ getRetroShellText NOTIFY retroShellTextChanged)
    Q_PROPERTY(int cursorPos READ getCursorPos NOTIFY retroShellTextChanged)

    QString getRetroShellText();
    int getCursorPos();

    Q_INVOKABLE void pressRetroShellKey(int key, int modifiers, const QString &text);


    //
    // Methods from InputManagerDelegate
    //

public:

    void keyDown(QKeyEvent *event, KeyModifier modifiers) override;
    void keyUp(QKeyEvent *event, KeyModifier modifiers) override;
    void keyCombo(KeyCombo combo, int count) override;
    void capsLock(bool state) override;

    void mouseXY(int port, u64 timestamp, float x, float y) override {}
    void mouseDxDy(int port, u64 timestamp, float dx, float dy) override;
    void mouseButton(int port, u64 timestamp, int button, bool down) override;
    bool detectShakeDxDy(float dx, float dy) override;

    void shakeDetected() override;

    void warpToCenter() override;
    void joystickMotionEvent(int port, u64 timestamp, bool state[5]) override;


    //
    // Methods from AudioControllerDelegate
    //

public:

    void linkAudioSink(QAudioSink *sink, QAudioFormat &format) override;


    //
    // Snapshots and workspaces
    //

public:

    Q_INVOKABLE void shrinkSnapshotStorage(int count);

private:

    /* The unconditional half of saveSnapshot(): captures the machine and
     * files the result. saveSnapshot() checks the capacity limit and asks the
     * user first; hibernation evicts silently and comes straight here, because
     * it runs on quit where a dialog would have nowhere to go.
     */
    void captureSnapshot();

public:

    //
    // Processing messages
    //

    // Receives messages from the emulator thread (see windowDidOpen()) and
    // marshals them onto the GUI thread.
    void process(const vc64::Message &msg, const string &attachment = "");
    void update();

private:

    // Processes incoming RPC messages
    void rpcReceive(const char *payload);
    void rpcSend(const char *payload);

    // Loads a specific snapshot from this VM's own SVM
    void loadSnapshot(const utl::UUID &uuid);

    // Called within the message receiver
    void didPowerOn();
    void didPowerOff();
    void didRun();
    void didPause();
    void didShutdown();

private:

    // Updates the VM state and reports it through the RPC server
    void reportState(VMState state);

    // Reports that the SVM file was just written to disk through the RPC server
    void notifySvmChanged(const QString &kind, const QString &uuid = {});

    /* Tells the Hub to pack the archive after we persisted into the root
     * folder it gave us. A no-op when nothing is listening, which is the
     * standalone case -- see the definition.
     */
    void notifyPersist();

public:

    /* Hands a fatal error to the Hub by sending a "fatalError" JSON-RPC
     * notification through the RPC server. Fatal errors are the ones this
     * window cannot recover from, so the Hub -- which outlives us -- shows
     * the dialog instead (see HubController::processRpcPacket()). Unlike the
     * other notifications, the payload is an object: the Hub's error dialog
     * takes a title and a body.
     */
    Q_INVOKABLE void notifyFatalError(const QString &title, const QString &text);

signals:

    void stateChanged();
    void retroShellChanged();
    void port0Changed();
    void port1Changed();
    void debugPanelChanged();
    void captureChanged();
    void mouseWasCaptured();
    void shutdown();
    void dxChanged();
    void dyChanged();
    void mbLeftChanged();
    void mbMiddleChanged();
    void mbRightChanged();
    void joyUpChanged();
    void joyDownChanged();
    void joyLeftChanged();
    void joyRightChanged();
    void joyFireChanged();

    void cpuStateChanged();
    void retroShellTextChanged();
    void rendererChanged();
    void workspaceSaved();
    void snapshotSaved(const QString &sUUID);
    void snapshotLimitReached();
    void formatChanged();
};
