// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmController.h"
#include "SiAmRenderer.h"
#include "Logger.h"
#include "Preferences.h"
#include "SleepGuard.h"
#include "Images/ImageError.h"
#include "Roms/RomManager.h"
#include "utl/abilities/Hashable.h"
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QCursor>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QStandardPaths>

using namespace vamiga;
using retro::vault::ImageError;
using retro::vault::SnapshotInfo;
using retro::vault::Platform;

// Receives messages from the emulator thread and marshals them onto the GUI thread
static void
process(const void *listener, const Message msg)
{
    /* Nothing to marshal onto once the application is gone.
     *
     * main() detaches the core on aboutToQuit, so this should not be
     * reached -- but the cost of being wrong is a crash report on the
     * user's screen, and the check is one comparison on a path that is
     * already crossing a thread boundary. QMetaObject::invokeMethod()
     * reads the receiver's thread data, which does not survive
     * ~QCoreApplication.
     */
    if (!QCoreApplication::instance()) return;

    auto *con = static_cast<SiAmController *>(const_cast<void *>(listener));

    QMetaObject::invokeMethod(con, [con, msg, att = std::string(msg.str ? msg.str : "")] {
        con->process(msg, att);
    }, Qt::QueuedConnection);
}

SiAmController::SiAmController()
{
    LogTask task("Creating SiAmController...");

    // Keep the mouseCaptured/keyboardCaptured properties in sync with the
    // input manager, which owns the actual capture state.
    connect(&inputManager, &InputManager::captureMouseChanged,    this, &SiAmController::captureChanged);
    connect(&inputManager, &InputManager::captureKeyboardChanged, this, &SiAmController::captureChanged);

    // Connect control port 0 to the mouse (device 1, see
    // InputManager::updateDevices()), the usual setup on an Amiga
    inputManager.setPort0(1);

    m_activityController = make_unique<SiAmActivityController>(this);
    m_configController = make_unique<SiAmConfigController>(this);
    m_keyboardController = make_unique<SiAmKeyboardController>(this);
    m_inspectorController = make_unique<SiAmInspectorController>(this);
    m_infoController = make_unique<SiAmInfoController>(this);
    m_ciaController = make_unique<SiAmCIAController>(this);
    m_eventController = make_unique<SiAmEventController>(this);
    m_memoryController = make_unique<SiAmMemoryController>(this);
    m_copperController = make_unique<SiAmCopperController>(this);
    m_blitterController = make_unique<SiAmBlitterController>(this);
    m_agnusController = make_unique<SiAmAgnusController>(this);
    m_paulaController = make_unique<SiAmPaulaController>(this);
    m_logicAnalyzerController = make_unique<SiAmLogicAnalyzerController>(this);
    m_layersController = make_unique<SiAmLayersController>(this);
    m_cpuController = make_unique<SiAmCPUController>(this);
    m_deniseController = make_unique<SiAmDeniseController>(this);
    m_portController = make_unique<SiAmPortController>(this);
    m_mediaController = make_unique<SiAmMediaController>(this);

    /* The window is handed this controller and nothing else, so what the
     * ones above report -- a disk that will not insert, a ROM that will not
     * load -- would otherwise have no listener. Every one of them is a child
     * of ours, so adopting them all keeps a new one from being forgotten.
     */
    for (auto *child : findChildren<Controller *>(Qt::FindDirectChildrenOnly)) {
        adopt(child);
    }
}

SiAmController &
SiAmController::instance()
{
    static SiAmController controller;
    return controller;
}

VAmiga &
SiAmController::core()
{
    static VAmiga core;
    return core;
}

