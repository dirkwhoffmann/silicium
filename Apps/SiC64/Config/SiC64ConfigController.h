// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "VirtualC64.h"
#include "Controller.h"
#include <QColor>
#include <QUrl>

//
// Port of Silicium's C64ConfigController, retyped for SiC64's own core
// (C64Controller::core(), a static VirtualC64 singleton) instead of the
// Hub-managed per-VM core the original controller was handed. The Q_PROPERTY
// surface matches the original one-for-one, so the ported config panels bind
// unchanged.
//

class C64Controller;

class SiC64ConfigController : public Controller {

    Q_OBJECT

    // Owning virtual machine controller
    C64Controller *parent = nullptr;

    // Drive selectors (mirrors vc64::DRIVE8 / vc64::DRIVE9)
    static constexpr long Drive8 = 0;
    static constexpr long Drive9 = 1;

    // Cached ROM properties
    vc64::RomTraits basicRom {};
    vc64::RomTraits kernalRom {};
    vc64::RomTraits charRom {};
    vc64::RomTraits vc1541Rom {};

  public:

    explicit SiC64ConfigController(C64Controller *parent = nullptr);
    ~SiC64ConfigController();


    //
    // Roms
    //

  public:

    Q_PROPERTY(bool hasBasicRom READ hasBasicRom NOTIFY romConfigChanged)
    Q_PROPERTY(u64 basicRomFnv READ getBasicRomFnv NOTIFY romConfigChanged)
    Q_PROPERTY(u32 basicRomCrc READ getBasicRomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl basicRomIcon READ getBasicRomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString basicRomTitle READ getBasicRomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString basicRomSubtitle READ getBasicRomSubtitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString basicRomRevision READ getBasicRomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString basicRomVendor READ getBasicRomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedBasicRom READ hasPatchedBasicRom NOTIFY romConfigChanged)

    Q_PROPERTY(bool hasKernalRom READ hasKernalRom NOTIFY romConfigChanged)
    Q_PROPERTY(u64 kernalRomFnv READ getKernalRomFnv NOTIFY romConfigChanged)
    Q_PROPERTY(u32 kernalRomCrc READ getKernalRomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl kernalRomIcon READ getKernalRomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString kernalRomTitle READ getKernalRomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString kernalRomSubtitle READ getKernalRomSubtitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString kernalRomRevision READ getKernalRomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString kernalRomVendor READ getKernalRomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedKernalRom READ hasPatchedKernalRom NOTIFY romConfigChanged)

    Q_PROPERTY(bool hasCharRom READ hasCharRom NOTIFY romConfigChanged)
    Q_PROPERTY(u64 charRomFnv READ getCharRomFnv NOTIFY romConfigChanged)
    Q_PROPERTY(u32 charRomCrc READ getCharRomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl charRomIcon READ getCharRomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString charRomTitle READ getCharRomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString charRomSubtitle READ getCharRomSubtitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString charRomRevision READ getCharRomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString charRomVendor READ getCharRomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedCharRom READ hasPatchedCharRom NOTIFY romConfigChanged)

    Q_PROPERTY(bool hasVC1541Rom READ hasVC1541Rom NOTIFY romConfigChanged)
    Q_PROPERTY(u64 vc1541RomFnv READ getVC1541RomFnv NOTIFY romConfigChanged)
    Q_PROPERTY(u32 vc1541RomCrc READ getVC1541RomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl vc1541RomIcon READ getVC1541RomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString vc1541RomTitle READ getVC1541RomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString vc1541RomSubtitle READ getVC1541RomSubtitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString vc1541RomRevision READ getVC1541RomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString vc1541RomVendor READ getVC1541RomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedVC1541Rom READ hasPatchedVC1541Rom NOTIFY romConfigChanged)

    Q_INVOKABLE bool isBasicRom(const QUrl &url) const { return isRom(url, vc64::RomType::BASIC); }
    Q_INVOKABLE bool isKernalRom(const QUrl &url) const { return isRom(url, vc64::RomType::KERNAL); }
    Q_INVOKABLE bool isCharRom(const QUrl &url) const { return isRom(url, vc64::RomType::CHAR); }
    Q_INVOKABLE bool isVC1541Rom(const QUrl &url) const { return isRom(url, vc64::RomType::VC1541); }

    Q_INVOKABLE void loadRom(const QUrl &url);
    Q_INVOKABLE void loadRom(const QUrl &url, vc64::RomType type);

    // Type-constrained loaders for use from QML, where RomType isn't accessible
    Q_INVOKABLE void loadBasicRom(const QUrl &url) { loadRom(url, vc64::RomType::BASIC); }
    Q_INVOKABLE void loadKernalRom(const QUrl &url) { loadRom(url, vc64::RomType::KERNAL); }
    Q_INVOKABLE void loadCharRom(const QUrl &url) { loadRom(url, vc64::RomType::CHAR); }
    Q_INVOKABLE void loadVC1541Rom(const QUrl &url) { loadRom(url, vc64::RomType::VC1541); }

    // Reloads the most recently used custom ROMs remembered in the user defaults
    Q_INVOKABLE void loadMostRecentRoms();

    // Installs the MEGA65 OpenROMs that ship inside the core. These are
    // free replacements for the BASIC, Kernal and Character ROMs; there is no
    // open VC1541 ROM, so that slot is left as it is.
    Q_INVOKABLE void installOpenRoms();
    Q_INVOKABLE void deleteBasicRom() { deleteRom(vc64::RomType::BASIC); }
    Q_INVOKABLE void deleteKernalRom() { deleteRom(vc64::RomType::KERNAL); }
    Q_INVOKABLE void deleteCharRom() { deleteRom(vc64::RomType::CHAR); }
    Q_INVOKABLE void deleteVC1541Rom() { deleteRom(vc64::RomType::VC1541); }

    // Updates all cached ROM traits
    Q_INVOKABLE void queryRoms();

  private:

    bool hasBasicRom() const { return basicRom.fnv != 0; }
    u64 getBasicRomFnv() const { return basicRom.fnv; }
    u32 getBasicRomCrc() const { return basicRom.crc; }
    QUrl getBasicRomIcon() const { return getRomIcon(basicRom); }
    QString getBasicRomTitle() const { return QString::fromUtf8(basicRom.title); }
    QString getBasicRomSubtitle() const { return QString::fromUtf8(basicRom.subtitle); }
    QString getBasicRomRevision() const { return QString::fromUtf8(basicRom.revision); }
    QString getBasicRomVendor() const { return getRomVendor(basicRom); }
    bool hasPatchedBasicRom() const { return basicRom.patched; }

    bool hasKernalRom() const { return kernalRom.fnv != 0; }
    u64 getKernalRomFnv() const { return kernalRom.fnv; }
    u32 getKernalRomCrc() const { return kernalRom.crc; }
    QUrl getKernalRomIcon() const { return getRomIcon(kernalRom); }
    QString getKernalRomTitle() const { return QString::fromUtf8(kernalRom.title); }
    QString getKernalRomSubtitle() const { return QString::fromUtf8(kernalRom.subtitle); }
    QString getKernalRomRevision() const { return QString::fromUtf8(kernalRom.revision); }
    QString getKernalRomVendor() const { return getRomVendor(kernalRom); }
    bool hasPatchedKernalRom() const { return kernalRom.patched; }

    bool hasCharRom() const { return charRom.fnv != 0; }
    u64 getCharRomFnv() const { return charRom.fnv; }
    u32 getCharRomCrc() const { return charRom.crc; }
    QUrl getCharRomIcon() const { return getRomIcon(charRom); }
    QString getCharRomTitle() const { return QString::fromUtf8(charRom.title); }
    QString getCharRomSubtitle() const { return QString::fromUtf8(charRom.subtitle); }
    QString getCharRomRevision() const { return QString::fromUtf8(charRom.revision); }
    QString getCharRomVendor() const { return getRomVendor(charRom); }
    bool hasPatchedCharRom() const { return charRom.patched; }

    bool hasVC1541Rom() const { return vc1541Rom.fnv != 0; }
    u64 getVC1541RomFnv() const { return vc1541Rom.fnv; }
    u32 getVC1541RomCrc() const { return vc1541Rom.crc; }
    QUrl getVC1541RomIcon() const { return getRomIcon(vc1541Rom); }
    QString getVC1541RomTitle() const { return QString::fromUtf8(vc1541Rom.title); }
    QString getVC1541RomSubtitle() const { return QString::fromUtf8(vc1541Rom.subtitle); }
    QString getVC1541RomRevision() const { return QString::fromUtf8(vc1541Rom.revision); }
    QString getVC1541RomVendor() const { return getRomVendor(vc1541Rom); }
    bool hasPatchedVC1541Rom() const { return vc1541Rom.patched; }

    QUrl getRomIcon(const vc64::RomTraits &traits) const;
    QString getRomVendor(const vc64::RomTraits &traits) const;

    void deleteRom(vc64::RomType type);

    // Remembers the URL of a successfully loaded ROM in the user defaults
    void rememberRomPath(const QUrl &url, vc64::RomType type);

    bool isRom(const QUrl &url, vc64::RomType type) const;


    //
    // Configuration options
    //

  public:

    //
    // Host
    //

    Q_PROPERTY(int HOST_REFRESH_RATE READ hostRefreshRate WRITE setHostRefreshRate NOTIFY configChanged)
    Q_PROPERTY(int HOST_SAMPLE_RATE READ hostSampleRate WRITE setHostSampleRate NOTIFY configChanged)
    Q_PROPERTY(int HOST_TEX_FORMAT READ hostTexFormat WRITE setHostTexFormat NOTIFY configChanged)
    Q_PROPERTY(int HOST_FRAMEBUF_WIDTH READ hostFramebufWidth WRITE setHostFramebufWidth NOTIFY configChanged)
    Q_PROPERTY(int HOST_FRAMEBUF_HEIGHT READ hostFramebufHeight WRITE setHostFramebufHeight NOTIFY configChanged)

    int hostRefreshRate() const { return (int)get(vc64::Opt::HOST_REFRESH_RATE); }
    void setHostRefreshRate(int value) { set(vc64::Opt::HOST_REFRESH_RATE, (i64)value); }
    int hostSampleRate() const { return (int)get(vc64::Opt::HOST_SAMPLE_RATE); }
    void setHostSampleRate(int value) { set(vc64::Opt::HOST_SAMPLE_RATE, (i64)value); }
    int hostTexFormat() const { return (int)get(vc64::Opt::HOST_TEX_FORMAT); }
    void setHostTexFormat(int value) { set(vc64::Opt::HOST_TEX_FORMAT, (i64)value); }
    int hostFramebufWidth() const { return (int)get(vc64::Opt::HOST_FRAMEBUF_WIDTH); }
    void setHostFramebufWidth(int value) { set(vc64::Opt::HOST_FRAMEBUF_WIDTH, (i64)value); }
    int hostFramebufHeight() const { return (int)get(vc64::Opt::HOST_FRAMEBUF_HEIGHT); }
    void setHostFramebufHeight(int value) { set(vc64::Opt::HOST_FRAMEBUF_HEIGHT, (i64)value); }

    //
    // Disassembler
    //

    // Number format used by the disassembler/inspector panels: 0 = hex,
    // 1 = hex padded, 2 = decimal, 3 = decimal padded (mirrors
    // C64Controller::format).
    Q_PROPERTY(int DASM_NUMBERS READ dasmNumbers WRITE setDasmNumbers NOTIFY configChanged)

    int dasmNumbers() const { return (int)get(vc64::Opt::DASM_NUMBERS); }
    void setDasmNumbers(int value) { set(vc64::Opt::DASM_NUMBERS, (i64)value); }

    //
    // Hardware
    //

