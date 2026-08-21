// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Assets.h"
#include "HubController.h"
#include "AppController.h"
#include "Logger.h"
#include "Images/ImageError.h"

// #include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>

using retro::vault::ImageError;
using retro::vault::PlatformEnum;

HubController::HubController() : Controller()
{
    // Propagate preference changes to running SiC64 instances. Silicium and
    // SiC64 share one settings file, so rather than shipping values we tell
    // each instance which group changed and let it re-read that group from
    // disk (see broadcastPrefsChange and Preferences::reloadGroup).
    auto &prefs = preferences();
    connect(&prefs, &Preferences::generalPrefsChanged,    this, [this] { broadcastPrefsChange("general"); });
    connect(&prefs, &Preferences::appearancePrefsChanged, this, [this] { broadcastPrefsChange("appearance"); });
    connect(&prefs, &Preferences::controlsPrefsChanged,   this, [this] { broadcastPrefsChange("controls"); });
    connect(&prefs, &Preferences::devicesPrefsChanged,    this, [this] { broadcastPrefsChange("devices"); });
    connect(&prefs, &Preferences::screenshotPrefsChanged, this, [this] { broadcastPrefsChange("screenshots"); });
    connect(&prefs, &Preferences::developerPrefsChanged,  this, [this] { broadcastPrefsChange("developer"); });
    connect(&prefs, &Preferences::miscPrefsChanged,       this, [this] { broadcastPrefsChange("misc"); });

    /* Rebuild the sidebar whenever the options that shape it change. The
     * general group carries vmSortMode and hideShowcases, both of which
     * HubSidebarModel::rebuild() reads; nothing else in the
     * group affects the sidebar, but rebuilding for those too costs a model
     * reset on a settings toggle and keeps this free of a second list to
     * maintain. Expansion state lives outside the model (see
     * HubSidebarModel::expanded) and survives the reset, as does the
     * selection.
     */
    connect(&prefs, &Preferences::generalPrefsChanged, this, [this] { m_sidebarController.rebuild(); });
}

HubController::~HubController()
{

}

HubController &
HubController::instance()
{
    static HubController *inst = new HubController();
    return *inst;
}

void
HubController::start() {

    try {

        LogTask task("Starting HubController...");

        // Initialize the VM library
        setupShowcases();
        setupUserVMs();

        // Update the sidebar model
        m_sidebarController.rebuild();
        commitLibrary();

    } catch (std::exception &e) {

        emit showError("Failed to start the hub controller.", e.what());
    }
}

void
HubController::stop()
{
    LogTask task("Stopping HubController...");
    writeVmList();

    /* Release the machines, which is what deletes their root folders (see
     * ~SVMFile). It has to happen here rather than being left to the process
     * exit: instance() hands out a leaked 'new', so this object's members are
     * never destroyed. Strictly after writeVmList(), which reads the library.
     *
     * Skipped while instances are still up. Since launch() hands them our
     * unpacked root rather than the archive, dropping the library now would
     * delete the tree a running emulator is working on. Leaving those roots
     * behind is the lesser evil -- they are temp directories, and the machines
     * still hold unsaved state we have no business destroying underneath them.
     */
    if (m_sic64Processes.empty()) {

        library.clear();

    } else {

        qCWarning(siLog) << "Keeping" << m_sic64Processes.size()
                         << "root folder(s): instances are still running";
    }
}

void
HubController::setupUserVMs()
{
    auto list = readVmList();

    for (const QString &str : list) {

        auto url = QUrl::fromLocalFile(str);

        try {

            auto path = fs::path(url.toLocalFile().toStdString());
            library.addVirtualMachine(path);

        } catch (std::exception &e) {

            qCWarning(siLog) << "Failed to add VM " << url;
            qCWarning(siLog) << e.what();
        }
    }
}

Manifest *
HubController::getManifest()
{
    if (auto *vm = library.lookupVirtualMachine(m_vUUID)) {
        return &vm->getManifest();
    }
    return nullptr;
}