void
SiAmController::initialize()
{
    // Point RomManager at the Rom library and scan it once. Nothing but this
    // class and SiAmConfigController::copyToLibrary() ever write here, so
    // there's nothing to watch for and nothing that would need a rescan later.
    auto romDir = romLibraryDir();
    QDir().mkpath(romDir);
    installBundledRomFiles(romDir);

    auto &romManager = retro::vault::RomManager::shared();
    romManager.addFolder(fs::path(romDir.toStdString()));
    romManager.scanFolders();

    // There is no free, redistributable Kickstart ROM, so the stub plugs in
    // the AROS Kickstart replacement instead (open-source, bundled under
    // Shared/Assets/Roms and installed into the Rom library above just like
    // any other bundled Rom -- see installBundledRomFiles()). A real Amiga
    // backend eventually wants a way to install a user-supplied Kickstart
    // here.
    if (auto path = romManager.getRomCRC32(retro::vault::CRC32_AROS_20260820)) {
        core().mem.loadRom(*path);
    } else {
        qCWarning(siLog) << "Failed to locate the bundled AROS Kickstart replacement.";
    }
    if (auto path = romManager.getRomCRC32(retro::vault::CRC32_AROS_20260820_EXT)) {
        core().mem.loadExt(*path);
    } else {
        qCWarning(siLog) << "Failed to locate the bundled AROS Kickstart extension.";
    }

    // Registering the listener and starting the emulator thread happen
    // together on this core's API (unlike VirtualC64, which splits them into
    // launch() and a separate setListener()).
    core().launch(this, ::process);

    /* Ask the emulator thread to snapshot every component as it runs.
     *
     * Without this nothing ever calls Backed::record(), and the cached values
     * SiAmInfoController reads would be frozen at whatever they were the
     * first time somebody asked. vAmiga sets the same mask (Inspector.swift),
     * but only while a debug panel is open; here the status bar wants this
     * information continuously, so it stays on. The cost is one snapshot pass
     * per inspection interval, off the GUI thread.
     */
    core().amiga.setAutoInspectionMask(u64(-1));
}

QString
SiAmController::romLibraryDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/roms/amiga";
}

void
SiAmController::installBundledRomFiles(const QString &dir)
{
    for (const auto &info : QDir(":/Roms").entryInfoList(QDir::Files)) {

        auto dest = QDir(dir).filePath(info.fileName());

        QFile::remove(dest);
        QFile::copy(info.filePath(), dest);
    }
}

fs::path
SiAmController::workspaceFolder() const
{
    if (!svm) throw utl::IOError(utl::IOError::DIR_NOT_FOUND, "workspace");
    return svm->root() / SVMFile::workspaceDir;
}

