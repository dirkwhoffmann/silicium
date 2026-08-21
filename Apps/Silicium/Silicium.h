// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "VirtualMachineLibrary.h"

#pragma once

class Silicium : public QObject {

    Q_OBJECT

    VirtualMachineLibrary library;

  public:

    static Silicium &instance();

    VirtualMachineLibrary &getLibrary() { return library; }
};
