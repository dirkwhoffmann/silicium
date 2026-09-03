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
#include "DiagRom.h"
#include <QCoreApplication>
#include <QMetaObject>

using namespace vamiga;

// Receives messages from the emulator thread (registered as the launch()
// listener in initialize()) and marshals them onto the GUI thread, where it
// is safe to touch QObjects.
static void
process(const void *listener, const Message msg)
{
    auto *con = static_cast<SiAmController *>(const_cast<void *>(listener));

    QMetaObject::invokeMethod(con, [con, msg, att = std::string(msg.str ? msg.str : "")] {
        con->process(msg, att);
    }, Qt::QueuedConnection);
}

SiAmController::SiAmController()
{
    LogTask task("Creating SiAmController...");

    m_activityController = make_unique<SiAmActivityController>(this);
    m_configController = make_unique<SiAmConfigController>(this);
    m_keyboardController = make_unique<SiAmKeyboardController>(this);
    m_inspectorController = make_unique<SiAmInspectorController>(this);
    m_infoController = make_unique<SiAmInfoController>(this);
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
    // There is no free, redistributable Kickstart ROM, so the stub plugs in
    // DiagRom (an open-source diagnostic ROM) instead -- the same one the
    // core's own Headless self-tests use. A real Amiga backend eventually
    // wants a way to install a user-supplied Kickstart here.
    core().mem.loadRom(diagROM13, sizeofDiagRom13);

    // Registering the listener and starting the emulator thread happen
    // together on this core's API (unlike VirtualC64, which splits them into
    // launch() and a separate setListener()).
    core().launch(this, ::process);
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
}

void
SiAmController::windowDidOpen()
{
    core().powerOn();

    // Kick the machine into motion right away -- the stub has no play/pause
    // overlay yet (see VMWindow.qml for how SiC64 wires that up), and the
    // point of this milestone is to see frames appear.
    core().run();

    startRenderer();

    m_audio.setDelegate(this);
    m_audio.start();
}

void
SiAmController::windowDidClose()
{
    stopRenderer();

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
    emit mouseWasCaptured();
}

void
SiAmController::releaseMouse()
{
    inputManager.setCaptureMouse(false);
}

bool
SiAmController::driveHasDisk(int nr) const
{
    return core().df[nr]->getInfo().hasDisk;
}

bool
SiAmController::driveWriteProtected(int nr) const
{
    return core().df[nr]->getInfo().hasProtectedDisk;
}

bool
SiAmController::driveModified(int nr) const
{
    return core().df[nr]->getInfo().hasModifiedDisk;
}

bool
SiAmController::driveMotor(int nr) const
{
    return core().df[nr]->getInfo().motor;
}

bool
SiAmController::driveWriting(int nr) const
{
    return core().df[nr]->getInfo().writing;
}

int
SiAmController::driveTrack(int nr) const
{
    return (int)core().df[nr]->getInfo().head.track();
}

void
SiAmController::insertDisk(int nr, const QUrl &url, bool wp)
{
    try {

        if (url.isLocalFile()) {
            core().df[nr]->insert(url.toLocalFile().toStdWString(), wp);
        }

    } catch (const std::exception &e) {

        showError("Failed to insert the disk.", e.what());
    }
}

void
SiAmController::newDisk(int nr)
{
    try {

        core().df[nr]->insertBlankDisk(amiga::FSFormat::OFS, amiga::BootBlockId::AMIGADOS_13, "Empty");

    } catch (const std::exception &e) {

        showError("Failed to create a new disk.", e.what());
    }
}

void
SiAmController::ejectDisk(int nr)
{
    try {

        core().df[nr]->ejectDisk();

    } catch (const std::exception &e) {

        showError("Failed to eject the disk.", e.what());
    }
}

void
SiAmController::exportDisk(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            core().df[nr]->writeToFile(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to export the disk.", e.what());
    }
}

void
SiAmController::toggleWriteProtection(int nr)
{
    try {

        auto &drive = *core().df[nr];
        drive.setFlag(DiskFlags::PROTECTED, !drive.getFlag(DiskFlags::PROTECTED));

    } catch (const std::exception &e) {

        showError("Failed to change the write-protection status.", e.what());
    }
}

bool
SiAmController::hdHasDisk(int nr) const
{
    return core().hd[nr]->getInfo().hasDisk;
}

void
SiAmController::attachHd(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            core().hd[nr]->attach(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to attach the hard drive.", e.what());
    }
}

void
SiAmController::detachHd(int nr)
{
    m_configController->setHdConnected(nr, false);
}

void
SiAmController::exportHd(int nr, const QUrl &url)
{
    try {

        if (url.isLocalFile()) {
            core().hd[nr]->writeToFile(url.toLocalFile().toStdWString());
        }

    } catch (const std::exception &e) {

        showError("Failed to export the hard drive.", e.what());
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
    setState(VMState::PAUSED);
    m_configController->queryRoms();
}

void
SiAmController::didPowerOff()
{
    setState(VMState::OFF);
}

void
SiAmController::didRun()
{
    setState(VMState::RUNNING);
}

void
SiAmController::didPause()
{
    setState(VMState::PAUSED);
}

void
SiAmController::didShutdown()
{
    setState(VMState::HALTED);
}

void
SiAmController::process(const Message &msg, const string &attachment)
{
    switch (msg.type) {

        case Msg::CONFIG:

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
        case Msg::HDR_STEP:
        case Msg::HDR_READ:
        case Msg::HDR_WRITE:
        case Msg::HDR_IDLE:

            m_infoIsDirty = true;
            break;

        case Msg::RSH_CLOSE:
        case Msg::RSH_UPDATE:
        case Msg::RSH_SWITCH:
        case Msg::RSH_WAIT:
        case Msg::RSH_ERROR:

            m_retroShellIsDirty = true;
            break;

        default:

            break;
    }
}

void
SiAmController::update()
{
    // Placeholder for coalesced per-frame UI updates (config/info dirty
    // flags and the like), following the same rhythm as C64Controller::update().
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

    if (m_infoIsDirty) {

        m_infoController->refresh();
        m_infoIsDirty = false;
    }
}