    Q_PROPERTY(int VICII_REVISION READ vicRevision WRITE setVicRevision NOTIFY configChanged)
    Q_PROPERTY(int VICII_GRAY_DOT_BUG READ vicGrayDotBug WRITE setVicGrayDotBug NOTIFY configChanged)
    Q_PROPERTY(bool VICII_HIDE_SPRITES READ vicHideSprites WRITE setVicHideSprites NOTIFY configChanged)
    Q_PROPERTY(int VICII_CUT_LAYERS READ vicCutLayers WRITE setVicCutLayers NOTIFY configChanged)
    Q_PROPERTY(int VICII_CUT_OPACITY READ vicCutOpacity WRITE setVicCutOpacity NOTIFY configChanged)
    Q_PROPERTY(int CIA_REVISION READ ciaRevision WRITE setCiaRevision NOTIFY configChanged)
    Q_PROPERTY(bool CIA_TIMER_B_BUG READ ciaTimerBBug WRITE setCiaTimerBBug NOTIFY configChanged)
    Q_PROPERTY(int SID_REV READ sidRevision WRITE setSidRevision NOTIFY configChanged)
    Q_PROPERTY(bool SID_ENABLE1 READ sidEnable1 WRITE setSidEnable1 NOTIFY configChanged)
    Q_PROPERTY(bool SID_ENABLE2 READ sidEnable2 WRITE setSidEnable2 NOTIFY configChanged)
    Q_PROPERTY(bool SID_ENABLE3 READ sidEnable3 WRITE setSidEnable3 NOTIFY configChanged)
    Q_PROPERTY(int SID_ADDRESS1 READ sidAddress1 WRITE setSidAddress1 NOTIFY configChanged)
    Q_PROPERTY(int SID_ADDRESS2 READ sidAddress2 WRITE setSidAddress2 NOTIFY configChanged)
    Q_PROPERTY(int SID_ADDRESS3 READ sidAddress3 WRITE setSidAddress3 NOTIFY configChanged)
    Q_PROPERTY(bool SID_FILTER READ sidFilter WRITE setSidFilter NOTIFY configChanged)
    Q_PROPERTY(int GLUE_LOGIC READ glueLogic WRITE setGlueLogic NOTIFY configChanged)
    Q_PROPERTY(int POWER_GRID READ powerGrid WRITE setPowerGrid NOTIFY configChanged)
    Q_PROPERTY(int MEM_INIT_PATTERN READ ramPattern WRITE setRamPattern NOTIFY configChanged)
    // Enables the memory-access heatmap texture, populated only while the
    // Memory inspector is open (see SiC64MemoryController).
    Q_PROPERTY(bool MEM_HEATMAP READ memHeatmap WRITE setMemHeatmap NOTIFY configChanged)

    // Restores the factory settings for every option the Hardware panel
    // exposes (SiC64HardwareConfig.qml) -- note that's a subset of the
    // hardware options above, e.g. the VICII cutout and heatmap debug options
    // aren't on that panel and are left untouched.
    Q_INVOKABLE void restoreHardwareDefaults();

    int vicRevision() const { return (int)get(vc64::Opt::VICII_REVISION); }
    void setVicRevision(int value) { set(vc64::Opt::VICII_REVISION, (i64)value); }
    bool vicGrayDotBug() const { return (bool)get(vc64::Opt::VICII_GRAY_DOT_BUG); }
    void setVicGrayDotBug(bool value) { set(vc64::Opt::VICII_GRAY_DOT_BUG, (i64)value); }
    bool vicHideSprites() const { return (bool)get(vc64::Opt::VICII_HIDE_SPRITES); }
    void setVicHideSprites(bool value) { set(vc64::Opt::VICII_HIDE_SPRITES, (i64)value); }
    int vicCutLayers() const { return (int)get(vc64::Opt::VICII_CUT_LAYERS); }
    void setVicCutLayers(int value) { set(vc64::Opt::VICII_CUT_LAYERS, (i64)value); }
    int vicCutOpacity() const { return (int)get(vc64::Opt::VICII_CUT_OPACITY); }
    void setVicCutOpacity(int value) { set(vc64::Opt::VICII_CUT_OPACITY, (i64)value); }
    int ciaRevision() const { return (int)get(vc64::Opt::CIA_REVISION); }
    void setCiaRevision(int value) { set(vc64::Opt::CIA_REVISION, (i64)value); }
    bool ciaTimerBBug() const { return (bool)get(vc64::Opt::CIA_TIMER_B_BUG); }
    void setCiaTimerBBug(bool value) { set(vc64::Opt::CIA_TIMER_B_BUG, (i64)value); }
    int sidRevision() const { return (int)get(vc64::Opt::SID_REV, 0); }
    void setSidRevision(int value) { set(vc64::Opt::SID_REV, (i64)value, 0); }
    bool sidEnable1() const { return (bool)get(vc64::Opt::SID_ENABLE, 1); }
    void setSidEnable1(bool value) { set(vc64::Opt::SID_ENABLE, (i64)value, 1); }
    bool sidEnable2() const { return (bool)get(vc64::Opt::SID_ENABLE, 2); }
    void setSidEnable2(bool value) { set(vc64::Opt::SID_ENABLE, (i64)value, 2); }
    bool sidEnable3() const { return (bool)get(vc64::Opt::SID_ENABLE, 3); }
    void setSidEnable3(bool value) { set(vc64::Opt::SID_ENABLE, (i64)value, 3); }
    int sidAddress1() const { return (int)get(vc64::Opt::SID_ADDRESS, 1); }
    void setSidAddress1(int value) { set(vc64::Opt::SID_ADDRESS, (i64)value, 1); }
    int sidAddress2() const { return (int)get(vc64::Opt::SID_ADDRESS, 2); }
    void setSidAddress2(int value) { set(vc64::Opt::SID_ADDRESS, (i64)value, 2); }
    int sidAddress3() const { return (int)get(vc64::Opt::SID_ADDRESS, 3); }
    void setSidAddress3(int value) { set(vc64::Opt::SID_ADDRESS, (i64)value, 3); }
    bool sidFilter() const { return (bool)get(vc64::Opt::SID_FILTER, 0); }
    void setSidFilter(bool value) { set(vc64::Opt::SID_FILTER, (i64)value, 0); }
    int glueLogic() const { return (int)get(vc64::Opt::GLUE_LOGIC); }
    void setGlueLogic(int value) { set(vc64::Opt::GLUE_LOGIC, (i64)value); }
    int powerGrid() const { return (int)get(vc64::Opt::POWER_GRID); }
    void setPowerGrid(int value) { set(vc64::Opt::POWER_GRID, (i64)value); }
    int ramPattern() const { return (int)get(vc64::Opt::MEM_INIT_PATTERN); }
    void setRamPattern(int value) { set(vc64::Opt::MEM_INIT_PATTERN, (i64)value); }
    bool memHeatmap() const { return (bool)get(vc64::Opt::MEM_HEATMAP); }
    void setMemHeatmap(bool value) { set(vc64::Opt::MEM_HEATMAP, (i64)value); }

