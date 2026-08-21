// -----------------------------------------------------------------------------
// This file is part of Silicium
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "SiObject.h"
#include "SVMFile.h"

using retro::vault::SVMFile;
using retro::vault::Manifest;
using retro::vault::SnapshotInfo;

class VirtualMachine : public SiObject {

    // The associated SVM file
    unique_ptr<SVMFile> svm;


    //
    // Initializing
    //

  public:

    explicit VirtualMachine(unique_ptr<SVMFile> svmFile) : svm(std::move(svmFile)) { }

    // Virtual machine factory
    static unique_ptr<VirtualMachine> make(const fs::path &path);


    //
    // Acessing the SVM
    //

  public:

    Manifest &getManifest() const { return svm->getManifest(); }

    // Re-reads the manifest (and already-extracted assets) from disk,
    // discarding whatever is currently held in memory. Used when another
    // process (e.g. a running SiC64 instance) has modified the SVM file.
    // The machine's UUID is deliberately preserved across this -- see the
    // implementation.
    void reload();

    const fs::path &getSourcePath() const { return svm->getSourcePath(); }
    const fs::path &root() const { return svm->root(); }

    bool isPreinstalled() const { return getManifest().isPreinstalled(); }
    bool isReadOnly() const { return svm->isReadOnly(); }
    bool isOutdated() const { return svm->isOutdated(); }

    void persist() const;
    void rename(const string &name);

    //
    // Managing snapshots
    //

    // Looks up a snapshot
    SnapshotInfo *lookupSnapshot(utl::UUID uuid);
    SnapshotInfo *lookupLatestSnapshot();

    // Changes the logical name of a snapshots
    void renameSnapshot(utl::UUID uuid, const string &name);

    // Deletes a snapshot
    bool deleteSnapshot(utl::UUID uuid);
    bool deleteSnapshot(const SnapshotInfo *info);
};