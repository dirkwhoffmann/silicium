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

    //
    // Virtual machine state (formerly VMController)
    //

    // Current State
    VMState m_state = VMState::HIBERNATED;

    // Indicates if the RetroShell panel is open
    bool m_retroShell = false;

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

    // Debug panel visibility
    bool m_debugPanel = false;

    // The associated SVM file
    unique_ptr<SVMFile> svm;

    // Gateway to the host audio backend. Hub controllers get one per VM;
    // SiC64 manages a single VM per process, so this lives directly on
    // C64Controller instead.
    AudioController m_audio;

    // Video renderer. Owned by the QML scene graph (SiC64Canvas.qml), not by
    // this controller -- see setRenderer().
    class SiC64Renderer *m_renderer = nullptr;

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

    // Shared by every open inspector window (see SiC64InspectorToolbar's
    // format combo box) -- the old Swift-based emulator's Inspector kept a
    // separate hex/padding setting per window instance, but since SiC64's
    // inspector sub-controllers (SiC64EventController, SiC64CIAController,
    // ...) are themselves shared singletons rather than one-per-window, a
    // single shared format setting is the simpler match for this
    // architecture.
    //
    // Values mirror the old Swift-based emulator's Inspector.format:
    // 0 = hex, 1 = hex zero-padded, 2 = decimal, 3 = decimal zero-padded.
    int m_format = 0;

    // Commands to execute after startup, collected from --exec (-e) arguments
    vector<string> execCommands;

    // Describes why the SVM file could not be opened, set by parseArguments()
    QString errorMessage;

    // Coalescing update signals
    bool m_configIsDirty = false;
    bool m_infoIsDirty = false;
    bool m_retroShellIsDirty = false;

    // Recently inserted disks. Shared by both drives (matching the old
    // Swift-based emulator's MediaManager.insertedFloppyDisks), newest
    // first, capped at 10, no duplicate URLs.
    QStringList m_recentDisks;

    // Adds url to m_recentDisks if not already present, trimming the list to
    // maxRecentDisks. Called after every successful disk insertion (both
    // insertDisk and insertRecentDisk funnel through it).
    void noteRecentlyInsertedDisk(const QUrl &url);

    // Recently inserted tapes / attached cartridges. Same rationale as
    // m_recentDisks above.
    QStringList m_recentTapes;
    QStringList m_recentCartridges;

    void noteRecentlyInsertedTape(const QUrl &url);
    void noteRecentlyAttachedCartridge(const QUrl &url);

