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

    /* Drops every machine, releasing the SVM files they own.
     *
     * Called on shutdown so the SVMFile destructors run and take their working
     * folders with them. HubController is a deliberately leaked singleton, so
     * nothing else ever destroys this.
     */
    void clear() { vms.clear(); }

    // Returns a view of raw pointers (updated to extract .second from the map pair)
    auto getVirtualMachines()
    {
        return vms | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }

    auto getVirtualMachines() const
    {
        return vms | std::views::transform([](const auto &pair) { return pair.second.get(); });
    }

    // Updated predicates to match map pairs
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

    utl::UUID lookupVirtualMachineUUID(utl::UUID uuid) const;
    utl::UUID lookupVirtualMachineUUID(const string &uuid) const;
    utl::UUID lookupVirtualMachineUUID(const fs::path &path) const;

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

    // Renames a virtual machine
    void rename(utl::UUID uuid, const string &name, bool uniquify = false);
    void rename(VirtualMachine &vm, const string &name, bool uniquify = false);
};