bool
SiAmController::parseArguments(const QCoreApplication &app)
{
    QCommandLineOption execOption(
            QStringList() << "e" << "exec",
            "Executes a command after startup. May be given multiple times.",
            "command");

    QCommandLineParser parser;
    parser.setApplicationDescription("SiAmiga - Amiga emulator");
    parser.addHelpOption();
    parser.addPositionalArgument("svm", "The SVM file to load.");
    parser.addOption(execOption);

    parser.process(app);

    const QStringList positionalArgs = parser.positionalArguments();
    const QString svmPath = positionalArgs.isEmpty() ? QString() : positionalArgs.first();

    execCommands.clear();
    for (const QString &command : parser.values(execOption)) {
        execCommands.push_back(command.toStdString());
    }

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
SiAmController::start()
{
    qCDebug(siLog) << "Starting SiAmController...";
}

void
SiAmController::stop()
{
    qCDebug(siLog) << "Stopping SiAmController...";
}

void
SiAmController::setState(VMState state)
{
    if (m_state != state) {

        m_state = state;
        emit stateChanged();
    }
}

void
SiAmController::setDebugPanel(bool value)
{
    if (m_debugPanel != value) {

        m_debugPanel = value;
        emit debugPanelChanged();
    }
}

void
SiAmController::setRetroShell(bool value)
{
    if (m_retroShell != value) {

        m_retroShell = value;
        updateKeyboardCapture();
        emit retroShellChanged();
    }
}

QString
SiAmController::getRetroShellText()
{
    auto *text = core().retroShell.text();
    return QString::fromUtf8(text);
}

int
SiAmController::getCursorPos()
{
    const auto &info = core().retroShell.getInfo();
    return (int)info.cursorRel;
}

void
SiAmController::pressRetroShellKey(int key, int modifiers, const QString &text)
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
SiAmController::attachWindow(QQuickWindow *window)
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
SiAmController::updateKeyboardCapture()
{
    // Decides who owns the keyboard: the virtual machine, or the app. See
    // C64Controller::updateKeyboardCapture() for the full rationale --
    // derived from window-active/RetroShell state rather than tracked as
    // its own flag, so it cannot fall out of step with either.
    inputManager.setCaptureKeyboard(m_window && m_window->isActive() && !m_retroShell);
}

void
SiAmController::windowDidOpen()
{
    try {
        core().amiga.loadWorkspace(svm->root() / SVMFile::workspaceDir);
    } catch (const std::exception &e) {
        showError("Failed to load workspace.", e.what());
    }

    core().powerOn();

    for (const auto &command : execCommands) {

        qCDebug(siLog).noquote() << "Executing command: '" << command << "'";
        core().retroShell.execScript(command);
    }

    startRenderer();

    // Setup to receive input events
    inputManager.setDelegate(this);

    m_audio.setDelegate(this);
    m_audio.start();
}

void
SiAmController::windowDidClose()
{
    stopRenderer();

    inputManager.removeDelegate(this);

    m_audio.removeDelegate(this);
    m_audio.stop();

    // The core is a static singleton (see core()), so halt it rather than
    // destroy it.
    core().halt();
}

void
SiAmController::setRenderer(SiAmRenderer *ptr)
{
    if (m_renderer != ptr) {

        m_renderer = ptr;
        emit rendererChanged();
    }
}

void
SiAmController::startRenderer()
{
    if (m_renderer) m_renderer->start();
}

void
SiAmController::stopRenderer()
{
    if (m_renderer) m_renderer->stop();
}

void
SiAmController::linkAudioSink(QAudioSink *sink, QAudioFormat &format)
{
    auto sampleRate = format.sampleRate();
    core().set(Opt::HOST_SAMPLE_RATE, sampleRate);

    sink->start([](QSpan<float> buffer) {

        const int sampleCount = buffer.size() / 2;
        core().audioPort.copyInterleaved(buffer.data(), sampleCount);
    });
}

bool
SiAmController::getReadOnly() const
{
    return svm ? svm->isReadOnly() : false;
}

QString
SiAmController::getUUID() const
{
    return svm ? QString::fromStdString(svm->getManifest().uuid.toString()) : "";
}

QString
SiAmController::getName() const
{
    return svm ? QString::fromStdString(svm->getManifest().name) : "";
}

void
SiAmController::hibernate(bool hibernateSnapshot, bool hibernateWorkspace)
{
    /* Both jobs run in the background and report to the status bar, one after
     * the other: the snapshot first, then the workspace. hibernated() is
     * emitted when the last of them is over, however it went.
     */
    auto workspace = [this, hibernateWorkspace] {

        auto finished = [this] { emit hibernated(); };

        if (hibernateWorkspace) startWorkspace(finished); else finished();
    };

    if (hibernateSnapshot) {

        try {
            shrinkSnapshotStorage(preferences().getMaxSnapshots() - 1);
        } catch (std::exception &e) {
            qCWarning(siLog) << "Failed to make room for a snapshot:" << e.what();
        }
        startSnapshot(workspace);

    } else {

        workspace();
    }
}

bool
SiAmController::writeWorkspace(const fs::path &folder, const QImage &screenshot)
{
    /* The folder is not emptied here. Amiga::saveWorkspace() clears it
     * itself, and it is the one that knows which files to spare: a hard
     * drive loaded from one of them writes its changes back into it, so
     * deleting it first would lose the drive.
     */
    std::error_code ec;
    fs::create_directories(folder, ec);

    core().amiga.saveWorkspace(folder);

    if (screenshot.isNull()) return false;

    if (!screenshot.save(QString::fromStdString((folder / "screenshot.jpg").string()))) {

        qCWarning(siLog) << "Failed to save workspace screenshot.";
        return false;
    }
    return true;
}

void
SiAmController::workspaceWritten(bool screenshotSaved)
{
    // The manifest is read by the window, so it is only ever written here,
    // on the window's own thread.
    if (screenshotSaved) svm->getManifest().screenshot = "screenshot.jpg";

    svm->persist();
    emit workspaceSaved();
    notifyPersist();
    notifySvmChanged("workspace");
}

void
SiAmController::saveWorkspaceNow()
{
    LogTask task("Saving workspace...");

    try {

        const auto folder = svm->root() / SVMFile::workspaceDir;
        auto screenshot = m_renderer ? m_renderer->grabScreenshot() : QImage();

        workspaceWritten(writeWorkspace(folder, screenshot));

    } catch (const std::exception &e) {

        showError("Failed to save workspace.", e.what());
    }
}

void
SiAmController::saveWorkspace()
{
    startWorkspace();
}

void
SiAmController::startWorkspace(std::function<void()> always)
{
    const auto folder = svm->root() / SVMFile::workspaceDir;

    /* The screenshot is taken here rather than in the job: it has to show the
     * machine as it is at the moment the workspace is asked for, not as it
     * happens to be once a thread gets round to it.
     */
    auto screenshot = m_renderer ? m_renderer->grabScreenshot() : QImage();
    auto saved = std::make_shared<std::atomic<bool>>(false);

    bool started = runTask(

            [this, folder, screenshot, saved] {

                report(tr("Saving workspace..."));
                *saved = writeWorkspace(folder, screenshot);
            },
            [this, saved] { workspaceWritten(*saved); },
            always);

    if (!started && always) always();
}

void
SiAmController::saveSnapshot()
{
    auto &m = svm->getManifest();

    if (m.numSnapshots() >= preferences().getMaxSnapshots() && !preferences().getAutoDeleteSnapshots()) {
        emit snapshotLimitReached();
    } else {
        startSnapshot();
    }
}

void
SiAmController::startSnapshot(std::function<void()> always)
{
    try {

        if (svm->isReadOnly()) throw ImageError(ImageError::VM_READ_ONLY);

        /* Taking the snapshot and the screenshot is quick and touches the
         * machine, so it happens here. Writing them out is the slow part and
         * happens in the job, which is why the screenshot is copied: it must
         * not point into the snapshot.
         */
        qCDebug(siLog) << "Taking snapshot...";
        std::shared_ptr snap = core().amiga.takeSnapshot(Compressor::LZ4);

        qCDebug(siLog) << "Taking screenshot...";
        auto thumbnail = snap->getHeader()->screenshot;
        QImage image = QImage((uchar *)thumbnail.screen,
                              (int)thumbnail.width,
                              (int)thumbnail.height,
                              QImage::Format_ARGB32).copy();

        // Assemble snapshot info
        SnapshotInfo info {};
        info.version    = VAmiga::snapshotVersion();
        info.uuid       = utl::UUID::v4();
        info.platform   = Platform::AMIGA;
        info.created    = thumbnail.timestamp;
        info.modified   = thumbnail.timestamp;
        info.screenshot = fs::path(info.uuid.toString() + ".jpg");
        info.binary     = fs::path(info.uuid.toString() + ".vasnap");

        const auto snapshotFolder = svm->root() / SVMFile::snapshotDir;
        const auto screenshotPath = snapshotFolder / info.screenshot;
        const auto snapshotPath   = snapshotFolder / info.binary;

        bool started = runTask(

            [this, snap, image, snapshotFolder, screenshotPath, snapshotPath] {

                report(tr("Saving snapshot..."));

                /* Bring the snapshot folder into being. Nothing else creates
                 * it, and the first snapshot of an SVM is exactly the case
                 * where it is not there yet.
                 */
                std::error_code ec;
                fs::create_directories(snapshotFolder, ec);
                if (ec) throw utl::IOError(utl::IOError::DIR_CANT_CREATE, snapshotFolder);

                if (!image.save(QString::fromStdString(screenshotPath.string())))
                    throw utl::IOError(utl::IOError::FILE_CANT_WRITE, screenshotPath);

                snap->writeToFile(snapshotPath);
            },
            [this, info] {

                // The manifest belongs to this thread
                qCDebug(siLog) << "Registering snapshot " << info.uuid.toString();
                svm->getManifest().appendSnapshot(info);

                svm->persist();
                notifyPersist();
                emit snapshotSaved(QString::fromStdString(info.uuid.toString()));
                notifySvmChanged("snapshot", QString::fromStdString(info.uuid.toString()));
            },
            always);

        if (!started && always) always();

    } catch (const std::exception &e) {

        showError("Failed to save snapshot.", e.what());
        if (always) always();
    }
}

void
SiAmController::revertSnapshot()
{
    auto *info = svm->getManifest().lookupLatestSnapshot();
    if (!info) {
        showError("Failed to load snapshot.", "This virtual machine has no snapshots yet.");
        return;
    }
    loadSnapshot(info->uuid);
}

void
SiAmController::shrinkSnapshotStorage(int count)
{
    svm->getManifest().snapshots.shrink(count);
}

void
SiAmController::rpcReceive(const string &payload)
{
    if (payload.empty()) return;
    qCDebug(siLog).noquote() << "RPC recv:" << payload;
    const auto doc = QJsonDocument::fromJson(QByteArray::fromStdString(payload));
    if (!doc.isObject()) return;
    const QJsonObject rpc = doc.object();
    const QString method = rpc["method"].toString();

    if (method == "prefsChanged") {
        preferences().reloadGroup(rpc["params"].toString());
    } else if (method == "raise") {
        if (m_window) { m_window->raise(); m_window->requestActivate(); }
    } else if (method == "loadSnapshot") {
        loadSnapshot(utl::UUID::fromString(rpc["params"].toString().toStdString()));
    } else if (method == "svmChanged") {
        try {
            svm->readManifest();
            qCDebug(siLog) << "Reloaded manifest:" << svm->getManifest().numSnapshots() << "snapshot(s)";
        } catch (const std::exception &e) {
            qCWarning(siLog).noquote() << "Failed to re-read the SVM manifest:" << e.what();
        }
    }
}

void
SiAmController::rpcSend(const string &payload)
{
    if (payload.empty()) return;
    qCDebug(siLog).noquote() << "RPC: Sent" << payload;
}

void
SiAmController::loadSnapshot(const utl::UUID &uuid)
{
    auto *info = svm->getManifest().lookupSnapshot(uuid);
    if (!info) {
        showError("Failed to load snapshot.", "The requested snapshot could not be found.");
        return;
    }
    try {
        auto path = svm->root() / SVMFile::snapshotDir / info->binary;
        core().amiga.loadSnapshot(path);
    } catch (const std::exception &e) {
        showError("Failed to load snapshot.", e.what());
    }
}

void
SiAmController::reportState(VMState state)
{
    setState(state);
    const QJsonObject rpc {
        { "jsonrpc", "2.0" }, { "method", "vmState" }, { "params", VMStateEnum::key(state) }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';
    try {
        core().remoteManager.send(ServerType::RPC, packet.toStdString());
    } catch (std::exception &exc) {
        qCWarning(siLog).noquote() << "Failed to report state:" << exc.what();
    }
}

void
SiAmController::notifySvmChanged(const QString &kind, const QString &uuid)
{
    QJsonObject params { { "kind", kind } };
    if (!uuid.isEmpty()) params["uuid"] = uuid;
    const QJsonObject rpc { { "jsonrpc", "2.0" }, { "method", "svmChanged" }, { "params", params } };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';
    core().remoteManager.send(ServerType::RPC, packet.toStdString());
}

void
SiAmController::notifyPersist()
{
    const QJsonObject rpc { { "jsonrpc", "2.0" }, { "method", "persist" } };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';
    core().remoteManager.send(ServerType::RPC, packet.toStdString());
}

void
SiAmController::notifyFatalError(const QString &title, const QString &text)
{
    const QJsonObject rpc {
        { "jsonrpc", "2.0" }, { "method", "fatalError" },
        { "params", QJsonObject { { "title", title }, { "text", text } } }
    };
    const QByteArray packet = QJsonDocument(rpc).toJson(QJsonDocument::Compact) + '\n';
    try {
        core().remoteManager.send(ServerType::RPC, packet.toStdString());
    } catch (std::exception &exc) {
        qCWarning(siLog).noquote() << "Failed to report fatal error:" << exc.what();
    }
}

void
SiAmController::run()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to run.", e.what());
    }
}

