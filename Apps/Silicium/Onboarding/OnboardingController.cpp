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
#include "utl/io.h"
#include <fstream>

using utl::IOError;
using retro::vault::Platform;

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
    fs::path svmPath = utl::makeUniquePath(utl::ensureExtension(path, ".svm"));

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
    createAmigaConfigScript(svm, prepareWorkspaceFolder(svm) / "config.retrosh");
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

    /* Model and ROM selection (m_modelAmiga, m_romAmiga) have no RetroShell
     * equivalent yet -- this codebase has no Amiga emulation core (see
     * Cores/, which holds VCCore for the C64 only), so there is nothing yet
     * to emit a command for. None of the Amiga showcases ship a
     * config.retrosh either, which is consistent with this: there is
     * currently nothing meaningful to put in one.
     */
    os << "# Add custom configurations here..." << std::endl;
}
