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
#include "SiAmigaRenderer.h"

class QCoreApplication;
using vamiga::VAmiga;

// A trimmed-down counterpart to C64Controller: enough structure (singleton
// core access, window lifecycle, message pump, renderer hookup) to power on
// the Amiga core and render its frames, without the media/inspector/RPC
// surface C64Controller carries for the fully built-out SiC64 app. Those
// land in later steps as SiAmiga grows.
class SiAmigaController : public Controller {

    Q_OBJECT

    // Current state
    VMState m_state = VMState::HIBERNATED;

    // Gateway to the host audio backend
    AudioController m_audio;

    // Video renderer. Owned by the QML scene graph (SiAmigaCanvas.qml), not
    // by this controller -- see setRenderer().
    class SiAmigaRenderer *m_renderer = nullptr;

public:

    SiAmigaController();

    static SiAmigaController &instance();
    static VAmiga &core();

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

    VMState getState() const { return m_state; }
    void setState(VMState state);
    bool isPoweredOn() const { return m_state == VMState::PAUSED || m_state == VMState::RUNNING; }
    bool isRunning() { return m_state == VMState::RUNNING; }
    bool isPaused() { return m_state == VMState::PAUSED; }


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

    // Starts the emulator core once the window's scene graph is ready, and
    // halts it when the window is destroyed (see attachWindow() below).
    void windowDidOpen();
    void windowDidClose();

    void startRenderer();
    void stopRenderer();

    // Associates this controller with its emulator window and wires up the
    // sceneGraphInitialized/destroyed signals to windowDidOpen()/windowDidClose().
    void attachWindow(QQuickWindow *window);

    Q_PROPERTY(SiAmigaRenderer *renderer READ getRenderer WRITE setRenderer NOTIFY rendererChanged)

    class SiAmigaRenderer *getRenderer() const { return m_renderer; }
    void setRenderer(class SiAmigaRenderer *ptr);


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
};
