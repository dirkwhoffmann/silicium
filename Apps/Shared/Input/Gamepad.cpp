// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Gamepad.h"

QString
Gamepad::typeString() const
{
    switch (type) {
        case GamepadType::Mouse:
            return "Mouse";
        case GamepadType::Joystick:
            return "Joystick";
        case GamepadType::Paddle:
            return "Paddle";
        default:
            return "None";
    }
}

QString
Gamepad::mappingLogic() const
{
    QString result;

    // Format is: GUID, Name, Logic
    QStringList parts = mapping.split(u',');

    if (parts.size() > 2) {

        // Remove GUID and Name
        parts.removeFirst();
        parts.removeFirst();

        // Rejoin the remaining parts
        result = parts.join(u',');

        // Remove a trailing comma (if it exists)
        if (result.endsWith(u',')) result.chop(1);
    }

    return result;
}

bool
Gamepad::hasEmulationKeys() const
{
    for (const auto &key : keys) {
        if (key) return true;
    }
    return false;
}

optional<int>
Gamepad::isEmulationKey(int qKey, int pKey) const
{
    for (int i = 0; i < keys.size(); ++i) {

        if (keys[i]) {
            if (keys[i]->pKey != -1) {
                if (keys[i]->pKey == pKey) return i;
            } else {
                if (keys[i]->qKey == qKey) return i;
            }
        }
    }
    return {};
}