void
SiAmController::pause()
{
    core().pause();
}

void
SiAmController::reset()
{
    core().hardReset();
    core().run();
}

void
SiAmController::powerOn()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to power on.", e.what());
    }
}

void
SiAmController::powerOff()
{
    core().powerOff();
}

void
SiAmController::softReset()
{
    core().softReset();
}

void
SiAmController::brk()
{
    // vAmiga has no direct equivalent of vc64's Cmd::CPU_BRK (an immediate
    // software breakpoint); pausing is the closest available action.
    pause();
}

void
SiAmController::stepOver()
{
    core().stepOver();
}

void
SiAmController::stepInto()
{
    core().stepInto();
}

void
SiAmController::finishLine()
{
    core().finishLine();
}

void
SiAmController::finishFrame()
{
    core().finishFrame();
}

void
SiAmController::toggleWarp()
{
    // Cycles the warp mode AUTO -> NEVER -> ALWAYS -> AUTO, mirroring
    // C64Controller::toggleWarp().
    switch (Warp(m_configController->warpMode())) {

        case Warp::AUTO:   m_configController->setWarpMode(int(Warp::NEVER));  break;
        case Warp::NEVER:  m_configController->setWarpMode(int(Warp::ALWAYS)); break;
        case Warp::ALWAYS: m_configController->setWarpMode(int(Warp::AUTO));   break;
    }
}

