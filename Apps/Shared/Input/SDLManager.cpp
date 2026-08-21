// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Logger.h"
#include "SDLManager.h"
#include "Preferences.h"
#include <QFile>
#include <QGuiApplication>
#include <QTextStream>
#include <QTimer>
#include <SDL3/SDL.h>

static float
normalizeAxis(int16_t value)
{
    constexpr float deadzone = 8000.0f;

    if (value > deadzone)
        return (value - deadzone) / (32767.0f - deadzone);
    else if (value < -deadzone)
        return (value + deadzone) / (32768.0f - deadzone);
    else
        return 0.0f;
}

SDLManager::SDLManager(QObject *parent) : QObject(parent)
{
    connect(&timer, &QTimer::timeout, this, QOverload<>::of(&SDLManager::update));
    timer.setTimerType(Qt::TimerType::PreciseTimer);
    timer.setSingleShot(true);
}

SDLManager::~SDLManager()
{
    stop();
}

void
SDLManager::start()
{
    if (!running) {

        LogTask task("Starting SDLManager...");

        if (!SDL_Init(SDL_INIT_GAMEPAD)) {

            qWarning() << "SDL init failed:" << SDL_GetError();
            return;
        }

        // Load device database
        loadDB();

        // Fire timer
        timer.start();

        running = true;
    }
}

// ----------------------------------------------------------------------------

void
SDLManager::stop()
{
    if (running) {

        LogTask task("Stopping SDLManager...");

        for (auto pad: m_gamePads) {
            SDL_CloseGamepad(pad.handle);
        }
        m_gamePads.clear();

        SDL_QuitSubSystem(SDL_INIT_GAMEPAD);

        running = false;
    }
}

void
SDLManager::loadDB()
{
    LogTask task("Loading game controller database...");

    QFile file(":/gamecontrollerdb.txt");

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open mappings file!";
        return;
    }

    QTextStream in(&file);
    int count = 0;

    while (!in.atEnd()) {

        QString line = in.readLine().trimmed();

        // Skip empty lines or comments to stay clean
        if (line.isEmpty() || line.startsWith('#')) {
            continue;
        }

        if (SDL_AddGamepadMapping(line.toUtf8().constData()) >= 0) {
            count++;
            // QString name = line.split(',').at(1);
            // qDebug() << "Loaded mapping for:" << name;
        }
    }

    qCDebug(siLog) << "Read" << count << "game controller mappings.";
}

void
SDLManager::update()
{
    SDL_Event event;

    // Process all pending events
    while (SDL_PollEvent(&event)) {

        char buf[512];
        SDL_GetEventDescription(&event, buf, sizeof(buf));

        // printf("SDL_PollEvent: %d: %s\n", event.type, buf);

        switch (event.type) {

            case SDL_EVENT_GAMEPAD_ADDED:

                // printf("SDL_EVENT_GAMEPAD_ADDED\n");
                addGamepad(event);
                break;

            case SDL_EVENT_GAMEPAD_REMOVED:

                // printf("SDL_EVENT_GAMEPAD_REMOVED\n");
                removeGamepad(event);
                break;


            case SDL_EVENT_MOUSE_MOTION:

                // event.motion.xrel and event.motion.yrel are the "delta" movements
                // Send these to your Virtual Machine's mouse registers
                // virtualMachine->updateMousePos(event.motion.xrel, event.motion.yrel);
                // printf("SDL_EVENT_MOUSE_MOTION\n");
                break;

            case SDL_EVENT_GAMEPAD_BUTTON_DOWN: {

                auto &e = event.gbutton;
                // printf("SDL_EVENT_GAMEPAD_BUTTON_DOWN\n");
                if (delegate) delegate->sdlButtonEvent(e.which, e.timestamp, e.button, e.down);
                break;
            }
            case SDL_EVENT_GAMEPAD_BUTTON_UP: {

                auto &e = event.gbutton;
                // printf("SDL_EVENT_GAMEPAD_BUTTON_UP\n");
                if (delegate) delegate->sdlButtonEvent(e.which, e.timestamp, e.button, e.down);
                break;
            }

            case SDL_EVENT_GAMEPAD_AXIS_MOTION: {

                auto &e = event.gaxis;
                // printf("SDL_EVENT_GAMEPAD_AXIS_MOTION\n");
                float value = normalizeAxis(e.value);
                if (delegate) delegate->sdlAxisEvent(e.which, e.timestamp, e.axis, e.value, value);
                break;
            }
        }
    }

    // Restart the timer
    if (running) {
        timer.start(TIMER_INTERVAL_MSEC);
    }
}

