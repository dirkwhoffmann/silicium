// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Palette.h"
#include "EmulationKey.h"
#include "utl/common.h"
#include <QtQml>

class Preferences : public QObject {

    Q_OBJECT

    //
    // Group: General
    //

    // Virtual Machine Library
    int vmSortMode;
    bool hideShowcases;

    // Snapshot Library
    int maxSnapshots;
    bool autoDeleteSnapshots;

    // Hibernation
    bool hibernateSnapshot;
    bool hibernateWorkspace;
    bool showHibernationDialog;

    // Workflow & Activity
    bool ejectWithoutAsking;
    bool pauseWhileInBackground;
    bool resolveUUIDConflicts;
    bool preventSleepWhileRunning;


    //
    // Group: Appearance
    //

    //
    int menuStyle;
    int statusbar;
    int resizeMode;
    bool autoHideToolbar;

    // Themes
    int appearance;
    int colorTheme;
    int fontTheme;
    int monoFontTheme;


    //
    // Group: Controls
    //

    // Mouse
    QString mouseHotkey;
    bool retainMouseByPressing;
    bool retainMouseByClicking;
    bool retainMouseByDoubleClicking;
    bool releaseMouseByPressing;
    bool releaseMouseByShaking;

    // Hotkeys
    int capsLockAction;

    // C64 Keyboard
    QHash<quint32, int> c64KeyMap;
    int c64KeyMapMode;
    bool c64AutoReleaseKeys;
    int c64CtrlLeftAlt;
    int c64CtrlRightAlt;
    int c64CtrlLeftMeta;
    int c64CtrlRightMeta;

    // Fullscreen
    bool exitWithEsc;


    //
    // Group: Devices
    //

    float mouseSensitivity;
    bool disconnectEmulationKeys;

    /* Gamepad mappings the user has edited, keyed by SDL GUID. Values are
     * complete SDL mapping strings ("<guid>,<name>,<logic>"). Only entries
     * that differ from what SDL supplies live here, so the map doubles as
     * the answer to "has this device been customized?".
     */
    QVariantMap gamepadMappings;

    EmulationKey keyset1Left;
    EmulationKey keyset1Right;
    EmulationKey keyset1Up;
    EmulationKey keyset1Down;
    EmulationKey keyset1Fire;

    EmulationKey keyset2Left;
    EmulationKey keyset2Right;
    EmulationKey keyset2Up;
    EmulationKey keyset2Down;
    EmulationKey keyset2Fire;

    EmulationKey mbutton1Key;
    EmulationKey mbutton2Key;
    EmulationKey mbutton3Key;


    //
    // Group: Developer
    //

    // Debugging
    bool developerMode;
    bool qtDebug;

    // Logging
    int logVerbosity;


    //
    // Group: Screenshots
    //

    // Screenshots
    int screenshotFormat;
    int screenshotSource;
    int screenshotCutout;
    int screenshotWidth;
    int screenshotHeight;


    //
    // Group: Misc
    //

    // Remembers the most recent custom-loaded ROMs
    QUrl basicPath;
    QUrl charPath;
    QUrl kernalPath;
    QUrl vc1541Path;


    //
    // Constructing
    //

  public:

    static Preferences &instance();
    static QSettings &store();

    Preferences(const Preferences&) = delete;
    Preferences& operator=(const Preferences&) = delete;

  private:

    Preferences();


    //
    // Persisting the virtual machine library
    //

  public:

    QStringList readVmList() const;
    void writeVmList(const QStringList &list);


    //
    // Reloading settings from disk
    //

  public:

    /* Reloads a single settings group from the backing store and emits the
     * group's changed signal. Used to propagate preference changes between
     * the Silicium app and the SiC64 helper processes, which share the same
     * QSettings file: when one process changes a setting, it notifies the
     * others, which call this to re-read the affected group. 'group' is one
     * of the QSettings group names ("general", "appearance", "controls",
     * "devices", "screenshots", "developer", "misc").
     */
    Q_INVOKABLE void reloadGroup(const QString &group);