void
HubController::setupShowcases()
{
    m_showcases = fs::temp_directory_path() / "Showcases";

    /* Start from scratch. Assets::extract() overwrites but never deletes, so
     * wiping first is what keeps a showcase removed from the resources from
     * lingering in temp across runs.
     */
    fs::remove_all(m_showcases);

    Assets::extract(":/Showcases", m_showcases);

    // Register all showcases
    for (const auto &entry : fs::directory_iterator(m_showcases)) {

        if (entry.is_directory() && entry.path().extension() == ".svm") {

            try {

                library.addVirtualMachine(entry.path());

            } catch (std::exception &e) {

                qCWarning(siLog) << "Failed to add VM " << entry.path().string();
                qCWarning(siLog) << e.what();
            }
        }
    }
}

void
HubController::setPanel(const QString &value)
{
    if (m_panel != value) {

        m_panel = value;
        emit panelChanged();
    }
}

void
HubController::setOverlay(const QString &value)
{
    if (m_overlay != value) {

        m_overlay = value;
        emit overlayChanged();
    }
}

void
HubController::validateSelection()
{
    if (m_vUUID && m_sUUID && !library.lookupSnapshot(m_sUUID)) {
        select(m_vUUID);
    } else if (m_vUUID && !library.lookupVirtualMachine(m_vUUID)) {
        select(UUID(0));
    }
}

QString
HubController::selected() const
{
    UUID uuid = m_sUUID ? m_sUUID : m_vUUID;
    return uuid ? QString::fromStdString(uuid.toString()) : QString("");
}

void
HubController::setSelected(const QString &value)
{
    select(UUID::fromString(value.toStdString()));
}

void
HubController::select(UUID uuid)
{
    try {

    auto [vm, snap] = library.resolve(uuid);

    auto toPath = [](const std::filesystem::path &path) -> QString {
        return QString::fromStdString(path.string());
    };
    auto toUrl = [&toPath](const std::filesystem::path &path) -> QString {
        return "file://" + toPath(path);
    };

    m_vUUID = {};
    m_sUUID = {};
    m_vInfo.clear();
    m_sInfo.clear();

    if (vm) {

        //
        // Collect information about the selected machine
        //

        auto m = vm->getManifest();
        const auto *dateString = "yyyy-MM-dd hh:mm:ss";
        auto engine = m.isAmiga() ? Assets::Icon::PoweredByVA : Assets::Icon::PoweredByVC;

        m_vUUID = m.uuid;

        m_vInfo["svm"]           = toUrl(vm->getSourcePath());
        m_vInfo["svmpath"]       = toPath(vm->getSourcePath());
        m_vInfo["version"]       = QString::fromStdString(m.version);
        m_vInfo["uuid"]          = QString::fromStdString(m.uuid.toString());
        m_vInfo["platform"]      = QString::fromUtf8(PlatformEnum::key(m.platform));
        m_vInfo["name"]          = QString::fromStdString(m.name);
        m_vInfo["engine"]        = Assets::getIconUrl(engine);
        m_vInfo["created"]       = QDateTime::fromSecsSinceEpoch(m.created).toString(dateString);
        m_vInfo["modified"]      = QDateTime::fromSecsSinceEpoch(m.modified).toString(dateString);
        m_vInfo["compatible"]    = m.isCompatible();
        m_vInfo["preinstalled"]  = m.isPreinstalled();
        m_vInfo["readonly"]      = vm->isReadOnly();
        m_vInfo["startup"]       = QString::fromStdString(m.startup.string());
        m_vInfo["author"]        = QString::fromStdString(m.meta ? m.meta->author : "");
        m_vInfo["description"]   = QString::fromStdString(m.meta ? m.meta->description : "");

        QVariantList metaList;

        if (m.meta) {

            auto publish = [&](const char *key, const string &value) {

                if (value.empty()) return;

                QVariantMap item;
                item["key"]   = QString::fromUtf8(key);
                item["value"] = QString::fromStdString(value);
                metaList.append(item);
            };

            publish("Author", m.meta->author);
            publish("Description", m.meta->description);
        }

        m_vInfo["meta"] = metaList;

        if (const auto screenshot = vm->root() / SVMFile::workspaceDir / m.screenshot;
            !m.screenshot.empty() && fs::exists(screenshot)) {

            m_vInfo["screenshot"] = QString::fromStdString(m.screenshot.string());
            m_vInfo["screenshotUrl"] = toUrl(screenshot);
        }

        //
        // Collect runtime information, if the machine in active
        //

        m_vInfo["state"] = VMStateEnum::key(lookupState(uuid));

        //
        // Collect information about the selected snapshot
        //

        if (snap) {

            m_sUUID = snap->uuid;

            m_sInfo["version"]       = QString::fromStdString(snap->version);
            m_sInfo["uuid"]          = QString::fromStdString(snap->uuid.toString());
            /* This used to be synthesized from the snapshot type ("Hibernation
             * State" / "User Snapshot"), which ignored the name the user can
             * set via renameSnapshot(). With one type there is nothing left to
             * synthesize, so show the real name and fall back to a generic
             * label while it is still unset (saveSnapshot does not assign one).
             */
            m_sInfo["name"]          = snap->name.empty() ?
                                       QString("Snapshot") :
                                       QString::fromStdString(snap->name);
            m_sInfo["platform"]      = QString::fromUtf8(PlatformEnum::key(snap->platform));
            m_sInfo["created"]       = QDateTime::fromSecsSinceEpoch(snap->created).toString(dateString);
            m_sInfo["modified"]      = QDateTime::fromSecsSinceEpoch(snap->modified).toString(dateString);

            if (const auto screenshot = vm->root() / SVMFile::snapshotDir / snap->screenshot;
                !snap->screenshot.empty() && fs::exists(screenshot)) {

                m_sInfo["screenshot"]    = QString::fromStdString(snap->screenshot.string());
                m_sInfo["screenshotUrl"] = toUrl(screenshot);
            }

            m_sInfo["binary"]        = QString::fromStdString(snap->binary.string());
            m_sInfo["compatible"]    = snap->isCompatible();
        }
    }

    emit selectionChanged();

    } catch (std::exception &e) {

        emit showError("Failed to select virtual machine.", e.what());
    }
}

