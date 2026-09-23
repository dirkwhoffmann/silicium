// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "OnboardingController.h"

#include "Assets.h"
#include "AppController.h"
#include "Logger.h"
#include "SVMFile.h"
#include "RomManager.h"
#include "utl/abilities/Hashable.h"
#include "utl/io.h"
#include <QDir>
#include <QFile>
#include <fstream>

using utl::IOError;
using retro::vault::Platform;
using namespace retro::vault;

OnboardingController::OnboardingController(QObject *parent) : Controller(parent)
{
    buildPageList();
}

OnboardingController *
OnboardingController::instance()
{
    static OnboardingController *inst = new OnboardingController();
    return inst;
}

QString
OnboardingController::nextPage() const
{
    int idx = m_pageList.indexOf(m_page);
    if (idx >= 0 && idx < m_pageList.size() - 1) return m_pageList[idx + 1];
    return QString();
}

QString
OnboardingController::prevPage() const
{
    int idx = m_pageList.indexOf(m_page);
    if (idx > 0) return m_pageList[idx - 1];
    return QString();
}

void
OnboardingController::next()
{
    setPage(nextPage());
}

void
OnboardingController::prev()
{
    setPage(prevPage());
}

bool
OnboardingController::hasNextPage() const
{
    return !m_pageList.empty() && m_page != m_pageList.last();
}

bool
OnboardingController::hasPrevPage() const
{
    return !m_pageList.empty() && m_page != m_pageList.first();
}

QUrl
OnboardingController::platformIcon() const
{
    if (m_platform == "c64") return Assets::getIconUrl(Assets::Icon::C64Logo);
    if (m_platform == "amiga") return Assets::getIconUrl(Assets::Icon::AmigaLogo);

    return QUrl("");
}

void
OnboardingController::setPage(const QString &value)
{
    if (value != "" && value != m_page) {

        m_page = value;
        emit pageChanged();
    }
}

int
OnboardingController::index() const
{
    return m_pageList.indexOf(m_page);
}

void
OnboardingController::setIndex(int value)
{
    if (value >= 0 && value <= m_pageList.size()) {
        setPage(m_pageList[value]);
    }
}

void
OnboardingController::setName(const QString &value)
{
    if (value != m_name) {

        m_name = value;
        emit nameChanged();
    }
}

void
OnboardingController::setPlatform(const QString &value)
{
    if (value != m_platform) {

        m_platform = value;
        buildPageList();
        emit platformChanged();
    }
}

void
OnboardingController::setModelC64(const QString &value)
{
    if (value != m_modelC64) {

        m_modelC64 = value;
        emit modelC64Changed();
    }
}

void
OnboardingController::setRomC64(const QString &value)
{
    if (value != m_romC64) {

        m_romC64 = value;
        emit romC64Changed();
    }
}

void
OnboardingController::setModelAmiga(const QString &value)
{
    if (value != m_modelAmiga) {

        m_modelAmiga = value;
        emit modelAmigaChanged();
    }
}

void
OnboardingController::setRomAmiga(const QString &value)
{
    if (value != m_romAmiga) {

        m_romAmiga = value;
        emit romAmigaChanged();
    }
}

void
OnboardingController::buildPageList()
{
    QStringList flow;

    flow << "welcome";

    if (m_platform == "amiga") {

        flow << "amigaModel";
        flow << "amigaRoms";

    } else if (m_platform == "c64") {

        flow << "c64Model";
        flow << "c64Roms";
    }

    flow << "summary";

    if (m_pageList != flow) {

        m_pageList = flow;
    }
}

QUrl
OnboardingController::create(const QUrl &path)
{
    return create(path.toLocalFile());
}

QUrl
OnboardingController::create(const QString &path)
{
    return create(fs::path(path.toStdString()));
}

QUrl
OnboardingController::create(const fs::path &path)
{
    LogTask task("Creating new virtual machine...");

    // Create the full file name of the SVM
    fs::path svmPath = utl::makeUniquePath(utl::ensureExtension(path, SVMFile::suffix));

    try {

        // Create SVM on disk
        SVMFile svm(SVMFile::Create, svmPath);

        // Update the manifest
        auto &manifest    = svm.getManifest();
        manifest.name     = m_name.toStdString();
        manifest.platform = m_platform == "c64" ? Platform::C64 : Platform::AMIGA;

        // Create the workspace
        if (manifest.isAmiga()) {
            createAmigaWorkspace(svm);
        } else {
            createC64Workspace(svm);
        }

        // Save changes
        svm.persist();

    } catch (const std::exception &e) {

        emit showError("Failed to create virtual machine.", e.what());
        return QUrl();
    }

    return QUrl::fromLocalFile(QString::fromStdString(svmPath.string()));
}