    //
    // Managing settings
    //

    //
    // General
    //

  public:

    Q_PROPERTY(int vmSortMode READ getVmSortMode WRITE setVmSortMode NOTIFY generalPrefsChanged)
    Q_PROPERTY(bool hideShowcases READ getHideShowcases WRITE setHideShowcases NOTIFY generalPrefsChanged)

    Q_PROPERTY(int maxSnapshots READ getMaxSnapshots WRITE setMaxSnapshots NOTIFY generalPrefsChanged)
    Q_PROPERTY(int autoDeleteSnapshots READ getAutoDeleteSnapshots WRITE setAutoDeleteSnapshots NOTIFY
                   generalPrefsChanged)

    Q_PROPERTY(bool hibernateSnapshot READ getHibernateSnapshot WRITE setHibernateSnapshot NOTIFY generalPrefsChanged)
    Q_PROPERTY(bool hibernateWorkspace READ getHibernateWorkspace WRITE setHibernateWorkspace NOTIFY generalPrefsChanged)
    Q_PROPERTY(bool showHibernationDialog READ getShowHibernationDialog WRITE setShowHibernationDialog NOTIFY generalPrefsChanged)

    Q_PROPERTY(bool ejectWithoutAsking READ getEjectWithoutAsking WRITE setEjectWithoutAsking NOTIFY generalPrefsChanged)
    Q_PROPERTY(bool pauseWhileInBackground READ getPauseWhileInBackground WRITE setPauseWhileInBackground NOTIFY
                   generalPrefsChanged)
    Q_PROPERTY(bool resolveUUIDConflicts READ getResolveUUIDConflicts WRITE setResolveUUIDConflicts NOTIFY
                   generalPrefsChanged)
    Q_PROPERTY(bool preventSleepWhileRunning READ getPreventSleepWhileRunning WRITE setPreventSleepWhileRunning NOTIFY
                   generalPrefsChanged)

    int getVmSortMode() const { return vmSortMode; }
    void setVmSortMode(int value) { setGeneralProperty(vmSortMode, value); }
    bool getHideShowcases() const { return hideShowcases; }
    void setHideShowcases(bool value) { setGeneralProperty(hideShowcases, value); }

    int getMaxSnapshots() const { return maxSnapshots; }
    void setMaxSnapshots(int value) { setGeneralProperty(maxSnapshots, value); }
    bool getAutoDeleteSnapshots() const { return autoDeleteSnapshots; }
    void setAutoDeleteSnapshots(bool value) { setGeneralProperty(autoDeleteSnapshots, value); }

    bool getHibernateSnapshot() const { return hibernateSnapshot; }
    void setHibernateSnapshot(bool value) { setGeneralProperty(hibernateSnapshot, value); }
    bool getHibernateWorkspace() const { return hibernateWorkspace; }
    void setHibernateWorkspace(bool value) { setGeneralProperty(hibernateWorkspace, value); }
    bool getShowHibernationDialog() const { return showHibernationDialog; }
    void setShowHibernationDialog(bool value) { setGeneralProperty(showHibernationDialog, value); }

    bool getEjectWithoutAsking() const { return ejectWithoutAsking; }
    void setEjectWithoutAsking(bool value) { setGeneralProperty(ejectWithoutAsking, value); }
    bool getPauseWhileInBackground() const { return pauseWhileInBackground; }
    void setPauseWhileInBackground(bool value) { setGeneralProperty(pauseWhileInBackground, value); }
    bool getResolveUUIDConflicts() const { return resolveUUIDConflicts; }
    void setResolveUUIDConflicts(bool value) { setGeneralProperty(resolveUUIDConflicts, value); }
    bool getPreventSleepWhileRunning() const { return preventSleepWhileRunning; }
    void setPreventSleepWhileRunning(bool value) { setGeneralProperty(preventSleepWhileRunning, value); }

  private:

    template <typename T>
    void setGeneralProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveGeneralSettings();
            emit generalPrefsChanged();
        }
    }

    //
    // Appearance
    //

  public:

    Q_PROPERTY(int menuStyle READ getMenuStyle WRITE setMenuStyle NOTIFY appearancePrefsChanged)
    Q_PROPERTY(int statusbar READ getStatusbar WRITE setStatusbar NOTIFY appearancePrefsChanged)
    Q_PROPERTY(int resizeMode READ getResizeMode WRITE setResizeMode NOTIFY appearancePrefsChanged)
    Q_PROPERTY(bool autoHideToolbar READ getAutoHideToolbar WRITE setAutoHideToolbar NOTIFY appearancePrefsChanged)

    Q_PROPERTY(int appearance READ getAppearance WRITE setAppearance NOTIFY appearancePrefsChanged)
    Q_PROPERTY(int colorTheme READ getColorTheme WRITE setColorTheme NOTIFY appearancePrefsChanged)
    Q_PROPERTY(int fontTheme READ getFontTheme WRITE setFontTheme NOTIFY appearancePrefsChanged)
    Q_PROPERTY(int monoFontTheme READ getMonoFontTheme WRITE setMonoFontTheme NOTIFY appearancePrefsChanged)

    int getMenuStyle() const { return menuStyle; }
    void setMenuStyle(int value) { setAppearanceProperty(menuStyle, value); }
    int getStatusbar() const { return statusbar; }
    void setStatusbar(int value) { setAppearanceProperty(statusbar, value); }
    int getResizeMode() const { return resizeMode; }
    void setResizeMode(int value) { setAppearanceProperty(resizeMode, value); }
    bool getAutoHideToolbar() const { return autoHideToolbar; }
    void setAutoHideToolbar(bool value) { setAppearanceProperty(autoHideToolbar, value); }

    int getAppearance() const { return appearance; }
    void setAppearance(int value) { setAppearanceProperty(appearance, value); }
    int getColorTheme() const { return colorTheme; }
    void setColorTheme(int value) { setAppearanceProperty(colorTheme, value); }
    int getFontTheme() const { return fontTheme; }
    void setFontTheme(int value) { setAppearanceProperty(fontTheme, value); }
    int getMonoFontTheme() const { return monoFontTheme; }
    void setMonoFontTheme(int value) { setAppearanceProperty(monoFontTheme, value); }

  private:

    template <typename T>
    void setAppearanceProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveAppearanceSettings();
            emit appearancePrefsChanged();
        }
    }

    //
    // Controls
    //

  public:

    const QHash<quint32, int> &getC64KeyMap() const { return c64KeyMap; }

    // Maps a physical key (native scancode) to a C64 key (see C64Key::nr).
    // Used by the virtual keyboard's key-recording feature. Any other
    // scancode previously mapped to the same C64 key is removed first, so
    // each C64 key is always reachable from at most one physical key.
    void setC64KeyMapping(quint32 scancode, int nr)
    {
        for (auto it = c64KeyMap.begin(); it != c64KeyMap.end(); ) {
            if (it.value() == nr && it.key() != scancode) it = c64KeyMap.erase(it);
            else ++it;
        }

        c64KeyMap.insert(scancode, nr);
        saveControlsSettings();
        emit controlsPrefsChanged();
    }

    // Discards all recorded overrides and restores the factory key map
    Q_INVOKABLE void resetC64KeyMap();

    // Human-readable summary of the existing mapping(s) for a given C64 key
    // (see C64Key::nr), e.g. for a tooltip while recording. No side effects.
    Q_INVOKABLE QString mappingInfo(int nr) const;

    // True if at least one physical key is currently mapped to the given C64 key
    Q_INVOKABLE bool isMapped(int nr) const;

    Q_PROPERTY(QString mouseHotkey READ getMouseHotkey WRITE setMouseHotkey NOTIFY
                       controlsPrefsChanged)
    Q_PROPERTY(bool retainMouseByPressing READ getRetainMouseByPressing WRITE setRetainMouseByPressing NOTIFY
                   controlsPrefsChanged)
    Q_PROPERTY(bool retainMouseByClicking READ getRetainMouseByClicking WRITE setRetainMouseByClicking NOTIFY
                   controlsPrefsChanged)
    Q_PROPERTY(bool retainMouseByDoubleClicking READ getRetainMouseByDoubleClicking WRITE setRetainMouseByDoubleClicking NOTIFY
                   controlsPrefsChanged)
    Q_PROPERTY(bool releaseMouseByPressing READ getReleaseMouseByPressing WRITE setReleaseMouseByPressing NOTIFY
                   controlsPrefsChanged)
    Q_PROPERTY(bool releaseMouseByShaking READ getReleaseMouseByShaking WRITE setReleaseMouseByShaking NOTIFY
                   controlsPrefsChanged)

    Q_PROPERTY(bool exitWithEsc READ getExitWithEsc WRITE setExitWithEsc NOTIFY controlsPrefsChanged)

    Q_PROPERTY(int capsLockAction READ getCapsLockAction WRITE setCapsLockAction NOTIFY controlsPrefsChanged)

    Q_PROPERTY(int c64KeyMapScheme READ getC64KeyMapScheme WRITE setC64KeyMapScheme NOTIFY controlsPrefsChanged)
    Q_PROPERTY(bool c64AutoReleaseKeys READ getC64AutoReleaseKeys WRITE setC64AutoReleaseKeys NOTIFY controlsPrefsChanged)
    Q_PROPERTY(int c64CtrlLeftAlt READ getC64CtrlLeftAlt WRITE setC64CtrlLeftAlt NOTIFY controlsPrefsChanged)
    Q_PROPERTY(int c64CtrlRightAlt READ getC64CtrlRightAlt WRITE setC64CtrlRightAlt NOTIFY controlsPrefsChanged)
    Q_PROPERTY(int c64CtrlLeftMeta READ getC64CtrlLeftMeta WRITE setC64CtrlLeftMeta NOTIFY controlsPrefsChanged)
    Q_PROPERTY(int c64CtrlRightMeta READ getC64CtrlRightMeta WRITE setC64CtrlRightMeta NOTIFY controlsPrefsChanged)

    QString getMouseHotkey() const { return mouseHotkey; }
    void setMouseHotkey(QString value) { setControlsProperty(mouseHotkey, value); }

    bool getRetainMouseByPressing() const { return retainMouseByPressing; }
    void setRetainMouseByPressing(bool value) { setControlsProperty(retainMouseByPressing, value); }

    bool getRetainMouseByClicking() const { return retainMouseByClicking; }
    void setRetainMouseByClicking(bool value) { setControlsProperty(retainMouseByClicking, value); }

    bool getRetainMouseByDoubleClicking() const { return retainMouseByDoubleClicking; }
    void setRetainMouseByDoubleClicking(bool value) { setControlsProperty(retainMouseByDoubleClicking, value); }

    bool getReleaseMouseByPressing() const { return releaseMouseByPressing; }
    void setReleaseMouseByPressing(bool value) { setControlsProperty(releaseMouseByPressing, value); }

    bool getReleaseMouseByShaking() const { return releaseMouseByShaking; }
    void setReleaseMouseByShaking(bool value) { setControlsProperty(releaseMouseByShaking, value); }

    bool getExitWithEsc() const { return exitWithEsc; }
    void setExitWithEsc(bool value) { setControlsProperty(exitWithEsc, value); }

    int getCapsLockAction() const { return capsLockAction; }
    void setCapsLockAction(int value) { setControlsProperty(capsLockAction, value); }

    int getC64KeyMapScheme() const { return c64KeyMapMode; }
    void setC64KeyMapScheme(int value) { setControlsProperty(c64KeyMapMode, value); }

    bool getC64AutoReleaseKeys() const { return c64AutoReleaseKeys; }
    void setC64AutoReleaseKeys(bool value) { setControlsProperty(c64AutoReleaseKeys, value); }

    int getC64CtrlLeftAlt() const { return c64CtrlLeftAlt; }
    void setC64CtrlLeftAlt(int value) { setControlsProperty(c64CtrlLeftAlt, value); }

    int getC64CtrlRightAlt() const { return c64CtrlRightAlt; }
    void setC64CtrlRightAlt(int value) { setControlsProperty(c64CtrlRightAlt, value); }

    int getC64CtrlLeftMeta() const { return c64CtrlLeftMeta; }
    void setC64CtrlLeftMeta(int value) { setControlsProperty(c64CtrlLeftMeta, value); }

    int getC64CtrlRightMeta() const { return c64CtrlRightMeta; }
    void setC64CtrlRightMeta(int value) { setControlsProperty(c64CtrlRightMeta, value); }

