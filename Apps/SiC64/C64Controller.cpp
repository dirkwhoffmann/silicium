// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "C64Controller.h"
#include "SiC64Renderer.h"
#include "Logger.h"
#include "SleepGuard.h"
#include "Images/ImageError.h"
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QCursor>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QTimer>
#include <QUrl>

using namespace vc64;
using retro::vault::ImageError;
using retro::vault::SnapshotInfo;
using retro::vault::Platform;

// Receives messages from the emulator thread (registered as the launch()
// listener in windowDidOpen()) and marshals them onto the GUI thread, where
// it is safe to touch QObjects.
static void
process(const void *listener, const Message msg)
{
    auto *con = static_cast<C64Controller *>(const_cast<void *>(listener));

    // Process message on the GUI thread
    QMetaObject::invokeMethod(con, [con, msg, att = std::string(msg.str ? msg.str : "")] {
        con->process(msg, att);
    }, Qt::QueuedConnection);
}

C64Controller::C64Controller()
{
    LogTask task("Creating C64Controller...");

    // Keep the mouseCaptured/keyboardCaptured properties in sync with the
    // input manager, which owns the actual capture state.
    connect(&inputManager, &InputManager::captureMouseChanged,    this, &C64Controller::captureChanged);
    connect(&inputManager, &InputManager::captureKeyboardChanged, this, &C64Controller::captureChanged);

    m_configController    = make_unique<SiC64ConfigController>(this);
    m_infoController      = make_unique<SiC64InfoController>(this);
    m_activityController  = make_unique<SiC64ActivityController>(this);
    m_statusbarController = make_unique<SiC64StatusbarController>(this);
    m_keyboardController  = make_unique<SiC64KeyboardController>(this);
    m_eventController     = make_unique<SiC64EventController>(this);
    m_ciaController       = make_unique<SiC64CIAController>(this);
    m_busController       = make_unique<SiC64BusController>(this);
    m_cpuController       = make_unique<SiC64CPUController>(this);
    m_memoryController    = make_unique<SiC64MemoryController>(this);
    m_vicController       = make_unique<SiC64VICController>(this);
    m_sidController       = make_unique<SiC64SIDController>(this);
}

void
C64Controller::setFormat(int value)
{
    if (m_format != value) {

        m_format = value;
        emit formatChanged();

        // The disassembler reads its number format straight from the
        // DASM_NUMBERS config option, whose values (0 = hex, 1 = hex padded,
        // 2 = decimal, 3 = decimal padded) line up with m_format.
        m_configController->setDasmNumbers(value);

        // Reformat any inspector panels that are currently showing
        m_eventController->refresh();
        m_ciaController->refresh();
        m_cpuController->refresh();
        m_memoryController->refresh();
        m_vicController->refresh();
        m_sidController->refresh();
    }
}

C64Controller &
C64Controller::instance()
{
    static C64Controller controller;
    return controller;
}

VirtualC64 &
C64Controller::core()
{
    static VirtualC64 core;
    return core;
}

void
C64Controller::initialize()
{
    core().launch();
}

bool
C64Controller::getReadOnly() const
{
    return svm ? svm->isReadOnly() : false;
}

QString
C64Controller::getUUID() const
{
    return svm ? QString::fromStdString(svm->getManifest().uuid.toString()) : "";
}

QString
C64Controller::getName() const
{
    return svm ? QString::fromStdString(svm->getManifest().name) : "";
}

bool
C64Controller::parseArguments(const QCoreApplication &app)
{
    /* SiC64 [options] [svm]
     *
     * Positional arguments:
     *   svm                SVM file to load.
     *
     * Options:
     *   -e, --exec <cmd>   Execute a command after startup. This option may be
     *                      specified multiple times and commands are executed
     *                      in the order they appear on the command line.
     */

    QCommandLineOption execOption(
            QStringList() << "e" << "exec",
            "Executes a command after startup. May be given multiple times.",
            "command");

    QCommandLineParser parser;
    parser.setApplicationDescription("SiC64 - Commodore 64 emulator");
    parser.addHelpOption();
    parser.addPositionalArgument("svm", "The SVM file to load.");
    parser.addOption(execOption);

    parser.process(app);

    const QStringList positionalArgs = parser.positionalArguments();
    const QString svmPath = positionalArgs.isEmpty() ? QString() : positionalArgs.first();

    execCommands.clear();
    for (const QString &command : parser.values(execOption)) {
        printf("Argument: %s\n", command.toStdString().c_str());
        execCommands.push_back(command.toStdString());
    }

    printf("SVM: %s\n", svmPath.toStdString().c_str());

    if (svmPath.isEmpty()) {
        errorMessage = "No SVM file specified";
        qCWarning(siLog).noquote() << errorMessage;
        return false;
    }

    try {

        svm = make_unique<SVMFile>(svmPath.toStdString());
        return true;

    } catch (std::exception &e) {

        errorMessage = QString::fromUtf8(e.what());
        qCWarning(siLog).noquote() << "Failed to open SVM file:" << errorMessage;
        return false;
    }
}

void
C64Controller::start()
{
    qCDebug(siLog) << "Starting C64Controller...";
}

void
C64Controller::stop()
{
    qCDebug(siLog) << "Stopping C64Controller...";
}

void
C64Controller::setState(VMState state)
{
    if (m_state != state) {

        m_state = state;
        emit stateChanged();
    }
}

bool
C64Controller::mouseCaptured()
{
    return inputManager.getCaptureMouse();
}

