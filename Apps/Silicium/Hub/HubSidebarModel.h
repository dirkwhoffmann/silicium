// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "VirtualMachineLibrary.h"
#include "Silicium.h"
#include "utl/types/UUID.h"
#include <set>
#include <QAbstractListModel>

using utl::UUID;

enum class ItemType { Platform, VM, Snapshot };

struct SidebarItem {

    // Represented object
    UUID uuid;
    ItemType type {};

    // Tree info
    UUID parent;
    int numChildren {};

    // Display info
    bool hidden;
    QString icon;

    // Computed values
    bool isExpandable() const { return numChildren > 0; }
    QString quuid() const { return QString::fromStdString(uuid.toString()); }
    int level() const { return type == ItemType::Platform ? 0 : type == ItemType::VM ? 1 : 2; }
    VMState state() const;
    QString stateIcon() const;
    QString svm() const;
    QString title() const;
    bool readOnly() const;
    bool compatible() const;
};

class HubSidebarModel : public QAbstractListModel, SiObject {

    Q_OBJECT

public:

    // Static UUIDs for all sidebar groups
    static constexpr UUID UUID_VM = UUID(1);
    static constexpr UUID UUID_C64 = UUID(2);
    static constexpr UUID UUID_AMIGA = UUID(3);

    enum SidebarRoles {

        TypeRole = Qt::UserRole + 1,
        LevelRole,
        ExpandableRole,
        ExpandedRole,
        UUIDRole,
        SVMRole,
        HiddenRole,
        IconSrcRole,
        StateSrcRole,
        TitleRole,
        StateRole,
        ReadOnlyRole,
        CompatibleRole
    };

private:

    // Quick references
    VirtualMachineLibrary &library = Silicium::instance().getLibrary();

    // Items
    QVector<SidebarItem> items;

    // Expansion state
    std::set<UUID> expanded;


    //
    // Initializing
    //

public:

    explicit HubSidebarModel(QObject *parent = nullptr);


    //
    // Methods from QAbstractListModel
    //

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;


    //
    // Managing the model
    //

    // Rebuilds the model from scratch
    void rebuild();
    void rebuild(int mode);

    // Emits dataChanged signals for all or a specific sidebar items
    void refresh(UUID uuid);
    void refresh(int row);
    void refresh();

    // Removes all items that are no longer contained in the library
    void validate();

    // Expands all groups
    void expandCategories();

  private:

    void rebuildGroup(QList<VirtualMachine *> &vms, UUID uuid);
    void rebuildVM(VirtualMachine *vm, UUID parent);
    void rebuildSnapshot(const SnapshotInfo &info, UUID parent);


    //
    // Expanding and collapsing
    //

  public:

    Q_INVOKABLE void expandOrCollapse(const QString &quuid);
    Q_INVOKABLE void expand(const QString &quuid);
    Q_INVOKABLE void collapse(const QString &quuid);

    void expandOrCollapse(UUID uuid);
    void expand(UUID uuid);
    void collapse(UUID uuid);

    /* Expands every ancestor of an item so that it is actually on screen.
     *
     * isHidden() reports an item as hidden if *any* ancestor is collapsed, so
     * revealing one means walking the whole chain -- with platform grouping
     * enabled that is the machine and its platform group, not just the
     * immediate parent.
     */
    void reveal(UUID uuid);

private:

    int numChildren(int row) const;

    bool isExpanded(UUID uuid) const;
    bool isCollapsed(UUID uuid) const;
    bool isHidden(UUID uuid) const;


    //
    // Navigating
    //

public:

    optional<int> find(UUID uuid, int startIndex = 0, int delta = 1) const;
    optional<int> find(ItemType type, int startIndex = 0, int delta = 1) const;

    optional<UUID> nextVMIndex(int index) const;
    optional<UUID> prevVMIndex(int index) const;
    optional<UUID> nextSnapIndex(int index) const;
    optional<UUID> prevSnapIndex(int index) const;

    optional<UUID> nextVM(UUID uuid) const; // DEPRECATED
    optional<UUID> prevVM(UUID uuid) const; // DEPRECATED
    optional<UUID> nextSnap(UUID uuid) const; // DEPRECATED
    optional<UUID> prevSnap(UUID uuid) const; // DEPRECATED
};
