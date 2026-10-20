// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "config.h"
#include "SiObject.h"
#include "VirtualMachine.h"
#include <ranges>

class VirtualMachineLibrary : public SiObject {

    // Virtual machine database
    std::unordered_map<utl::UUID, std::unique_ptr<VirtualMachine>> vms;

  public:

    VirtualMachineLibrary();

    // Returns the number of managed virtual machines
    isize numVirtualMachines() const { return (isize)vms.size(); }


    //
    // Returning a view of raw pointers
    //

    auto getVirtualMachines()
    {
        return vms | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }

    auto getVirtualMachines() const
    {
        return vms | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }

    auto getVirtualMachines(auto predicate)
    {
        return vms
               | std::views::filter(predicate)
               | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }

    auto getVirtualMachines(auto predicate) const
    {
        return vms
               | std::views::filter(predicate)
               | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }


    //
    // Searching the database
    //

    // Resolves a given UUID
    std::pair<VirtualMachine *, SnapshotInfo *> resolve(utl::UUID uuid);
    std::pair<const VirtualMachine *, const SnapshotInfo *> resolve(utl::UUID uuid) const;

    // Looks up a virtual machine with a given UUID
    VirtualMachine *lookupVirtualMachine(utl::UUID uuid);
    VirtualMachine *lookupVirtualMachine(const string &uuid);
    const VirtualMachine *lookupVirtualMachine(utl::UUID uuid) const;
    const VirtualMachine *lookupVirtualMachine(const string &uuid) const;

    // Looks up a virtual machine with a given SVM path
    VirtualMachine *lookupVirtualMachine(const fs::path &path);
    const VirtualMachine *lookupVirtualMachine(const fs::path &path) const;

    // Looks up a snapshot with the given UUID
    SnapshotInfo *lookupSnapshot(utl::UUID uuid);
    SnapshotInfo *lookupSnapshot(const string &uuid);

    // Returns the UUIDs all virtual machine with a matching predicate
    vector<utl::UUID> collect(const std::function<bool(const VirtualMachine &)> &predicate) const;


    //
    // Adding and removing virtual machines
    //

    /* Adds an existing virtual machine.
     *
     * - Throws an exception if a machine with the same path exists.
     * - Throws an exception if a machine with the same UUID exists.
     * - Returns a pointer to the added machine.
     */
    VirtualMachine *addVirtualMachine(const fs::path &path);

    /* Clones an existing virtual machine.
     *
     * - Creates a new virtual machine at clonePath with the contents of another
     *   machine. After that, the machine is added to the library.
     * - Returns a pointer to the cloned machine.
     */
    VirtualMachine *cloneVirtualMachine(utl::UUID uuid, const fs::path &clonePath);
    VirtualMachine *cloneVirtualMachine(const fs::path &path, const fs::path &clonePath);

    // Removes a virtual machine from the database
    bool removeVirtualMachine(utl::UUID uuid);
    bool removeVirtualMachine(const string &uuid);
    bool removeVirtualMachine(const fs::path &path);

    // Removes all virtual machines
    void clear() { vms.clear(); }

    // Renames a virtual machine
    void rename(utl::UUID uuid, const string &name, bool uniquify = false);
    void rename(VirtualMachine &vm, const string &name, bool uniquify = false);
};