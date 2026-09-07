// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "Preferences.h"
#include "Logger.h"
#include <algorithm>

Preferences::Preferences()
{
    loadSettings();
}

Preferences &
Preferences::instance()
{
    static Preferences inst {};
    return inst;
}

QSettings &
Preferences::store()
{
    static QSettings settings("dirkwhoffmann", "Silicium");
    return settings;
}

QStringList
Preferences::readVmList() const
{
    return store().value("userVMs").toStringList();
}

void
Preferences::writeVmList(const QStringList &list)
{
    auto &s = store();

    s.setValue("userVMs", list);
    s.sync();

    if (s.status()) {
        qCWarning(siLog) << "Failed to persist list of virtual machines:" << s.status();
    }
}

//
// Devices
//

//
// General
//

void
Preferences::loadSettings()
{
    loadGeneralSettings();
    loadAppearanceSettings();
    loadControlsSettings();
    loadDevicesSettings();
    loadScreenshotSettings();
    loadDeveloperSettings();
    loadMiscSettings();
}

void
Preferences::reloadGroup(const QString &group)
{
    // Pull in changes made by other processes sharing this settings file.
    // Without this, QSettings would serve stale, cached values.
    store().sync();

    if (group == "general") {
        loadGeneralSettings();
        emit generalPrefsChanged();
    } else if (group == "appearance") {
        loadAppearanceSettings();
        emit appearancePrefsChanged();
    } else if (group == "controls") {
        loadControlsSettings();
        emit controlsPrefsChanged();
    } else if (group == "devices") {
        loadDevicesSettings();
        emit devicesPrefsChanged();
    } else if (group == "screenshots") {
        loadScreenshotSettings();
        emit screenshotPrefsChanged();
    } else if (group == "developer") {
        loadDeveloperSettings();
        emit developerPrefsChanged();
    } else if (group == "misc") {
        loadMiscSettings();
        emit miscPrefsChanged();
    } else {
        qCWarning(siLog).noquote() << "reloadGroup: unknown group" << group;
    }
}

void
Preferences::loadGeneralSettings()
{
    auto &s = store();

    s.beginGroup("general");

    vmSortMode             = s.value("vmSortMode", 3).toInt();
    hideShowcases          = s.value("hideShowcases", false).toBool();
    resolveUUIDConflicts   = s.value("resolveUUIDConflicts", false).toBool();

    maxSnapshots           = s.value("maxSnapshots", 8).toInt();
    autoDeleteSnapshots    = s.value("autoDeleteSnapshots", false).toBool();

    hibernateSnapshot      = s.value("hibernateSnapshot", true).toBool();
    hibernateWorkspace     = s.value("hibernateWorkspace", true).toBool();
    showHibernationDialog  = s.value("showHibernationDialog", true).toBool();

    ejectWithoutAsking     = s.value("ejectWithoutAsking", false).toBool();
    pauseWhileInBackground = s.value("pauseWhileInBackground", false).toBool();
    preventSleepWhileRunning = s.value("preventSleepWhileRunning", true).toBool();

    s.endGroup();
}

void
Preferences::loadAppearanceSettings()
{
    auto &s = store();

    s.beginGroup("appearance");

    appearance = s.value("appearance", 0).toInt();
    colorTheme = s.value("colorTheme", 0).toInt();
    fontTheme = s.value("fontTheme", 0).toInt();
    // Defaults to Serif, which is the monospace face the app used before this
    // was made selectable -- so adding the option does not silently restyle
    // every existing installation's RetroShell and debugger views.
    monoFontTheme = s.value("monoFontTheme", 1).toInt();

    menuStyle    = s.value("menuStyle", 0).toInt();
    statusbar    = s.value("statusbar", 1).toInt();
    resizeMode   = s.value("resizeMode", 0).toInt();
    autoHideToolbar = s.value("autoHideToolbar", false).toBool();

    s.endGroup();
}