bool
HubController::vIsSelected(const QString &uuid) const
{
    return m_vInfo.value("uuid").toString() == uuid;
}

bool
HubController::sIsSelected(const QString &uuid) const
{
    return m_sInfo.value("uuid").toString() == uuid;
}

/*
bool
HubController::isSelected(const QString &uuid) const
{
    return vIsSelected(uuid) || sIsSelected(uuid);
}
*/
/*
void
HubController::select(const QString &quuid)
{
    select(UUID::fromString(quuid.toStdString()));
}

void
HubController::select(UUID uuid)
{


    emit vmSelected();
}
*/

void
HubController::rename(const QString &quuid, const QString &qname)
{
    try {

        auto uuid = UUID::fromString(quuid.toStdString());
        auto name = qname.toStdString();

        library.rename(uuid, name);
        m_sidebarController.refresh(uuid);

        /* 'uuid' may name either the machine or one of its snapshots, and
         * either way it is the machine's SVM that was rewritten -- so resolve
         * back to the owner before telling the running instance.
         */
        if (auto [vm, snap] = library.resolve(uuid); vm) {
            notifySvmChanged(vm->getManifest().uuid);
        }

    } catch (std::exception &e) {

        emit showError("Failed to rename virtual machine.", e.what());
    }
}

bool
HubController::remove(const QString &quuid)
{
    try {

        bool success = false;
        auto uuid = UUID::fromString(quuid.toStdString());

        if (auto [vm, snap] = library.resolve(uuid); vm) {

            if (snap) {

                /* Remove snapshot. Read the owner's UUID before the delete:
                 * 'snap' dangles once the entry is gone, and 'uuid' is the
                 * snapshot's, not the machine's.
                 */
                auto vUUID = vm->getManifest().uuid;

                success = vm->deleteSnapshot(uuid);
                if (success) notifySvmChanged(vUUID);

            } else {

                // Remove virtual machine
                if (isOpen(uuid)) throw ImageError(ImageError::VM_RUNNING);
                success = library.removeVirtualMachine(uuid);
            }

            m_sidebarController.validate();
            validateSelection();
        }
        return success;

    } catch (std::exception &e) {

        emit showError("Failed to remove virtual machine.", e.what());
        return false;
    }
}

/*
bool
HubController::removeVM(UUID uuid)
{

}

bool
HubController::removeSnapshot(UUID uuid)
{

}
*/

int
HubController::vCount() const
{
    return library.numVirtualMachines();
}