bool
C64Controller::keyboardCaptured()
{
    return inputManager.getCaptureKeyboard();
}

void
C64Controller::captureMouse()
{
    inputManager.setCaptureMouse(true);
    emit mouseWasCaptured();
}

void
C64Controller::releaseMouse()
{
    inputManager.setCaptureMouse(false);
}

void
C64Controller::attachWindow(QQuickWindow *window)
{
    m_window = window;
    inputManager.setCaptureWindow(window);
    if (!m_window) return;

    if (m_window->isSceneGraphInitialized()) {
        qCDebug(siLog) << "windowDidOpen() (scene graph already initialized)";
        windowDidOpen();

    } else {
        connect(m_window, &QQuickWindow::sceneGraphInitialized, this, [this]() {
            qCDebug(siLog) << "windowDidOpen()";
            windowDidOpen();
        });
    }

    connect(m_window, &QObject::destroyed, this, [this]() {
        qCDebug(siLog) << "windowDidClose()";
        windowDidClose();
    });

    connect(m_window, &QQuickWindow::activeChanged, this, [this]() {
        updateKeyboardCapture();
    });

    updateKeyboardCapture();
}

void
C64Controller::updateKeyboardCapture()
{
    /* Decides who owns the keyboard: the virtual machine, or the app.
     *
     * The window has to be active, so keystrokes never reach the machine from
     * behind another window. And nothing in the app may be taking text --
     * RetroShell is a console, and while it is up the keys are its own. The
     * emulator does not merely stop consuming them then, it stops receiving
     * them (see InputManager::keyDownEventFilter), because otherwise a typed
     * command would land in both places at once.
     *
     * Derived here from the two states rather than tracked as its own flag, so
     * it cannot fall out of step with either.
     */
    inputManager.setCaptureKeyboard(m_window && m_window->isActive() && !m_retroShell);
}

void
C64Controller::setRetroShell(bool value)
{
    if (m_retroShell != value) {

        m_retroShell = value;
        updateKeyboardCapture();
        emit retroShellChanged();
    }
}

void
C64Controller::setPort0(int value)
{
    if (m_port0 != value) {

        m_port0 = value;
        emit port0Changed();
    }
}

void
C64Controller::setPort1(int value)
{
    if (m_port1 != value) {

        m_port1 = value;
        emit port1Changed();
    }
}

void
C64Controller::setDebugPanel(bool value)
{
    if (m_debugPanel != value) {

        m_debugPanel = value;
        emit debugPanelChanged();
    }
}

void
C64Controller::setDx(float value)
{
    if (m_dx != value) {

        m_dx = value;
        emit dxChanged();
    }
}

void
C64Controller::setDy(float value)
{
    if (m_dy != value) {

        m_dy = value;
        emit dyChanged();
    }
}

void
C64Controller::setMbLeft(bool value)
{
    if (m_mb_left != value) {
        m_mb_left = value;
        emit mbLeftChanged();
    }
}

void
C64Controller::setMbMiddle(bool value)
{
    if (m_mb_middle != value) {
        m_mb_middle = value;
        emit mbMiddleChanged();
    }
}

void
C64Controller::setMbRight(bool value)
{
    if (m_mb_right != value) {
        m_mb_right = value;
        emit mbRightChanged();
    }
}

void
C64Controller::setJoyUp(bool value)
{
    if (m_joy_up != value) {
        m_joy_up = value;
        emit joyUpChanged();
    }
}

void
C64Controller::setJoyDown(bool value)
{
    if (m_joy_down != value) {
        m_joy_down = value;
        emit joyDownChanged();
    }
}

void
C64Controller::setJoyLeft(bool value)
{
    if (m_joy_left != value) {
        m_joy_left = value;
        emit joyLeftChanged();
    }
}

void
C64Controller::setJoyRight(bool value)
{
    if (m_joy_right != value) {
        m_joy_right = value;
        emit joyRightChanged();
    }
}

void
C64Controller::setJoyFire(bool value)
{
    if (m_joy_fire != value) {
        m_joy_fire = value;
        emit joyFireChanged();
    }
}

void
C64Controller::warpToCenter()
{
    if (m_window) {

        // Calculate the center of the window in local coordinates
        QPoint localCenter(m_window->width() / 2, m_window->height() / 2);

        // Map local center to global screen coordinates
        QPoint globalCenter = m_window->mapToGlobal(localCenter);

        // Warp the cursor back to the center
        QCursor::setPos(globalCenter);
    }
}

QString
C64Controller::getRetroShellText()
{
    auto *text = core().retroShell.text();
    return QString::fromUtf8(text);
}

int
C64Controller::getCursorPos()
{
    const auto &info = core().retroShell.getInfo();
    return (int)info.cursorRel;
}

