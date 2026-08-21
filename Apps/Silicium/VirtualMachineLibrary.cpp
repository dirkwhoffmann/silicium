// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "VirtualMachineLibrary.h"
#include "Images/ImageError.h"
#include "Preferences.h"

using retro::vault::ImageError;

#include <stdio.h>
#include <algorithm>

VirtualMachineLibrary::VirtualMachineLibrary()
{

}

std::pair<VirtualMachine *, SnapshotInfo *>
VirtualMachineLibrary::resolve(utl::UUID uuid)
{
    if (auto it = vms.find(uuid); it != vms.end()) {
        return {it->second.get(), nullptr};
    }

    for (const auto &vm : std::views::values(vms)) {

        if (auto *snapshot = vm->getManifest().lookupSnapshot(uuid)) {
            return { vm.get(), snapshot };
        }
    }

    return { nullptr, nullptr };
}

std::pair<const VirtualMachine *, const SnapshotInfo *>
VirtualMachineLibrary::resolve(utl::UUID uuid) const
{
    return const_cast<VirtualMachineLibrary *>(this)->resolve(uuid);
}

VirtualMachine *
VirtualMachineLibrary::lookupVirtualMachine(utl::UUID uuid)
{
    if (auto it = vms.find(uuid); it != vms.end())
        return it->second.get();

    return nullptr;

    /*
    for (const auto &vm : std::views::values(vms)) {
        if (vm->getManifest().uuid == uuid) return vm.get();
    }

    return nullptr;
    */
}

VirtualMachine *
VirtualMachineLibrary::lookupVirtualMachine(const string &uuid)
{
    return lookupVirtualMachine(utl::UUID::fromString(uuid));
}

VirtualMachine*
VirtualMachineLibrary::lookupVirtualMachine(const fs::path &path)
{
    std::error_code ec;

    // for (auto &vm : vms) {
    for (const auto &vm : std::views::values(vms)) {
        if (fs::equivalent(vm->getSourcePath(), path, ec)) return vm.get();
    }
    return nullptr;
}

const VirtualMachine *
VirtualMachineLibrary::lookupVirtualMachine(utl::UUID uuid) const
{
    return const_cast<VirtualMachineLibrary *>(this)->lookupVirtualMachine(uuid);
}

const VirtualMachine *
VirtualMachineLibrary::lookupVirtualMachine(const string &uuid) const
{
    return const_cast<VirtualMachineLibrary *>(this)->lookupVirtualMachine(uuid);
}

const VirtualMachine *
VirtualMachineLibrary::lookupVirtualMachine(const fs::path &path) const
{
    return const_cast<VirtualMachineLibrary *>(this)->lookupVirtualMachine(path);
}

SnapshotInfo *
VirtualMachineLibrary::lookupSnapshot(utl::UUID uuid)
{
    // for (auto &vm : vms) {
    for (const auto &vm : std::views::values(vms)) {

        if (auto *snapshot = vm->getManifest().lookupSnapshot(uuid)) {
            return snapshot;
        }
    }
    return nullptr;
}

SnapshotInfo *
VirtualMachineLibrary::lookupSnapshot(const string &uuid)
{
    return lookupSnapshot(utl::UUID::fromString(uuid));
}

vector<utl::UUID>
VirtualMachineLibrary::collect(const std::function<bool(const VirtualMachine &)> &predicate) const
{
    vector<utl::UUID> result;

    // for (const auto &vm : vms) {
    for (const auto &vm : std::views::values(vms)) {
        if (vm && predicate(*vm)) result.push_back(vm->getManifest().uuid);
    }

    return result;
}

VirtualMachine *
VirtualMachineLibrary::addVirtualMachine(const fs::path &path)
{
    // Check if a virtual with the same source path already exists
    if (lookupVirtualMachine(path))
        throw ImageError(ImageError::VM_EXISTS, path.string());

    // Create the virtual machine
    auto newVm = VirtualMachine::make(path);
    auto uuid = newVm->getManifest().uuid;

    // Check if a machine with the same UUID already exists
    if (lookupVirtualMachine(uuid)) {

        if (!Preferences::instance().getResolveUUIDConflicts())
            throw ImageError(ImageError::VM_SAME_UUID, uuid.toString());

        // Assign a new UUID and persist it
        newVm->getManifest().uuid = utl::UUID::v4();
        newVm->persist();
    }

    // Move the machine into the libary
    vms[uuid] = std::move(newVm);

    return vms[uuid].get();
}

VirtualMachine *
VirtualMachineLibrary::cloneVirtualMachine(const fs::path &path, const fs::path &clonePath)
{
    // Create a clone on disk
    SVMFile svm(SVMFile::Clone, path, clonePath);

    // Add the clone
    return addVirtualMachine(clonePath);
}

VirtualMachine *
VirtualMachineLibrary::cloneVirtualMachine(utl::UUID uuid, const fs::path &clonePath)
{
    if (auto *vm = lookupVirtualMachine(uuid))
        return cloneVirtualMachine(vm->getSourcePath(), clonePath);

    return nullptr;
}

bool
VirtualMachineLibrary::removeVirtualMachine(utl::UUID uuid)
{
    auto it = vms.find(uuid);

    if (it != vms.end()) {

        vms.erase(it);
        return true;
    }
    return false;
}

bool
VirtualMachineLibrary::removeVirtualMachine(const std::string &uuid)
{
    return removeVirtualMachine(utl::UUID::fromString(uuid));
}

bool
VirtualMachineLibrary::removeVirtualMachine(const fs::path &path)
{
    std::error_code ec;

    for (auto it = vms.begin(); it != vms.end(); ++it) {

        if (fs::equivalent(it->second->getSourcePath(), path, ec)) {
            vms.erase(it);
            return true;
        }
    }

    return false;
}

void
VirtualMachineLibrary::rename(utl::UUID uuid, const string &name, bool uniquify)
{
    auto [vm, snap] = resolve(uuid);

    if (snap) {
        vm->renameSnapshot(uuid, name);
    } else {
        rename(*vm, name, uniquify);
    }
}

void
VirtualMachineLibrary::rename(VirtualMachine &vm, const string &name, bool uniquify)
{
    auto nameExists = [this](const std::string& s) {
        return std::any_of(vms.begin(), vms.end(), [&s](const auto& pair) {
            return pair.second && s == pair.second->getManifest().name;
        });
    };

    auto finalName = name;

    if (uniquify) {

        // Loop until we find a name that doesn't exist yet
        for (isize nr = 2; nameExists(finalName); nr++)
            finalName = name + "-" + std::to_string(nr);
    }

    vm.rename(finalName);
}