bool
SiAmController::mouseCaptured()
{
    return inputManager.getCaptureMouse();
}

void
SiAmController::captureMouse()
{
    inputManager.setCaptureMouse(true);
}

void
SiAmController::releaseMouse()
{
    inputManager.setCaptureMouse(false);
}

bool
SiAmController::keyboardCaptured()
{
    return inputManager.getCaptureKeyboard();
}

void
SiAmController::keyDown(QKeyEvent *event, KeyModifier modifiers)
{
    if (keyboardCaptured()) {
        m_keyboardController->keyDown(event, modifiers);
    }
}

void
SiAmController::keyUp(QKeyEvent *event, KeyModifier modifiers)
{
    // Always release the key, independent of the capture state. Otherwise,
    // keys can get stuck, e.g., when opening RetroShell with a key held down.

    m_keyboardController->keyUp(event, modifiers);
}

void
SiAmController::keyCombo(KeyCombo combo, int count)
{
    if (keyboardCaptured()) {
        m_keyboardController->keyCombo(combo, count);
    }
}

void
SiAmController::capsLock(bool state)
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
SiAmController::mouseDxDy(int port, u64 timestamp, float dx, float dy)
{
    if (mouseCaptured()) {

        auto &cp = port == 0 ? core().controlPort1 : core().controlPort2;
        cp.mouse.setDxDy(dx, dy);
    }
}