int
HubController::sCount() const
{
    if (auto *vm = library.lookupVirtualMachine(m_vUUID)) {
        return vm->getManifest().numSnapshots();
    }
    return 0;
}

vector<UUID>
HubController::openVMs() const
{
    std::vector<UUID> result;

    for (const auto &sic64 : m_sic64Processes) {
        result.push_back(sic64.vUUID);
    }

    return result;
}

const HubController::SiC64Process *
HubController::findSiC64Process(UUID uuid) const
{
    for (const auto &sic64 : m_sic64Processes) {
        if (sic64.vUUID == uuid) return &sic64;
    }

    return nullptr;
}

VMState
HubController::lookupState(UUID uuid) const
{
    if (auto *sic64 = findSiC64Process(uuid)) return sic64->state;

    return VMState::HIBERNATED;
}

void
HubController::commitLibrary()
{
    // Persist all changes
    writeVmList();

    // Signal the change
    emit libraryChanged();
}

QStringList
HubController::readVmList() const
{
    return preferences().readVmList();
}

void
HubController::writeVmList()
{
    QStringList vmList;

    for (auto *vm : library.getVirtualMachines()) {

        // Skip all preinstalled machines. They ship with the app and are
        // registered on every launch (see setupShowcases), so recording them
        // here would only invite duplicates.
        if (vm->isPreinstalled()) continue;

        vmList.append(QString::fromStdString(vm->getSourcePath().string()));
    }

    preferences().writeVmList(vmList);
}

QString
HubController::addVM(const QUrl &url)
{
    try {

        auto path = fs::path(url.toLocalFile().toStdString());

        if (auto *vm = library.addVirtualMachine(path)) {

            // Rebuild the sidebar model
            m_sidebarController.rebuild();

            // Persist the change
            commitLibrary();

            return QString::fromStdString(vm->getManifest().uuid.toString());
        }

    } catch (const std::exception &e) {

        emit showError("Failed to Add Virtual Machine", e.what());
    }

    return QString::fromStdString(UUID().toString());
}

QString
HubController::cloneVM(const QString &quuid, const QUrl &cloneUrl)
{
    try {

        auto clonePath = fs::path(cloneUrl.toLocalFile().toStdString());
        auto uuid = UUID::fromString(quuid.toStdString());

        if (auto *vm = library.cloneVirtualMachine(uuid, clonePath)) {

            // Assign a unique name
            library.rename(*vm, clonePath.stem().string(), true);

            // Rebuild the sidebar model
            m_sidebarController.rebuild();

            // Persist the change
            commitLibrary();

            return QString::fromStdString(vm->getManifest().uuid.toString());
        }

    } catch (const std::exception &e) {

        emit showError("Failed to Clone Virtual Machine", e.what());
    }

    return QString::fromStdString(UUID().toString());
}

void
HubController::open()
{
    open(m_vUUID, m_sUUID);
}

void
HubController::open(const QString &vQUUID, const QString &sQUUID)
{
    open(UUID::fromString(vQUUID.toStdString()), UUID::fromString(sQUUID.toStdString()));
}
void
HubController::open(UUID vUUID, UUID sUUID)
{
    try {

        LogTask task("Opening virtual machine...");

        if (auto *sic64 = findSiC64Process(vUUID)) {

            qCDebug(siLog) << "Machine already running, raising its window.";
            sendRpc(sic64->process, "raise");

            if (sUUID) {
                sendRpc(sic64->process, "loadSnapshot", QString::fromStdString(sUUID.toString()));
            }

        } else {

            launch(vUUID, sUUID);
        }

    } catch (const std::exception &e) {

        emit showError("Failed to open virtual machine", e.what());
    }
}