private:

    template <typename T>
    void setControlsProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveControlsSettings();
            emit controlsPrefsChanged();
        }
    }

    // Replaces c64KeyMap with the factory defaults (no save, no signal --
    // used both while loading settings and by the public resetC64KeyMap())
    void resetC64KeyMapToDefaults();

    //
    // Devices
    //

  public:

    Q_PROPERTY(float mouseSensitivity READ getMouseSensitivity WRITE setMouseSensitivity NOTIFY devicesPrefsChanged)

    Q_PROPERTY(bool disconnectEmulationKeys READ getDisconnectEmulationKeys WRITE setDisconnectEmulationKeys NOTIFY
                   devicesPrefsChanged)

    Q_PROPERTY(EmulationKey keyset1Left READ getKeyset1Left WRITE setKeyset1Left NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset1Right READ getKeyset1Right WRITE setKeyset1Right NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset1Up READ getKeyset1Up WRITE setKeyset1Up NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset1Down READ getKeyset1Down WRITE setKeyset1Down NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset1Fire READ getKeyset1Fire WRITE setKeyset1Fire NOTIFY devicesPrefsChanged)

    Q_PROPERTY(EmulationKey keyset2Left READ getKeyset2Left WRITE setKeyset2Left NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset2Right READ getKeyset2Right WRITE setKeyset2Right NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset2Up READ getKeyset2Up WRITE setKeyset2Up NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset2Down READ getKeyset2Down WRITE setKeyset2Down NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey keyset2Fire READ getKeyset2Fire WRITE setKeyset2Fire NOTIFY devicesPrefsChanged)

    Q_PROPERTY(EmulationKey mbutton1Key READ getMButton1Key WRITE setMButton1Key NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey mbutton2Key READ getMButton2Key WRITE setMButton2Key NOTIFY devicesPrefsChanged)
    Q_PROPERTY(EmulationKey mbutton3Key READ getMButton3Key WRITE setMButton3Key NOTIFY devicesPrefsChanged)

    float getMouseSensitivity() const { return mouseSensitivity; }
    void setMouseSensitivity(float value) { setDevicesProperty(mouseSensitivity, value); }

    bool getDisconnectEmulationKeys() const { return disconnectEmulationKeys; }
    void setDisconnectEmulationKeys(bool value) { setDevicesProperty(disconnectEmulationKeys, value); }

    // Returns the stored override for a gamepad, or an empty string if the
    // device still runs on the mapping SDL supplies.
    QString getGamepadMapping(const QString &guid) const
    {
        return gamepadMappings.value(guid).toString();
    }

    // Stores an override, or drops it again when 'mapping' is empty.
    void setGamepadMapping(const QString &guid, const QString &mapping)
    {
        auto updated = gamepadMappings;
        mapping.isEmpty() ? (void)updated.remove(guid) : (void)updated.insert(guid, mapping);
        setDevicesProperty(gamepadMappings, updated);
    }

    EmulationKey getKeyset1Left() const { return keyset1Left; }
    EmulationKey getKeyset1Right() const { return keyset1Right; }
    EmulationKey getKeyset1Up() const { return keyset1Up; }
    EmulationKey getKeyset1Down() const { return keyset1Down; }
    EmulationKey getKeyset1Fire() const { return keyset1Fire; }

    EmulationKey getKeyset2Left() const { return keyset2Left; }
    EmulationKey getKeyset2Right() const { return keyset2Right; }
    EmulationKey getKeyset2Up() const { return keyset2Up; }
    EmulationKey getKeyset2Down() const { return keyset2Down; }
    EmulationKey getKeyset2Fire() const { return keyset2Fire; }

    EmulationKey getMButton1Key() const { return mbutton1Key; }
    EmulationKey getMButton2Key() const { return mbutton2Key; }
    EmulationKey getMButton3Key() const { return mbutton3Key; }

    void setKeyset1Left(EmulationKey key)  { setDevicesProperty(keyset1Left, key); }
    void setKeyset1Right(EmulationKey key)  { setDevicesProperty(keyset1Right, key); }
    void setKeyset1Up(EmulationKey key)  { setDevicesProperty(keyset1Up, key); }
    void setKeyset1Down(EmulationKey key)  { setDevicesProperty(keyset1Down, key); }
    void setKeyset1Fire(EmulationKey key)  { setDevicesProperty(keyset1Fire, key); }

    void setKeyset2Left(EmulationKey key)  { setDevicesProperty(keyset2Left, key); }
    void setKeyset2Right(EmulationKey key)  { setDevicesProperty(keyset2Right, key); }
    void setKeyset2Up(EmulationKey key)  { setDevicesProperty(keyset2Up, key); }
    void setKeyset2Down(EmulationKey key)  { setDevicesProperty(keyset2Down, key); }
    void setKeyset2Fire(EmulationKey key)  { setDevicesProperty(keyset2Fire, key); }

    void setMButton1Key(EmulationKey key)  { setDevicesProperty(mbutton1Key, key); }
    void setMButton2Key(EmulationKey key)  { setDevicesProperty(mbutton2Key, key); }
    void setMButton3Key(EmulationKey key)  { setDevicesProperty(mbutton3Key, key); }

  private:

    template <typename T>
    void setDevicesProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveDevicesSettings();
            emit devicesPrefsChanged();
        }
    }


    //
    // Screenshots
    //

    Q_PROPERTY(int screenshotFormat READ getScreenshotFormat WRITE setScreenshotFormat NOTIFY screenshotPrefsChanged)
    Q_PROPERTY(int screenshotSource READ getScreenshotSource WRITE setScreenshotSource NOTIFY screenshotPrefsChanged)
    Q_PROPERTY(int screenshotCutout READ getScreenshotCutout WRITE setScreenshotCutout NOTIFY screenshotPrefsChanged)
    Q_PROPERTY(int screenshotWidth READ getScreenshotWidth WRITE setScreenshotWidth NOTIFY screenshotPrefsChanged)
    Q_PROPERTY(int screenshotHeight READ getScreenshotHeight WRITE setScreenshotHeight NOTIFY screenshotPrefsChanged)

    int getScreenshotFormat() const { return screenshotFormat; }
    void setScreenshotFormat(int value) { setScreenshotProperty(screenshotFormat, value); }
    int getScreenshotSource() const { return screenshotSource; }
    void setScreenshotSource(int value)  { setScreenshotProperty(screenshotSource, value); }
    int getScreenshotCutout() const { return screenshotCutout; }
    void setScreenshotCutout(int value) { setScreenshotProperty(screenshotCutout, value); }
    int getScreenshotWidth() const { return screenshotWidth; }
    void setScreenshotWidth(int value) { setScreenshotProperty(screenshotWidth, value); }
    int getScreenshotHeight() const { return screenshotHeight; }
    void setScreenshotHeight(int value) { setScreenshotProperty(screenshotHeight, value); }

  private:

    template <typename T>
    void setScreenshotProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveScreenshotSettings();
            emit screenshotPrefsChanged();
        }
    }

    //
    // Developer
    //

    Q_PROPERTY(bool developerMode READ getDeveloperMode WRITE setDeveloperMode NOTIFY developerPrefsChanged)
    Q_PROPERTY(bool qtDebug READ getQtDebug WRITE setQtDebug NOTIFY developerPrefsChanged)
    Q_PROPERTY(int logVerbosity READ getLogVerbosity WRITE setLogVerbosity NOTIFY developerPrefsChanged)

    bool getDeveloperMode() const { return developerMode; }
    void setDeveloperMode(bool value) { setDeveloperProperty(developerMode, value); }
    bool getQtDebug() const { return qtDebug; }
    void setQtDebug(bool value) { setDeveloperProperty(qtDebug, value); }
    int getLogVerbosity() const { return logVerbosity; }
    void setLogVerbosity(int value) { setDeveloperProperty(logVerbosity, value); }

  private:

    template <typename T>
    void setDeveloperProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveDeveloperSettings();
            emit developerPrefsChanged();
        }
    }

    //
    // Misc
    //

  public:

    Q_PROPERTY(QUrl basicPath READ getBasicPath WRITE setBasicPath NOTIFY miscPrefsChanged)
    Q_PROPERTY(QUrl charPath READ getCharPath WRITE setCharPath NOTIFY miscPrefsChanged)
    Q_PROPERTY(QUrl kernalPath READ getKernalPath WRITE setKernalPath NOTIFY miscPrefsChanged)
    Q_PROPERTY(QUrl vc1541Path READ getVc1541Path WRITE setVc1541Path NOTIFY miscPrefsChanged)

    QUrl getBasicPath() const { return basicPath; }
    void setBasicPath(const QUrl &value) { setMiscProperty(basicPath, value); }
    QUrl getCharPath() const { return charPath; }
    void setCharPath(const QUrl &value) { setMiscProperty(charPath, value); }
    QUrl getKernalPath() const { return kernalPath; }
    void setKernalPath(const QUrl &value) { setMiscProperty(kernalPath, value); }
    QUrl getVc1541Path() const { return vc1541Path; }
    void setVc1541Path(const QUrl &value) { setMiscProperty(vc1541Path, value); }

  private:

    template <typename T>
    void setMiscProperty(T& property, const T& newValue)
    {
        if (property != newValue) {
            property = newValue;
            saveMiscSettings();
            emit miscPrefsChanged();
        }
    }

  private:

    Q_INVOKABLE void loadSettings();
    Q_INVOKABLE void loadGeneralSettings();
    Q_INVOKABLE void loadAppearanceSettings();
    Q_INVOKABLE void loadControlsSettings();
    Q_INVOKABLE void loadDevicesSettings();
    Q_INVOKABLE void loadScreenshotSettings();
    Q_INVOKABLE void loadDeveloperSettings();
    Q_INVOKABLE void loadMiscSettings();

    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void saveGeneralSettings();
    Q_INVOKABLE void saveAppearanceSettings();
    Q_INVOKABLE void saveControlsSettings();
    Q_INVOKABLE void saveDevicesSettings();
    Q_INVOKABLE void saveScreenshotSettings();
    Q_INVOKABLE void saveDeveloperSettings();
    Q_INVOKABLE void saveMiscSettings();

  public:

    /* Discards all user settings of a group and restores the factory defaults.
     * Each function drops the group from the backing store and reloads it, so
     * the group's changed signal fires and any SiC64 helper process is notified
     * (see reloadGroup). Called from the preferences pages' burger menus, which
     * is why these are public: one function per page.
     */
    Q_INVOKABLE void resetSettings();
    Q_INVOKABLE void resetGeneralSettings();
    Q_INVOKABLE void resetAppearanceSettings();
    Q_INVOKABLE void resetControlsSettings();
    Q_INVOKABLE void resetDevicesSettings();
    Q_INVOKABLE void resetScreenshotSettings();
    Q_INVOKABLE void resetDeveloperSettings();
    Q_INVOKABLE void resetMiscSettings();

  signals:

    void generalPrefsChanged();
    void appearancePrefsChanged();
    void devicesPrefsChanged();
    void controlsPrefsChanged();
    void screenshotPrefsChanged();
    void developerPrefsChanged();
    void miscPrefsChanged();
};