void
C64Controller::pressRetroShellKey(int key, int modifiers, const QString &text)
{
    const bool shift = modifiers & Qt::ShiftModifier;
    const bool ctrl  = modifiers & Qt::ControlModifier;

    if (ctrl) {

        switch (key) {

            case Qt::Key_A: core().retroShell.press(RSKey::HOME, shift); return;
            case Qt::Key_E: core().retroShell.press(RSKey::END, shift); return;
            case Qt::Key_K: core().retroShell.press(RSKey::CUT, shift); return;
            default:        break;
        }
    }

    switch (key) {

        case Qt::Key_Up:        core().retroShell.press(RSKey::UP, shift); break;
        case Qt::Key_Down:      core().retroShell.press(RSKey::DOWN, shift); break;
        case Qt::Key_Left:      core().retroShell.press(RSKey::LEFT, shift); break;
        case Qt::Key_Right:     core().retroShell.press(RSKey::RIGHT, shift); break;
        case Qt::Key_PageUp:    core().retroShell.press(RSKey::PAGE_UP, shift); break;
        case Qt::Key_PageDown:  core().retroShell.press(RSKey::PAGE_DOWN, shift); break;
        case Qt::Key_Home:      core().retroShell.press(RSKey::HOME, shift); break;
        case Qt::Key_End:       core().retroShell.press(RSKey::END, shift); break;
        case Qt::Key_Backspace: core().retroShell.press(RSKey::BACKSPACE, shift); break;
        case Qt::Key_Delete:    core().retroShell.press(RSKey::DEL, shift); break;
        case Qt::Key_Return:    core().retroShell.press(RSKey::RETURN, shift); break;
        case Qt::Key_Enter:     core().retroShell.press(RSKey::RETURN, shift); break;
        case Qt::Key_Tab:       core().retroShell.press(RSKey::TAB, shift); break;
        case Qt::Key_Backtab:   core().retroShell.press(RSKey::TAB, true); break;
        case Qt::Key_Escape:    setRetroShell(false); break;

        default:
            if (!text.isEmpty()) {
                char c = text.toUtf8().at(0);
                core().retroShell.press(c);
            }
            break;
    }

    m_retroShellIsDirty = true;
}

void
C64Controller::windowDidOpen()
{
    // Power on the emulator
    core().setListener(this, ::process);
    core().c64.installOpenRoms();

    // A corrupted SVM archive can throw here (e.g. while unpacking it into
    // its temp-space root on first access). This runs inside a Qt signal
    // handler (see attachWindow()), and Qt does not tolerate an exception
    // escaping one, so the failure must be caught here rather than left to
    // propagate.
    try {

        core().c64.loadWorkspace(svm->root() / SVMFile::workspaceDir);

    } catch (const std::exception &e) {

        showError("Failed to load workspace.", e.what());
    }

    core().powerOn();

    for (const auto &command : execCommands) {

        qCDebug(siLog).noquote() << "Executing command: '" << command << "'";
        core().retroShell.execScript(command);
    }

    // Start the renderer
    startRenderer();

    // Setup to receive input events
    inputManager.setDelegate(this);

    // Setup the audio backend
    m_audio.setDelegate(this);
    m_audio.start();
}

void
C64Controller::windowDidClose()
{
    stopRenderer();

    inputManager.removeDelegate(this);

    m_audio.removeDelegate(this);
    m_audio.stop();

    // Halt the emulator thread. The core itself is a static singleton (see
    // core()), so unlike OldC64Controller::windowDidClose() -- which deletes
    // its per-VM core -- we stop it rather than destroy it.
    core().halt();
}

void
C64Controller::setRenderer(SiC64Renderer *ptr)
{
    if (m_renderer != ptr) {

        m_renderer = ptr;
        emit rendererChanged();
    }
}

void
C64Controller::startRenderer()
{
    if (m_renderer) m_renderer->start();
}

void
C64Controller::stopRenderer()
{
    if (m_renderer) m_renderer->stop();
}

bool
C64Controller::detectShakeDxDy(float dx, float dy)
{
    return core().controlPort1.mouse.detectShakeDxDy(dx, dy);
}

void
C64Controller::shakeDetected()
{
    if (preferences().getReleaseMouseByShaking()) {
        inputManager.setCaptureMouse(false);
    }
}

void
C64Controller::keyDown(QKeyEvent *event, KeyModifier modifiers)
{
    if (keyboardCaptured()) {
        m_keyboardController->keyDown(event, modifiers);
    }
}

void
C64Controller::keyUp(QKeyEvent *event, KeyModifier modifiers)
{
    if (keyboardCaptured()) {
        m_keyboardController->keyUp(event, modifiers);
    }
}

void
C64Controller::keyCombo(KeyCombo combo, int count)
{
    if (mouseCaptured()) {
        m_keyboardController->keyCombo(combo, count);
    }
}

void
C64Controller::capsLock(bool state)
{
    switch (preferences().getCapsLockAction()) {

        case 1:
            m_configController->setWarpMode(int(state ? Warp::ALWAYS : Warp::NEVER));
            break;

        default:
            break;
    }
}

void
C64Controller::mouseDxDy(int port, u64 timestamp, float dx, float dy)
{
    auto &cp = port == 0 ? core().controlPort1 : core().controlPort2;

    cp.mouse.setDxDy(dx, dy);
}

void
C64Controller::mouseButton(int port, u64 timestamp, int button, bool down)
{
    auto &cp = port == 0 ? core().controlPort1 : core().controlPort2;
    auto action = button == 0 ? GamePadAction::PRESS_LEFT : GamePadAction::PRESS_RIGHT;

    cp.mouse.trigger(action);
}

void
C64Controller::joystickMotionEvent(int port, u64 timestamp, bool state[5])
{
    auto &cp = port == 0 ? core().controlPort1 : core().controlPort2;

    cp.joystick.trigger(state);
}

void
C64Controller::linkAudioSink(QAudioSink *sink, QAudioFormat &format)
{
    auto sampleRate = format.sampleRate();
    m_configController->setHostSampleRate(sampleRate);

    sink->start([this](QSpan<float> buffer) {

        const int sampleCount = buffer.size() / 2;
        core().audioPort.copyInterleaved(buffer.data(), sampleCount);
    });
}