void
Preferences::loadControlsSettings()
{
    auto &s = store();

    s.beginGroup("controls");

    mouseHotkey             = s.value("mouseHotkey", "Ctrl+G").toString();
    retainMouseByPressing   = s.value("retainMouseByPressing", true).toBool();
    retainMouseByClicking   = s.value("retainMouseByClicking", true).toBool();
    retainMouseByDoubleClicking = s.value("retainMouseByDoubleClicking", false).toBool();
    releaseMouseByPressing  = s.value("releaseMouseByPressing", true).toBool();
    releaseMouseByShaking   = s.value("releaseMouseByShaking", true).toBool();
    exitWithEsc             = s.value("exitWithEsc", false).toBool();
    capsLockAction          = s.value("capsLockAction", true).toBool();
    c64KeyMapMode           = s.value("c64KeyMapMode", 1).toInt();
    c64AutoReleaseKeys      = s.value("c64AutoReleaseKeys", false).toBool();
    c64CtrlLeftAlt          = s.value("c64CtrlLeftAlt", 0).toInt();
    c64CtrlRightAlt         = s.value("c64CtrlRightAlt", 0).toInt();
    c64CtrlLeftMeta         = s.value("c64CtrlLeftMeta", 0).toInt();
    c64CtrlRightMeta        = s.value("c64CtrlRightMeta", 0).toInt();

    QVariantMap keyMapVariant = s.value("c64KeyMap").toMap();

    resetC64KeyMapToDefaults();
    for (auto it = keyMapVariant.constBegin(); it != keyMapVariant.constEnd(); ++it) {
        c64KeyMap.insert(it.key().toUInt(), it.value().toInt());
    }

    s.endGroup();
}

void
Preferences::resetC64KeyMapToDefaults()
{
    // Maps a physical key (native scancode) to a C64 key number (see
    // C64Key::nr in VCCore). Hard-coded here (rather than calling
    // SiC64KeyboardController::defaultC64KeyMap()) to keep Preferences free
    // of a dependency on the emulator core.
    c64KeyMap = {
        {0x00, 35}, // A
        {0x0B, 55}, // B
        {0x08, 53}, // C
        {0x02, 37}, // D
        {0x0E, 20}, // E
        {0x03, 38}, // F
        {0x05, 39}, // G
        {0x04, 40}, // H
        {0x22, 25}, // I
        {0x26, 41}, // J
        {0x28, 42}, // K
        {0x25, 43}, // L
        {0x2E, 57}, // M
        {0x2D, 56}, // N
        {0x1F, 26}, // O
        {0x23, 27}, // P
        {0x0C, 18}, // Q
        {0x0F, 21}, // R
        {0x01, 36}, // S
        {0x11, 22}, // T
        {0x20, 24}, // U
        {0x09, 54}, // V
        {0x0D, 19}, // W
        {0x07, 52}, // X
        {0x10, 23}, // Y
        {0x06, 51}, // Z

        {0x12, 1},  // digit1
        {0x13, 2},  // digit2
        {0x14, 3},  // digit3
        {0x15, 4},  // digit4
        {0x17, 5},  // digit5
        {0x16, 6},  // digit6
        {0x1A, 7},  // digit7
        {0x1C, 8},  // digit8
        {0x19, 9},  // digit9
        {0x1D, 10}, // digit0
        {0x1B, 11}, // plus
        {0x18, 12}, // minus

        {0x31, 65}, // space
        {0x24, 47}, // ret
        {0x33, 15}, // del
        {0x38, 50}, // leftShift
        {0x3C, 61}, // rightShift
        {0x2B, 58}, // comma
        {0x2F, 59}, // period
        {0x2C, 60}, // slash
        {0x29, 44}, // colon
        {0x27, 45}, // semicolon
        {0x2A, 46}, // equal
        {0x21, 29}, // asterisk
        {0x1E, 28}, // at
        {0x7D, 62}, // curUpDown
        {0x7C, 63}, // curLeftRight

        {0x7A, 16}, // F1
        {0x78, 16}, // F2
        {0x63, 32}, // F3
        {0x76, 32}, // F4
        {0x60, 48}, // F5
        {0x61, 48}, // F6
        {0x62, 64}, // F7
        {0x64, 64}, // F8
    };
}

void
Preferences::resetC64KeyMap()
{
    resetC64KeyMapToDefaults();
    saveControlsSettings();
    emit controlsPrefsChanged();
}

QString
Preferences::mappingInfo(int nr) const
{
    QStringList scancodes;

    for (auto it = c64KeyMap.constBegin(); it != c64KeyMap.constEnd(); ++it) {
        if (it.value() == nr) scancodes << QString::number(it.key());
    }

    return scancodes.isEmpty()
        ? QString("No mapping yet")
        : QString("Mapped to scancode %1").arg(scancodes.join(", "));
}

bool
Preferences::isMapped(int nr) const
{
    return std::any_of(c64KeyMap.constBegin(), c64KeyMap.constEnd(), [nr](int value) { return value == nr; });
}

