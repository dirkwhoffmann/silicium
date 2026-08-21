// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiTypes.h"
#include "EmulationKey.h"
#include "utl/common.h"
#include <optional>

// Ensure your enum is also visible to the Meta-Object system
enum class GamepadType { None, Mouse, Joystick, Paddle };
Q_ENUMS(GamepadType)

struct Gamepad {

    Q_GADGET

  public:

    // General
    QString name;
    GamepadType type { GamepadType::None };

    // SDL properties
    struct SDL_Gamepad *handle = nullptr;
    QString sdlName;
    QString guidString;
    int sdlid = -1;
    int vendorId = -1;
    int productId = -1;
    int productVersion = -1;
    QString mapping;

    /* The mapping SDL supplied when this device was connected, before any
     * user override was applied. Kept so a customized device can be put back
     * the way it came, and so the UI can tell the two apart.
     */
    QString defaultMapping;

    // Emulation keys
    std::array<std::optional<EmulationKey>, 5> keys {};

    // Current joystick state
    bool state[5] {};

    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(GamepadType type MEMBER type)
    Q_PROPERTY(QString typeString READ typeString)
    Q_PROPERTY(int sdlid MEMBER sdlid)


    //
    // Pretty printing
    //

    QString typeString() const;
    QString mappingLogic() const;


    //
    // Emulation keys
    //

    bool hasEmulationKeys() const;
    optional<int> isEmulationKey(int key, int vkey) const;
};

Q_DECLARE_METATYPE(Gamepad)