void
C64Controller::run()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to run.", e.what());
    }
}

void
C64Controller::pause()
{
    core().pause();
}

void
C64Controller::reset()
{
    core().hardReset();
    core().run();
}

void
C64Controller::powerOn()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to power on.", e.what());
    }
}

void
C64Controller::powerOff()
{
    core().powerOff();
}

void
C64Controller::stopAndGo()
{
    if (core().isRunning()) {
        core().pause();
    } else {
        core().run();
    }
}

void
C64Controller::softReset()
{
    core().softReset();
}

void
C64Controller::brk()
{
    core().put(Cmd::CPU_BRK);
}

void
C64Controller::stepOver()
{
    core().stepOver();
}

void
C64Controller::stepInto()
{
    core().stepInto();
}

void
C64Controller::stepCycle()
{
    core().stepCycle();
}

void
C64Controller::finishLine()
{
    core().finishLine();
}

void
C64Controller::finishFrame()
{
    core().finishFrame();
}

void
C64Controller::toggleWarp()
{
    // Ported from the Mac app's warpAction(_:) -- cycles the warp mode
    // AUTO -> NEVER -> ALWAYS -> AUTO.
    switch (Warp(m_configController->warpMode())) {

        case Warp::AUTO:   m_configController->setWarpMode(int(Warp::NEVER));  break;
        case Warp::NEVER:  m_configController->setWarpMode(int(Warp::ALWAYS)); break;
        case Warp::ALWAYS: m_configController->setWarpMode(int(Warp::AUTO));   break;
    }
}

void
C64Controller::hibernate(bool hibernateSnapshot, bool hibernateWorkspace)
{
    try {

        LogTask task("Hibernating...");

        if (hibernateSnapshot) {

            shrinkSnapshotStorage(preferences().getMaxSnapshots() - 1);
            captureSnapshot();
        }
        if (hibernateWorkspace) {

            saveWorkspace();
        }

    } catch (std::exception &e) {

        qCWarning(siLog) << "Failed to hibernate the virtual machine:" << e.what();
    }
}

void
C64Controller::saveWorkspace()
{
    LogTask task("Saving workspace...");

    try {

        const auto folder = svm->root() / SVMFile::workspaceDir;

        // Start from scratch
        fs::remove_all(folder);
        fs::create_directories(folder);

        // Save assets
        core().c64.saveWorkspace(folder);

        /* Refresh the VM's screenshot. This is the only place it is written:
         * it depicts the machine as the workspace left it, so it lives in the
         * workspace folder and is rewritten by the same operation that
         * rewrites the workspace. Taking a snapshot captures a moment the
         * workspace knows nothing about and deliberately leaves it alone.
         *
         * It has to be written after the folder is cleared above, which would
         * otherwise wipe it. The path is stored relative to the workspace
         * folder; that folder lives inside a randomized temp directory
         * recreated every time the SVM is opened, so an absolute path would
         * go stale as soon as this session ends.
         */
        if (m_renderer) {

            if (auto image = m_renderer->grabScreenshot(); !image.isNull()) {

                fs::path screenshot = "screenshot.jpg";

                if (image.save(QString::fromStdString((folder / screenshot).string()))) {
                    svm->getManifest().screenshot = screenshot;
                } else {
                    qCWarning(siLog) << "Failed to save workspace screenshot.";
                }
            }
        }

        svm->persist();
        emit workspaceSaved();
        notifyPersist();
        notifySvmChanged("workspace");

    } catch (const std::exception &e) {

        showError("Failed to save workspace.", e.what());
    }
}

void
C64Controller::saveSnapshot()
{
    auto &m = svm->getManifest();

    if (m.numSnapshots() >= preferences().getMaxSnapshots() && !preferences().getAutoDeleteSnapshots()) {
        emit snapshotLimitReached();
    } else {
        captureSnapshot();
    }
}

void
C64Controller::captureSnapshot()
{
    LogTask task("Saving snapshot...");

    try {

        auto &m = svm->getManifest();

        if (svm->isReadOnly()) throw ImageError(ImageError::VM_READ_ONLY);

        // Take snapshot
        qCDebug(siLog) << "Taking snapshot...";
        auto snap = core().c64.takeSnapshot(Compressor::LZ4);

        // Take screenshot
        qCDebug(siLog) << "Taking screenshot...";
        auto thumbnail = snap->getHeader()->screenshot;
        QImage image((uchar *)thumbnail.screen,
                     (int)thumbnail.width,
                     (int)thumbnail.height,
                     QImage::Format_ARGB32);

        // Assemble snapshot info
        SnapshotInfo info {};
        info.version    = VirtualC64::snapshotVersion();
        info.uuid       = utl::UUID::v4();
        info.platform   = Platform::C64;
        info.created    = thumbnail.timestamp;
        info.modified   = thumbnail.timestamp;
        info.screenshot = fs::path(info.uuid.toString() + ".jpg");
        info.binary     = fs::path(info.uuid.toString() + ".vcsnap");

        /* Bring the snapshot folder into being. Nothing else creates it, and
         * the first snapshot of an SVM is exactly the case where it is not
         * there yet.
         */
        const auto snapshotFolder = svm->root() / SVMFile::snapshotDir;

        std::error_code ec;
        fs::create_directories(snapshotFolder, ec);
        if (ec) throw utl::IOError(utl::IOError::DIR_CANT_CREATE, snapshotFolder);

        auto screenshotPath = snapshotFolder / info.screenshot;
        auto snapshotPath   = snapshotFolder / info.binary;

        // Save assets
        qCDebug(siLog) << "Copying screenshot to working folder...";
        if (!image.save(QString::fromStdString(screenshotPath.string()))) {
            qCWarning(siLog) << "Failed to save screenshot" << screenshotPath;
            return;
        }
        qCDebug(siLog) << "Copying snapshot to working folder...";
        snap->writeToFile(snapshotPath);

        // Add snapshot to the manifest
        qCDebug(siLog) << "Registering snapshot " << info.uuid.toString();
        m.appendSnapshot(info);

        svm->persist();
        notifyPersist();
        emit snapshotSaved(QString::fromStdString(info.uuid.toString()));
        notifySvmChanged("snapshot", QString::fromStdString(info.uuid.toString()));

    } catch (const std::exception &e) {

        showError("Failed to save snapshot.", e.what());
    }
}

