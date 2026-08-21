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
#include "Preferences.h"
#include "Assets.h"

//
// Sidebar Item
//

VMState
SidebarItem::state() const
{
    return HubController::instance().lookupState(uuid);
}

QString
SidebarItem::stateIcon() const
{
    switch (state()) {

        case VMState::THAWED:  return Assets::getIconUrl(Assets::Icon::LedRoundGray).toString();
        case VMState::OFF:     return Assets::getIconUrl(Assets::Icon::LedRoundGray).toString();
        case VMState::PAUSED:  return Assets::getIconUrl(Assets::Icon::LedRoundYellow).toString();
        case VMState::RUNNING: return Assets::getIconUrl(Assets::Icon::LedRoundGreen).toString();
        case VMState::HALTED:  return Assets::getIconUrl(Assets::Icon::LedRoundGray).toString();
        default:               return "";
    }
}

QString
SidebarItem::svm() const
{
    auto &library = Silicium::instance().getLibrary();

    auto *vm = library.lookupVirtualMachine(uuid);
    return vm ? QString::fromStdString(vm->getSourcePath().string()) : "";
}

QString
SidebarItem::title() const
{
    auto &library = Silicium::instance().getLibrary();

    switch (type) {

        case ItemType::VM:

            if (auto *vm = library.lookupVirtualMachine(uuid)) {
                return QString::fromStdString(vm->getManifest().name);
            }
            break;

        case ItemType::Snapshot:

            if (auto *vm = library.lookupVirtualMachine(parent)) {
                if (auto *info = vm->lookupSnapshot(uuid)) {
                    if (info->name.empty()) {
                        return QDateTime::fromSecsSinceEpoch(info->created).toString("yyyy-MM-dd HH:mm:ss");
                    } else {
                        return QString::fromStdString(info->name);
                    }
                }
            }
            break;

        default:

            if (uuid == HubSidebarModel::UUID_VM) return "VIRTUAL MACHINES";
            if (uuid == HubSidebarModel::UUID_C64) return "COMMODORE 64";
            if (uuid == HubSidebarModel::UUID_AMIGA) return "COMMODORE AMIGA";
            break;
    }

    return "???";
}

bool
SidebarItem::readOnly() const
{
    auto &library = Silicium::instance().getLibrary();

    if (auto *vm = library.lookupVirtualMachine(uuid))
        return vm->isReadOnly();

    return false;
}

bool
SidebarItem::compatible() const
{
    auto &library = Silicium::instance().getLibrary();

    switch (type) {

        case ItemType::VM:

            if (auto *vm = library.lookupVirtualMachine(uuid)) {
                return vm->getManifest().isCompatible();
            }
            break;

        case ItemType::Snapshot:

            if (auto *vm = library.lookupVirtualMachine(parent)) {
                if (auto *info = vm->lookupSnapshot(uuid)) {
                    return info->isCompatible();
                }
            }
            break;

        default:
            break;
    }

    return true;
}


//
// Sidebar Model
//

HubSidebarModel::HubSidebarModel(QObject *parent) : QAbstractListModel(parent) {}

int
HubSidebarModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return items.size();
}

QHash<int, QByteArray>
HubSidebarModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[TypeRole]       = "type";
    roles[UUIDRole]       = "uuid";
    roles[SVMRole]        = "svm";
    roles[LevelRole]      = "level";
    roles[ExpandableRole] = "isExpandable";
    roles[ExpandedRole]   = "isExpanded";
    roles[HiddenRole]     = "isHidden";
    roles[IconSrcRole]    = "iconSrc";
    roles[StateSrcRole]   = "stateSrc";
    roles[TitleRole]      = "title";
    roles[StateRole]      = "state";
    roles[ReadOnlyRole]   = "readOnly";
    roles[CompatibleRole] = "isCompatible";

    return roles;
}

QVariant
HubSidebarModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) return {};

    const auto &item = items[index.row()];

    switch (role) {

        case UUIDRole:       return item.quuid();
        case TypeRole:       return (int)item.type;
        case SVMRole:        return item.svm();
        case LevelRole:      return item.level();
        case ExpandableRole: return item.isExpandable();
        case ExpandedRole:   return expanded.contains(item.uuid);
        case HiddenRole:     return isHidden(item.uuid);
        case IconSrcRole:    return item.icon;
        case StateRole:      return int(item.state());
        case StateSrcRole:   return item.stateIcon();
        case TitleRole:      return item.title();
        case ReadOnlyRole:   return item.readOnly();
        case CompatibleRole: return item.compatible();
        default:             return {};
    }
}

void
HubSidebarModel::expandOrCollapse(const QString &quuid)
{
    expandOrCollapse(UUID::fromString(quuid.toStdString()));
}

void
HubSidebarModel::expand(const QString &quuid)
{
    expand(UUID::fromString(quuid.toStdString()));
}

void
HubSidebarModel::collapse(const QString &quuid)
{
    collapse(UUID::fromString(quuid.toStdString()));
}

void
HubSidebarModel::expandOrCollapse(UUID uuid)
{
    expanded.contains(uuid) ? collapse(uuid) : expand(uuid);
}