void
SiAmController::mouseButton(int port, u64 timestamp, int button, bool down)
{
    if (mouseCaptured()) {

        auto &cp = port == 0 ? core().controlPort1 : core().controlPort2;

        switch (button) {

            case 0: cp.mouse.trigger(down ? GamePadAction::PRESS_LEFT : GamePadAction::RELEASE_LEFT); break;
            case 1: cp.mouse.trigger(down ? GamePadAction::PRESS_MIDDLE : GamePadAction::RELEASE_MIDDLE); break;
            case 2: cp.mouse.trigger(down ? GamePadAction::PRESS_RIGHT : GamePadAction::RELEASE_RIGHT); break;

            default:
                break;
        }
    }
}

void
SiAmController::joystickMotionEvent(int port, u64 timestamp, bool state[5], bool prev[5])
{
    if (port != 0 && port != 1) return;

    // The state is ordered up, down, left, right, fire. Only changes are
    // forwarded: pressing fire again would toggle autofire, for example.
    auto &joystick = port == 0 ? core().controlPort1.joystick : core().controlPort2.joystick;

    if (state[0] != prev[0] || state[1] != prev[1]) {

        joystick.trigger(state[0] ? GamePadAction::PULL_UP :
                         state[1] ? GamePadAction::PULL_DOWN : GamePadAction::RELEASE_Y);
    }
    if (state[2] != prev[2] || state[3] != prev[3]) {

        joystick.trigger(state[2] ? GamePadAction::PULL_LEFT :
                         state[3] ? GamePadAction::PULL_RIGHT : GamePadAction::RELEASE_X);
    }
    if (state[4] != prev[4]) {

        joystick.trigger(state[4] ? GamePadAction::PRESS_FIRE : GamePadAction::RELEASE_FIRE);
    }
}

