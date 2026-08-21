// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Assets
import Silicium.Controllers

SettingsPage {

    required property PrefController controller

    background: Assets.iconUrl(Assets.PreferencesBg)
    contentSpacing: paneSpacing
}