public:

    C64Controller();

    static C64Controller &instance();
    static VirtualC64 &core();

    void initialize();


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
    Q_PROPERTY(bool readOnly READ getReadOnly CONSTANT)

    Q_PROPERTY(QString uuid READ getUUID CONSTANT)
    Q_PROPERTY(QString name READ getName CONSTANT)

    VMState getState() const { return m_state; }
    void setState(VMState state);
    bool isPoweredOn() const { return m_state == VMState::PAUSED || m_state == VMState::RUNNING; }
    bool isRunning() { return m_state == VMState::RUNNING; }
    bool isPaused() { return m_state == VMState::PAUSED; }
    bool getReadOnly() const;
    QString getUUID() const;
    QString getName() const;


    //
    // Controlling input devices
    //

    Q_PROPERTY(bool keyboardCaptured READ keyboardCaptured NOTIFY captureChanged)
    Q_PROPERTY(bool mouseCaptured READ mouseCaptured NOTIFY captureChanged)

    Q_INVOKABLE void captureMouse();
    Q_INVOKABLE void releaseMouse();
    Q_INVOKABLE void captureOrReleaseMouse() { mouseCaptured() ? releaseMouse() : captureMouse(); }

    bool mouseCaptured();
    bool keyboardCaptured();


    //
    //
    //

    Q_PROPERTY(bool retroShell READ getRetroShell WRITE setRetroShell NOTIFY retroShellChanged)
    Q_PROPERTY(int port0 READ getPort0 WRITE setPort0 NOTIFY port0Changed)
    Q_PROPERTY(int port1 READ getPort1 WRITE setPort1 NOTIFY port1Changed)
    Q_PROPERTY(bool debugPanel READ getDebugPanel WRITE setDebugPanel NOTIFY debugPanelChanged)

    bool getRetroShell() const { return m_retroShell; }
    void setRetroShell(bool value);

    int getPort0() const { return m_port0; }
    void setPort0(int value);

    int getPort1() const { return m_port1; }
    void setPort1(int value);

    bool getDebugPanel() const { return m_debugPanel; }
    void setDebugPanel(bool value);

    Q_INVOKABLE void hibernate(bool hibernateSnapshot, bool hibernateWorkspace);


    //
    // Debug state (captured mouse and joystick values, shown by the dev panel)
    //

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
    // General action
    //

    Q_INVOKABLE void openConfigurator() {}
    Q_INVOKABLE void openInspector() {}
    Q_INVOKABLE void saveWorkspace();
    Q_INVOKABLE void saveSnapshot();
    Q_INVOKABLE void revertSnapshot();
    Q_INVOKABLE void openKeyboard() {}


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
    Q_INVOKABLE void toggleDebugPanel() { setDebugPanel(!m_debugPanel); }

    // Starts the emulator core once the window's scene graph is ready, and
    // halts it when the window is destroyed (see attachWindow() below).
    void windowDidOpen();
    void windowDidClose();

    void startRenderer();
    void stopRenderer();

    // Associates this controller with its emulator window and wires up the
    // sceneGraphInitialized/destroyed signals to windowDidOpen()/windowDidClose().
    void attachWindow(QQuickWindow *window);

    // Hands the keyboard to the virtual machine or back to the app, from the
    // window's focus and whether RetroShell is up. Call after either changes.
    void updateKeyboardCapture();

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

    // Shared inspector display format (see m_format above)
    Q_PROPERTY(int format READ format WRITE setFormat NOTIFY formatChanged)

    int format() const { return m_format; }
    void setFormat(int value);

    bool isHex() const { return m_format == 0 || m_format == 1; }
    bool isPadded() const { return m_format == 1 || m_format == 3; }

    // Parses the command line, opens the SVM file it names into 'svm', and
    // collects any --exec (-e) commands into execCommands. Returns false if
    // no SVM file was given or it could not be opened, in which case
    // errorMessage describes the failure.
    bool parseArguments(const QCoreApplication &app);

    Q_PROPERTY(QString errorMessage READ getErrorMessage CONSTANT)
    const QString &getErrorMessage() const { return errorMessage; }

    //
    // RetroShell
    //

    Q_PROPERTY(QString retroShellText READ getRetroShellText NOTIFY retroShellTextChanged)
    Q_PROPERTY(int cursorPos READ getCursorPos NOTIFY retroShellTextChanged)

    QString getRetroShellText();
    int getCursorPos();

    Q_INVOKABLE void pressRetroShellKey(int key, int modifiers, const QString &text);

    //
    // Methods from InputManagerDelegate
    //

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

    void linkAudioSink(QAudioSink *sink, QAudioFormat &format) override;


    // Additional emulator control actions (see SiC64Actions' Edit menu
    // commands, wired up in SiC64Menu.qml).
    Q_INVOKABLE void stopAndGo();
    Q_INVOKABLE void softReset();
    Q_INVOKABLE void brk();
    Q_INVOKABLE void stepOver();
    Q_INVOKABLE void stepInto();
    Q_INVOKABLE void stepCycle();
    Q_INVOKABLE void finishLine();
    Q_INVOKABLE void finishFrame();
    Q_INVOKABLE void toggleWarp();


    //
    // Snapshots and workspaces
    //

    Q_INVOKABLE void shrinkSnapshotStorage(int count);


    //
    // Media files
    //

    // 'drive' is 8 or 9 throughout this class' public API (matching the UI's
    // drive numbers), converted to the core's 0/1 indexing internally.
    //
    // Q_INVOKABLE methods must stay in a public: section -- QML's method
    // dispatch silently ignores ones declared under private:/protected:
    // (calling them reports "is not a function" instead of erroring at
    // registration time), which is why this was moved out of the private
    // block below that still holds the plain C++ helpers.
    Q_INVOKABLE void insertDisk(int drive, const QUrl &url, bool wp = false);

    // Flashes a program file (PRG / P00 / T64) straight into the running
    // machine's RAM, making it immediately runnable -- the "Memory" drop zone.
    // Mirrors the old Swift-based emulator's MediaManager.flashFile(url:).
    Q_INVOKABLE void flash(const QUrl &url);

    // Creates and inserts a blank disk. 'fsFormat' is a retro::vault::cbm::FSFormat
    // value (0 = NODOS, 1 = CBM), matching the "File system" combo box in
    // SiC64DiskCreator.
    Q_INVOKABLE void newDisk(int drive, int fsFormat, const QString &name);

    // Whether the drive currently holds a disk with unsaved changes (see
    // SiC64Window's proceedWithUnsavedFloppyDisk).
    Q_INVOKABLE bool hasModifiedDisk(int drive) const;

    // Exports the current disk to an image file. Only D64 is supported by
    // the core's codec right now (see FloppyDisk::writeToFile), which is why
    // SiC64DiskExporter doesn't offer T64/PRG like the old Swift-based
    // emulator did.
    Q_INVOKABLE void exportDisk(int drive, const QUrl &url);

    // Exports the current disk's file system as a folder of plain files.
    Q_INVOKABLE void exportDiskFolder(int drive, const QUrl &url);

    // Ejects the current disk. Callers are expected to run this through
    // SiC64Window's proceedWithUnsavedFloppyDisk first, same as insert/new.
    Q_INVOKABLE void ejectDisk(int drive);

    // Toggles write-protection on the current disk.
    Q_INVOKABLE void toggleWriteProtection(int drive);

    // Toggles the modification flag ("unsaved changes") on the current disk.
    // Developer-only escape hatch for exercising the unsaved-state UI (the
    // eject/quit confirmation prompts) without having to actually modify a
    // disk's contents first.
    Q_INVOKABLE void toggleUnsavedState(int drive);

    // Toggles the drive's own power switch (independent of the disk).
    Q_INVOKABLE void toggleDrivePower(int drive);

    // Per-drive state for the Drive menu's Eject/Export/Write Protected/Power
    // items (enabled state and checkmarks). Two properties per state rather
    // than a parameterized getter, since Q_INVOKABLE methods aren't reactive
    // QML bindings and the menu needs to redraw as disks are
    // inserted/ejected/protected. Refreshed alongside the rest of the polled
    // "info" state -- see update().
    Q_PROPERTY(bool drive8HasDisk READ drive8HasDisk NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9HasDisk READ drive9HasDisk NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8WriteProtected READ drive8WriteProtected NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9WriteProtected READ drive9WriteProtected NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8Modified READ drive8Modified NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9Modified READ drive9Modified NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive8PoweredOn READ drive8PoweredOn NOTIFY driveStateChanged)
    Q_PROPERTY(bool drive9PoweredOn READ drive9PoweredOn NOTIFY driveStateChanged)

    bool drive8HasDisk() const { return core().drive8.getInfo().hasDisk; }
    bool drive9HasDisk() const { return core().drive9.getInfo().hasDisk; }
    bool drive8WriteProtected() const { return core().drive8.getInfo().hasProtectedDisk; }
    bool drive9WriteProtected() const { return core().drive9.getInfo().hasProtectedDisk; }
    bool drive8Modified() const { return core().drive8.getInfo().hasModifiedDisk; }
    bool drive9Modified() const { return core().drive9.getInfo().hasModifiedDisk; }
    bool drive8PoweredOn() const { return core().get(vc64::Opt::DRV_POWER_SWITCH, 0); }
    bool drive9PoweredOn() const { return core().get(vc64::Opt::DRV_POWER_SWITCH, 1); }


    //
    // Datasette
    //

    Q_INVOKABLE void insertTape(const QUrl &url);
    Q_INVOKABLE void ejectTape();
    Q_INVOKABLE void exportTape(const QUrl &url);
    Q_INVOKABLE void rewindTape();

    // Presses the datasette's Play key, or Stop if it's already playing.
    Q_INVOKABLE void playOrStopTape();

    // Same rationale as the drive properties above: reused by the Datasette
    // menu's enabled state and the Play/Stop item's dynamic title.
    Q_PROPERTY(bool tapeInserted READ tapeInserted NOTIFY driveStateChanged)
    Q_PROPERTY(bool tapePlaying READ tapePlaying NOTIFY driveStateChanged)

    bool tapeInserted() const { return core().datasette.getInfo().hasTape; }
    bool tapePlaying() const { return core().datasette.getInfo().playKey; }


    //
    // Cartridges
    //

    Q_INVOKABLE void attachCartridge(const QUrl &url);
    Q_INVOKABLE void detachCartridge();
    Q_INVOKABLE void attachReu(int capacity);
    Q_INVOKABLE void attachGeoRam(int capacity);
    Q_INVOKABLE void attachIsepic();
    Q_INVOKABLE void exportCartridge(const QUrl &url);

    // Presses the given cartridge button (1 or 2) briefly, then releases it.
    Q_INVOKABLE void pressCartridgeButton(int nr);

    // Sets the cartridge switch position: -1 = left, 0 = neutral, 1 = right.
    Q_INVOKABLE void setCartridgeSwitch(int pos);

    // Same rationale as the drive/tape properties above.
    Q_PROPERTY(bool cartridgeAttached READ cartridgeAttached NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsReu READ cartridgeIsReu NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsGeoRam READ cartridgeIsGeoRam NOTIFY driveStateChanged)
    Q_PROPERTY(bool cartridgeIsIsepic READ cartridgeIsIsepic NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeMemory READ cartridgeMemory NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeButtons READ cartridgeButtons NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeSwitches READ cartridgeSwitches NOTIFY driveStateChanged)
    Q_PROPERTY(int cartridgeSwitchPos READ cartridgeSwitchPos NOTIFY driveStateChanged)

    bool cartridgeAttached() const { return core().expansionPort.getCartridgeTraits().type != vc64::CartridgeType::NONE; }
    bool cartridgeIsReu() const { return core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::REU; }
    bool cartridgeIsGeoRam() const { return core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::GEO_RAM; }
    bool cartridgeIsIsepic() const { return core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::ISEPIC; }
    // CartridgeTraits::memory is in bytes; the REU/GeoRam submenus compare
    // against KB capacities (128/256/512/...), matching attachReu/attachGeoRam's
    // own KB-based parameter.
    int cartridgeMemory() const { return (int)(core().expansionPort.getCartridgeTraits().memory / 1024); }
    int cartridgeButtons() const { return (int)core().expansionPort.getCartridgeTraits().buttons; }
    int cartridgeSwitches() const { return (int)core().expansionPort.getCartridgeTraits().switches; }
    int cartridgeSwitchPos() const { return (int)core().expansionPort.getInfo().switchPos; }


    //
    // Recently used media -- see the Q_PROPERTY declarations further below;
    // these Q_INVOKABLE methods must stay public for the same reason
    // insertDisk/hasModifiedDisk were moved up here
    //

    // Inserts the recently used disk at the given position into the drive.
    // The list itself is shared by both drives; only the target drive
    // depends on which one's "Insert Recent" submenu was used.
    Q_INVOKABLE void insertRecentDisk(int drive, int index);

    // Clears the shared list of recently inserted disks
    Q_INVOKABLE void clearRecentlyInsertedDisks();

    // Inserts the recently used tape at the given position into the datasette
    Q_INVOKABLE void insertRecentTape(int index);

    // Clears the list of recently inserted tapes
    Q_INVOKABLE void clearRecentlyInsertedTapes();

    // Attaches the recently used cartridge at the given position
    Q_INVOKABLE void attachRecentCartridge(int index);

    // Clears the list of recently attached cartridges
    Q_INVOKABLE void clearRecentlyAttachedCartridges();

