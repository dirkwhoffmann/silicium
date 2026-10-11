// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Controller.h"

Controller::Controller(QObject *parent) : QObject(parent)
{

}

QString
Controller::errorText(std::exception_ptr exception)
{
    if (!exception) return { };

    try {
        std::rethrow_exception(exception);
    } catch (const std::exception &e) {
        return QString::fromUtf8(e.what());
    } catch (...) {
        return tr("Unknown error");
    }
}
