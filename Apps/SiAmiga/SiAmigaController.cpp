// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiAmigaController.h"
#include "SiAmigaRenderer.h"
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
    auto *con = static_cast<SiAmigaController *>(const_cast<void *>(listener));

    QMetaObject::invokeMethod(con, [con, msg, att = std::string(msg.str ? msg.str : "")] {
        con->process(msg, att);
    }, Qt::QueuedConnection);
}

SiAmigaController::SiAmigaController()
{
    LogTask task("Creating SiAmigaController...");
}

SiAmigaController &
SiAmigaController::instance()
{
    static SiAmigaController controller;
    return controller;
}

VAmiga &
SiAmigaController::core()
{
    static VAmiga core;
    return core;
}

void
SiAmigaController::initialize()
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
SiAmigaController::start()
{
    qCDebug(siLog) << "Starting SiAmigaController...";
}

void
SiAmigaController::stop()
{
    qCDebug(siLog) << "Stopping SiAmigaController...";
}

void
SiAmigaController::setState(VMState state)
{
    if (m_state != state) {

        m_state = state;
        emit stateChanged();
    }
}

void
SiAmigaController::attachWindow(QQuickWindow *window)
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
SiAmigaController::windowDidOpen()
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
SiAmigaController::windowDidClose()
{
    stopRenderer();

    m_audio.removeDelegate(this);
    m_audio.stop();

    // The core is a static singleton (see core()), so halt it rather than
    // destroy it.
    core().halt();
}

void
SiAmigaController::setRenderer(SiAmigaRenderer *ptr)
{
    if (m_renderer != ptr) {

        m_renderer = ptr;
        emit rendererChanged();
    }
}

void
SiAmigaController::startRenderer()
{
    if (m_renderer) m_renderer->start();
}

void
SiAmigaController::stopRenderer()
{
    if (m_renderer) m_renderer->stop();
}

void
SiAmigaController::linkAudioSink(QAudioSink *sink, QAudioFormat &format)
{
    auto sampleRate = format.sampleRate();
    core().set(Opt::HOST_SAMPLE_RATE, sampleRate);

    sink->start([](QSpan<float> buffer) {

        const int sampleCount = buffer.size() / 2;
        core().audioPort.copyInterleaved(buffer.data(), sampleCount);
    });
}

void
SiAmigaController::run()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to run.", e.what());
    }
}

void
SiAmigaController::pause()
{
    core().pause();
}

void
SiAmigaController::reset()
{
    core().hardReset();
    core().run();
}

void
SiAmigaController::powerOn()
{
    try {
        core().run();
    } catch (const std::exception &e) {
        showError("The emulator refuses to power on.", e.what());
    }
}

void
SiAmigaController::powerOff()
{
    core().powerOff();
}

void
SiAmigaController::didPowerOn()
{
    setState(VMState::PAUSED);
}

void
SiAmigaController::didPowerOff()
{
    setState(VMState::OFF);
}

void
SiAmigaController::didRun()
{
    setState(VMState::RUNNING);
}

void
SiAmigaController::didPause()
{
    setState(VMState::PAUSED);
}

void
SiAmigaController::didShutdown()
{
    setState(VMState::HALTED);
}

void
SiAmigaController::process(const Message &msg, const string &attachment)
{
    switch (msg.type) {

        case Msg::POWER:

            msg.value ? didPowerOn() : didPowerOff();
            break;

        case Msg::RUN:

            didRun();
            break;

        case Msg::PAUSE:

            didPause();
            break;

        case Msg::SHUTDOWN:

            didShutdown();
            break;

        case Msg::ABORT:

            qApp->exit((int)msg.value);
            break;

        default:

            break;
    }
}

void
SiAmigaController::update()
{
    // Placeholder for coalesced per-frame UI updates (config/info dirty
    // flags and the like), following the same rhythm as C64Controller::update().
    // Nothing needs coalescing yet -- this stub has no inspector panels.
}