    //
    // Peripherals
    //

    Q_PROPERTY(bool DRIVE8_CONNECTED READ drive8Connected WRITE setDrive8Connected NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE9_CONNECTED READ drive9Connected WRITE setDrive9Connected NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE8_AUTO_CONFIG READ drive8AutoConf WRITE setDrive8AutoConf NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE9_AUTO_CONFIG READ drive9AutoConf WRITE setDrive9AutoConf NOTIFY configChanged)
    Q_PROPERTY(int DRIVE8_TYPE READ drive8Type WRITE setDrive8Type NOTIFY configChanged)
    Q_PROPERTY(int DRIVE9_TYPE READ drive9Type WRITE setDrive9Type NOTIFY configChanged)
    Q_PROPERTY(int DRIVE8_RAM READ drive8Ram WRITE setDrive8Ram NOTIFY configChanged)
    Q_PROPERTY(int DRIVE9_RAM READ drive9Ram WRITE setDrive9Ram NOTIFY configChanged)
    Q_PROPERTY(int DRIVE8_PARCABLE READ drive8ParCable WRITE setDrive8ParCable NOTIFY configChanged)
    Q_PROPERTY(int DRIVE9_PARCABLE READ drive9ParCable WRITE setDrive9ParCable NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE8_POWER_SWITCH READ drive8PowerSwitch WRITE setDrive8PowerSwitch NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE9_POWER_SWITCH READ drive9PowerSwitch WRITE setDrive9PowerSwitch NOTIFY configChanged)
    Q_PROPERTY(bool DAT_CONNECT READ datasetteConnected WRITE setDatasetteConnected NOTIFY configChanged)
    Q_PROPERTY(int DAT_MODEL READ datasetteModel WRITE setDatasetteModel NOTIFY configChanged)
    Q_PROPERTY(int MOUSE_MODEL READ mouseModel WRITE setMouseModel NOTIFY configChanged)
    Q_PROPERTY(int PADDLE_ORIENTATION READ paddleOrientation WRITE setPaddleOrientation NOTIFY configChanged)
    Q_PROPERTY(bool AUTOFIRE READ autofire WRITE setAutofire NOTIFY configChanged)
    Q_PROPERTY(bool AUTOFIRE_BURSTS READ autofireBursts WRITE setAutofireBursts NOTIFY configChanged)
    Q_PROPERTY(int AUTOFIRE_BULLETS READ autofireBullets WRITE setAutofireBullets NOTIFY configChanged)
    Q_PROPERTY(int AUTOFIRE_DELAY READ autofireFrequency WRITE setAutofireFrequency NOTIFY configChanged)

