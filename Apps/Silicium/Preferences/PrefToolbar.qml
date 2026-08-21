// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import Silicium.Theme

/* The toolbar of a preferences page: a SettingsToolbar wearing frosted glass
 * instead of a flat surface.
 */
SettingsToolbar {

    id: root

    /* Artwork sampled for the frosted background, normally the enclosing page's
     * backgroundItem. Without it SiGlass falls back to a plain tint, so a page
     * that forgets to pass it still looks reasonable -- just not glassy.
     */
    property Image backdrop: null

    background: SiGlass {

        backdrop: root.backdrop
        tint: Qt.alpha(Palette.backgroundElevated, 0.25)
        radius: Style.radius
    }
}