QProcess *
HubController::createProcess(UUID vUUID, UUID sUUID)
{
    auto *process = new QProcess(this);

    // SiC64 runs its RPC server on the stdio transport, so JSON-RPC
    // packets arrive on the process's stdout. State changes come in
    // as newline-terminated "vmState" notifications -- pick them out
    // to keep our tracked state (and the sidebar icon) in sync.
    // Everything that doesn't parse as JSON (debug prints etc.) is
    // passed on to the log.
    connect(process, &QProcess::readyReadStandardOutput, this, [this, process, vUUID]() {

        while (process->canReadLine()) {

            const QString line = QString::fromUtf8(process->readLine()).trimmed();
            if (line.isEmpty()) continue;

            QJsonParseError parseError;
            const auto doc = QJsonDocument::fromJson(line.toUtf8(), &parseError);

            if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {

                // qCDebug(siLog).noquote() << "SiC64:" << line;
                continue;
            }

            // Surface received RPC traffic in the logger window.
            qCDebug(siLog).noquote() << "RPC: Received" << line;

            /* Nothing above us can handle this: we are inside a slot,
             * so letting it escape would take down the event loop.
             * The packets that get here report real trouble in a
             * running machine (a reload finding a foreign UUID, say),
             * which the user has to know about -- logging alone would
             * leave the Hub looking healthy while it is not.
             */
            try {
                processRpcPacket(process, vUUID, doc.object());
            } catch (const std::exception &e) {
                qCWarning(siLog).noquote() << "RPC error:" << e.what();
                emit showError("The emulator reported a problem.", e.what());
            }

        }
    });

    connect(process, &QProcess::readyReadStandardError, this, [process]() {
        qCWarning(siLog).noquote() << "SiC64 (stderr):" << QString::fromUtf8(process->readAllStandardError());
    });

    connect(process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        emit showError("Failed to launch SiC64", QString::number(error));
    });

    if (sUUID) {

        // Writing to the process's stdin before it has actually started
        // isn't guaranteed to arrive, so defer this until Qt confirms the
        // process is up -- the packet then sits in the pipe until SiC64's
        // RPC server (enabled by the first --exec commands in launch())
        // starts reading it, so it's safe to send this before that point.
        connect(process, &QProcess::started, this, [this, process, sUUID]() {
            sendRpc(process, "loadSnapshot", QString::fromStdString(sUUID.toString()));
        });
    }

    connect(process, &QProcess::finished, this, [this, process, vUUID](int exitCode, QProcess::ExitStatus exitStatus) {

        qCDebug(siLog) << "SiC64 finished with exit code" << exitCode
                       << "status" << (exitStatus == QProcess::NormalExit ? "NormalExit" : "CrashExit");

        std::erase_if(m_sic64Processes, [process](const auto &p) { return p.process == process; });
        emit openChanged();
        process->deleteLater();

        m_sidebarController.refresh(vUUID);
        if (vUUID == m_vUUID) {
            m_vInfo["state"] = VMStateEnum::key(VMState::HIBERNATED);
            emit selectionChanged();
        }
    });

    /* numOpen and isOpen are both derived from this vector and both notify
     * on openChanged, so every change to it has to say so -- a QML binding
     * re-reads the property only when the signal fires. Missing it here is
     * what made the quit dialog report 0 running machines however many were
     * actually up: the binding still held the value it read at startup.
     */
    m_sic64Processes.push_back({ process, vUUID, VMState::HIBERNATED });
    emit openChanged();

    return process;
}

QStringList
HubController::buildArguments(const QString &svmPath, const Manifest &manifest, UUID sUUID)
{
    QStringList argv;

    argv << svmPath;
    argv << "--exec" << "server rpc set TRANSPORT STDIO";
    argv << "--exec" << "server rpc set ENABLE true";

    // Instruct SiC64 to run the startup script or power up -- unless a
    // specific snapshot was requested, in which case the state it captures
    // (including whether the machine was running) replaces both, so booting
    // fresh would just be immediately overwritten.

    if (sUUID) {

        // Nothing to add: loadSnapshot is requested via RPC above, once the
        // process (and its RPC server) is up.

    } else if (!manifest.startup.empty()) {

        auto startup = manifest.startup;
        // auto startup = vm->getSvm().root() / manifest.startup;

        argv << "--exec"
             << QString("source \"%1\"").arg(QString::fromStdString(startup.string()));
    } else {
        argv << "--exec" << "power on";
    }

    return argv;
}

void
HubController::launch(UUID vUUID, UUID sUUID)
{
    LogTask task("Launching new virtual machine...");

    try {

        // Lookup the virtual machine
        auto *vm = library.lookupVirtualMachine(vUUID);
        if (!vm) throw ImageError(ImageError::VM_NOT_FOUND, vUUID.toString());

        // Locate the emulator app
        auto &manifest = vm->getManifest();
        const QString exePath = AppController::locateExecutable(manifest.platform);

        // Hand over the root folder, not the archive
        const QString svmPath = QString::fromStdString(vm->root().string());

        // Create a new process
        auto *process = createProcess(vUUID, sUUID);

        // Assemble arguments and launch the process
        const QStringList argv = buildArguments(svmPath, manifest, sUUID);
        qCDebug(siLog) << "Executing" << exePath << argv;
        process->start(exePath, argv);

    } catch (std::exception &e) {

        emit showError("Failed to open virtual machine.", e.what());
    }
}