    bool drive8Connected() const { return (bool)get(vc64::Opt::DRV_CONNECT, Drive8); }
    void setDrive8Connected(bool value) { set(vc64::Opt::DRV_CONNECT, (i64)value, Drive8); }
    bool drive9Connected() const { return (bool)get(vc64::Opt::DRV_CONNECT, Drive9); }
    void setDrive9Connected(bool value) { set(vc64::Opt::DRV_CONNECT, (i64)value, Drive9); }
    bool drive8AutoConf() const { return (bool)get(vc64::Opt::DRV_AUTO_CONFIG, Drive8); }
    void setDrive8AutoConf(bool value) { set(vc64::Opt::DRV_AUTO_CONFIG, (i64)value, Drive8); }
    bool drive9AutoConf() const { return (bool)get(vc64::Opt::DRV_AUTO_CONFIG, Drive9); }
    void setDrive9AutoConf(bool value) { set(vc64::Opt::DRV_AUTO_CONFIG, (i64)value, Drive9); }
    int drive8Type() const { return (int)get(vc64::Opt::DRV_TYPE, Drive8); }
    void setDrive8Type(int value) { set(vc64::Opt::DRV_TYPE, (i64)value, Drive8); }
    int drive9Type() const { return (int)get(vc64::Opt::DRV_TYPE, Drive9); }
    void setDrive9Type(int value) { set(vc64::Opt::DRV_TYPE, (i64)value, Drive9); }
    int drive8Ram() const { return (int)get(vc64::Opt::DRV_RAM, Drive8); }
    void setDrive8Ram(int value) { set(vc64::Opt::DRV_RAM, (i64)value, Drive8); }
    int drive9Ram() const { return (int)get(vc64::Opt::DRV_RAM, Drive9); }
    void setDrive9Ram(int value) { set(vc64::Opt::DRV_RAM, (i64)value, Drive9); }
    int drive8ParCable() const { return (int)get(vc64::Opt::DRV_PARCABLE, Drive8); }
    void setDrive8ParCable(int value) { set(vc64::Opt::DRV_PARCABLE, (i64)value, Drive8); }
    int drive9ParCable() const { return (int)get(vc64::Opt::DRV_PARCABLE, Drive9); }
    void setDrive9ParCable(int value) { set(vc64::Opt::DRV_PARCABLE, (i64)value, Drive9); }
    bool drive8PowerSwitch() const { return (bool)get(vc64::Opt::DRV_POWER_SWITCH, Drive8); }
    void setDrive8PowerSwitch(bool value) { set(vc64::Opt::DRV_POWER_SWITCH, (i64)value, Drive8); }
    bool drive9PowerSwitch() const { return (bool)get(vc64::Opt::DRV_POWER_SWITCH, Drive9); }
    void setDrive9PowerSwitch(bool value) { set(vc64::Opt::DRV_POWER_SWITCH, (i64)value, Drive9); }
    bool datasetteConnected() const { return (bool)get(vc64::Opt::DAT_CONNECT); }
    void setDatasetteConnected(bool value) { set(vc64::Opt::DAT_CONNECT, (i64)value); }
    int datasetteModel() const { return (int)get(vc64::Opt::DAT_MODEL); }
    void setDatasetteModel(int value) { set(vc64::Opt::DAT_MODEL, (i64)value); }
    int mouseModel() const { return (int)get(vc64::Opt::MOUSE_MODEL, 1); }
    void setMouseModel(int value) { set(vc64::Opt::MOUSE_MODEL, (i64)value); }
    int paddleOrientation() const { return (int)get(vc64::Opt::PADDLE_ORIENTATION, 1); }
    void setPaddleOrientation(int value) { set(vc64::Opt::PADDLE_ORIENTATION, (i64)value); }
    bool autofire() const { return (bool)get(vc64::Opt::AUTOFIRE, 1); }
    void setAutofire(bool value) { set(vc64::Opt::AUTOFIRE, (i64)value); }
    bool autofireBursts() const { return (bool)get(vc64::Opt::AUTOFIRE_BURSTS, 1); }
    void setAutofireBursts(bool value) { set(vc64::Opt::AUTOFIRE_BURSTS, (i64)value); }
    int autofireBullets() const { return (int)get(vc64::Opt::AUTOFIRE_BULLETS, 1); }
    void setAutofireBullets(int value) { set(vc64::Opt::AUTOFIRE_BULLETS, (i64)value); }
    int autofireFrequency() const { return (int)get(vc64::Opt::AUTOFIRE_DELAY, 1); }
    void setAutofireFrequency(int value) { set(vc64::Opt::AUTOFIRE_DELAY, (i64)value); }

    // Restores the factory settings for every option the Devices panel
    // exposes (SiC64DevicesConfig.qml).
    Q_INVOKABLE void restoreDevicesDefaults();

    //
    // Performance
    //

    Q_PROPERTY(bool DRIVE8_POWER_SAVE READ drive8PowerSave WRITE setDrive8PowerSave NOTIFY configChanged)
    Q_PROPERTY(bool DRIVE9_POWER_SAVE READ drive9PowerSave WRITE setDrive9PowerSave NOTIFY configChanged)
    Q_PROPERTY(bool VICII_POWER_SAVE READ viciiPowerSave WRITE setViciiPowerSave NOTIFY configChanged)
    Q_PROPERTY(bool SID_POWER_SAVE READ sidPowerSave WRITE setSidPowerSave NOTIFY configChanged)
    Q_PROPERTY(bool VICII_SS_COLLISIONS READ ssCollisions WRITE setSsCollisions NOTIFY configChanged)
    Q_PROPERTY(bool VICII_SB_COLLISIONS READ sbCollisions WRITE setSbCollisions NOTIFY configChanged)
    Q_PROPERTY(int C64_WARP_MODE READ warpMode WRITE setWarpMode NOTIFY configChanged)
    Q_PROPERTY(int C64_WARP_BOOT READ warpBoot WRITE setWarpBoot NOTIFY configChanged)
    Q_PROPERTY(bool C64_VSYNC READ vsync WRITE setVsync NOTIFY configChanged)
    Q_PROPERTY(int C64_SPEED_BOOST READ speedBoost WRITE setSpeedBoost NOTIFY configChanged)
    Q_PROPERTY(int C64_RUN_AHEAD READ runAhead WRITE setRunAhead NOTIFY configChanged)

    bool drive8PowerSave() const { return (bool)get(vc64::Opt::DRV_POWER_SAVE, Drive8); }
    void setDrive8PowerSave(bool value) { set(vc64::Opt::DRV_POWER_SAVE, (i64)value, Drive8); }
    bool drive9PowerSave() const { return (bool)get(vc64::Opt::DRV_POWER_SAVE, Drive9); }
    void setDrive9PowerSave(bool value) { set(vc64::Opt::DRV_POWER_SAVE, (i64)value, Drive9); }
    bool viciiPowerSave() const { return (bool)get(vc64::Opt::VICII_POWER_SAVE); }
    void setViciiPowerSave(bool value) { set(vc64::Opt::VICII_POWER_SAVE, (i64)value); }
    bool sidPowerSave() const { return (bool)get(vc64::Opt::SID_POWER_SAVE, 0); }
    void setSidPowerSave(bool value) { set(vc64::Opt::SID_POWER_SAVE, (i64)value); }
    bool ssCollisions() const { return (bool)get(vc64::Opt::VICII_SS_COLLISIONS); }
    void setSsCollisions(bool value) { set(vc64::Opt::VICII_SS_COLLISIONS, (i64)value); }
    bool sbCollisions() const { return (bool)get(vc64::Opt::VICII_SB_COLLISIONS); }
    void setSbCollisions(bool value) { set(vc64::Opt::VICII_SB_COLLISIONS, (i64)value); }
    int warpMode() const { return (int)get(vc64::Opt::C64_WARP_MODE); }
    void setWarpMode(int value) { set(vc64::Opt::C64_WARP_MODE, (i64)value); }
    int warpBoot() const { return (int)get(vc64::Opt::C64_WARP_BOOT); }
    void setWarpBoot(int value) { set(vc64::Opt::C64_WARP_BOOT, (i64)value); }
    bool vsync() const { return (bool)get(vc64::Opt::C64_VSYNC); }
    void setVsync(bool value) { set(vc64::Opt::C64_VSYNC, (i64)value); }
    int speedBoost() const { return (int)get(vc64::Opt::C64_SPEED_BOOST); }
    void setSpeedBoost(int value) { set(vc64::Opt::C64_SPEED_BOOST, (i64)value); }
    int runAhead() const { return (int)get(vc64::Opt::C64_RUN_AHEAD); }
    void setRunAhead(int value) { set(vc64::Opt::C64_RUN_AHEAD, (i64)value); }