private:

    /* The unconditional half of saveSnapshot(): captures the machine and
     * files the result. saveSnapshot() checks the capacity limit and asks the
     * user first; hibernation evicts silently and comes straight here, because
     * it runs on quit where a dialog would have nowhere to go.
     */
    void captureSnapshot();

public:

    //
    // Managing the emulator state
    //

    // Called within the message receiver
    void didPowerOn();
    void didPowerOff();
    void didRun();
    void didPause();
    void didShutdown();

private:

    // Updates the VM state and reports it to the Hub (if this instance was
    // launched by one) by sending a "vmState" JSON-RPC notification through
    // the RPC server. The Hub reads it over the process's stdout pipe to
    // track our state -- see HubController::launch().
    void reportState(VMState state);

    /* Reports that the SVM file was just written to disk (workspace or
     * snapshot save) by sending a "svmChanged" JSON-RPC notification through
     * the RPC server. Lets the Hub know its in-memory manifest for this VM
     * is stale -- see HubController::processRpcPacket().
     *
     * 'uuid' names the snapshot that was just created, when the write was a
     * snapshot save. The Hub uses it to reveal and select the new item; it is
     * left empty for anything else.
     */
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


    //
    // Processing methods
    //

    // Receives messages from the emulator thread (see windowDidOpen()) and
    // marshals them onto the GUI thread.
    void process(const vc64::Message &msg, const string &attachment = "");
    void update();

private:

    // Processes incoming RPC messages
    void rpcReceive(const char *payload);
    void rpcSend(const char *payload);

    // Loads a specific snapshot from this VM's own SVM. Invoked in response
    // to a "loadSnapshot" RPC request from the Hub, sent when the user opens
    // a snapshot of a machine that's already running (see
    // HubController::open()).
    void loadSnapshot(const utl::UUID &uuid);


    //
    // Recently inserted disks (shared by both drives)
    //

    Q_PROPERTY(QStringList recentDisks READ recentDisks NOTIFY recentDisksChanged)

    QStringList recentDisks() const { return m_recentDisks; }


    //
    // Recently inserted tapes
    //

    Q_PROPERTY(QStringList recentTapes READ recentTapes NOTIFY recentTapesChanged)

    QStringList recentTapes() const { return m_recentTapes; }


    //
    // Recently attached cartridges
    //

    Q_PROPERTY(QStringList recentCartridges READ recentCartridges NOTIFY recentCartridgesChanged)

    QStringList recentCartridges() const { return m_recentCartridges; }

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
    void driveStateChanged();
    void recentDisksChanged();
    void recentTapesChanged();
    void recentCartridgesChanged();
    void formatChanged();
};