bool
SiAmController::detectShakeDxDy(float dx, float dy)
{
    return core().controlPort1.mouse.detectShakeDxDy(dx, dy);
}

void
SiAmController::shakeDetected()
{
    if (preferences().getReleaseMouseByShaking()) {
        inputManager.setCaptureMouse(false);
    }
}

void
SiAmController::warpToCenter()
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

void
SiAmController::resetKeyboardMatrix()
{
    core().put(Cmd::KEY_RELEASE_ALL);
}

void
SiAmController::didPowerOn()
{
    try {
        reportState(VMState::PAUSED);
        m_configController->queryRoms();
    } catch (const std::exception &e) {
        qCWarning(siLog).noquote() << "Power-on bookkeeping failed:" << e.what();
    }
    try {
        core().run();
    } catch (const std::exception &e) {
        qCCritical(siLog).noquote() << "Failed to power on the virtual machine:" << e.what();
        emit showFatalError("Failed to power on the virtual machine.", e.what());
    }
}

void
SiAmController::didPowerOff()
{
    SleepGuard::allowSleep();
    reportState(VMState::OFF);
}

void
SiAmController::didRun()
{
    if (preferences().getPreventSleepWhileRunning()) SleepGuard::preventSleep();
    reportState(VMState::RUNNING);
}

void
SiAmController::didPause()
{
    SleepGuard::allowSleep();
    reportState(VMState::PAUSED);
}

void
SiAmController::didShutdown()
{
    SleepGuard::allowSleep();
    reportState(VMState::HALTED);
}

void
SiAmController::didHdrAttach(i64 nr)
{
    auto &core = SiAmController::core();
    auto &info = core.hd[nr]->getInfo();

    if (info.hasDisk && !info.snapshotable) {

        const auto limit = (int)core.get(Opt::HDR_SNAPSHOT_LIMIT, nr);
        showNotification(tr("Large hard drive"),
        tr("HD%1 is too large to be saved in snapshots because it exceeds "
            "the %2 MB limit. It is kept in the virtual machine folder only.")
            .arg(nr).arg(limit));
    }
}