void
HubController::processRpcPacket(QProcess *process, UUID vUUID, const QJsonObject &rpc)
{
    const QString method = rpc["method"].toString();

    if (method == "vmState") {

        auto state = VMStateEnum::parseEnum(rpc["params"].toString().toStdString());
        if (!state) return;

        for (auto &sic64 : m_sic64Processes) {

            if (sic64.process != process) continue;

            sic64.state = *state;

            if (sic64.vUUID == m_vUUID) {
                m_vInfo["state"] = VMStateEnum::key(*state);
                emit selectionChanged();
            }

            m_sidebarController.refresh(vUUID);
            break;
        }
        return;
    }

    if (method == "persist") {

        /* The instance saved into the root folder we handed it. The tree on
         * disk is already correct -- its persist() wrote the manifest in place
         * -- but only we know where the archive is, so packing it up is ours
         * to do.
         *
         * reload() first, and it is not optional: our in-memory manifest
         * predates their write, and persist() would save it straight over
         * theirs, dropping the snapshot they just took. Manifest::generation
         * is what makes the staleness detectable rather than assumed.
         */
        for (auto &sic64 : m_sic64Processes) {

            if (sic64.process != process) continue;

            if (auto *vm = library.resolve(sic64.vUUID).first) {

                if (vm->isOutdated()) vm->reload();
                if (!vm->isReadOnly()) vm->persist();

                m_sidebarController.rebuild();
                if (sic64.vUUID == m_vUUID) select(m_vUUID);
            }
            break;
        }
        return;
    }

    if (method == "svmChanged") {

        // Set only for a snapshot save, and names the snapshot that appeared
        // (see C64Controller::notifySvmChanged).
        const QJsonObject params = rpc["params"].toObject();
        const QString kind = params["kind"].toString();

        /* Parsed defensively: this packet arrives on another process's stdout,
         * and UUID::fromString() throws on anything that is not hex. We are
         * inside a Qt slot here, so an escaping exception would abort the Hub
         * rather than surface as an error. A nil UUID simply means "no
         * snapshot to reveal", which is also the workspace-save case.
         */
        UUID sUUID;
        try {

            sUUID = UUID::fromString(params["uuid"].toString().toStdString());

        } catch (const std::exception &e) {

            qCWarning(siLog).noquote() << "Malformed snapshot uuid in svmChanged packet:" << e.what();
        }

        for (auto &sic64 : m_sic64Processes) {

            if (sic64.process != process) continue;

            // The SVM file was rewritten on disk by the SiC64 instance that
            // owns it (workspace or snapshot save). Our in-memory manifest
            // for that machine is now stale -- re-read it and, if it's the
            // one currently on screen, refresh the detail view too.
            auto *vm = library.resolve(sic64.vUUID).first;
            if (vm) {

                vm->reload();

                /* Rebuilt, not refreshed: a saved snapshot adds a row to the
                 * sidebar, and refresh() only re-emits dataChanged for rows
                 * that already exist -- it cannot make a new one appear, nor
                 * update the parent's cached numChildren. A workspace save
                 * can reorder rows too, since it bumps the manifest's
                 * modification date and that is one of the sort keys.
                 *
                 * Resetting the model is safe here: expansion state lives in
                 * HubSidebarModel's own 'expanded' set rather than in the
                 * rebuilt items, and the delegate derives its selection by
                 * comparing UUIDs (not by row index), so neither is lost.
                 */
                m_sidebarController.rebuild();

                if (kind == "snapshot" && sUUID) {

                    // Expand whatever hides the new row, so it is genuinely
                    // on screen and not merely present in the model.
                    m_sidebarController.reveal(sUUID);

                    /* Selection follows the new snapshot only while its
                     * machine is the one already on screen. A background
                     * instance saving a snapshot (a hibernation autosave, say)
                     * must not yank the user away from whatever they are
                     * currently inspecting.
                     */
                    if (sic64.vUUID == m_vUUID) select(sUUID);

                    emit snapshotSaved(QString::fromStdString(sic64.vUUID.toString()),
                                       QString::fromStdString(sUUID.toString()));

                } else if (sic64.vUUID == m_vUUID) {

                    // Refresh the detail view against the reloaded manifest.
                    select(m_vUUID);
                }
            }
            break;
        }
        return;
    }

    if (method == "fatalError") {

        // A SiC64 instance hit something it cannot carry on from and handed
        // us the message to show, because its own window is in no state to
        // show it (see C64Controller::notifyFatalError).
        const QJsonObject params = rpc["params"].toObject();
        const QString title = params["title"].toString();
        const QString text = params["text"].toString();

        qCCritical(siLog).noquote() << "SiC64 reported a fatal error:" << title << "-" << text;
        emit showError(title, text);
        return;
    }

    qCDebug(siLog).noquote() << "Unhandled RPC packet:"
                             << QJsonDocument(rpc).toJson(QJsonDocument::Compact);
}

