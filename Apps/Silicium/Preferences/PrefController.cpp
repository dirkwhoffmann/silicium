// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "PrefController.h"
#include "../Preferences/Preferences.h"
#include "AppController.h"

PrefController::PrefController()
{
    m_keyModel = new C64KeyModel(this);

    // The state lives in the input manager; pass its change signals on
    connect(&inputManager, &InputManager::mouseStateChanged,
            this, &PrefController::mouseStateChanged);
    connect(&inputManager, &InputManager::joystickStateChanged,
            this, &PrefController::joystickStateChanged);
}

PrefController::~PrefController()
{

}

QString
PrefController::ctrlSymbol() const
{
#ifdef Q_OS_MACOS
    return QStringLiteral("⌘");
#else
    return QStringLiteral("⌃");
#endif
}

QString
PrefController::altSymbol() const
{
#ifdef Q_OS_MACOS
    return QStringLiteral("⌥");
#else
    return QStringLiteral("⎇");
#endif
}

QString
PrefController::metaSymbol() const
{
#ifdef Q_OS_MACOS
    return QStringLiteral("⌃");
#else
    return QStringLiteral("❖");
#endif
}

void
PrefController::registerAsInputManagerDelegate()
{
    inputManager.setDelegate(this);
    inputManager.setPort1(0);
    inputManager.setPort0(m_device);
}

void
PrefController::setWindow(QQuickWindow *ptr)
{
    if (m_window != ptr) {

        m_window = ptr;

        // Install event filter
        if (m_window) m_window->installEventFilter(this);

        emit windowChanged();
    }
}

void
PrefController::setDevice(int index)
{
    if (m_device != index) {

        m_device = index;
        emit deviceChanged();
    }
}

void
PrefController::setJoyKeyset0(int nr, int key, int virtualKey)
{
    setJoyKeyset(0, nr, key, virtualKey);
}

void
PrefController::setJoyKeyset1(int nr, int key, int virtualKey)
{
    setJoyKeyset(1, nr, key, virtualKey);
}

void
PrefController::setJoyKeyset(int joyNr, int nr, int key, int virtualKey)
{
    assert(joyNr == 0 || joyNr == 1);
    assert(nr >= 0 && nr < 5);

    /* Write the preference, not the device.
     *
     * updateDevices() rebuilds every device from the preferences, so assigning
     * to the Gamepad directly (as this used to do) was undone by the very call
     * that was meant to publish it -- recording a key appeared to work and then
     * vanished. Mirror setMouseKeyset() instead. Slot order follows
     * InputManager::updateDevices(): up, down, left, right, fire.
     */
    EmulationKey k { key, virtualKey };
    auto &p = preferences();

    if (joyNr == 0) {

        switch (nr) {
            case 0: p.setKeyset1Up(k);    break;
            case 1: p.setKeyset1Down(k);  break;
            case 2: p.setKeyset1Left(k);  break;
            case 3: p.setKeyset1Right(k); break;
            case 4: p.setKeyset1Fire(k);  break;
        }

    } else {

        switch (nr) {
            case 0: p.setKeyset2Up(k);    break;
            case 1: p.setKeyset2Down(k);  break;
            case 2: p.setKeyset2Left(k);  break;
            case 3: p.setKeyset2Right(k); break;
            case 4: p.setKeyset2Fire(k);  break;
        }
    }
}

void
PrefController::setMouseKeyset(int nr, int key, int virtualKey)
{
    EmulationKey k { key, virtualKey };
    auto &p = preferences();

    if (nr == 0) p.setMButton1Key(k);
    else if (nr == 1) p.setMButton2Key(k);
    else if (nr == 2) p.setMButton3Key(k);
}

void
PrefController::setMapping(const QString &mapping)
{
    inputManager.updateMapping(m_device, mapping);
}

void
PrefController::resetMapping()
{
    inputManager.resetMapping(m_device);
}

void
PrefController::toggleRecording()
{
    m_recording = !m_recording;
    m_selectedKey = -1;

    emit recordingChanged();
    emit selectedKeyChanged();
}

void
PrefController::selectKey(int nr)
{
    if (!m_recording) return;

    m_selectedKey = nr;
    emit selectedKeyChanged();
}

void
PrefController::revertKeyMap()
{
    Preferences::instance().resetC64KeyMap();
    emit selectedKeyChanged();
}

void
PrefController::captureKey(uint scancode)
{
    if (m_recording && m_selectedKey != -1) {

        preferences().setC64KeyMapping(scancode, m_selectedKey);
        m_selectedKey = -1;
        emit selectedKeyChanged();
    }
}

void
PrefController::warpToCenter()
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