void
C64Controller::revertSnapshot()
{
    qCDebug(siLog) << "Reverting to latest snapshot...";

    /* "Latest" deliberately spans both pools: lookupLatestSnapshot() weighs
     * the newest auto snapshot against the newest user one and hands back
     * whichever is more recent. Reverting means going back to the last state
     * that was captured, not the last one the user captured by hand.
     */
    auto *info = svm->getManifest().lookupLatestSnapshot();

    if (!info) {

        showError("Failed to load snapshot.", "This virtual machine has no snapshots yet.");
        return;
    }

    /* Hand off to the path the Hub drives when it asks for one snapshot by
     * name: it resolves the UUID to a file, reports a missing one, and wraps
     * the load itself. Nothing to add here but the choice of snapshot.
     */
    loadSnapshot(info->uuid);
}

void
C64Controller::shrinkSnapshotStorage(int count)
{
    // Drops the oldest entries first (see SnapshotPool::shrink)
    svm->getManifest().snapshots.shrink(count);
}

void
C64Controller::reportState(VMState state)
{
    setState(state);

    // Report the new state to the Hub as a JSON-RPC notification (a request
    // without an "id", so the Hub must not reply). The packet travels
    // through the RPC server's stdio transport, i.e., it is written to
    // stdout where the Hub picks it up. If the RPC server is not up (yet),
    // the packet is dropped silently; the state is re-announced once the
    // server connects (see Msg::SRV_STATE).
    const QJsonObject rpc {
        { "jsonrpc", "2.0" },
        { "method", "vmState" },
        { "params", VMStateEnum::key(state) }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';

    // Never let a reporting hiccup escape: reportState() is called from the
    // middle of the power-on sequence, and an exception thrown here would
    // skip the rest of it (see didPowerOn).
    try {

        core().remoteManager.send(ServerType::RPC, packet.toStdString());

    } catch (std::exception &exc) {

        qCWarning(siLog).noquote() << "Failed to report state:" << exc.what();
    }
}

void
C64Controller::notifySvmChanged(const QString &kind, const QString &uuid)
{
    // An object payload (like notifyFatalError's) rather than a bare string:
    // for a snapshot save the Hub wants to know *which* snapshot appeared, so
    // it can bring it on screen instead of only reloading the manifest.
    QJsonObject params { { "kind", kind } };
    if (!uuid.isEmpty()) params["uuid"] = uuid;

    // Same fire-and-forget JSON-RPC notification pattern as reportState's
    // "vmState" packet (no "id", so the Hub must not reply).
    const QJsonObject rpc {
        { "jsonrpc", "2.0" },
        { "method", "svmChanged" },
        { "params", params }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';

    core().remoteManager.send(ServerType::RPC, packet.toStdString());
}

void
C64Controller::notifyPersist()
{
    /* Ask the Hub to pack the archive.
     *
     * Our own persist() has already written the manifest and the assets into
     * the root folder, but when the Hub launched us that root is a directory
     * it unpacked from a .svm file we know nothing about. Only it can zip the
     * tree back up. It reloads before doing so, because the manifest it holds
     * is now older than the one we just wrote (see Manifest::generation).
     *
     * Sent unconditionally: when SiC64 was started directly on an archive
     * there is no Hub listening and the packet goes nowhere, which is exactly
     * right -- in that case our own persist() already updated the ZIP.
     */
    const QJsonObject rpc {
        { "jsonrpc", "2.0" },
        { "method", "persist" }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';

    core().remoteManager.send(ServerType::RPC, packet.toStdString());
}

void
C64Controller::notifyFatalError(const QString &title, const QString &text)
{
    // Same fire-and-forget notification pattern as the packets above, but
    // with an object payload -- the Hub needs both halves of the message.
    const QJsonObject rpc {
        { "jsonrpc", "2.0" },
        { "method", "fatalError" },
        { "params", QJsonObject { { "title", title }, { "text", text } } }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';

    // Never throw from here: this is the last thing that happens on a path
    // that has already gone wrong, and losing the report is better than
    // replacing it with a second failure.
    try {

        core().remoteManager.send(ServerType::RPC, packet.toStdString());

    } catch (std::exception &exc) {

        qCWarning(siLog).noquote() << "Failed to report fatal error:" << exc.what();
    }
}

void
C64Controller::didPowerOn()
{
    // Announcing the state to the Hub and refreshing the ROM info is
    // bookkeeping. It used to share a try block with the run() call below, so
    // a throw from either of them skipped "release brakes" and left the
    // machine powered on but never started -- which looks exactly like "the
    // emulator doesn't power up", and silently so, because showFatalError has
    // no receiver anywhere in the app.
    try {

        reportState(VMState::PAUSED);
        m_configController->queryRoms();

    } catch (const std::exception &e) {

        qCWarning(siLog).noquote() << "Power-on bookkeeping failed:" << e.what();
    }

    // Release brakes
    try {

        core().run();

    } catch (const std::exception &e) {

        qCCritical(siLog).noquote() << "Failed to power on the virtual machine:" << e.what();
        emit showFatalError("Failed to power on the virtual machine.", e.what());
    }
}

void
C64Controller::didPowerOff()
{
    SleepGuard::allowSleep();
    reportState(VMState::OFF);
}

void
C64Controller::didRun()
{
    if (preferences().getPreventSleepWhileRunning()) SleepGuard::preventSleep();
    reportState(VMState::RUNNING);
}

void
C64Controller::didPause()
{
    SleepGuard::allowSleep();
    reportState(VMState::PAUSED);
}

void
C64Controller::didShutdown()
{
    SleepGuard::allowSleep();
    reportState(VMState::HALTED);
}

void
C64Controller::process(const Message &msg, const string &attachment)
{
    auto value = [&msg]() -> int { return static_cast<int>(msg.value); };

    switch (msg.type) {

        case Msg::CONFIG: {

            m_configIsDirty = true;
            m_infoIsDirty = true;
            break;
        }

        case Msg::POWER: {

            msg.value ? didPowerOn() : didPowerOff();
            m_infoIsDirty = true;
            break;
        }

        case Msg::RUN: {

            didRun();
            m_infoIsDirty = true;
            break;
        }

        case Msg::PAUSE: {

            didPause();
            m_infoIsDirty = true;
            break;
        }

        case Msg::STEP: {

            emit cpuStateChanged();
        }

        case Msg::EOL_TRAP:
        case Msg::EOF_TRAP: {

            break;
        }

        case Msg::RESET: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::SHUTDOWN: {

            didShutdown();
            break;
        }

        case Msg::ABORT: {

            qInfo() << "Aborting with exit code" << value();
            qApp->exit(value());
            break;
        }

        case Msg::WARP: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::TRACK:
        case Msg::MUTE: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::EASTER_EGG: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::RSH_CLOSE:
        case Msg::RSH_UPDATE:
        case Msg::RSH_SWITCH:
        case Msg::RSH_DEBUGGER:
        case Msg::RSH_WAIT:
        case Msg::RSH_ERROR: {

            m_retroShellIsDirty = true;
            break;
        }

        case Msg::BREAKPOINT_UPDATED:
        case Msg::BREAKPOINT_REACHED:
        case Msg::WATCHPOINT_UPDATED:
        case Msg::WATCHPOINT_REACHED:
        case Msg::CPU_JUMPED: {

            break;
        }

        case Msg::CPU_JAMMED: {

            // The jammed state is now polled from CPUInfo::jammed; just
            // trigger a refresh so the statusbar picks it up promptly.
            m_infoIsDirty = true;
            break;
        }

        case Msg::PAL:
        case Msg::NTSC: {

            break;
        }

        case Msg::SER_BUSY:
        case Msg::SER_IDLE: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::MON_SETTING: {

            // Monitor options bypass Msg::CONFIG, so flag them here to keep
            // the config controller's properties (and the renderer's texture
            // cutout) in sync.
            m_configIsDirty = true;
            break;
        }

        case Msg::DRIVE_CONNECT:
        case Msg::DRIVE_POWER:
        case Msg::DRIVE_POWER_SAVE:
        case Msg::DRIVE_READ:
        case Msg::DRIVE_WRITE:
        case Msg::DRIVE_LED:
        case Msg::DRIVE_MOTOR:
        case Msg::DRIVE_STEP:
        case Msg::DISK_INSERT:
        case Msg::DISK_EJECT:
        case Msg::DISK_PROTECTED:
        case Msg::DISK_MODIFIED:
        case Msg::FILE_FLASHED: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::VC1530_CONNECT:
        case Msg::VC1530_TAPE:
        case Msg::VC1530_PLAY:
        case Msg::VC1530_MOTOR:
        case Msg::VC1530_COUNTER: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::CRT_ATTACHED: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::KB_PRESS: {

            m_keyboardController->kbChanged(value(), true);
            break;
        }

        case Msg::KB_RELEASE: {

            m_keyboardController->kbChanged(value(), false);
            break;
        }

        case Msg::KB_LOCK:
        case Msg::KB_UNLOCK: {

            m_infoIsDirty = true;
            break;
        }

        case Msg::SHAKING: {

            break;
        }

        case Msg::SNAPSHOT_TAKEN:
        case Msg::SNAPSHOT_RESTORED: {

            break;
        }

        case Msg::WORKSPACE_LOADED:
        case Msg::WORKSPACE_SAVED: {

            break;
        }

        case Msg::DMA_DEBUG: {

            break;
        }

        case Msg::ALARM:
        case Msg::RS232:
        case Msg::RS232_IN:
        case Msg::RS232_OUT: {

            break;
        }

        case Msg::SRV_STATE: {

            // Refresh the statusbar's server indicator on any state change.
            m_infoIsDirty = true;

            // Re-announce the current state once a client connects. State
            // changes that occurred before the RPC server came up (e.g.,
            // the initial power-on sequence) were dropped, so the Hub
            // would be out of sync otherwise.
            if (SrvState(msg.value) == SrvState::CONNECTED) reportState(getState());
            break;
        }

        case Msg::SRV_RECEIVE: {

            rpcReceive(msg.str);
            break;
        }

        case Msg::SRV_SEND: {

            rpcSend(msg.str);
            break;
        }

        default: {

            break;
        }
    }
}

void
C64Controller::rpcReceive(const char *payload)
{
    if (!payload) return;

    // Surface all received RPC traffic in the logger window as debug output.
    qCDebug(siLog).noquote() << "RPC recv:" << payload;

    const auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(payload));
    if (!doc.isObject()) return;

    const QJsonObject rpc = doc.object();
    const QString method = rpc["method"].toString();

    if (method == "prefsChanged") {

        // Re-read the changed settings group from the shared file.
        preferences().reloadGroup(rpc["params"].toString());

    } else if (method == "raise") {

        // The Hub found this instance already running and wants its window
        // brought to the front instead of launching a second one.
        if (m_window) {
            m_window->raise();
            m_window->requestActivate();
        }

    } else if (method == "loadSnapshot") {

        loadSnapshot(utl::UUID::fromString(rpc["params"].toString().toStdString()));

    } else if (method == "svmChanged") {

        /* The Hub rewrote our SVM file (see HubController::notifySvmChanged).
         * Only the manifest is re-read: what the Hub changes is bookkeeping,
         * and a full reload() would clear and refill the working folder this
         * machine is running from. Files the manifest no longer mentions are
         * swept by the next persist().
         */
        try {

            svm->readManifest();
            qCDebug(siLog) << "Reloaded manifest:" << svm->getManifest().numSnapshots() << "snapshot(s)";

        } catch (const std::exception &e) {

            qCWarning(siLog).noquote() << "Failed to re-read the SVM manifest:" << e.what();
        }
    }
}

void
C64Controller::rpcSend(const char *payload)
{
    if (!payload) return;

    // Surface all sent RPC traffic in the logger window as debug output.
    qCDebug(siLog).noquote() << "RPC: Sent" << payload;
}

void
C64Controller::loadSnapshot(const utl::UUID &uuid)
{
    auto *info = svm->getManifest().lookupSnapshot(uuid);

    if (!info) {

        showError("Failed to load snapshot.", "The requested snapshot could not be found.");
        return;
    }

    try {

        auto path = svm->root() / SVMFile::snapshotDir / info->binary;
        core().c64.loadSnapshot(path);

    } catch (const std::exception &e) {

        showError("Failed to load snapshot.", e.what());
    }
}

void
C64Controller::update()
{
    if (m_retroShellIsDirty) {

        emit retroShellTextChanged();
        m_retroShellIsDirty = false;
    }

    if (m_configIsDirty) {

        emit m_configController->configChanged();
        m_configIsDirty = false;
    }

    if (m_infoIsDirty) {

        m_infoController->refresh();
        m_infoIsDirty = false;
        emit driveStateChanged();
    }
}

void
C64Controller::insertDisk(int drive, const QUrl &url, bool wp)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());

        if (drive == 8) core().drive8.insert(path, wp);
        if (drive == 9) core().drive9.insert(path, wp);

        noteRecentlyInsertedDisk(url);

    } catch (const std::exception &e) {

        showError("Failed to insert disk.", e.what());
    }
}

