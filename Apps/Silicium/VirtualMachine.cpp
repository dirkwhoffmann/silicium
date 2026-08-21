// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "VirtualMachine.h"
#include "Logger.h"
#include <stdio.h>

unique_ptr<VirtualMachine>
VirtualMachine::make(const fs::path &path)
{
    return make_unique<VirtualMachine>(make_unique<SVMFile>(path));
}

void
VirtualMachine::reload()
{
    /* A machine's UUID is the key it is filed under in the library (see
     * VirtualMachineLibrary::addVirtualMachine), so it has to survive a
     * re-read. If the manifest on disk names a different one, this object no
     * longer matches its own key: lookups by that key would hand back a
     * machine reporting a different identity, and the sidebar -- which reads
     * the manifest, not the key -- would render two machines sharing one UUID.
     *
     * Overwriting the new UUID with the old one would paper over that, but it
     * only hides the damage: whatever rewrote the file is still out there, and
     * the next persist() would push the patched-up manifest back to disk. The
     * file is not what this machine was opened as any more, so refuse it.
     */
    auto uuid = getManifest().uuid;

    svm->readManifest();

    if (getManifest().uuid != uuid) {

        throw ImageError(ImageError::VM_CORRUPTED,
                         "the UUID of '" + getSourcePath().string() + "' no longer matches. "
                         "Expected " + uuid.toString() +
                         ", found " + getManifest().uuid.toString() + ".");
    }
}

SnapshotInfo *
VirtualMachine::lookupSnapshot(utl::UUID uuid)
{
    return getManifest().lookupSnapshot(uuid);
}

SnapshotInfo *
VirtualMachine::lookupLatestSnapshot()
{
    return getManifest().lookupLatestSnapshot();
}

void
VirtualMachine::persist() const
{
    LogTask task("Persisting virtual machine...");

    svm->persist();
}

void
VirtualMachine::rename(const string &name)
{
    LogTask task("Renaming virtual machine...");

    auto &manifest = getManifest();

    if (isReadOnly())
        throw ImageError(ImageError::VM_READ_ONLY);

    manifest.name = name;
    persist();
}

void
VirtualMachine::renameSnapshot(utl::UUID uuid, const string &name)
{
    LogTask task("Renaming snapshot...");

    auto &manifest = getManifest();

    if (auto *snap = manifest.lookupSnapshot(uuid)) {

        if (isReadOnly())
            throw ImageError(ImageError::VM_READ_ONLY);

        snap->name = name;
        persist();
    }
}

bool
VirtualMachine::deleteSnapshot(utl::UUID uuid)
{
    auto &manifest = getManifest();

    if (isReadOnly())
        throw ImageError(ImageError::VM_READ_ONLY);

    return deleteSnapshot(manifest.lookupSnapshot(uuid));
}

bool
VirtualMachine::deleteSnapshot(const SnapshotInfo *info)
{
    LogTask task("Deleting snapshot...");

    auto &manifest = getManifest();

    if (isReadOnly())
        throw ImageError(ImageError::VM_READ_ONLY);

    if (info) {

        auto binary = root() / SVMFile::snapshotDir / info->binary;
        auto screenshot = root() / SVMFile::snapshotDir / info->screenshot;

        if (manifest.removeSnapshot(info->uuid)) {

            // Remove snapshot files
            std::error_code ec;
            fs::remove(binary, ec);
            fs::remove(screenshot, ec);

            // Update the SVM
            persist();

            return true;
        }
    }

    return false;
}