void
OnboardingController::createC64Workspace(SVMFile &svm)
{
    createC64ConfigScript(svm, prepareWorkspaceFolder(svm) / "config.retrosh");
}

void
OnboardingController::createAmigaWorkspace(SVMFile &svm)
{
    const auto folder = prepareWorkspaceFolder(svm);

    /* The Roms are copied into the workspace rather than referenced where they
     * happen to sit today: an SVM is meant to be self-contained, so that
     * moving it to another machine (or emptying the Rom library) leaves a
     * machine that still boots. 'rom.bin' and 'ext.bin' are the names
     * Amiga::saveWorkspace() uses, so a later save overwrites these rather
     * than leaving a second copy behind under a different name.
     *
     * Which Roms are bundled is decided in SiAmiga (see
     * SiAmController::initialize(), which installs the same AROS pair) --
     * keep the two in step.
     */
    if (m_romAmiga == "aros") {

        // AROS replaces Kickstart in two parts, and is useless without both.
        installBundledRom(CRC32_AROS_20260820, folder / "rom.bin");
        installBundledRom(CRC32_AROS_20260820_EXT, folder / "ext.bin");

    } else {

        // DiagROM occupies the Kickstart socket on its own.
        installBundledRom(CRC32_DIAG13, folder / "rom.bin");
    }

    createAmigaConfigScript(svm, folder / "config.retrosh");
}

void
OnboardingController::installBundledRom(u32 crc, const fs::path &dest)
{
    /* The Roms are embedded as Qt resources (see qt_add_resources(silicium,
     * "assets_files") in Apps/CMakeLists.txt), which std::filesystem cannot
     * read and RomManager therefore cannot scan -- the Hub has no Rom library
     * of its own the way SiAmiga does. So the resource folder is walked here
     * and the wanted Rom picked out by checksum rather than by file name: a
     * renamed or re-dated asset then fails loudly instead of quietly
     * installing the wrong Rom.
     */
    for (const auto &info : QDir(":/Roms").entryInfoList(QDir::Files)) {

        QFile file(info.filePath());
        if (!file.open(QIODevice::ReadOnly)) continue;

        const QByteArray data = file.readAll();
        const auto *addr = reinterpret_cast<const u8 *>(data.constData());

        if (utl::Hashable::crc32(addr, isize(data.size())) != crc) continue;

        std::ofstream os(dest, std::ios::binary);
        if (!os) throw IOError(IOError::FILE_CANT_CREATE, dest);

        os.write(data.constData(), std::streamsize(data.size()));
        if (!os) throw IOError(IOError::FILE_CANT_CREATE, dest);

        return;
    }

    throw IOError(IOError::FILE_NOT_FOUND, dest.filename());
}

fs::path
OnboardingController::prepareWorkspaceFolder(SVMFile &svm)
{
    /* The SVM was created moments ago and has nothing in it but a manifest,
     * so the workspace folder has to be brought into being before the config
     * script can be written into it.
     */
    const auto folder = svm.root() / SVMFile::workspaceDir;

    std::error_code ec;
    fs::create_directories(folder, ec);
    if (ec) throw IOError(IOError::DIR_CANT_CREATE, folder);

    return folder;
}

void
OnboardingController::createC64ConfigScript(SVMFile &svm, const fs::path &scriptFile)
{
    std::ofstream os(scriptFile);
    if (!os) throw IOError(IOError::FILE_CANT_CREATE, scriptFile);

    //
    // Header
    //

    os << "# Created with Silicium " << AppController::version() << std::endl;
    os << std::endl;

    //
    // Model
    //

    const std::unordered_map<string, string> table = {
        { "early", "c64 init PAL_OLD" },
        { "c64",   "c64 init PAL"     }
    };

    if (auto it = table.find(m_modelC64.toStdString()); it != table.end()) {
        os << it->second << std::endl;
    }

    //
    // ROMs
    //

    os << "mem load openroms" << std::endl;
}

