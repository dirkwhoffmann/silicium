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
#include "SiAmMediaController.h"
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
    unique_ptr<SiAmMediaController> m_mediaController;


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

    // Sampled once per rendered frame (see update()) rather than read
    // straight off the core, so the status bar's warp icon gets a change
    // notification instead of having to poll.
    bool m_warping = false;


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

    SiAmController();

    static SiAmController &instance();
    static VAmiga &core();

    void initialize();

    // Parses the command line, opens the SVM file it names into 'svm', and
    // collects any --exec (-e) commands into execCommands. Returns false if
    // no SVM file was given or it could not be opened, in which case
    // errorMessage describes the failure.
    bool parseArguments(const QCoreApplication &app);

    /* The Rom library: a fixed, app-private folder that only this class and
     * SiAmConfigController::copyToLibrary() ever write to (mirrors
     * C64Controller::romLibraryDir()). Since nothing else can change its
     * contents, RomManager needs pointing here and scanning exactly once, at
     * startup -- no watching, no rescanning.
     */
    static QString romLibraryDir();

private:

    /* Copies every Rom bundled under Shared/Assets/Roms (embedded as Qt
     * resources under ":/Roms", see the ASSET_RESOURCES glob in
     * Apps/CMakeLists.txt) into the Rom library, keeping their original
     * filenames -- unlike copyToLibrary(), there's no need to name these by
     * checksum, since the bundled set is fixed and already uniquely named.
     * Run on every startup, unconditionally, so a copy the user deleted
     * comes back.
     */
    static void installBundledRomFiles(const QString &dir);

public:

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

    // Sampled once per rendered frame (see update()) rather than read
    // straight off the core, so the status bar's warp icon gets a change
    // notification instead of having to poll.
    Q_PROPERTY(bool warping READ warping NOTIFY warpingChanged)

    bool warping() const { return m_warping; }

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
    Q_INVOKABLE void stepOver();
    Q_INVOKABLE void stepInto();
    Q_INVOKABLE void finishLine();
    Q_INVOKABLE void finishFrame();
    Q_INVOKABLE void toggleWarp();


    //
    // Handling subcomponents
    //

    // Toggled by the Debug menu's "Debug Panel" item (see SiAmMenu.qml);
    // shown when both this and Preferences.developerMode are true (see
    // SiAmWindow.qml's SiAmDevPanel instantiation).
    Q_PROPERTY(bool retroShell READ getRetroShell WRITE setRetroShell NOTIFY retroShellChanged)
    Q_PROPERTY(bool debugPanel READ getDebugPanel WRITE setDebugPanel NOTIFY debugPanelChanged)

    bool getRetroShell() const { return m_retroShell; }
    void setRetroShell(bool value);

    bool getDebugPanel() const { return m_debugPanel; }
    void setDebugPanel(bool value);

    Q_INVOKABLE void toggleDebugPanel() { setDebugPanel(!m_debugPanel); }

    Q_INVOKABLE void saveWorkspace();
    Q_INVOKABLE void saveSnapshot();
    Q_INVOKABLE void revertSnapshot();

    Q_PROPERTY(SiAmActivityController *activityController READ getActivityController CONSTANT)
    Q_PROPERTY(SiAmConfigController *configController READ getConfigController CONSTANT)
    Q_PROPERTY(SiAmKeyboardController *keyboardController READ getKeyboardController CONSTANT)
    Q_PROPERTY(SiAmInspectorController *inspectorController READ getInspectorController CONSTANT)
    Q_PROPERTY(SiAmInfoController *info READ getInfoController CONSTANT)
    Q_PROPERTY(SiAmCIAController *ciaController READ getCIAController CONSTANT)
    Q_PROPERTY(SiAmEventController *eventController READ getEventController CONSTANT)
    Q_PROPERTY(SiAmMemoryController *memoryController READ getMemoryController CONSTANT)
    Q_PROPERTY(SiAmCopperController *copperController READ getCopperController CONSTANT)
    Q_PROPERTY(SiAmBlitterController *blitterController READ getBlitterController CONSTANT)
    Q_PROPERTY(SiAmPaulaController *paulaController READ getPaulaController CONSTANT)
    Q_PROPERTY(SiAmBusController *busController READ getBusController CONSTANT)
    Q_PROPERTY(SiAmCPUController *cpuController READ getCPUController CONSTANT)
    Q_PROPERTY(SiAmDeniseController *deniseController READ getDeniseController CONSTANT)
    Q_PROPERTY(SiAmPortController *portController READ getPortController CONSTANT)
    Q_PROPERTY(SiAmRenderer *renderer READ getRenderer WRITE setRenderer NOTIFY rendererChanged)
    Q_PROPERTY(SiAmMediaController *media READ media CONSTANT)

    SiAmActivityController *getActivityController() const { return m_activityController.get(); }
    SiAmConfigController *getConfigController() const { return m_configController.get(); }
    SiAmKeyboardController *getKeyboardController() const { return m_keyboardController.get(); }
    SiAmInspectorController *getInspectorController() const { return m_inspectorController.get(); }
    SiAmInfoController *getInfoController() const { return m_infoController.get(); }
    SiAmCIAController *getCIAController() const { return m_ciaController.get(); }
    SiAmEventController *getEventController() const { return m_eventController.get(); }
    SiAmMemoryController *getMemoryController() const { return m_memoryController.get(); }
    SiAmCopperController *getCopperController() const { return m_copperController.get(); }
    SiAmBlitterController *getBlitterController() const { return m_blitterController.get(); }
    SiAmPaulaController *getPaulaController() const { return m_paulaController.get(); }
    SiAmBusController *getBusController() const { return m_busController.get(); }
    SiAmCPUController *getCPUController() const { return m_cpuController.get(); }
    SiAmDeniseController *getDeniseController() const { return m_deniseController.get(); }
    SiAmPortController *getPortController() const { return m_portController.get(); }

    class SiAmRenderer *getRenderer() const { return m_renderer; }
    void setRenderer(class SiAmRenderer *ptr);

    SiAmMediaController *media() const { return m_mediaController.get(); }


    //
    // Controlling input devices
    //

public:

    Q_PROPERTY(bool keyboardCaptured READ keyboardCaptured NOTIFY captureChanged)
    Q_PROPERTY(bool mouseCaptured READ mouseCaptured NOTIFY captureChanged)

    Q_INVOKABLE void captureMouse();
    Q_INVOKABLE void releaseMouse();
    Q_INVOKABLE void captureOrReleaseMouse() { mouseCaptured() ? releaseMouse() : captureMouse(); }

    bool mouseCaptured();
    bool keyboardCaptured();

    // Hands the keyboard to the virtual machine or back to the app, from the
    // window's focus and whether RetroShell is up. Call after either changes.
    void updateKeyboardCapture();


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


    //
    // Keyboard
    //

public:

    Q_INVOKABLE void resetKeyboardMatrix();


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

    // Receives messages from the emulator thread (see initialize()) and
    // marshals them onto the GUI thread.
    void process(const vamiga::Message &msg, const string &attachment = "");
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
    void rendererChanged();
    void shutdown();
    void captureChanged();
    void mouseWasCaptured();
    void warpingChanged();
    void debugPanelChanged();
    void retroShellChanged();
    void retroShellTextChanged();
    void workspaceSaved();
    void snapshotSaved(const QString &sUUID);
    void snapshotLimitReached();
};
