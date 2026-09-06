// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "C64MediaController.h"
#include "C64Controller.h"
#include <QTimer>

using namespace vc64;

C64MediaController::C64MediaController(C64Controller *parent)
    : Controller(parent), parent(parent)
{

}

void
C64MediaController::insertDisk(int drive, const QUrl &url, bool wp)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        auto &core = C64Controller::core();

        if (drive == 8) core.drive8.insert(path, wp);
        if (drive == 9) core.drive9.insert(path, wp);

        noteRecentlyInsertedDisk(url);

    } catch (const std::exception &e) {

        showError("Failed to insert disk.", e.what());
    }
}

void
C64MediaController::flash(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        auto &core = C64Controller::core();

        core.c64.flash(path);
        core.keyboard.autoType("run\n");

    } catch (const std::exception &e) {

        showError("Failed to flash file.", e.what());
    }
}

void
C64MediaController::noteRecentlyInsertedDisk(const QUrl &url)
{
    static constexpr int maxRecentDisks = 10;

    auto str = url.toString();
    if (m_recentDisks.contains(str)) return;

    if (m_recentDisks.size() >= maxRecentDisks) m_recentDisks.removeLast();
    m_recentDisks.prepend(str);

    emit recentDisksChanged();
}

void
C64MediaController::newDisk(int drive, int fsFormat, const QString &name)
{
    try {

        auto fmt = FSFormat(fsFormat);
        auto n = name.toStdString();
        auto &core = C64Controller::core();

        if (drive == 8) core.drive8.insertBlankDisk(fmt, n);
        if (drive == 9) core.drive9.insertBlankDisk(fmt, n);

    } catch (const std::exception &e) {

        showError("Failed to create disk.", e.what());
    }
}

bool
C64MediaController::hasModifiedDisk(int drive) const
{
    auto &core = C64Controller::core();

    return drive == 8 ?
        core.drive8.getInfo().hasModifiedDisk :
        core.drive9.getInfo().hasModifiedDisk;
}

void
C64MediaController::exportDisk(int drive, const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        auto &core = C64Controller::core();
        int slot = drive == 8 ? 0 : 1;

        if (drive == 8) core.drive8.save(path);
        if (drive == 9) core.drive9.save(path);

        core.put(Cmd::DSK_UNMODIFIED, slot);

    } catch (const std::exception &e) {

        showError("Failed to export disk.", e.what());
    }
}

void
C64MediaController::exportDiskFolder(int drive, const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        auto &core = C64Controller::core();
        int slot = drive == 8 ? 0 : 1;

        if (drive == 8) core.drive8.saveFiles(path);
        if (drive == 9) core.drive9.saveFiles(path);

        core.put(Cmd::DSK_UNMODIFIED, slot);

    } catch (const std::exception &e) {

        showError("Failed to export disk.", e.what());
    }
}

void
C64MediaController::ejectDisk(int drive)
{
    try {

        auto &core = C64Controller::core();

        if (drive == 8) core.drive8.ejectDisk();
        if (drive == 9) core.drive9.ejectDisk();

    } catch (const std::exception &e) {

        showError("Failed to eject disk.", e.what());
    }
}

void
C64MediaController::toggleWriteProtection(int drive)
{
    int slot = drive == 8 ? 0 : 1;
    C64Controller::core().put(Cmd::DSK_TOGGLE_WP, slot);
}

void
C64MediaController::toggleUnsavedState(int drive)
{
    // Unlike DSK_TOGGLE_WP, the core has no single "toggle" command for the
    // modification flag -- DSK_MODIFIED and DSK_UNMODIFIED set it explicitly
    // in either direction -- so the toggle happens here, from the current
    // state.
    int slot = drive == 8 ? 0 : 1;
    bool modified = drive == 8 ? drive8Modified() : drive9Modified();
    C64Controller::core().put(modified ? Cmd::DSK_UNMODIFIED : Cmd::DSK_MODIFIED, slot);
}

void
C64MediaController::toggleDrivePower(int drive)
{
    if (drive == 8) {
        parent->getConfigController()->setDrive8PowerSwitch(!parent->getConfigController()->drive8PowerSwitch());
    } else {
        parent->getConfigController()->setDrive9PowerSwitch(!parent->getConfigController()->drive9PowerSwitch());
    }
}

bool C64MediaController::drive8HasDisk() const { return C64Controller::core().drive8.getInfo().hasDisk; }
bool C64MediaController::drive9HasDisk() const { return C64Controller::core().drive9.getInfo().hasDisk; }
bool C64MediaController::drive8WriteProtected() const { return C64Controller::core().drive8.getInfo().hasProtectedDisk; }
bool C64MediaController::drive9WriteProtected() const { return C64Controller::core().drive9.getInfo().hasProtectedDisk; }
bool C64MediaController::drive8Modified() const { return C64Controller::core().drive8.getInfo().hasModifiedDisk; }
bool C64MediaController::drive9Modified() const { return C64Controller::core().drive9.getInfo().hasModifiedDisk; }
bool C64MediaController::drive8PoweredOn() const { return C64Controller::core().get(vc64::Opt::DRV_POWER_SWITCH, 0); }
bool C64MediaController::drive9PoweredOn() const { return C64Controller::core().get(vc64::Opt::DRV_POWER_SWITCH, 1); }

void
C64MediaController::insertTape(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        C64Controller::core().datasette.insertTape(path);

        noteRecentlyInsertedTape(url);

    } catch (const std::exception &e) {

        showError("Failed to insert tape.", e.what());
    }
}

void
C64MediaController::noteRecentlyInsertedTape(const QUrl &url)
{
    static constexpr int maxRecentTapes = 10;

    auto str = url.toString();
    if (m_recentTapes.contains(str)) return;

    if (m_recentTapes.size() >= maxRecentTapes) m_recentTapes.removeLast();
    m_recentTapes.prepend(str);

    emit recentTapesChanged();
}

