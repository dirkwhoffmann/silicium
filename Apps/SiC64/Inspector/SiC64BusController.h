// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiC64InspectorController.h"

//
// Bus inspector controller -- supplies SiC64BusPanel's inspector-window
// chrome (currentController for the toolbar, the shared active flag, tick
// throttle and beam-position readout from SiC64InspectorController). It owns
// no properties of its own: the DMA debugger's settings are DMA_DEBUG_*
// config options, and the panel binds to those directly on the shared
// SiC64ConfigController (controller.configController) instead of proxying
// them through here.
//

class C64Controller;

class SiC64BusController : public SiC64InspectorController {

    Q_OBJECT

  public:

    explicit SiC64BusController(C64Controller *parent = nullptr);
};