void
HubSidebarModel::expand(UUID uuid)
{
    if (!expanded.contains(uuid)) {

        expanded.insert(uuid);
        emit dataChanged(index(0, 0), index(items.size() - 1, 0), { HiddenRole, ExpandedRole });
    }
}

void
HubSidebarModel::collapse(UUID uuid)
{
    if (expanded.contains(uuid)) {

        expanded.erase(uuid);
        emit dataChanged(index(0, 0), index(items.size() - 1, 0), { HiddenRole, ExpandedRole });
    }
}

void
HubSidebarModel::reveal(UUID uuid)
{
    auto row = find(uuid);
    if (!row) return;

    bool changed = false;

    // Ancestors are reached by uuid rather than by walking backwards through
    // the rows, since a group's children are not guaranteed to be adjacent to
    // it in every sort order. The chain terminates on its own: a top-level
    // item's parent is the nil UUID.
    for (UUID parent = items[*row].parent; parent; ) {

        if (expanded.insert(parent).second) changed = true;

        auto parentRow = find(parent);
        if (!parentRow) break;

        parent = items[*parentRow].parent;
    }

    // One signal for the whole chain rather than one per expand() call, and
    // only when something actually changed.
    if (changed) {
        emit dataChanged(index(0, 0), index(items.size() - 1, 0), { HiddenRole, ExpandedRole });
    }
}

optional<int>
HubSidebarModel::find(UUID uuid, int startIndex, int delta) const
{
    for (int i = startIndex; i >= 0 && i < items.size(); i += delta) {
        if (items[i].uuid == uuid) return i;
    }
    return {};
}

optional<int>
HubSidebarModel::find(ItemType type, int startIndex, int delta) const
{
    for (int i = startIndex; i >= 0 && i < items.size(); i += delta) {
        if (items[i].type == type) return i;
    }
    return {};
}

optional<UUID>
HubSidebarModel::nextVMIndex(int index) const
{
    for (int i = index + 1; i >= 0 && i < items.size(); ++i) {
        if (items[i].type == ItemType::VM) return i;
    }
    return {};
}

optional<UUID>
HubSidebarModel::prevVMIndex(int index) const
{
    for (int i = index - 1; i >= 0 && i < items.size(); --i) {
        if (items[i].type == ItemType::VM) return i;
    }
    return {};
}

optional<UUID>
HubSidebarModel::nextSnapIndex(int index) const
{
    for (int i = index + 1; i >= 0 && i < items.size(); ++i) {
        if (items[i].type == ItemType::Snapshot) return i;
    }
    return {};
}

optional<UUID>
HubSidebarModel::prevSnapIndex(int index) const
{
    for (int i = index - 1; i >= 0 && i < items.size(); --i) {
        if (items[i].type == ItemType::Snapshot) return i;
    }
    return {};
}

std::optional<UUID>
HubSidebarModel::nextVM(UUID uuid) const
{
    if (auto matchIndex = find(uuid, 0, 1)) {

        auto nextVMIndex = find(ItemType::VM, matchIndex.value() + 1, 1);
        if (nextVMIndex.has_value()) return items[nextVMIndex.value()].uuid;
    }
    return {};
}

std::optional<UUID>
HubSidebarModel::prevVM(UUID uuid) const
{
    if (auto matchIndex = find(uuid, 0, 1)) {

        auto prevVMIndex = find(ItemType::VM, matchIndex.value() - 1, -1);
        if (prevVMIndex.has_value()) return items[prevVMIndex.value()].uuid;
    }
    return {};
}

std::optional<UUID>
HubSidebarModel::nextSnap(UUID uuid) const
{
    if (auto matchIndex = find(uuid, 0, 1)) {

        auto nextIndex = matchIndex.value() + 1;
        if (nextIndex < items.size() && items[nextIndex].type == ItemType::Snapshot) {
            return items[nextIndex].uuid;
        }
    }
    return {};
}

std::optional<UUID>
HubSidebarModel::prevSnap(UUID uuid) const
{
    if (auto matchIndex = find(uuid, 0, 1)) {

        auto nextIndex = matchIndex.value() - 1;
        if (nextIndex >= 0 && items[nextIndex].type == ItemType::Snapshot) {
            return items[nextIndex].uuid;
        }
    }
    return {};
}

void
HubSidebarModel::rebuild()
{
    rebuild(Preferences::instance().getVmSortMode());
}

