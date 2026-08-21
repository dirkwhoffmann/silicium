// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "AppController.h"
#include "HubSidebarController.h"
#include <QtQml>
#include <QQuickWindow>
#include <QJsonValue>

class QProcess;

class HubController : public Controller {

    Q_OBJECT

    // Subcontroller
    HubSidebarController m_sidebarController;

    // Quick references
    VirtualMachineLibrary &library = Silicium::instance().getLibrary();

    // A running SiC64 helper process and the state it last reported of
    // itself. SiC64 has no controller of its own yet, so the Hub tracks its
    // state from "GUI <state>" lines sent over the process's stdout -- see
    // launch() and lookupState(). Temporary until SiC64 gets a proper
    // controller wrapping the process + JSON-RPC link.
    struct SiC64Process {
        QProcess *process = nullptr;
        UUID vUUID;
        VMState state = VMState::HIBERNATED;
    };
    vector<SiC64Process> m_sic64Processes;

    // Resource path to all pre-installed virtual machines
    fs::path m_showcases;

    // The currently selected virtual machine and snapshot
    UUID m_vUUID;
    UUID m_sUUID;

    // Properties of the currently selected virtual machine and snapshot
    QVariantMap m_vInfo;
    QVariantMap m_sInfo;

    // The currently displayed panel
    QString m_panel = "splash";
    QString m_overlay = "";

    //
    // Initializing

  public:

    static HubController &instance();

  private:

    HubController();
    ~HubController();

    void setupShowcases();
    void setupUserVMs();


    //
    // Accessing subcomponents
    //

  public:

    // Returns the sidebar controller
    Q_PROPERTY(HubSidebarController *sidebarController READ sidebarController CONSTANT)

    // Returns the current state of a tracked virtual machine (see
    // m_sic64Processes), or VMState::HIBERNATED if it isn't running.
    VMState lookupState(UUID uuid) const;

  private:

    HubSidebarController *sidebarController() { return &m_sidebarController; }

    // Finds the tracked SiC64 process for a running machine, or nullptr.
    const SiC64Process *findSiC64Process(UUID uuid) const;


    //
    // Methods from Controller
    //

  public:

    Q_INVOKABLE void start() override;
    Q_INVOKABLE void stop() override;


    //
    // Managing panels
    //

  public:

    Q_PROPERTY(QString panel READ getPanel WRITE setPanel NOTIFY panelChanged)
    Q_PROPERTY(QString overlay READ getOverlay WRITE setOverlay NOTIFY overlayChanged)

  private:

    QString getPanel() const { return m_panel; }
    void setPanel(const QString &value);

    QString getOverlay() const { return m_overlay; }
    void setOverlay(const QString &value);


    //
    // Querying meta data
    //

  public:

    // Returns the number of virtual machines, and the number of machines which are open
    Q_PROPERTY(int vCount READ vCount NOTIFY libraryChanged)
    Q_PROPERTY(int numOpen READ numOpen NOTIFY openChanged)

    // Returns the UUID of the current selection (matches m_vUUID or m_sUUID)
    Q_PROPERTY(QString selected READ selected WRITE setSelected NOTIFY selectionChanged)

    // Indicates whether a virtual machine, a snapshot, or any of them is selected
    Q_PROPERTY(bool vSelected READ vSelected NOTIFY selectionChanged)
    Q_PROPERTY(bool sSelected READ sSelected NOTIFY selectionChanged)

    // Indicates whether an item with a certain UUID is selected
    Q_INVOKABLE bool vIsSelected(const QString &uuid) const;
    Q_INVOKABLE bool sIsSelected(const QString &uuid) const;

    // Returns meta-information about the selected machine
    Q_PROPERTY(QVariantMap vInfo READ vInfo NOTIFY selectionChanged)
    Q_PROPERTY(int sCount READ sCount NOTIFY selectionChanged)

    // Returns meta-information about the selected snapshot
    Q_PROPERTY(QVariantMap sInfo READ sInfo NOTIFY selectionChanged)

    // Indicates whether the selected machine has an open emulator window
    Q_PROPERTY(bool isOpen READ isOpen NOTIFY openChanged)

    // Returns the manifest of the selected virtual machine
    Manifest *getManifest();

    // Selects a virtual machine
    Q_INVOKABLE void select(const QString &quuid) { setSelected(quuid); }

    // Checks if the selected virtual machine still exists
    Q_INVOKABLE void validateSelection();

  private:

    QString selected() const;
    void setSelected(const QString &quuid);
    void select(UUID uuid);

    int vCount() const;
    int numOpen() const { return (int)m_sic64Processes.size(); }