void
SDLManager::addGamepad(SDL_Event &event)
{
    auto id = event.gdevice.which;

    // Verify that the game pad is not yet registered
    if (m_gamePads.contains(id)) {

        qWarning() << Q_FUNC_INFO << "SDL game pad " << id << " already added.";
        return;
    }

    // Check if the connected joystick is recognized. If not, register a default mapping
    if (!SDL_IsGamepad(id)) {

        const char *generic = "a:b0,b:b1,dpdown:+a1,dpleft:-a0,dpright:+a0,dpup:-a1,x:b2,y:b3";

        SDL_Joystick *js = SDL_GetJoystickFromID(id);
        if (js) {

            char guid[1024];
            SDL_GUIDToString(SDL_GetJoystickGUID(js), guid, sizeof(guid));
            QString mapping =
                QString("%1,%2,%3").arg(guid).arg(SDL_GetJoystickName(js)).arg(generic);
            SDL_AddGamepadMapping(mapping.toStdString().c_str());
            qWarning() << Q_FUNC_INFO << "Joystick " << guid << " registered with default mapping.";
        }
    }

    // Open gamepad
    // SDL_Joystick *joystick = SDL_OpenJoystick(id);
    SDL_Gamepad *gamepad = SDL_OpenGamepad(id);
    if (!gamepad) {

        qWarning() << Q_FUNC_INFO << "Can't open joystick with id: " << id;
        return;
    }

    // Register joystick
    Gamepad pad;
    const char *sdlName = SDL_GetGamepadName(gamepad);

    pad.name           = "Gamepad";
    pad.sdlName        = sdlName ? QString::fromUtf8(sdlName) : QStringLiteral("Unknown Joystick");
    pad.type           = GamepadType::Joystick;
    pad.sdlid          = id;
    pad.handle         = gamepad;
    pad.vendorId       = SDL_GetGamepadVendor(gamepad);
    pad.productId      = SDL_GetGamepadProduct(gamepad);
    pad.productVersion = SDL_GetGamepadProductVersion(gamepad);

    // Get the GUID string
    SDL_GUID guid = SDL_GetGamepadGUIDForID(id);
    char guidBuf[33]; // GUIDs are 32 chars + null terminator
    SDL_GUIDToString(guid, guidBuf, sizeof(guidBuf));
    pad.guidString = QString(guidBuf);

    // Get the gamepad mapping string
    char *mapping      = SDL_GetGamepadMappingForGUID(guid);
    pad.mapping        = QString::fromUtf8(mapping ? mapping : "");
    pad.defaultMapping = pad.mapping;

    m_gamePads.insert(id, pad);

    // Adopt the user's override for this device, if there is one
    applyStoredMapping(m_gamePads[id]);
    qInfo() << "Added GamePad: " << pad.name << "with ID: " << id;
    emit countChanged();
}

void
SDLManager::removeGamepad(SDL_Event &event)
{
    auto id = event.gdevice.which;

    // Only proceed if the gamepad is registered
    if (!m_gamePads.contains(id)) return;

    // Lookup gamepad
    const auto &pad = m_gamePads[id];

    qInfo() << "Removing GamePad: " << pad.name << "with ID: " << id;

    // Close gamepad
    if (pad.handle) {
        SDL_CloseGamepad(pad.handle);
        qDebug() << "Closed joystick:" << id;
    }

    // Remove gamepad
    m_gamePads.remove(id);

    emit countChanged();
}

void
SDLManager::applyStoredMapping(Gamepad &pad)
{
    /* Fall back to the mapping the device came with when there is no
     * override. Doing this unconditionally rather than only when an override
     * exists is what makes "use default" work: SDL has no way to withdraw a
     * mapping, so a customization is undone by putting the original back.
     */
    const QString stored = Preferences::instance().getGamepadMapping(pad.guidString);
    const QString wanted = stored.isEmpty() ? pad.defaultMapping : stored;

    if (wanted.isEmpty() || wanted == pad.mapping) return;

    if (addMapping(wanted)) {

        reopen(pad);
        pad.mapping = wanted;
    }
}

void
SDLManager::applyStoredMappings()
{
    for (auto it = m_gamePads.begin(); it != m_gamePads.end(); ++it) {
        applyStoredMapping(it.value());
    }
}

bool
SDLManager::addMapping(const QString &mapping)
{
    if (SDL_AddGamepadMapping(mapping.toUtf8().constData()) < 0) {

        qWarning() << "Failed to add mapping:" << SDL_GetError();
        return false;
    }

    qDebug() << "Registered gamepad mapping:" << mapping;
    return true;
}

void
SDLManager::reopen(Gamepad &pad)
{
    if (pad.handle) {

        SDL_CloseGamepad(pad.handle);
        pad.handle = SDL_OpenGamepad(pad.sdlid);

        if (!pad.handle) {
            qWarning() << "Failed to re-open gamepad after mapping update:" << SDL_GetError();
        }
    }
}