void
Preferences::loadDevicesSettings()
{
    // Register EmulationKey to with QMetaType's type system
    qRegisterMetaType<EmulationKey>();

    auto &s = store();

    s.beginGroup("devices");

    mouseSensitivity        = s.value("sensitivity", 1.0).toFloat();
    disconnectEmulationKeys = s.value("disconnectEmulationKeys", false).toBool();
    gamepadMappings         = s.value("gamepadMappings").toMap();

    auto loadKey = [&](const char *key, EmulationKey defaultVal) {
        auto v = s.value(key);
        return v.isValid() ? v.value<EmulationKey>() : defaultVal;
    };

    keyset1Up    = loadKey("keyset1Up",    { Qt::Key_Up,    126 });
    keyset1Down  = loadKey("keyset1Down",  { Qt::Key_Down,  125 });
    keyset1Left  = loadKey("keyset1Left",  { Qt::Key_Left,  123 });
    keyset1Right = loadKey("keyset1Right", { Qt::Key_Right, 124 });
    keyset1Fire  = loadKey("keyset1Fire",  { Qt::Key_Space,  49 });

    keyset2Up    = loadKey("keyset2Up",    { Qt::Key_W,  13 });
    keyset2Down  = loadKey("keyset2Down",  { Qt::Key_Y,   6 });
    keyset2Left  = loadKey("keyset2Left",  { Qt::Key_A,   0 });
    keyset2Right = loadKey("keyset2Right", { Qt::Key_S,   1 });
    keyset2Fire  = loadKey("keyset2Fire",  { Qt::Key_D,   2 });

    mbutton1Key = loadKey("mbutton1Key", { -1, -1 });
    mbutton2Key = loadKey("mbutton2Key", { -1, -1 });
    mbutton3Key = loadKey("mbutton3Key", { -1, -1 });

    s.endGroup();
}

void
Preferences::loadScreenshotSettings()
{
    auto &s = store();

    s.beginGroup("screenshots");

    screenshotFormat    = s.value("screenshotFormat", 0).toInt();
    screenshotSource    = s.value("screenshotSource", 0).toInt();
    screenshotCutout    = s.value("screenshotCutout", 0).toInt();
    screenshotWidth     = s.value("screenshotWidth", 320).toInt();
    screenshotHeight    = s.value("screenshotHeight", 200).toInt();

    s.endGroup();
}

void
Preferences::loadDeveloperSettings()
{
    auto &s = store();

    s.beginGroup("developer");

    developerMode = s.value("developerMode", false).toBool();
    qtDebug       = s.value("qtDebug", false).toBool();
    logVerbosity  = s.value("logVerbosity", 1).toInt();

    s.endGroup();
}

void
Preferences::loadMiscSettings()
{
    auto &s = store();

    s.beginGroup("misc");

    basicPath  = s.value("basicPath").toUrl();
    charPath   = s.value("charPath").toUrl();
    kernalPath = s.value("kernalPath").toUrl();
    vc1541Path = s.value("vc1541Path").toUrl();

    s.endGroup();
}

void
Preferences::saveSettings()
{
    saveGeneralSettings();
    saveAppearanceSettings();
    saveControlsSettings();
    saveDevicesSettings();
    saveScreenshotSettings();
    saveDeveloperSettings();
    saveMiscSettings();
}