void
OnboardingController::createAmigaConfigScript(SVMFile &svm, const fs::path &scriptFile)
{
    std::ofstream os(scriptFile);
    if (!os) throw IOError(IOError::FILE_CANT_CREATE, scriptFile);

    //
    // Header
    //

    os << "# Created with Silicium " << AppController::version() << std::endl;
    os << std::endl;

    //
    // ROM
    //

    // Names the files createAmigaWorkspace() has just put next to this script.
    // They resolve against the workspace folder, which Amiga::loadWorkspace()
    // installs as the search path before running us.
    os << "mem load rom rom.bin" << std::endl;
    if (m_romAmiga == "aros") os << "mem load ext ext.bin" << std::endl;
    os << std::endl;

    /* Chip revisions and memory.
     *
     * The values come from the core's own model presets (see
     * Amiga::set(ConfigScheme) -- A1000_OCS_1MB, A500_OCS_1MB, A500_PLUS_1MB,
     * A1200_2MB), which is the one place in the tree that says what a given
     * machine is made of. The A2000 has no preset of its own; it is an A500
     * with ECS Agnus and a Fast RAM board, which is what the entry below
     * spells out.
     */

    if (m_modelAmiga == "a500") {
        os << "cpu set REVISION 68000" << std::endl;
        os << "cpu set OVERCLOCKING 0" << std::endl;
        os << "agnus set REVISION OCS" << std::endl;
        os << "denise set REVISION OCS" << std::endl;
        os << "mem set CHIP_RAM 512" << std::endl;
        os << "mem set SLOW_RAM 512" << std::endl;
        os << "mem set FAST_RAM 0" << std::endl;
        os << "mem set BUS_WIDTH 16" << std::endl;
    }

    if (m_modelAmiga == "a1000") {
        // OCS_OLD is the MOS 8367 the A1000 shipped with, not a typo for OCS.
        os << "cpu set REVISION 68000" << std::endl;
        os << "cpu set OVERCLOCKING 0" << std::endl;
        os << "agnus set REVISION OCS_OLD" << std::endl;
        os << "denise set REVISION OCS" << std::endl;
        os << "mem set CHIP_RAM 512" << std::endl;
        os << "mem set SLOW_RAM 512" << std::endl;
        os << "mem set FAST_RAM 0" << std::endl;
        os << "mem set BUS_WIDTH 16" << std::endl;
    }

    if (m_modelAmiga == "a2000") {
        os << "cpu set REVISION 68000" << std::endl;
        os << "cpu set OVERCLOCKING 0" << std::endl;
        os << "agnus set REVISION ECS_1MB" << std::endl;
        os << "denise set REVISION OCS" << std::endl;
        os << "mem set CHIP_RAM 512" << std::endl;
        os << "mem set SLOW_RAM 512" << std::endl;
        os << "mem set FAST_RAM 8192" << std::endl;
        os << "mem set BUS_WIDTH 16" << std::endl;
    }

    if (m_modelAmiga == "a500+") {
        os << "cpu set REVISION 68000" << std::endl;
        os << "cpu set OVERCLOCKING 0" << std::endl;
        os << "agnus set REVISION ECS_2MB" << std::endl;
        os << "denise set REVISION ECS" << std::endl;
        os << "mem set CHIP_RAM 1024" << std::endl;
        os << "mem set SLOW_RAM 0" << std::endl;
        os << "mem set FAST_RAM 0" << std::endl;
        os << "mem set BUS_WIDTH 16" << std::endl;
    }

    if (m_modelAmiga == "a1200") {
        // 68EC020 is the fastest CPU the core models; there is no plain 68020.
        os << "cpu set REVISION 68EC020" << std::endl;
        os << "cpu set OVERCLOCKING 2" << std::endl;
        os << "agnus set REVISION AGA" << std::endl;
        os << "denise set REVISION AGA" << std::endl;
        os << "mem set CHIP_RAM 2048" << std::endl;
        os << "mem set SLOW_RAM 0" << std::endl;
        os << "mem set FAST_RAM 0" << std::endl;
        os << "mem set BUS_WIDTH 32" << std::endl;
    }

    //
    // Video format
    //

    os << "amiga set VIDEO_FORMAT PAL" << std::endl;
}
