// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "HubController.h"
#include "HubSidebarController.h"
#include "Assets.h"

QString
HubSidebarController::prevVM(const QString &uuid)
{
    if (auto vm = m_sidebarModel.prevVM(UUID::fromString(uuid.toStdString()))) {
        return QString::fromStdString(vm.value().toString());
    }
    return "";
}

QString
HubSidebarController::nextVM(const QString &uuid)
{
    if (auto vm = m_sidebarModel.nextVM(UUID::fromString(uuid.toStdString()))) {
        return QString::fromStdString(vm.value().toString());
    }
    return "";
}

QString
HubSidebarController::prevSnap(const QString &uuid)
{
    if (auto vm = m_sidebarModel.prevSnap(UUID::fromString(uuid.toStdString()))) {
        return QString::fromStdString(vm.value().toString());
    }
    return "";
}

QString
HubSidebarController::nextSnap(const QString &uuid)
{
    if (auto vm = m_sidebarModel.nextSnap(UUID::fromString(uuid.toStdString()))) {
        return QString::fromStdString(vm.value().toString());
    }
    return "";
}

void
HubSidebarController::refresh()
{
    m_sidebarModel.refresh();
}

void
HubSidebarController::refresh(const QString &quuid)
{
    refresh(UUID::fromString(quuid.toStdString()));
}

void
HubSidebarController::refresh(UUID uuid)
{
    m_sidebarModel.refresh(uuid);
}

/*
void
HubSidebarController::remove(const QString &quuid) {

    remove(UUID::fromString(quuid.toStdString()));
}

void
HubSidebarController::remove(UUID uuid)
{
    m_sidebarModel.remove(uuid);
}
*/

void
HubSidebarController::validate()
{
    m_sidebarModel.validate();
}

void
HubSidebarController::expandCategories()
{
    m_sidebarModel.expandCategories();
}

void
HubSidebarController::rebuild()
{
    m_sidebarModel.rebuild();
}

void
HubSidebarController::reveal(UUID uuid)
{
    m_sidebarModel.reveal(uuid);
}
