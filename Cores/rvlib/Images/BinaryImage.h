// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Images/AnyImage.h"
#include "utl/abilities/Compressible.h"
#include "utl/storage/BackedBuffer.h"

namespace retro::vault {

class LinearDevice;

/* An image that is a contiguous block of bytes.
 *
 * This is what almost every format in this library is: a floppy image, a hard
 * drive image, an executable. Everything below -- sizing, copying, hashing,
 * dumping, exporting -- is a statement about those bytes.
 *
 * The bytes live in a utl::BackedBuffer. An image read from a file sits on
 * top of that file and loads its bytes as they are asked for, so opening a
 * hard drive image of several gigabytes costs next to nothing until its
 * blocks are used. Images built in memory -- from a size, from bytes, or from
 * a device -- have no backing and hold all of their bytes.
 *
 * What lazy loading means for an image read from a file:
 *
 * - The image keeps the file open for as long as it lives.
 * - It is not a snapshot. Parts not loaded yet are read when first asked for,
 *   so nobody else may change the file in the meantime. Writing the image to
 *   its own file (save(), writeToFile()) is safe; that case is handled.
 *
 * The bytes are private. Everything, subclasses included, reaches them through
 * two views:
 *
 *   byteView()         read-only
 *   mutableByteView()  writable. Ask for it only when writing: the region
 *                      counts as modified from then on.
 *
 * Images cannot be copied, because two copies would share one backing.
 *
 * Compression:
 *
 * An image knows nothing about compression. It only meets it when it is
 * created from, or written to, a compressed byte stream: the functions that
 * do so take a utl::Compressor, which defaults to NONE. A compressed file is
 * uncompressed into memory on the way in, so an image created from one is
 * memory backed and remembers nothing about the file. On the way out, the
 * bytes are compressed before they are written. Which file name stands for
 * which compressor is not decided here (see AnyImage::compressorFor()).
 */
class BinaryImage : public AnyImage, public utl::Dumpable {

    // The raw data of this file
    utl::BackedBuffer data;


    //
    // Initializing
    //

public:

    /* Creates an image of the given size.
     *
     * The image is initialized with all zeroes.
     */
    void init(isize len);

    /* Creates an image holding a copy of the given bytes.
     *
     * If a compressor is given, the bytes are the compressed form of the
     * image and are uncompressed first.
     */
    void init(const u8 *buf, isize len, utl::Compressor compressor = utl::Compressor::NONE);

    /* Creates an image on top of a file, loading its contents lazily.
     *
     * A compressed file cannot be read in pieces. If a compressor is given,
     * the file is therefore uncompressed in full, and the image holds the
     * result in memory: it is MEMORY_BACKED, has no path, and save() has
     * nowhere to write to (use saveAs() with the compressor).
     */
    void init(const fs::path& p, utl::Compressor compressor = utl::Compressor::NONE);

    /* Initializes the image with the contents of a device.
     *
     * The device is asked for its bytes rather than handing over a pointer to
     * them, so this works for any device, including ones that do not keep the
     * whole image in memory. All of them are copied.
     */
    void init(const LinearDevice& device);

protected:

    // Changes the size of the image, keeping its contents
    void resize(isize len);


    //
    // Methods from Hashable
    //

public:

    u64 hash(HashAlgorithm algorithm) const override {
        return byteView(0, getSize()).hash(algorithm);
    }


    //
    // Methods from Dumpable
    //

public:

    Dumpable::DataProvider dataProvider() const override {
        return byteView(0, getSize()).dataProvider();
    }


    //
    // Querying meta information
    //

public:

    isize getSize() const { return data.size(); }
    bool empty() const { return data.empty(); }

    /* Returns where the bytes of the image live
     *
     * FILE_BACKED if the image sits on top of the file it was read from or
     * saved to, MEMORY_BACKED if it was built in memory or let go of its file
     * (see detach()).
     */
    StorageMode getStorageMode() const {
        return data.backed() ? StorageMode::FILE_BACKED : StorageMode::MEMORY_BACKED;
    }

    /* Returns true if the image holds changes the file does not have yet
     *
     * A memory-backed image has no file to compare itself to; for such an
     * image, the answer says nothing (see save()).
     */
    bool modified() const { return data.dirty(); }


    //
    // Accessing data
    //

public:

    // Returns a view of bytes [offset, offset + len), which must lie within the image
    utl::ByteView byteView(isize offset, isize len) const;
    utl::MutableByteView mutableByteView(isize offset, isize len);

    /* Loads the image into memory and lets go of its file.
     *
     * The image keeps its contents and forgets where they came from: it is
     * then an image built in memory, like any other, and the file is no
     * longer touched. Modifications that were never saved are kept.
     */
    void detach();

    // Copies the file contents into a buffer
    virtual void copy(u8 *dst, isize offset, isize len) const;
    virtual void copy(u8 *dst, isize offset = 0) const;


    //
    // Exporting
    //

public:

    /* Writes the modifications back to the file the image came from.
     *
     * Only what has been modified is written (see utl::BackedBuffer::persist).
     * An image that was built in memory has no file to go back to; for such
     * an image, save() is saveAs(path), which fails if there is no path.
     */
    void save() override;

    /* Writes the entire image to a new file and continues on top of it.
     *
     * Later calls to save() go to the new file. The file is written before
     * the image switches over, so if writing fails, nothing changes. Views
     * taken before the call must not be used after it.
     *
     * A compressed file cannot be built on. If a compressor is given, the
     * file is written compressed and the image is left in memory, as if it
     * had been created from that file (see init()).
     */
    void saveAs(const fs::path &path, utl::Compressor compressor = utl::Compressor::NONE);

    /* Writes bytes [offset, offset + len), or the entire image, to a stream or
     * a file, compressed if a compressor is given. The result is the number
     * of bytes written, which is the compressed size in that case.
     */
    virtual isize writeToStream(std::ostream &stream,
                                utl::Compressor compressor = utl::Compressor::NONE) const;
    virtual isize writeToFile(const fs::path &path,
                              utl::Compressor compressor = utl::Compressor::NONE) const;

    virtual isize writeToStream(std::ostream &stream, isize offset, isize len,
                                utl::Compressor compressor = utl::Compressor::NONE) const;
    virtual isize writeToFile(const fs::path &path, isize offset, isize len,
                              utl::Compressor compressor = utl::Compressor::NONE) const;

private:

    // Called at the end of init()
    virtual void didInitialize() {};
};

}
