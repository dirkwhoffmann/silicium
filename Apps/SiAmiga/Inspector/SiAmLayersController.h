// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiAmInspectorController.h"

//
// Layers inspector controller -- supplies SiAmXRayPanel's inspector-window
// chrome (currentController for the toolbar, the shared active flag, tick
// throttle and beam-position readout from SiAmInspectorController). It owns
// no properties of its own: the X-Ray debugger's settings are XRAY_*
// config options, and the panel binds to those directly on the shared
// SiAmConfigController (controller.configController) instead of proxying
// them through here. Mirrors SiC64BusController, which plays the same
// no-data-of-its-own role for SiC64BusPanel.
//

class SiAmController;

class SiAmLayersController : public SiAmInspectorController {

    Q_OBJECT

  public:

    explicit SiAmLayersController(SiAmController *parent = nullptr);
};