void
Preferences::saveGeneralSettings()
{
    auto &s = store();

    s.beginGroup("general");

    s.setValue("vmSortMode", vmSortMode);
    s.setValue("hideShowcases", hideShowcases);
    s.setValue("resolveUUIDConflicts", resolveUUIDConflicts);

    s.setValue("maxSnapshots", maxSnapshots);
    s.setValue("autoDeleteSnapshots", autoDeleteSnapshots);

    s.setValue("hibernateSnapshot", hibernateSnapshot);
    s.setValue("hibernateWorkspace", hibernateWorkspace);
    s.setValue("showHibernationDialog", showHibernationDialog);

    s.setValue("ejectWithoutAsking", ejectWithoutAsking);
    s.setValue("pauseWhileInBackground", pauseWhileInBackground);
    s.setValue("preventSleepWhileRunning", preventSleepWhileRunning);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveAppearanceSettings()
{
    auto &s = store();

    s.beginGroup("appearance");

    s.setValue("appearance", appearance);
    s.setValue("colorTheme", colorTheme);
    s.setValue("fontTheme", fontTheme);
    s.setValue("monoFontTheme", monoFontTheme);

    s.setValue("menuStyle", menuStyle);
    s.setValue("statusbar", statusbar);
    s.setValue("resizeMode", resizeMode);
    s.setValue("autoHideToolbar", autoHideToolbar);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveControlsSettings()
{
    auto &s = store();

    s.beginGroup("controls");

    s.setValue("mouseHotkey", mouseHotkey);
    s.setValue("retainMouseByPressing", retainMouseByPressing);
    s.setValue("retainMouseByClicking", retainMouseByClicking);
    s.setValue("retainMouseByDoubleClicking", retainMouseByDoubleClicking);
    s.setValue("releaseMouseByPressing", releaseMouseByPressing);
    s.setValue("releaseMouseByShaking", releaseMouseByShaking);
    s.setValue("exitWithEsc", exitWithEsc);
    s.setValue("capsLockAction", capsLockAction);
    s.setValue("c64KeyMapMode", c64KeyMapMode);
    s.setValue("c64AutoReleaseKeys", c64AutoReleaseKeys);
    s.setValue("c64CtrlLeftAlt", c64CtrlLeftAlt);
    s.setValue("c64CtrlRightAlt", c64CtrlRightAlt);
    s.setValue("c64CtrlLeftMeta", c64CtrlLeftMeta);
    s.setValue("c64CtrlRightMeta", c64CtrlRightMeta);

    QVariantMap keyMapVariant;
    for (auto it = c64KeyMap.constBegin(); it != c64KeyMap.constEnd(); ++it) {
        keyMapVariant.insert(QString::number(it.key()), it.value());
    }
    s.setValue("c64KeyMap", keyMapVariant);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveDevicesSettings()
{
    auto &s = store();

    s.beginGroup("devices");

    s.setValue("sensitivity", mouseSensitivity);
    s.setValue("disconnectEmulationKeys", disconnectEmulationKeys);
    s.setValue("gamepadMappings", gamepadMappings);

    s.setValue("keyset1Up",    QVariant::fromValue(keyset1Up));
    s.setValue("keyset1Down",  QVariant::fromValue(keyset1Down));
    s.setValue("keyset1Left",  QVariant::fromValue(keyset1Left));
    s.setValue("keyset1Right", QVariant::fromValue(keyset1Right));
    s.setValue("keyset1Fire",  QVariant::fromValue(keyset1Fire));

    s.setValue("keyset2Up",    QVariant::fromValue(keyset2Up));
    s.setValue("keyset2Down",  QVariant::fromValue(keyset2Down));
    s.setValue("keyset2Left",  QVariant::fromValue(keyset2Left));
    s.setValue("keyset2Right", QVariant::fromValue(keyset2Right));
    s.setValue("keyset2Fire",  QVariant::fromValue(keyset2Fire));

    s.setValue("mbutton1Key",  QVariant::fromValue(mbutton1Key));
    s.setValue("mbutton2Key",  QVariant::fromValue(mbutton2Key));
    s.setValue("mbutton3Key",  QVariant::fromValue(mbutton3Key));

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveScreenshotSettings()
{
    auto &s = store();

    s.beginGroup("screenshots");

    s.setValue("screenshotFormat", screenshotFormat);
    s.setValue("screenshotSource", screenshotSource);
    s.setValue("screenshotCutout", screenshotCutout);
    s.setValue("screenshotWidth", screenshotWidth);
    s.setValue("screenshotHeight", screenshotHeight);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveDeveloperSettings()
{
    auto &s = store();

    s.beginGroup("developer");

    s.setValue("developerMode", developerMode);
    s.setValue("qtDebug", qtDebug);
    s.setValue("logVerbosity", logVerbosity);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::saveMiscSettings()
{
    auto &s = store();

    s.beginGroup("misc");

    s.setValue("basicPath", basicPath);
    s.setValue("charPath", charPath);
    s.setValue("kernalPath", kernalPath);
    s.setValue("vc1541Path", vc1541Path);

    s.endGroup();

    // Flush to disk so other processes sharing this file see the change
    s.sync();
}

void
Preferences::resetSettings()
{
    resetGeneralSettings();
    resetAppearanceSettings();
    resetControlsSettings();
    resetDevicesSettings();
    resetScreenshotSettings();
    resetDeveloperSettings();
    resetMiscSettings();
}

/* All group resets go through reloadGroup(), which reloads the group *and*
 * emits its changed signal. Calling loadXSettings() directly would leave every
 * QML binding showing the old value, and would skip the notification to the
 * SiC64 helper processes.
 */

void
Preferences::resetGeneralSettings()
{
    store().remove("general");
    reloadGroup("general");
}

void
Preferences::resetAppearanceSettings()
{
    store().remove("appearance");
    reloadGroup("appearance");
}

void
Preferences::resetControlsSettings()
{
    store().remove("controls");
    reloadGroup("controls");
}

void
Preferences::resetDevicesSettings()
{
    store().remove("devices");
    reloadGroup("devices");
}

void
Preferences::resetScreenshotSettings()
{
    store().remove("screenshots");
    reloadGroup("screenshots");
}

void
Preferences::resetDeveloperSettings()
{
    store().remove("developer");
    reloadGroup("developer");
}

void
Preferences::resetMiscSettings()
{
    store().remove("misc");
    reloadGroup("misc");
}