    bool vSelected() const { return !m_vUUID.isZero() && m_sUUID.isZero(); }
    bool sSelected() const { return !m_sUUID.isZero(); }
    // bool selected() const { return vSelected() || sSelected(); }

    QVariantMap vInfo() const { return m_vInfo; }

    int sCount() const;
    QVariantMap sInfo() const { return m_sInfo; }

    bool isOpen(UUID uuid) const { return findSiC64Process(uuid) != nullptr; }
    bool isOpen() const { return isOpen(m_vUUID); }

    // Returns a vector with all open virtual machines
    vector<UUID> openVMs() const;

    //
    // Managing virtual machines
    //

  public:

    // Adds a virtual machine to the library
    Q_INVOKABLE QString addVM(const QUrl &url);

    // Duplicates the virtual machine before adding
    Q_INVOKABLE QString cloneVM(const QString &quuid, const QUrl &cloneUrl);

    // Renames a virtual machine or a snapshot
    Q_INVOKABLE void rename(const QString &quuid, const QString &name);

    // Removes a virtual machine or a snapshot
    Q_INVOKABLE bool remove(const QString &quuid);
    // bool removeVM(UUID uuid);
    // bool removeSnapshot(UUID uuid);

    /* Opens a virtual machine based on the current selection.
     *
     * Case 1: A virtual machine is selected
     *
     * - If the machine is already running, its window is brought to the front.
     * - Otherwise, a new machine is launched and booted from scratch.
     *
     * Case 2: A snapshot is selected
     *
     * - If the corresponding machine is already running, its window is brought to
     *   the front and the snapshot is restored.
     * - Otherwise, a new machine is launched with the machine initialized from
     *   the snapshot.
     */
    Q_INVOKABLE void open();
    Q_INVOKABLE void open(const QString &vQUUID, const QString &sQUUID = "");

    // Closes a window or all windows
    Q_INVOKABLE void closeWindow(const QString &uuid);
    Q_INVOKABLE void closeAll();

  private:

    void open(UUID vUUID, UUID sUUID);

    // Launches a new virtual machine in a new emulator window
    void launch(UUID vUUID, UUID sUUID);

    /* Creates and wires up a QProcess for a new SiC64 instance: hooks its
     * stdout/stderr/started/finished signals and registers it in
     * m_sic64Processes. 'sUUID', if set, is loaded via RPC once the process
     * has started. The caller still has to start() it.
     */
    QProcess *createProcess(UUID vUUID, UUID sUUID);

    /* Assembles the SiC64 command line: the SVM path plus the --exec
     * commands that bring up its RPC server and start the machine running.
     * 'sUUID', if set, is loaded via RPC after startup (see createProcess),
     * so no boot instruction is added here for that case.
     */
    static QStringList buildArguments(const QString &svmPath, const Manifest &manifest, UUID sUUID);

    // Processes a JSON-RPC packet received from a SiC64 process
    void processRpcPacket(QProcess *process, UUID vUUID, const QJsonObject &rpc);

    // Sends a JSON-RPC "prefsChanged" notification for the given settings
    // group to every running SiC64 process, prompting each to re-read that
    // group from the shared settings file.
    void broadcastPrefsChange(const QString &group);

    // Sends a fire-and-forget JSON-RPC notification to every running SiC64
    // process. 'params' is omitted from the packet entirely when left null.
    void broadcastRpc(const QString &method, const QJsonValue &params = QJsonValue());

    // Sends a fire-and-forget JSON-RPC notification to a single SiC64
    // process (no "id", so its RPC server sends no reply). 'params' is
    // omitted from the packet entirely when left null.
    void sendRpc(QProcess *process, const QString &method, const QJsonValue &params = QJsonValue());

    /* Tells the SiC64 instance running 'vUUID', if any, that we just rewrote
     * its SVM file. Call after every Hub-side write -- see the definition for
     * why a silent write is a bug rather than a missed refresh.
     */
    void notifySvmChanged(UUID vUUID);

    // Shuts down a launched machine
    void shutdown(UUID uuid);

    //
    // Persisting data
    //

    // Persists the current sidebar model and emits the libraryChanged signal
    void commitLibrary();

  private:

    // Load or save the virtual machine path list from the QSettings
    QStringList readVmList() const;

    // Load or save the virtual machine path list from the QSettings
    void writeVmList();

    //
    // Signals
    //

  signals:

    void panelChanged();
    void overlayChanged();
    void selectionChanged();
    void libraryChanged();
    // void vmSelected();
    void openChanged();
    void ambiguousUUID(const QUrl &url);
    void snapshotSaved(const QString &vUUID, const QString &sUUID);
};