void
C64MediaController::ejectTape()
{
    try {

        C64Controller::core().datasette.ejectTape();

    } catch (const std::exception &e) {

        showError("Failed to eject tape.", e.what());
    }
}

void
C64MediaController::exportTape(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        C64Controller::core().datasette.exportTape(path);

    } catch (const std::exception &e) {

        showError("Failed to export tape.", e.what());
    }
}

void
C64MediaController::rewindTape()
{
    C64Controller::core().put(Cmd::DATASETTE_REWIND);
}

void
C64MediaController::playOrStopTape()
{
    C64Controller::core().put(C64Controller::core().datasette.getInfo().playKey ? Cmd::DATASETTE_STOP : Cmd::DATASETTE_PLAY);
}

bool C64MediaController::tapeInserted() const { return C64Controller::core().datasette.getInfo().hasTape; }
bool C64MediaController::tapePlaying() const { return C64Controller::core().datasette.getInfo().playKey; }

void
C64MediaController::attachCartridge(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        C64Controller::core().expansionPort.attachCartridge(path);

        noteRecentlyAttachedCartridge(url);

    } catch (const std::exception &e) {

        showError("Failed to attach cartridge.", e.what());
    }
}

void
C64MediaController::noteRecentlyAttachedCartridge(const QUrl &url)
{
    static constexpr int maxRecentCartridges = 10;

    auto str = url.toString();
    if (m_recentCartridges.contains(str)) return;

    if (m_recentCartridges.size() >= maxRecentCartridges) m_recentCartridges.removeLast();
    m_recentCartridges.prepend(str);

    emit recentCartridgesChanged();
}

void
C64MediaController::detachCartridge()
{
    C64Controller::core().expansionPort.detachCartridge();
    C64Controller::core().hardReset();
}

void
C64MediaController::attachReu(int capacity)
{
    try {

        C64Controller::core().expansionPort.attachReu(capacity);

    } catch (const std::exception &e) {

        showError("Failed to attach REU.", e.what());
    }
}

void
C64MediaController::attachGeoRam(int capacity)
{
    try {

        C64Controller::core().expansionPort.attachGeoRam(capacity);

    } catch (const std::exception &e) {

        showError("Failed to attach GeoRAM.", e.what());
    }
}

void
C64MediaController::attachIsepic()
{
    C64Controller::core().expansionPort.attachIsepicCartridge();
}

void
C64MediaController::exportCartridge(const QUrl &url)
{
    try {

        auto path = fs::u8path(url.toLocalFile().toUtf8().constData());
        C64Controller::core().expansionPort.exportCRT(path);

    } catch (const std::exception &e) {

        showError("Failed to export cartridge.", e.what());
    }
}

void
C64MediaController::pressCartridgeButton(int nr)
{
    C64Controller::core().put(Cmd::CRT_BUTTON_PRESS, nr);

    QTimer::singleShot(500, this, [nr]() {
        C64Controller::core().put(Cmd::CRT_BUTTON_RELEASE, nr);
    });
}

void
C64MediaController::setCartridgeSwitch(int pos)
{
    auto &core = C64Controller::core();

    if (pos < 0) core.put(Cmd::CRT_SWITCH_LEFT);
    else if (pos > 0) core.put(Cmd::CRT_SWITCH_RIGHT);
    else core.put(Cmd::CRT_SWITCH_NEUTRAL);

    // No message is emitted for switch changes (unlike CRT_ATTACHED), so
    // the menu's checkmark needs an explicit nudge to refresh.
    emit driveStateChanged();
}

bool C64MediaController::cartridgeAttached() const { return C64Controller::core().expansionPort.getCartridgeTraits().type != vc64::CartridgeType::NONE; }
bool C64MediaController::cartridgeIsReu() const { return C64Controller::core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::REU; }
bool C64MediaController::cartridgeIsGeoRam() const { return C64Controller::core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::GEO_RAM; }
bool C64MediaController::cartridgeIsIsepic() const { return C64Controller::core().expansionPort.getCartridgeTraits().type == vc64::CartridgeType::ISEPIC; }
int C64MediaController::cartridgeMemory() const { return (int)(C64Controller::core().expansionPort.getCartridgeTraits().memory / 1024); }
int C64MediaController::cartridgeButtons() const { return (int)C64Controller::core().expansionPort.getCartridgeTraits().buttons; }
int C64MediaController::cartridgeSwitches() const { return (int)C64Controller::core().expansionPort.getCartridgeTraits().switches; }
int C64MediaController::cartridgeSwitchPos() const { return (int)C64Controller::core().expansionPort.getInfo().switchPos; }

void
C64MediaController::insertRecentDisk(int drive, int index)
{
    if (index < 0 || index >= m_recentDisks.size()) return;

    insertDisk(drive, QUrl(m_recentDisks.at(index)));
}

void
C64MediaController::clearRecentlyInsertedDisks()
{
    m_recentDisks.clear();
    emit recentDisksChanged();
}

void
C64MediaController::insertRecentTape(int index)
{
    if (index < 0 || index >= m_recentTapes.size()) return;

    insertTape(QUrl(m_recentTapes.at(index)));
}

void
C64MediaController::clearRecentlyInsertedTapes()
{
    m_recentTapes.clear();
    emit recentTapesChanged();
}

void
C64MediaController::attachRecentCartridge(int index)
{
    if (index < 0 || index >= m_recentCartridges.size()) return;

    attachCartridge(QUrl(m_recentCartridges.at(index)));
}

void
C64MediaController::clearRecentlyAttachedCartridges()
{
    m_recentCartridges.clear();
    emit recentCartridgesChanged();
}
