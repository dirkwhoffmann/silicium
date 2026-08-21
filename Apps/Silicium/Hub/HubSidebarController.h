// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "AppController.h"
#include "HubSidebarModel.h"

class HubSidebarController : public Controller {

    Q_OBJECT

    friend class HubController;

    // Quick references
    VirtualMachineLibrary &library = Silicium::instance().getLibrary();

    // Model
    HubSidebarModel m_sidebarModel = HubSidebarModel(this);

  public:

    using Controller::Controller;

    //
    // Constants
    //

  public:

    /* The uuids of the three platform rows, for QML to tell them apart. They
     * are matched against a delegate's 'uuid' rather than its title, because
     * the title is a display string ("COMMODORE 64", see SidebarItem::title)
     * that carries no identity -- rewording or translating it would silently
     * break whatever compared against it.
     */
    Q_PROPERTY(QString CATEGORY_VM READ categoryVM CONSTANT)
    Q_PROPERTY(QString CATEGORY_C64 READ categoryC64 CONSTANT)
    Q_PROPERTY(QString CATEGORY_AMIGA READ categoryAmiga CONSTANT)

  private:

    static QString quuid(const UUID &uuid) { return QString::fromStdString(uuid.toString()); }

    QString categoryVM() const { return quuid(HubSidebarModel::UUID_VM); }
    QString categoryC64() const { return quuid(HubSidebarModel::UUID_C64); }
    QString categoryAmiga() const { return quuid(HubSidebarModel::UUID_AMIGA); }

    //
    // Accessing the model
    //

  public:

    Q_PROPERTY(HubSidebarModel *sidebarModel READ getSidebarModel NOTIFY sidebarModelChanged)

    Q_INVOKABLE QString prevVM(const QString &quuid);
    Q_INVOKABLE QString nextVM(const QString &quuid);
    Q_INVOKABLE QString nextSnap(const QString &quuid);
    Q_INVOKABLE QString prevSnap(const QString &quuid);

  private:

    HubSidebarModel *getSidebarModel() { return &m_sidebarModel; }

    //
    // Updating the model
    //

  public:

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void refresh(const QString &quuid);
    Q_INVOKABLE void validate();
    Q_INVOKABLE void expandCategories();

  private:

    void refresh(UUID uuid);
    // void remove(UUID uuid);
    void rebuild();

    // Expands whatever it takes to bring an item on screen
    void reveal(UUID uuid);

    //
    // Signals
    //

  signals:

    void sidebarModelChanged();
    void renamed(const QString &uuid, const QString &name);
};