void
HubController::broadcastPrefsChange(const QString &group)
{
    broadcastRpc("prefsChanged", group);
}

void
HubController::broadcastRpc(const QString &method, const QJsonValue &params)
{
    for (auto &sic64 : m_sic64Processes) {

        sendRpc(sic64.process, method, params);
    }
}

void
HubController::notifySvmChanged(UUID vUUID)
{
    /* The Hub and a running SiC64 instance each hold their own SVMFile for the
     * same file on disk. Whenever the Hub writes -- a rename, a deleted
     * snapshot -- the instance's copy silently goes stale, and it keeps making
     * decisions from the manifest it read at startup: counting a snapshot the
     * user just deleted, and so refusing to save a new one against a capacity
     * that is no longer full.
     *
     * This is the mirror image of the notification SiC64 sends the other way
     * after it writes (see C64Controller::notifySvmChanged), and it carries no
     * params for the same reason that one carries a kind: there is nothing to
     * reveal or select here, the receiver simply re-reads.
     */
    for (auto &sic64 : m_sic64Processes) {

        if (sic64.vUUID == vUUID) sendRpc(sic64.process, "svmChanged");
    }
}

void
HubController::sendRpc(QProcess *process, const QString &method, const QJsonValue &params)
{
    if (!process || process->state() != QProcess::Running) return;

    // Fire-and-forget JSON-RPC notification (no "id", so SiC64's RPC server
    // sends no reply). The newline lets the receiver frame the packet.
    QJsonObject rpc {
        { "jsonrpc", "2.0" },
        { "method", method }
    };
    if (!params.isNull()) rpc["params"] = params;

    const QByteArray compact = QJsonDocument(rpc).toJson(QJsonDocument::Compact);
    process->write(compact + '\n');

    // Surface sent RPC traffic in the logger window.
    qCDebug(siLog).noquote() << "RPC: Sent" << compact;
}

void
HubController::closeWindow(const QString &uuid)
{
    shutdown(UUID::fromString(uuid.toStdString()));
}

void
HubController::shutdown(UUID uuid)
{
    // Cleanup (erasing the process's m_sic64Processes entry, refreshing the
    // sidebar, updating vInfo if this machine is selected) happens in the
    // QProcess::finished handler installed in launch(), triggered once the
    // process actually exits below.
    //
    // Uses kill() (SIGKILL) rather than terminate() (SIGTERM): SiC64 doesn't
    // install a signal handler yet, so terminate() is silently ignored and
    // the process lingers -- confirmed by hand while testing this. Revisit
    // once SiC64 has a JSON-RPC link and can be asked to close gracefully.
    if (auto *sic64 = findSiC64Process(uuid)) {

        // No openChanged here: nothing has changed yet. The process is still
        // in the vector at this point and only leaves it when the kill lands
        // and the finished handler runs, which is where the signal belongs.
        sic64->process->kill();

    } else {

        emit showError("Failed to shutdown virtual machine.", "Machine not found.");
    }
}

void
HubController::closeAll()
{
    qDebug() << "Closing all managed windows...";

    for (const auto &uuid : openVMs()) {
        shutdown(uuid);
    }
}