    // Restores the factory settings for every option the Performance panel
    // exposes (SiC64PerformanceConfig.qml).
    Q_INVOKABLE void restorePerformanceDefaults();

    //
    // Audio
    //

    Q_PROPERTY(int SID_ENGINE READ sidEngine WRITE setSidEngine NOTIFY configChanged)
    Q_PROPERTY(int SID_SAMPLING READ sidSampling WRITE setSidSampling NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL0 READ vol0 WRITE setVol0 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL1 READ vol1 WRITE setVol1 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL2 READ vol2 WRITE setVol2 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL3 READ vol3 WRITE setVol3 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN0 READ pan0 WRITE setPan0 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN1 READ pan1 WRITE setPan1 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN2 READ pan2 WRITE setPan2 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN3 READ pan3 WRITE setPan3 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL_L READ volL WRITE setVolL NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL_R READ volR WRITE setVolR NOTIFY configChanged)
    Q_PROPERTY(int DRV_STEP_VOL READ stepVolume WRITE setStepVolume NOTIFY configChanged)
    Q_PROPERTY(int DRV_INSERT_VOL READ insertVolume WRITE setInsertVolume NOTIFY configChanged)
    Q_PROPERTY(int DRV_EJECT_VOL READ ejectVolume WRITE setEjectVolume NOTIFY configChanged)
    Q_PROPERTY(int DRIVE8_PAN READ drive8Pan WRITE setDrive8Pan NOTIFY configChanged)
    Q_PROPERTY(int DRIVE9_PAN READ drive9Pan WRITE setDrive9Pan NOTIFY configChanged)
    Q_PROPERTY(int AUD_ASR READ asr WRITE setAsr NOTIFY configChanged)
    Q_PROPERTY(int AUD_BUFFER_SIZE READ audioBufferSize WRITE setAudioBufferSize NOTIFY configChanged)

    int sidEngine() const { return (int)get(vc64::Opt::SID_ENGINE, 0); }
    void setSidEngine(int value) { set(vc64::Opt::SID_ENGINE, (i64)value); }
    int sidSampling() const { return (int)get(vc64::Opt::SID_SAMPLING, 0); }
    void setSidSampling(int value) { set(vc64::Opt::SID_SAMPLING, (i64)value); }
    int vol0() const { return (int)get(vc64::Opt::AUD_VOL0); }
    void setVol0(int value) { set(vc64::Opt::AUD_VOL0, (i64)value); }
    int vol1() const { return (int)get(vc64::Opt::AUD_VOL1); }
    void setVol1(int value) { set(vc64::Opt::AUD_VOL1, (i64)value); }
    int vol2() const { return (int)get(vc64::Opt::AUD_VOL2); }
    void setVol2(int value) { set(vc64::Opt::AUD_VOL2, (i64)value); }
    int vol3() const { return (int)get(vc64::Opt::AUD_VOL3); }
    void setVol3(int value) { set(vc64::Opt::AUD_VOL3, (i64)value); }
    int pan0() const { return (int)get(vc64::Opt::AUD_PAN0); }
    void setPan0(int value) { set(vc64::Opt::AUD_PAN0, (i64)value); }
    int pan1() const { return (int)get(vc64::Opt::AUD_PAN1); }
    void setPan1(int value) { set(vc64::Opt::AUD_PAN1, (i64)value); }
    int pan2() const { return (int)get(vc64::Opt::AUD_PAN2); }
    void setPan2(int value) { set(vc64::Opt::AUD_PAN2, (i64)value); }
    int pan3() const { return (int)get(vc64::Opt::AUD_PAN3); }
    void setPan3(int value) { set(vc64::Opt::AUD_PAN3, (i64)value); }
    int volL() const { return (int)get(vc64::Opt::AUD_VOL_L); }
    void setVolL(int value) { set(vc64::Opt::AUD_VOL_L, (i64)value); }
    int volR() const { return (int)get(vc64::Opt::AUD_VOL_R); }
    void setVolR(int value) { set(vc64::Opt::AUD_VOL_R, (i64)value); }
    int stepVolume() const { return (int)get(vc64::Opt::DRV_STEP_VOL, Drive8); }
    void setStepVolume(int value) { set(vc64::Opt::DRV_STEP_VOL, (i64)value); }
    int insertVolume() const { return (int)get(vc64::Opt::DRV_INSERT_VOL, Drive8); }
    void setInsertVolume(int value) { set(vc64::Opt::DRV_INSERT_VOL, (i64)value); }
    int ejectVolume() const { return (int)get(vc64::Opt::DRV_EJECT_VOL, Drive8); }
    void setEjectVolume(int value) { set(vc64::Opt::DRV_EJECT_VOL, (i64)value); }
    int drive8Pan() const { return (int)get(vc64::Opt::DRV_PAN, Drive8); }
    void setDrive8Pan(int value) { set(vc64::Opt::DRV_PAN, (i64)value, Drive8); }
    int drive9Pan() const { return (int)get(vc64::Opt::DRV_PAN, Drive9); }
    void setDrive9Pan(int value) { set(vc64::Opt::DRV_PAN, (i64)value, Drive9); }
    int asr() const { return (int)get(vc64::Opt::AUD_ASR); }
    void setAsr(int value) { set(vc64::Opt::AUD_ASR, (i64)value); }
    int audioBufferSize() const { return (int)get(vc64::Opt::AUD_BUFFER_SIZE); }
    void setAudioBufferSize(int value) { set(vc64::Opt::AUD_BUFFER_SIZE, (i64)value); }