void
C64Controller::flash(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        core().c64.flash(path);
        core().keyboard.autoType("run\n");

    } catch (const std::exception &e) {

        showError("Failed to flash file.", e.what());
    }
}

void
C64Controller::noteRecentlyInsertedDisk(const QUrl &url)
{
    static constexpr int maxRecentDisks = 10;

    auto str = url.toString();
    if (m_recentDisks.contains(str)) return;

    if (m_recentDisks.size() >= maxRecentDisks) m_recentDisks.removeLast();
    m_recentDisks.prepend(str);

    emit recentDisksChanged();
}

void
C64Controller::newDisk(int drive, int fsFormat, const QString &name)
{
    try {

        auto fmt = FSFormat(fsFormat);
        auto n = name.toStdString();

        if (drive == 8) core().drive8.insertBlankDisk(fmt, n);
        if (drive == 9) core().drive9.insertBlankDisk(fmt, n);

    } catch (const std::exception &e) {

        showError("Failed to create disk.", e.what());
    }
}

bool
C64Controller::hasModifiedDisk(int drive) const
{
    return drive == 8 ?
        core().drive8.getInfo().hasModifiedDisk :
        core().drive9.getInfo().hasModifiedDisk;
}

void
C64Controller::exportDisk(int drive, const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        int slot = drive == 8 ? 0 : 1;

        if (drive == 8) core().drive8.save(path);
        if (drive == 9) core().drive9.save(path);

        core().put(Cmd::DSK_UNMODIFIED, slot);

    } catch (const std::exception &e) {

        showError("Failed to export disk.", e.what());
    }
}