void
SiAmController::process(const Message &msg, const string &attachment)
{
    switch (msg.type) {

        case Msg::CONFIG:

            m_configIsDirty = true;
            m_infoIsDirty = true;
            break;

        case Msg::POWER:

            msg.value ? didPowerOn() : didPowerOff();
            m_infoIsDirty = true;
            break;

        case Msg::RUN:

            didRun();
            m_infoIsDirty = true;
            break;

        case Msg::PAUSE:

            didPause();
            m_infoIsDirty = true;
            break;

        case Msg::SHUTDOWN:

            didShutdown();
            break;

        case Msg::ABORT:

            qApp->exit((int)msg.value);
            break;

        case Msg::RESET:
        case Msg::WARP:
        case Msg::TRACK:
        case Msg::MUTE:
        case Msg::CPU_HALT:

            m_infoIsDirty = true;
            break;

        case Msg::DRIVE_CONNECT:
        case Msg::DRIVE_SELECT:
        case Msg::DRIVE_READ:
        case Msg::DRIVE_WRITE:
        case Msg::DRIVE_LED:
        case Msg::DRIVE_MOTOR:
        case Msg::DRIVE_STEP:
        case Msg::DISK_INSERT:
        case Msg::DISK_EJECT:
        case Msg::DISK_PROTECTED:
        case Msg::HDC_CONNECT:
        case Msg::HDC_STATE:

            m_infoIsDirty = true;
            break;

        case Msg::HDR_ATTACH:

            didHdrAttach(msg.value);
            m_infoIsDirty = true;
            break;

        case Msg::HDR_DETACH:
        case Msg::HDR_STEP:
        case Msg::HDR_READ:
        case Msg::HDR_WRITE:
        case Msg::HDR_IDLE:

            m_infoIsDirty = true;
            break;

        case Msg::VIEWPORT:

            // Denise's viewport tracker (DeniseDebugger::vsyncHandler())
            // reports the live beam/display window -- feed it to the
            // renderer's MON_CENTER == 1 (Automatic) cutout. Mirrors
            // MyController.swift's own .VIEWPORT case.
            if (m_renderer) {
                m_renderer->updateTextureRect(msg.viewport.hstrt, msg.viewport.vstrt,
                                               msg.viewport.hstop, msg.viewport.vstop);
            }
            break;

        case Msg::KB_PRESS:

            m_keyboardController->kbChanged((int)msg.value, true);
            break;

        case Msg::KB_RELEASE:

            m_keyboardController->kbChanged((int)msg.value, false);
            break;

        case Msg::KB_LOCK:
        case Msg::KB_UNLOCK:

            m_infoIsDirty = true;
            break;

        case Msg::CTRL_AMIGA_AMIGA:

            // Ctrl + both Amiga keys is the Amiga's own reset combo, and the
            // core reports it rather than acting on it. vAmiga's Mac app
            // answers with its reset action; so do we.
            reset();
            break;

        case Msg::RSH_CLOSE:
        case Msg::RSH_UPDATE:
        case Msg::RSH_SWITCH:
        case Msg::RSH_WAIT:
        case Msg::RSH_ERROR:

            m_retroShellIsDirty = true;
            break;

        case Msg::SRV_STATE:

            m_infoIsDirty = true;
            if (SrvState(msg.value) == SrvState::CONNECTED) reportState(getState());
            break;

        case Msg::SRV_RECEIVE:

            /* 'attachment', not msg.str: the message crossed a thread
             * boundary (see ::process above), and msg.str still points into
             * the emulator thread's copy of the packet, which is long gone
             * by the time this runs. The marshalling lambda copied it into
             * 'attachment' for exactly this reason.
             */
            rpcReceive(attachment);
            break;

        case Msg::SRV_SEND:

            rpcSend(attachment);
            break;

        default:

            break;
    }
}

void
SiAmController::update()
{
    // Coalesced per-frame UI updates (config/info/retroShell dirty flags),
    // following the same rhythm as C64Controller::update().
    // Warping is the one piece of state so far that changes on its own
    // (AUTO mode kicks in without any user action), so it's sampled here
    // rather than read straight off the core -- see the warping property.
    bool warping = core().isWarping();
    if (warping != m_warping) {

        m_warping = warping;
        emit warpingChanged();
    }

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
    }
}