    // Restores the factory settings for every option the Audio panel exposes
    // (SiC64AudioConfig.qml).
    Q_INVOKABLE void restoreAudioDefaults();

    //
    // Video
    //

    Q_PROPERTY(int MON_PALETTE READ palette WRITE setPalette NOTIFY configChanged)
    Q_PROPERTY(int MON_BRIGHTNESS READ brightness WRITE setBrightness NOTIFY configChanged)
    Q_PROPERTY(int MON_CONTRAST READ contrast WRITE setContrast NOTIFY configChanged)
    Q_PROPERTY(int MON_SATURATION READ saturation WRITE setSaturation NOTIFY configChanged)
    Q_PROPERTY(int MON_HCENTER READ hCenter WRITE setHCenter NOTIFY configChanged)
    Q_PROPERTY(int MON_VCENTER READ vCenter WRITE setVCenter NOTIFY configChanged)
    Q_PROPERTY(int MON_HZOOM READ hZoom WRITE setHZoom NOTIFY configChanged)
    Q_PROPERTY(int MON_VZOOM READ vZoom WRITE setVZoom NOTIFY configChanged)

    int palette() const { return (int)get(vc64::Opt::MON_PALETTE); }
    void setPalette(int value) { set(vc64::Opt::MON_PALETTE, (i64)value); }
    int brightness() const { return (int)get(vc64::Opt::MON_BRIGHTNESS); }
    void setBrightness(int value) { set(vc64::Opt::MON_BRIGHTNESS, (i64)value); }
    int contrast() const { return (int)get(vc64::Opt::MON_CONTRAST); }
    void setContrast(int value) { set(vc64::Opt::MON_CONTRAST, (i64)value); }
    int saturation() const { return (int)get(vc64::Opt::MON_SATURATION); }
    void setSaturation(int value) { set(vc64::Opt::MON_SATURATION, (i64)value); }
    int hCenter() const { return (int)get(vc64::Opt::MON_HCENTER); }
    void setHCenter(int value) { set(vc64::Opt::MON_HCENTER, (i64)value); }
    int vCenter() const { return (int)get(vc64::Opt::MON_VCENTER); }
    void setVCenter(int value) { set(vc64::Opt::MON_VCENTER, (i64)value); }
    int hZoom() const { return (int)get(vc64::Opt::MON_HZOOM); }
    void setHZoom(int value) { set(vc64::Opt::MON_HZOOM, (i64)value); }
    int vZoom() const { return (int)get(vc64::Opt::MON_VZOOM); }
    void setVZoom(int value) { set(vc64::Opt::MON_VZOOM, (i64)value); }

    // Restores the factory settings for every option the Video panel exposes
    // (SiC64VideoConfig.qml) -- the panel covers the geometry and color
    // options only, so the other MON_* options are left untouched.
    Q_INVOKABLE void restoreVideoDefaults();

    //
    // Servers
    //

    Q_PROPERTY(bool SRV_RSH_ENABLE READ rshServerEnable WRITE setRshServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_RSH_TRANSPORT READ rshServerTransport WRITE setRshServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_RSH_PORT READ rshServerPort WRITE setRshServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_RPC_ENABLE READ rpcServerEnable WRITE setRpcServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_RPC_TRANSPORT READ rpcServerTransport WRITE setRpcServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_RPC_PORT READ rpcServerPort WRITE setRpcServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_DAP_ENABLE READ dapServerEnable WRITE setDapServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_DAP_TRANSPORT READ dapServerTransport WRITE setDapServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_DAP_PORT READ dapServerPort WRITE setDapServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_PROM_ENABLE READ promServerEnable WRITE setPromServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_PROM_TRANSPORT READ promServerTransport WRITE setPromServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_PROM_PORT READ promServerPort WRITE setPromServerPort NOTIFY configChanged)

    bool rshServerEnable() const { return (bool)get(vc64::Opt::SRV_ENABLE, 0); }
    void setRshServerEnable(bool value) { set(vc64::Opt::SRV_ENABLE, (i64)value, 0); }
    int rshServerTransport() const { return (int)get(vc64::Opt::SRV_TRANSPORT, 0); }
    void setRshServerTransport(int value) { set(vc64::Opt::SRV_TRANSPORT, (i64)value, 0); }
    int rshServerPort() const { return (int)get(vc64::Opt::SRV_PORT, 0); }
    void setRshServerPort(int value) { set(vc64::Opt::SRV_PORT, (i64)value, 0); }
    bool rpcServerEnable() const { return (bool)get(vc64::Opt::SRV_ENABLE, 1); }
    void setRpcServerEnable(bool value) { set(vc64::Opt::SRV_ENABLE, (i64)value, 1); }
    int rpcServerTransport() const { return (int)get(vc64::Opt::SRV_TRANSPORT, 1); }
    void setRpcServerTransport(int value) { set(vc64::Opt::SRV_TRANSPORT, (i64)value, 1); }
    int rpcServerPort() const { return (int)get(vc64::Opt::SRV_PORT, 1); }
    void setRpcServerPort(int value) { set(vc64::Opt::SRV_PORT, (i64)value, 1); }
    bool dapServerEnable() const { return (bool)get(vc64::Opt::SRV_ENABLE, 2); }
    void setDapServerEnable(bool value) { set(vc64::Opt::SRV_ENABLE, (i64)value, 2); }
    int dapServerTransport() const { return (int)get(vc64::Opt::SRV_TRANSPORT, 2); }
    void setDapServerTransport(int value) { set(vc64::Opt::SRV_TRANSPORT, (i64)value, 2); }
    int dapServerPort() const { return (int)get(vc64::Opt::SRV_PORT, 2); }
    void setDapServerPort(int value) { set(vc64::Opt::SRV_PORT, (i64)value, 2); }
    bool promServerEnable() const { return (bool)get(vc64::Opt::SRV_ENABLE, 3); }
    void setPromServerEnable(bool value) { set(vc64::Opt::SRV_ENABLE, (i64)value, 3); }
    int promServerTransport() const { return (int)get(vc64::Opt::SRV_TRANSPORT, 3); }
    void setPromServerTransport(int value) { set(vc64::Opt::SRV_TRANSPORT, (i64)value, 3); }
    int promServerPort() const { return (int)get(vc64::Opt::SRV_PORT, 3); }
    void setPromServerPort(int value) { set(vc64::Opt::SRV_PORT, (i64)value, 3); }