void
C64Controller::exportDiskFolder(int drive, const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        int slot = drive == 8 ? 0 : 1;

        if (drive == 8) core().drive8.saveFiles(path);
        if (drive == 9) core().drive9.saveFiles(path);

        core().put(Cmd::DSK_UNMODIFIED, slot);

    } catch (const std::exception &e) {

        showError("Failed to export disk.", e.what());
    }
}

void
C64Controller::ejectDisk(int drive)
{
    try {

        if (drive == 8) core().drive8.ejectDisk();
        if (drive == 9) core().drive9.ejectDisk();

    } catch (const std::exception &e) {

        showError("Failed to eject disk.", e.what());
    }
}

void
C64Controller::toggleWriteProtection(int drive)
{
    int slot = drive == 8 ? 0 : 1;
    core().put(Cmd::DSK_TOGGLE_WP, slot);
}

void
C64Controller::toggleUnsavedState(int drive)
{
    // Unlike DSK_TOGGLE_WP, the core has no single "toggle" command for the
    // modification flag -- DSK_MODIFIED and DSK_UNMODIFIED set it explicitly
    // in either direction -- so the toggle happens here, from the current
    // state.
    int slot = drive == 8 ? 0 : 1;
    bool modified = drive == 8 ? drive8Modified() : drive9Modified();
    core().put(modified ? Cmd::DSK_UNMODIFIED : Cmd::DSK_MODIFIED, slot);
}