void
HubSidebarModel::rebuild(int mode)
{
    bool sortByName      = mode % 3 == 0;
    bool sortByCreated   = mode % 3 == 1;
    bool groupByPlatform = mode >= 3;

    auto customMachine = [](const auto& pair) { return !pair.second->isPreinstalled(); };

    beginResetModel();

    items.clear();

    //
    // Collect all virtual machines
    //

    QList<VirtualMachine *> vms;
    if (preferences().getHideShowcases()) {
        for (auto *vm : library.getVirtualMachines(customMachine)) vms.append(vm);
    } else {
        for (auto *vm : library.getVirtualMachines()) vms.append(vm);
    }

    //
    //  Sort the list
    //

    auto sortFunc = [&](VirtualMachine *a, VirtualMachine *b) {
        auto ma = a->getManifest();
        auto mb = b->getManifest();

        if (sortByName) {
            return QString::fromStdString(ma.name).compare(QString::fromStdString(mb.name), Qt::CaseInsensitive) < 0;
        }
        if (sortByCreated) {
            return ma.created > mb.created;
        }
        return ma.modified > mb.modified;
    };

    std::sort(vms.begin(), vms.end(), sortFunc);

    //
    // Build sidebar
    //

    if (groupByPlatform) {

        QList<VirtualMachine *> amigaVMs;
        QList<VirtualMachine *> c64VMs;

        for (auto *vm : vms) {

            if (vm->getManifest().isAmiga()) {
                amigaVMs.append(vm);
            } else {
                c64VMs.append(vm);
            }
        }

        rebuildGroup(c64VMs, UUID_C64);
        rebuildGroup(amigaVMs, UUID_AMIGA);

    } else {

        rebuildGroup(vms, UUID_VM);
    }

    endResetModel();
}

void
HubSidebarModel::refresh()
{
    if (!items.empty()) {

        emit dataChanged(index(0, 0),
                         index(items.size() - 1, 0),
                         { ExpandableRole, ExpandedRole, HiddenRole, StateSrcRole, TitleRole, StateRole, ReadOnlyRole });
    }
}

void
HubSidebarModel::refresh(UUID uuid)
{
    if (auto row = find(uuid)) refresh(*row);
}

void
HubSidebarModel::refresh(int row) {

    emit dataChanged(index(row, 0),
                     index(row, 0),
                     {ExpandableRole, ExpandedRole, HiddenRole, StateSrcRole, TitleRole, StateRole, ReadOnlyRole});
}

void
HubSidebarModel::validate() {

    for (int row = items.size() - 1; row >= 0; --row) {

        auto &item = items[row];
        bool invalid = false;

        switch (item.type) {

            case ItemType::VM: {

                invalid = !library.lookupVirtualMachine(item.uuid);
                break;
            }
            case ItemType::Snapshot: {

                auto *vm = library.lookupVirtualMachine(item.parent);
                invalid = !vm || !vm->lookupSnapshot(item.uuid);
                break;
            }
            default:
                break;
        }

        if (invalid) {

            beginRemoveRows(QModelIndex(), row, row);
            items.remove(row, 1);
            endRemoveRows();
        }
    }

    refresh();
}

void
HubSidebarModel::rebuildGroup(QList<VirtualMachine *> &vms, UUID uuid)
{
    if (!vms.empty()) {

        SidebarItem item {};

        item.type = ItemType::Platform;
        item.uuid = uuid;
        item.numChildren = vms.size();
        items.append(item);

        for (auto *vm : vms)
            rebuildVM(vm, uuid);
    }
}

void
HubSidebarModel::rebuildVM(VirtualMachine *vm, UUID parent)
{
    auto manifest = vm->getManifest();
    auto icon = manifest.isAmiga() ? Assets::Icon::AmigaCore : Assets::Icon::C64Core;

    SidebarItem item {};

    item.type = ItemType::VM;
    item.uuid = manifest.uuid;
    item.parent = parent;
    item.numChildren = (int) manifest.numSnapshots();
    item.icon = Assets::getIconUrl(icon).toString();

    items.append(item);

    /* No merge and no sort: the pool is already ordered newest first (see
     * SnapshotPool::insert), which is the order this used to reconstruct by
     * hand after concatenating the two pools.
     */
    for (const auto &snapshot : manifest.snapshots.get())
        rebuildSnapshot(snapshot, item.uuid);
}

void
HubSidebarModel::rebuildSnapshot(const SnapshotInfo &info, UUID parent)
{
    // auto date = QDateTime::fromSecsSinceEpoch(info.created).toString("yyyy-MM-dd HH:mm:ss");

    SidebarItem item {};
    item.type = ItemType::Snapshot;
    item.uuid = info.uuid;
    item.parent = parent;
    item.icon = Assets::getIconUrl(Assets::Icon::Snapshot).toString();

    items.append(item);
}

void
HubSidebarModel::expandCategories()
{
    expand(UUID_VM);
    expand(UUID_AMIGA);
    expand(UUID_C64);
}

int
HubSidebarModel::numChildren(int row) const
{
    int result = 0;

    if (row >= 0 && row < items.size()) {
        for (int i = row + 1; i < items.size(); ++i) {
            if (items[i].parent == items[row].uuid) ++result;
        }
    }
    return result;
}

bool
HubSidebarModel::isExpanded(UUID uuid) const
{
    return expanded.contains(uuid);
}

bool
HubSidebarModel::isCollapsed(UUID uuid) const
{
    return !expanded.contains(uuid);
}

bool
HubSidebarModel::isHidden(UUID uuid) const
{
    if (!uuid) return true;

    if (auto index = find(uuid)) {
        if (auto parent = items[index.value()].parent) {
            return isCollapsed(parent) || isHidden(parent);
        }
    }

    return false;
}