    // Restores the factory settings for every option the Server panel exposes
    // (SiC64ServerConfig.qml).
    Q_INVOKABLE void restoreServerDefaults();

    //
    // DMA Debugger
    //

  public:

    Q_PROPERTY(bool DMA_DEBUG_ENABLE READ dmaDebugEnable WRITE setDmaDebugEnable NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_OVERLAY READ dmaDebugOverlay WRITE setDmaDebugOverlay NOTIFY configChanged)
    Q_PROPERTY(int DMA_DEBUG_MODE READ dmaDebugMode WRITE setDmaDebugMode NOTIFY configChanged)
    Q_PROPERTY(int DMA_DEBUG_OPACITY READ dmaDebugOpacity WRITE setDmaDebugOpacity NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL0 READ dmaDebugChannel0 WRITE setDmaDebugChannel0 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL1 READ dmaDebugChannel1 WRITE setDmaDebugChannel1 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL2 READ dmaDebugChannel2 WRITE setDmaDebugChannel2 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL3 READ dmaDebugChannel3 WRITE setDmaDebugChannel3 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL4 READ dmaDebugChannel4 WRITE setDmaDebugChannel4 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL5 READ dmaDebugChannel5 WRITE setDmaDebugChannel5 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR0 READ dmaDebugColor0 WRITE setDmaDebugColor0 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR1 READ dmaDebugColor1 WRITE setDmaDebugColor1 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR2 READ dmaDebugColor2 WRITE setDmaDebugColor2 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR3 READ dmaDebugColor3 WRITE setDmaDebugColor3 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR4 READ dmaDebugColor4 WRITE setDmaDebugColor4 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR5 READ dmaDebugColor5 WRITE setDmaDebugColor5 NOTIFY configChanged)

    bool dmaDebugEnable() const { return (bool)get(vc64::Opt::DMA_DEBUG_ENABLE); }
    void setDmaDebugEnable(bool value) { set(vc64::Opt::DMA_DEBUG_ENABLE, (i64)value); }
    bool dmaDebugOverlay() const { return (bool)get(vc64::Opt::DMA_DEBUG_OVERLAY); }
    void setDmaDebugOverlay(bool value) { set(vc64::Opt::DMA_DEBUG_OVERLAY, (i64)value); }
    int dmaDebugMode() const { return (int)get(vc64::Opt::DMA_DEBUG_MODE); }
    void setDmaDebugMode(int value) { set(vc64::Opt::DMA_DEBUG_MODE, (i64)value); }
    int dmaDebugOpacity() const { return (int)get(vc64::Opt::DMA_DEBUG_OPACITY); }
    void setDmaDebugOpacity(int value) { set(vc64::Opt::DMA_DEBUG_OPACITY, (i64)value); }
    bool dmaDebugChannel0() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL0); }
    void setDmaDebugChannel0(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL0, (i64)value); }
    bool dmaDebugChannel1() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL1); }
    void setDmaDebugChannel1(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL1, (i64)value); }
    bool dmaDebugChannel2() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL2); }
    void setDmaDebugChannel2(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL2, (i64)value); }
    bool dmaDebugChannel3() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL3); }
    void setDmaDebugChannel3(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL3, (i64)value); }
    bool dmaDebugChannel4() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL4); }
    void setDmaDebugChannel4(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL4, (i64)value); }
    bool dmaDebugChannel5() const { return (bool)get(vc64::Opt::DMA_DEBUG_CHANNEL5); }
    void setDmaDebugChannel5(bool value) { set(vc64::Opt::DMA_DEBUG_CHANNEL5, (i64)value); }
    QColor dmaDebugColor0() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR0); }
    void setDmaDebugColor0(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR0, c); }
    QColor dmaDebugColor1() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR1); }
    void setDmaDebugColor1(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR1, c); }
    QColor dmaDebugColor2() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR2); }
    void setDmaDebugColor2(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR2, c); }
    QColor dmaDebugColor3() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR3); }
    void setDmaDebugColor3(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR3, c); }
    QColor dmaDebugColor4() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR4); }
    void setDmaDebugColor4(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR4, c); }
    QColor dmaDebugColor5() const { return dmaColor(vc64::Opt::DMA_DEBUG_COLOR5); }
    void setDmaDebugColor5(const QColor &c) { setDmaColor(vc64::Opt::DMA_DEBUG_COLOR5, c); }

    //
    // Helpers
    //

  private:

    i64 get(vc64::Opt opt) const;
    i64 get(vc64::Opt opt, long id) const;
    void set(vc64::Opt opt, i64 newValue);
    void set(vc64::Opt opt, i64 newValue, long id);
    QColor dmaColor(vc64::Opt opt) const;
    void setDmaColor(vc64::Opt opt, const QColor &c);

    // Drops the user's stored value for an option so the core's factory
    // fallback applies again, and pushes that value into the running machine.
    // 'objids' selects the sub-components to reset for indexed options (e.g.
    // the individual SIDs); leave it empty for plain, unindexed ones.
    void restoreDefaults(vc64::Opt opt, std::vector<isize> objids = { });

    //
    // Signals
    //

  signals:

    void configChanged();
    void romConfigChanged();
};
