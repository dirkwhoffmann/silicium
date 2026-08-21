// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiTypes.h"
#include "Images/ImageError.h"
#include "Preferences.h"
#include "utl/abilities/Loggable.h"

using retro::vault::ImageError;

class SiObject : public utl::Loggable {

  public:

    Preferences &preferences() { return Preferences::instance(); }
    const Preferences &preferences() const { return Preferences::instance(); }

};