void
C64Controller::toggleDrivePower(int drive)
{
    if (drive == 8) {
        m_configController->setDrive8PowerSwitch(!m_configController->drive8PowerSwitch());
    } else {
        m_configController->setDrive9PowerSwitch(!m_configController->drive9PowerSwitch());
    }
}

void
C64Controller::insertTape(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        core().datasette.insertTape(path);

        noteRecentlyInsertedTape(url);

    } catch (const std::exception &e) {

        showError("Failed to insert tape.", e.what());
    }
}

void
C64Controller::noteRecentlyInsertedTape(const QUrl &url)
{
    static constexpr int maxRecentTapes = 10;

    auto str = url.toString();
    if (m_recentTapes.contains(str)) return;

    if (m_recentTapes.size() >= maxRecentTapes) m_recentTapes.removeLast();
    m_recentTapes.prepend(str);

    emit recentTapesChanged();
}

void
C64Controller::ejectTape()
{
    try {

        core().datasette.ejectTape();

    } catch (const std::exception &e) {

        showError("Failed to eject tape.", e.what());
    }
}

void
C64Controller::exportTape(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        core().datasette.exportTape(path);

    } catch (const std::exception &e) {

        showError("Failed to export tape.", e.what());
    }
}

void
C64Controller::rewindTape()
{
    core().put(Cmd::DATASETTE_REWIND);
}

void
C64Controller::playOrStopTape()
{
    core().put(core().datasette.getInfo().playKey ? Cmd::DATASETTE_STOP : Cmd::DATASETTE_PLAY);
}

void
C64Controller::attachCartridge(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        core().expansionPort.attachCartridge(path);

        noteRecentlyAttachedCartridge(url);

    } catch (const std::exception &e) {

        showError("Failed to attach cartridge.", e.what());
    }
}

void
C64Controller::noteRecentlyAttachedCartridge(const QUrl &url)
{
    static constexpr int maxRecentCartridges = 10;

    auto str = url.toString();
    if (m_recentCartridges.contains(str)) return;

    if (m_recentCartridges.size() >= maxRecentCartridges) m_recentCartridges.removeLast();
    m_recentCartridges.prepend(str);

    emit recentCartridgesChanged();
}

void
C64Controller::detachCartridge()
{
    core().expansionPort.detachCartridge();
    core().hardReset();
}

void
C64Controller::attachReu(int capacity)
{
    try {

        core().expansionPort.attachReu(capacity);

    } catch (const std::exception &e) {

        showError("Failed to attach REU.", e.what());
    }
}

void
C64Controller::attachGeoRam(int capacity)
{
    try {

        core().expansionPort.attachGeoRam(capacity);

    } catch (const std::exception &e) {

        showError("Failed to attach GeoRAM.", e.what());
    }
}

void
C64Controller::attachIsepic()
{
    core().expansionPort.attachIsepicCartridge();
}

void
C64Controller::exportCartridge(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        core().expansionPort.exportCRT(path);

    } catch (const std::exception &e) {

        showError("Failed to export cartridge.", e.what());
    }
}

void
C64Controller::pressCartridgeButton(int nr)
{
    core().put(Cmd::CRT_BUTTON_PRESS, nr);

    QTimer::singleShot(500, this, [this, nr]() {
        core().put(Cmd::CRT_BUTTON_RELEASE, nr);
    });
}

void
C64Controller::setCartridgeSwitch(int pos)
{
    if (pos < 0) core().put(Cmd::CRT_SWITCH_LEFT);
    else if (pos > 0) core().put(Cmd::CRT_SWITCH_RIGHT);
    else core().put(Cmd::CRT_SWITCH_NEUTRAL);

    // No message is emitted for switch changes (unlike CRT_ATTACHED), so
    // the menu's checkmark needs an explicit nudge to refresh.
    emit driveStateChanged();
}

void
C64Controller::insertRecentDisk(int drive, int index)
{
    if (index < 0 || index >= m_recentDisks.size()) return;

    insertDisk(drive, QUrl(m_recentDisks.at(index)));
}

void
C64Controller::clearRecentlyInsertedDisks()
{
    m_recentDisks.clear();
    emit recentDisksChanged();
}

void
C64Controller::insertRecentTape(int index)
{
    if (index < 0 || index >= m_recentTapes.size()) return;

    insertTape(QUrl(m_recentTapes.at(index)));
}

void
C64Controller::clearRecentlyInsertedTapes()
{
    m_recentTapes.clear();
    emit recentTapesChanged();
}

void
C64Controller::attachRecentCartridge(int index)
{
    if (index < 0 || index >= m_recentCartridges.size()) return;

    attachCartridge(QUrl(m_recentCartridges.at(index)));
}

void
C64Controller::clearRecentlyAttachedCartridges()
{
    m_recentCartridges.clear();
    emit recentCartridgesChanged();
}