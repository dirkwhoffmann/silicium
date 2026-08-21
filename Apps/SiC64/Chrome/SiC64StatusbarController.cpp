// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SiC64StatusbarController.h"
#include "C64Controller.h"

using namespace vc64;

SiC64StatusbarController::SiC64StatusbarController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}
