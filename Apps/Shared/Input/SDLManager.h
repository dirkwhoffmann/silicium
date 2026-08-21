// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Gamepad.h"
#include <QMap>
#include <QObject>
#include <QTimer>
#include <atomic>
#include <thread>

struct SDL_Gamepad;
union SDL_Event;

class SDLManagerDelegate {

public:

    virtual void sdlAxisEvent(int id, u64 timestamp, int axis, int value, float normalize) = 0;
    virtual void sdlMotionEvent(int id, u64 timestamp, char state[5]) = 0;
    virtual void sdlButtonEvent(int id, u64 timestamp, int button, bool down) = 0;
};

class SDLManager : public QObject {

    friend class InputManager;

    Q_OBJECT

    bool running = false;

    //
    // std::vector<SDL_Gamepad *> controllers;

    // Polling interval for SDL events
    static constexpr int TIMER_INTERVAL_MSEC = 10;

    // Polling timer
    QTimer timer = QTimer(this);

    // Currently available SDL game pads
    QMap<int, Gamepad> m_gamePads;

    // Delegate
    SDLManagerDelegate *delegate = nullptr;

  signals:

    void countChanged();

  public:

    SDLManager(QObject *parent);
    ~SDLManager();

    void setDelegate(SDLManagerDelegate *ptr) { delegate = ptr; }

    void start();
    void stop();

  private:

    // Loads the device database from the assets folder
    void loadDB();

    // Adds or removes a gamepad
    void addGamepad(SDL_Event &event);
    void removeGamepad(SDL_Event &event);

    /* Registers a complete SDL mapping string ("<guid>,<name>,<logic>")
     * with this process's SDL database. Returns false if SDL rejected it.
     */
    bool addMapping(const QString &mapping);

    // Re-opens a gamepad so it picks up a mapping that just changed
    void reopen(Gamepad &pad);

    /* Brings a device in line with the stored preferences: the user's
     * override if there is one, the device's own mapping otherwise. SDL's
     * mapping database is per-process, so every process has to do this for
     * itself -- which is also how a SiC64 instance picks up an edit made in
     * the Hub (see InputManager::updateDevices).
     */
    void applyStoredMapping(Gamepad &pad);
    void applyStoredMappings();

  private slots:

    void update();
};