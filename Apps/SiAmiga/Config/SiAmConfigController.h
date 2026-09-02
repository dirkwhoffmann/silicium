// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "VAmiga.h"
#include "Controller.h"
#include <QColor>
#include <QUrl>

//
// Port of Silicium's C64ConfigController (as adapted for SiC64 -- see
// SiC64ConfigController), retargeted at vamiga::Opt, the config option set
// vAmiga offers. The shape is the same: one Q_PROPERTY per scalar option,
// backed by a get()/set() pair that goes straight to SiAmController::core().
//
// vAmiga has roughly four times the option count of the C64 core (Agnus,
// Denise, Blitter, RTC, up to four floppy and four hard drives, ...), and
// several of those are indexed 0..3 rather than the pair SiC64Controller
// deals with (Drive8/Drive9). Named per-instance properties stay the shape
// for genuinely small, fixed sets (the two CIAs, the two mouse/joystick
// ports, the five remote servers) -- exactly SiC64ConfigController's own
// pattern -- but ballooning that same pattern out to four drives times ten
// options each would mean forty near-identical property declarations, so
// floppy- and hard-drive options are exposed as Q_INVOKABLE(nr) pairs
// instead. Both shapes bind fine from QML; only the drive panel's future
// implementation cares about the difference (a Repeater over df[0..3]/
// hd[0..3] rather than four hand-written rows).
//

class SiAmController;

class SiAmConfigController : public Controller {

    Q_OBJECT

    // Owning virtual machine controller
    SiAmController *parent = nullptr;

    // Cached ROM properties
    vamiga::RomTraits kickRom {};
    vamiga::RomTraits extRom {};

  public:

    explicit SiAmConfigController(SiAmController *parent = nullptr);
    ~SiAmConfigController();


    //
    // Roms
    //

  public:

    Q_PROPERTY(bool hasKickRom READ hasKickRom NOTIFY romConfigChanged)
    Q_PROPERTY(u32 kickRomCrc READ getKickRomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl kickRomIcon READ getKickRomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString kickRomTitle READ getKickRomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString kickRomRevision READ getKickRomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString kickRomReleased READ getKickRomReleased NOTIFY romConfigChanged)
    Q_PROPERTY(QString kickRomModel READ getKickRomModel NOTIFY romConfigChanged)
    Q_PROPERTY(QString kickRomVendor READ getKickRomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedKickRom READ hasPatchedKickRom NOTIFY romConfigChanged)

    Q_PROPERTY(bool hasExtRom READ hasExtRom NOTIFY romConfigChanged)
    Q_PROPERTY(u32 extRomCrc READ getExtRomCrc NOTIFY romConfigChanged)
    Q_PROPERTY(QUrl extRomIcon READ getExtRomIcon NOTIFY romConfigChanged)
    Q_PROPERTY(QString extRomTitle READ getExtRomTitle NOTIFY romConfigChanged)
    Q_PROPERTY(QString extRomRevision READ getExtRomRevision NOTIFY romConfigChanged)
    Q_PROPERTY(QString extRomReleased READ getExtRomReleased NOTIFY romConfigChanged)
    Q_PROPERTY(QString extRomModel READ getExtRomModel NOTIFY romConfigChanged)
    Q_PROPERTY(QString extRomVendor READ getExtRomVendor NOTIFY romConfigChanged)
    Q_PROPERTY(bool hasPatchedExtRom READ hasPatchedExtRom NOTIFY romConfigChanged)

    // Unlike vc64's RomFile, vAmiga's RomFile format is the same for the
    // Kickstart and Extended ROM slots -- there's nothing in the file itself
    // that says which one it's meant for, so there's no isKickRom/isExtRom
    // pair here, just a plain compatibility check.
    Q_INVOKABLE bool isRom(const QUrl &url) const;

    Q_INVOKABLE void loadKickRom(const QUrl &url);
    Q_INVOKABLE void loadExtRom(const QUrl &url);
    Q_INVOKABLE void deleteKickRom();
    Q_INVOKABLE void deleteExtRom();

    // Updates all cached ROM traits
    Q_INVOKABLE void queryRoms();

  private:

    bool hasKickRom() const { return kickRom.crc != 0; }
    u32 getKickRomCrc() const { return kickRom.crc; }
    QUrl getKickRomIcon() const { return getRomIcon(kickRom); }
    QString getKickRomTitle() const { return QString::fromUtf8(kickRom.title); }
    QString getKickRomRevision() const { return QString::fromUtf8(kickRom.revision); }
    QString getKickRomReleased() const { return QString::fromUtf8(kickRom.released); }
    QString getKickRomModel() const { return QString::fromUtf8(kickRom.model); }
    QString getKickRomVendor() const { return getRomVendor(kickRom); }
    bool hasPatchedKickRom() const { return kickRom.patched; }

    bool hasExtRom() const { return extRom.crc != 0; }
    u32 getExtRomCrc() const { return extRom.crc; }
    QUrl getExtRomIcon() const { return getRomIcon(extRom); }
    QString getExtRomTitle() const { return QString::fromUtf8(extRom.title); }
    QString getExtRomRevision() const { return QString::fromUtf8(extRom.revision); }
    QString getExtRomReleased() const { return QString::fromUtf8(extRom.released); }
    QString getExtRomModel() const { return QString::fromUtf8(extRom.model); }
    QString getExtRomVendor() const { return getRomVendor(extRom); }
    bool hasPatchedExtRom() const { return extRom.patched; }

    QUrl getRomIcon(const vamiga::RomTraits &traits) const;
    QString getRomVendor(const vamiga::RomTraits &traits) const;


    //
    // Configuration options
    //

  public:

    //
    // Host
    //

    Q_PROPERTY(int HOST_REFRESH_RATE READ hostRefreshRate WRITE setHostRefreshRate NOTIFY configChanged)
    Q_PROPERTY(int HOST_SAMPLE_RATE READ hostSampleRate WRITE setHostSampleRate NOTIFY configChanged)
    Q_PROPERTY(int HOST_FRAMEBUF_WIDTH READ hostFramebufWidth WRITE setHostFramebufWidth NOTIFY configChanged)
    Q_PROPERTY(int HOST_FRAMEBUF_HEIGHT READ hostFramebufHeight WRITE setHostFramebufHeight NOTIFY configChanged)

    int hostRefreshRate() const { return (int)get(vamiga::Opt::HOST_REFRESH_RATE); }
    void setHostRefreshRate(int value) { set(vamiga::Opt::HOST_REFRESH_RATE, (i64)value); }
    int hostSampleRate() const { return (int)get(vamiga::Opt::HOST_SAMPLE_RATE); }
    void setHostSampleRate(int value) { set(vamiga::Opt::HOST_SAMPLE_RATE, (i64)value); }
    int hostFramebufWidth() const { return (int)get(vamiga::Opt::HOST_FRAMEBUF_WIDTH); }
    void setHostFramebufWidth(int value) { set(vamiga::Opt::HOST_FRAMEBUF_WIDTH, (i64)value); }
    int hostFramebufHeight() const { return (int)get(vamiga::Opt::HOST_FRAMEBUF_HEIGHT); }
    void setHostFramebufHeight(int value) { set(vamiga::Opt::HOST_FRAMEBUF_HEIGHT, (i64)value); }

    //
    // Disassembler
    //

    Q_PROPERTY(int CPU_DASM_REVISION READ dasmRevision WRITE setDasmRevision NOTIFY configChanged)
    Q_PROPERTY(int CPU_DASM_SYNTAX READ dasmSyntax WRITE setDasmSyntax NOTIFY configChanged)
    Q_PROPERTY(int CPU_DASM_NUMBERS READ dasmNumbers WRITE setDasmNumbers NOTIFY configChanged)

    int dasmRevision() const { return (int)get(vamiga::Opt::CPU_DASM_REVISION); }
    void setDasmRevision(int value) { set(vamiga::Opt::CPU_DASM_REVISION, (i64)value); }
    int dasmSyntax() const { return (int)get(vamiga::Opt::CPU_DASM_SYNTAX); }
    void setDasmSyntax(int value) { set(vamiga::Opt::CPU_DASM_SYNTAX, (i64)value); }
    int dasmNumbers() const { return (int)get(vamiga::Opt::CPU_DASM_NUMBERS); }
    void setDasmNumbers(int value) { set(vamiga::Opt::CPU_DASM_NUMBERS, (i64)value); }

    //
    // Hardware
    //

    Q_PROPERTY(int AMIGA_VIDEO_FORMAT READ videoFormat WRITE setVideoFormat NOTIFY configChanged)
    Q_PROPERTY(int AGNUS_REVISION READ agnusRevision WRITE setAgnusRevision NOTIFY configChanged)
    Q_PROPERTY(bool AGNUS_PTR_DROPS READ agnusPtrDrops WRITE setAgnusPtrDrops NOTIFY configChanged)
    Q_PROPERTY(int DENISE_REVISION READ deniseRevision WRITE setDeniseRevision NOTIFY configChanged)
    Q_PROPERTY(bool DENISE_SHRES_BLEND READ deniseShresBlend WRITE setDeniseShresBlend NOTIFY configChanged)
    Q_PROPERTY(bool DENISE_VIEWPORT_TRACKING READ deniseViewportTracking WRITE setDeniseViewportTracking NOTIFY configChanged)
    Q_PROPERTY(int DENISE_FRAME_SKIPPING READ deniseFrameSkipping WRITE setDeniseFrameSkipping NOTIFY configChanged)
    // Debug cutouts, not exposed by any panel yet -- kept for completeness.
    Q_PROPERTY(int DENISE_HIDDEN_BITPLANES READ deniseHiddenBitplanes WRITE setDeniseHiddenBitplanes NOTIFY configChanged)
    Q_PROPERTY(int DENISE_HIDDEN_SPRITES READ deniseHiddenSprites WRITE setDeniseHiddenSprites NOTIFY configChanged)
    Q_PROPERTY(int DENISE_HIDDEN_LAYERS READ deniseHiddenLayers WRITE setDeniseHiddenLayers NOTIFY configChanged)
    Q_PROPERTY(int DENISE_HIDDEN_LAYER_ALPHA READ deniseHiddenLayerAlpha WRITE setDeniseHiddenLayerAlpha NOTIFY configChanged)
    Q_PROPERTY(bool DENISE_CLX_SPR_SPR READ deniseClxSprSpr WRITE setDeniseClxSprSpr NOTIFY configChanged)
    Q_PROPERTY(bool DENISE_CLX_SPR_PLF READ deniseClxSprPlf WRITE setDeniseClxSprPlf NOTIFY configChanged)
    Q_PROPERTY(bool DENISE_CLX_PLF_PLF READ deniseClxPlfPlf WRITE setDeniseClxPlfPlf NOTIFY configChanged)
    Q_PROPERTY(int CPU_REVISION READ cpuRevision WRITE setCpuRevision NOTIFY configChanged)
    Q_PROPERTY(int CPU_OVERCLOCKING READ overclocking WRITE setOverclocking NOTIFY configChanged)
    Q_PROPERTY(int CPU_RESET_VAL READ cpuResetVal WRITE setCpuResetVal NOTIFY configChanged)
    Q_PROPERTY(int RTC_MODEL READ rtcModel WRITE setRtcModel NOTIFY configChanged)
    Q_PROPERTY(int MEM_BUS_WIDTH READ memBusWidth WRITE setMemBusWidth NOTIFY configChanged)
    Q_PROPERTY(int MEM_CHIP_RAM READ chipRam WRITE setChipRam NOTIFY configChanged)
    Q_PROPERTY(int MEM_SLOW_RAM READ slowRam WRITE setSlowRam NOTIFY configChanged)
    Q_PROPERTY(int MEM_FAST_RAM READ fastRam WRITE setFastRam NOTIFY configChanged)
    Q_PROPERTY(int MEM_EXT_START READ extStart WRITE setExtStart NOTIFY configChanged)
    Q_PROPERTY(bool MEM_SLOW_RAM_DELAY READ slowRamDelay WRITE setSlowRamDelay NOTIFY configChanged)
    Q_PROPERTY(bool MEM_SLOW_RAM_MIRROR READ slowRamMirror WRITE setSlowRamMirror NOTIFY configChanged)
    Q_PROPERTY(int MEM_BANKMAP READ bankMap WRITE setBankMap NOTIFY configChanged)
    Q_PROPERTY(int MEM_UNMAPPING_TYPE READ unmappingType WRITE setUnmappingType NOTIFY configChanged)
    Q_PROPERTY(int MEM_RAM_INIT_PATTERN READ ramInitPattern WRITE setRamInitPattern NOTIFY configChanged)
    Q_PROPERTY(bool MEM_SAVE_ROMS READ saveRoms WRITE setSaveRoms NOTIFY configChanged)
    Q_PROPERTY(int BLITTER_ACCURACY READ blitterAccuracy WRITE setBlitterAccuracy NOTIFY configChanged)
    Q_PROPERTY(int CIA_A_REVISION READ ciaARevision WRITE setCiaARevision NOTIFY configChanged)
    Q_PROPERTY(int CIA_B_REVISION READ ciaBRevision WRITE setCiaBRevision NOTIFY configChanged)
    Q_PROPERTY(bool DIAG_BOARD READ diagBoard WRITE setDiagBoard NOTIFY configChanged)

    // Restores the factory settings for every option the Hardware panel
    // exposes (SiAmHardwareConfig.qml) -- the Denise debug cutouts above
    // aren't on that panel and are left untouched, same rationale as
    // SiC64ConfigController's VICII cutout options.
    Q_INVOKABLE void restoreHardwareDefaults();

    int videoFormat() const { return (int)get(vamiga::Opt::AMIGA_VIDEO_FORMAT); }
    void setVideoFormat(int value) { set(vamiga::Opt::AMIGA_VIDEO_FORMAT, (i64)value); }
    int agnusRevision() const { return (int)get(vamiga::Opt::AGNUS_REVISION); }
    void setAgnusRevision(int value) { set(vamiga::Opt::AGNUS_REVISION, (i64)value); }
    bool agnusPtrDrops() const { return (bool)get(vamiga::Opt::AGNUS_PTR_DROPS); }
    void setAgnusPtrDrops(bool value) { set(vamiga::Opt::AGNUS_PTR_DROPS, (i64)value); }
    int deniseRevision() const { return (int)get(vamiga::Opt::DENISE_REVISION); }
    void setDeniseRevision(int value) { set(vamiga::Opt::DENISE_REVISION, (i64)value); }
    bool deniseShresBlend() const { return (bool)get(vamiga::Opt::DENISE_SHRES_BLEND); }
    void setDeniseShresBlend(bool value) { set(vamiga::Opt::DENISE_SHRES_BLEND, (i64)value); }
    bool deniseViewportTracking() const { return (bool)get(vamiga::Opt::DENISE_VIEWPORT_TRACKING); }
    void setDeniseViewportTracking(bool value) { set(vamiga::Opt::DENISE_VIEWPORT_TRACKING, (i64)value); }
    int deniseFrameSkipping() const { return (int)get(vamiga::Opt::DENISE_FRAME_SKIPPING); }
    void setDeniseFrameSkipping(int value) { set(vamiga::Opt::DENISE_FRAME_SKIPPING, (i64)value); }
    int deniseHiddenBitplanes() const { return (int)get(vamiga::Opt::DENISE_HIDDEN_BITPLANES); }
    void setDeniseHiddenBitplanes(int value) { set(vamiga::Opt::DENISE_HIDDEN_BITPLANES, (i64)value); }
    int deniseHiddenSprites() const { return (int)get(vamiga::Opt::DENISE_HIDDEN_SPRITES); }
    void setDeniseHiddenSprites(int value) { set(vamiga::Opt::DENISE_HIDDEN_SPRITES, (i64)value); }
    int deniseHiddenLayers() const { return (int)get(vamiga::Opt::DENISE_HIDDEN_LAYERS); }
    void setDeniseHiddenLayers(int value) { set(vamiga::Opt::DENISE_HIDDEN_LAYERS, (i64)value); }
    int deniseHiddenLayerAlpha() const { return (int)get(vamiga::Opt::DENISE_HIDDEN_LAYER_ALPHA); }
    void setDeniseHiddenLayerAlpha(int value) { set(vamiga::Opt::DENISE_HIDDEN_LAYER_ALPHA, (i64)value); }
    bool deniseClxSprSpr() const { return (bool)get(vamiga::Opt::DENISE_CLX_SPR_SPR); }
    void setDeniseClxSprSpr(bool value) { set(vamiga::Opt::DENISE_CLX_SPR_SPR, (i64)value); }
    bool deniseClxSprPlf() const { return (bool)get(vamiga::Opt::DENISE_CLX_SPR_PLF); }
    void setDeniseClxSprPlf(bool value) { set(vamiga::Opt::DENISE_CLX_SPR_PLF, (i64)value); }
    bool deniseClxPlfPlf() const { return (bool)get(vamiga::Opt::DENISE_CLX_PLF_PLF); }
    void setDeniseClxPlfPlf(bool value) { set(vamiga::Opt::DENISE_CLX_PLF_PLF, (i64)value); }
    int cpuRevision() const { return (int)get(vamiga::Opt::CPU_REVISION); }
    void setCpuRevision(int value) { set(vamiga::Opt::CPU_REVISION, (i64)value); }
    int overclocking() const { return (int)get(vamiga::Opt::CPU_OVERCLOCKING); }
    void setOverclocking(int value) { set(vamiga::Opt::CPU_OVERCLOCKING, (i64)value); }
    int cpuResetVal() const { return (int)get(vamiga::Opt::CPU_RESET_VAL); }
    void setCpuResetVal(int value) { set(vamiga::Opt::CPU_RESET_VAL, (i64)value); }
    int rtcModel() const { return (int)get(vamiga::Opt::RTC_MODEL); }
    void setRtcModel(int value) { set(vamiga::Opt::RTC_MODEL, (i64)value); }
    int memBusWidth() const { return (int)get(vamiga::Opt::MEM_BUS_WIDTH); }
    void setMemBusWidth(int value) { set(vamiga::Opt::MEM_BUS_WIDTH, (i64)value); }
    int chipRam() const { return (int)get(vamiga::Opt::MEM_CHIP_RAM); }
    void setChipRam(int value) { set(vamiga::Opt::MEM_CHIP_RAM, (i64)value); }
    int slowRam() const { return (int)get(vamiga::Opt::MEM_SLOW_RAM); }
    void setSlowRam(int value) { set(vamiga::Opt::MEM_SLOW_RAM, (i64)value); }
    int fastRam() const { return (int)get(vamiga::Opt::MEM_FAST_RAM); }
    void setFastRam(int value) { set(vamiga::Opt::MEM_FAST_RAM, (i64)value); }
    int extStart() const { return (int)get(vamiga::Opt::MEM_EXT_START); }
    void setExtStart(int value) { set(vamiga::Opt::MEM_EXT_START, (i64)value); }
    bool slowRamDelay() const { return (bool)get(vamiga::Opt::MEM_SLOW_RAM_DELAY); }
    void setSlowRamDelay(bool value) { set(vamiga::Opt::MEM_SLOW_RAM_DELAY, (i64)value); }
    bool slowRamMirror() const { return (bool)get(vamiga::Opt::MEM_SLOW_RAM_MIRROR); }
    void setSlowRamMirror(bool value) { set(vamiga::Opt::MEM_SLOW_RAM_MIRROR, (i64)value); }
    int bankMap() const { return (int)get(vamiga::Opt::MEM_BANKMAP); }
    void setBankMap(int value) { set(vamiga::Opt::MEM_BANKMAP, (i64)value); }
    int unmappingType() const { return (int)get(vamiga::Opt::MEM_UNMAPPING_TYPE); }
    void setUnmappingType(int value) { set(vamiga::Opt::MEM_UNMAPPING_TYPE, (i64)value); }
    int ramInitPattern() const { return (int)get(vamiga::Opt::MEM_RAM_INIT_PATTERN); }
    void setRamInitPattern(int value) { set(vamiga::Opt::MEM_RAM_INIT_PATTERN, (i64)value); }
    bool saveRoms() const { return (bool)get(vamiga::Opt::MEM_SAVE_ROMS); }
    void setSaveRoms(bool value) { set(vamiga::Opt::MEM_SAVE_ROMS, (i64)value); }
    int blitterAccuracy() const { return (int)get(vamiga::Opt::BLITTER_ACCURACY); }
    void setBlitterAccuracy(int value) { set(vamiga::Opt::BLITTER_ACCURACY, (i64)value); }
    int ciaARevision() const { return (int)get(vamiga::Opt::CIA_REVISION, CiaA); }
    void setCiaARevision(int value) { set(vamiga::Opt::CIA_REVISION, (i64)value, CiaA); }
    int ciaBRevision() const { return (int)get(vamiga::Opt::CIA_REVISION, CiaB); }
    void setCiaBRevision(int value) { set(vamiga::Opt::CIA_REVISION, (i64)value, CiaB); }
    bool diagBoard() const { return (bool)get(vamiga::Opt::DIAG_BOARD); }
    void setDiagBoard(bool value) { set(vamiga::Opt::DIAG_BOARD, (i64)value); }

    //
    // Peripherals
    //

    Q_PROPERTY(int CIA_A_TODBUG READ ciaATodBug WRITE setCiaATodBug NOTIFY configChanged)
    Q_PROPERTY(int CIA_B_TODBUG READ ciaBTodBug WRITE setCiaBTodBug NOTIFY configChanged)
    Q_PROPERTY(bool SER_DEVICE READ serDevice WRITE setSerDevice NOTIFY configChanged)
    Q_PROPERTY(bool SER_VERBOSE READ serVerbose WRITE setSerVerbose NOTIFY configChanged)
    Q_PROPERTY(int MIDI_DEVICE_OUT READ midiDeviceOut WRITE setMidiDeviceOut NOTIFY configChanged)
    Q_PROPERTY(int MIDI_DEVICE_IN READ midiDeviceIn WRITE setMidiDeviceIn NOTIFY configChanged)
    Q_PROPERTY(bool KBD_ACCURACY READ kbdAccuracy WRITE setKbdAccuracy NOTIFY configChanged)
    Q_PROPERTY(bool MOUSE1_PULLUP_RESISTORS READ mouse1PullupResistors WRITE setMouse1PullupResistors NOTIFY configChanged)
    Q_PROPERTY(bool MOUSE2_PULLUP_RESISTORS READ mouse2PullupResistors WRITE setMouse2PullupResistors NOTIFY configChanged)
    Q_PROPERTY(bool MOUSE1_SHAKE_DETECTION READ mouse1ShakeDetection WRITE setMouse1ShakeDetection NOTIFY configChanged)
    Q_PROPERTY(bool MOUSE2_SHAKE_DETECTION READ mouse2ShakeDetection WRITE setMouse2ShakeDetection NOTIFY configChanged)
    Q_PROPERTY(int MOUSE1_VELOCITY READ mouse1Velocity WRITE setMouse1Velocity NOTIFY configChanged)
    Q_PROPERTY(int MOUSE2_VELOCITY READ mouse2Velocity WRITE setMouse2Velocity NOTIFY configChanged)
    Q_PROPERTY(bool JOY1_AUTOFIRE READ joy1Autofire WRITE setJoy1Autofire NOTIFY configChanged)
    Q_PROPERTY(bool JOY2_AUTOFIRE READ joy2Autofire WRITE setJoy2Autofire NOTIFY configChanged)
    Q_PROPERTY(bool JOY1_AUTOFIRE_BURSTS READ joy1AutofireBursts WRITE setJoy1AutofireBursts NOTIFY configChanged)
    Q_PROPERTY(bool JOY2_AUTOFIRE_BURSTS READ joy2AutofireBursts WRITE setJoy2AutofireBursts NOTIFY configChanged)
    Q_PROPERTY(int JOY1_AUTOFIRE_BULLETS READ joy1AutofireBullets WRITE setJoy1AutofireBullets NOTIFY configChanged)
    Q_PROPERTY(int JOY2_AUTOFIRE_BULLETS READ joy2AutofireBullets WRITE setJoy2AutofireBullets NOTIFY configChanged)
    Q_PROPERTY(int JOY1_AUTOFIRE_DELAY READ joy1AutofireDelay WRITE setJoy1AutofireDelay NOTIFY configChanged)
    Q_PROPERTY(int JOY2_AUTOFIRE_DELAY READ joy2AutofireDelay WRITE setJoy2AutofireDelay NOTIFY configChanged)

    // Floppy drives (df0..df3) and hard drives (hd0..hd3) are exposed as
    // parameterized pairs rather than named properties -- see the header
    // comment at the top of this file for why.
    Q_INVOKABLE bool driveConnected(int nr) const { return (bool)get(vamiga::Opt::DRIVE_CONNECT, nr); }
    Q_INVOKABLE void setDriveConnected(int nr, bool value) { set(vamiga::Opt::DRIVE_CONNECT, (i64)value, nr); }
    Q_INVOKABLE int driveType(int nr) const { return (int)get(vamiga::Opt::DRIVE_TYPE, nr); }
    Q_INVOKABLE void setDriveType(int nr, int value) { set(vamiga::Opt::DRIVE_TYPE, (i64)value, nr); }
    Q_INVOKABLE int driveMechanics(int nr) const { return (int)get(vamiga::Opt::DRIVE_MECHANICS, nr); }
    Q_INVOKABLE void setDriveMechanics(int nr, int value) { set(vamiga::Opt::DRIVE_MECHANICS, (i64)value, nr); }
    Q_INVOKABLE int driveRpm(int nr) const { return (int)get(vamiga::Opt::DRIVE_RPM, nr); }
    Q_INVOKABLE void setDriveRpm(int nr, int value) { set(vamiga::Opt::DRIVE_RPM, (i64)value, nr); }
    Q_INVOKABLE int driveSwapDelay(int nr) const { return (int)get(vamiga::Opt::DRIVE_SWAP_DELAY, nr); }
    Q_INVOKABLE void setDriveSwapDelay(int nr, int value) { set(vamiga::Opt::DRIVE_SWAP_DELAY, (i64)value, nr); }

    Q_INVOKABLE bool hdConnected(int nr) const { return (bool)get(vamiga::Opt::HDC_CONNECT, nr); }
    Q_INVOKABLE void setHdConnected(int nr, bool value) { set(vamiga::Opt::HDC_CONNECT, (i64)value, nr); }
    Q_INVOKABLE int hdType(int nr) const { return (int)get(vamiga::Opt::HDR_TYPE, nr); }
    Q_INVOKABLE void setHdType(int nr, int value) { set(vamiga::Opt::HDR_TYPE, (i64)value, nr); }

    // Restores the factory settings for every option the Devices panel
    // exposes (SiAmDevicesConfig.qml).
    Q_INVOKABLE void restoreDevicesDefaults();

    int ciaATodBug() const { return (int)get(vamiga::Opt::CIA_TODBUG, CiaA); }
    void setCiaATodBug(int value) { set(vamiga::Opt::CIA_TODBUG, (i64)value, CiaA); }
    int ciaBTodBug() const { return (int)get(vamiga::Opt::CIA_TODBUG, CiaB); }
    void setCiaBTodBug(int value) { set(vamiga::Opt::CIA_TODBUG, (i64)value, CiaB); }
    bool serDevice() const { return (bool)get(vamiga::Opt::SER_DEVICE); }
    void setSerDevice(bool value) { set(vamiga::Opt::SER_DEVICE, (i64)value); }
    bool serVerbose() const { return (bool)get(vamiga::Opt::SER_VERBOSE); }
    void setSerVerbose(bool value) { set(vamiga::Opt::SER_VERBOSE, (i64)value); }
    int midiDeviceOut() const { return (int)get(vamiga::Opt::MIDI_DEVICE_OUT); }
    void setMidiDeviceOut(int value) { set(vamiga::Opt::MIDI_DEVICE_OUT, (i64)value); }
    int midiDeviceIn() const { return (int)get(vamiga::Opt::MIDI_DEVICE_IN); }
    void setMidiDeviceIn(int value) { set(vamiga::Opt::MIDI_DEVICE_IN, (i64)value); }
    bool kbdAccuracy() const { return (bool)get(vamiga::Opt::KBD_ACCURACY); }
    void setKbdAccuracy(bool value) { set(vamiga::Opt::KBD_ACCURACY, (i64)value); }
    bool mouse1PullupResistors() const { return (bool)get(vamiga::Opt::MOUSE_PULLUP_RESISTORS, Port1); }
    void setMouse1PullupResistors(bool value) { set(vamiga::Opt::MOUSE_PULLUP_RESISTORS, (i64)value, Port1); }
    bool mouse2PullupResistors() const { return (bool)get(vamiga::Opt::MOUSE_PULLUP_RESISTORS, Port2); }
    void setMouse2PullupResistors(bool value) { set(vamiga::Opt::MOUSE_PULLUP_RESISTORS, (i64)value, Port2); }
    bool mouse1ShakeDetection() const { return (bool)get(vamiga::Opt::MOUSE_SHAKE_DETECTION, Port1); }
    void setMouse1ShakeDetection(bool value) { set(vamiga::Opt::MOUSE_SHAKE_DETECTION, (i64)value, Port1); }
    bool mouse2ShakeDetection() const { return (bool)get(vamiga::Opt::MOUSE_SHAKE_DETECTION, Port2); }
    void setMouse2ShakeDetection(bool value) { set(vamiga::Opt::MOUSE_SHAKE_DETECTION, (i64)value, Port2); }
    int mouse1Velocity() const { return (int)get(vamiga::Opt::MOUSE_VELOCITY, Port1); }
    void setMouse1Velocity(int value) { set(vamiga::Opt::MOUSE_VELOCITY, (i64)value, Port1); }
    int mouse2Velocity() const { return (int)get(vamiga::Opt::MOUSE_VELOCITY, Port2); }
    void setMouse2Velocity(int value) { set(vamiga::Opt::MOUSE_VELOCITY, (i64)value, Port2); }
    bool joy1Autofire() const { return (bool)get(vamiga::Opt::JOY_AUTOFIRE, Port1); }
    void setJoy1Autofire(bool value) { set(vamiga::Opt::JOY_AUTOFIRE, (i64)value, Port1); }
    bool joy2Autofire() const { return (bool)get(vamiga::Opt::JOY_AUTOFIRE, Port2); }
    void setJoy2Autofire(bool value) { set(vamiga::Opt::JOY_AUTOFIRE, (i64)value, Port2); }
    bool joy1AutofireBursts() const { return (bool)get(vamiga::Opt::JOY_AUTOFIRE_BURSTS, Port1); }
    void setJoy1AutofireBursts(bool value) { set(vamiga::Opt::JOY_AUTOFIRE_BURSTS, (i64)value, Port1); }
    bool joy2AutofireBursts() const { return (bool)get(vamiga::Opt::JOY_AUTOFIRE_BURSTS, Port2); }
    void setJoy2AutofireBursts(bool value) { set(vamiga::Opt::JOY_AUTOFIRE_BURSTS, (i64)value, Port2); }
    int joy1AutofireBullets() const { return (int)get(vamiga::Opt::JOY_AUTOFIRE_BULLETS, Port1); }
    void setJoy1AutofireBullets(int value) { set(vamiga::Opt::JOY_AUTOFIRE_BULLETS, (i64)value, Port1); }
    int joy2AutofireBullets() const { return (int)get(vamiga::Opt::JOY_AUTOFIRE_BULLETS, Port2); }
    void setJoy2AutofireBullets(int value) { set(vamiga::Opt::JOY_AUTOFIRE_BULLETS, (i64)value, Port2); }
    int joy1AutofireDelay() const { return (int)get(vamiga::Opt::JOY_AUTOFIRE_DELAY, Port1); }
    void setJoy1AutofireDelay(int value) { set(vamiga::Opt::JOY_AUTOFIRE_DELAY, (i64)value, Port1); }
    int joy2AutofireDelay() const { return (int)get(vamiga::Opt::JOY_AUTOFIRE_DELAY, Port2); }
    void setJoy2AutofireDelay(int value) { set(vamiga::Opt::JOY_AUTOFIRE_DELAY, (i64)value, Port2); }

    //
    // Performance
    //

    Q_PROPERTY(int AMIGA_WARP_MODE READ warpMode WRITE setWarpMode NOTIFY configChanged)
    Q_PROPERTY(int AMIGA_WARP_BOOT READ warpBoot WRITE setWarpBoot NOTIFY configChanged)
    Q_PROPERTY(bool AMIGA_VSYNC READ vsync WRITE setVsync NOTIFY configChanged)
    Q_PROPERTY(int AMIGA_SPEED_BOOST READ speedBoost WRITE setSpeedBoost NOTIFY configChanged)
    Q_PROPERTY(int AMIGA_RUN_AHEAD READ runAhead WRITE setRunAhead NOTIFY configChanged)
    Q_PROPERTY(bool CIA_A_IDLE_SLEEP READ ciaAIdleSleep WRITE setCiaAIdleSleep NOTIFY configChanged)
    Q_PROPERTY(bool CIA_B_IDLE_SLEEP READ ciaBIdleSleep WRITE setCiaBIdleSleep NOTIFY configChanged)
    Q_PROPERTY(bool CIA_A_ECLOCK_SYNCING READ ciaAEClockSyncing WRITE setCiaAEClockSyncing NOTIFY configChanged)
    Q_PROPERTY(bool CIA_B_ECLOCK_SYNCING READ ciaBEClockSyncing WRITE setCiaBEClockSyncing NOTIFY configChanged)
    Q_PROPERTY(int DC_SPEED READ dcSpeed WRITE setDcSpeed NOTIFY configChanged)
    Q_PROPERTY(bool DC_LOCK_DSKSYNC READ dcLockDskSync WRITE setDcLockDskSync NOTIFY configChanged)
    Q_PROPERTY(bool DC_AUTO_DSKSYNC READ dcAutoDskSync WRITE setDcAutoDskSync NOTIFY configChanged)

    // Restores the factory settings for every option the Performance panel
    // exposes (SiAmPerformanceConfig.qml).
    Q_INVOKABLE void restorePerformanceDefaults();

    int warpMode() const { return (int)get(vamiga::Opt::AMIGA_WARP_MODE); }
    void setWarpMode(int value) { set(vamiga::Opt::AMIGA_WARP_MODE, (i64)value); }
    int warpBoot() const { return (int)get(vamiga::Opt::AMIGA_WARP_BOOT); }
    void setWarpBoot(int value) { set(vamiga::Opt::AMIGA_WARP_BOOT, (i64)value); }
    bool vsync() const { return (bool)get(vamiga::Opt::AMIGA_VSYNC); }
    void setVsync(bool value) { set(vamiga::Opt::AMIGA_VSYNC, (i64)value); }
    int speedBoost() const { return (int)get(vamiga::Opt::AMIGA_SPEED_BOOST); }
    void setSpeedBoost(int value) { set(vamiga::Opt::AMIGA_SPEED_BOOST, (i64)value); }
    int runAhead() const { return (int)get(vamiga::Opt::AMIGA_RUN_AHEAD); }
    void setRunAhead(int value) { set(vamiga::Opt::AMIGA_RUN_AHEAD, (i64)value); }
    bool ciaAIdleSleep() const { return (bool)get(vamiga::Opt::CIA_IDLE_SLEEP, CiaA); }
    void setCiaAIdleSleep(bool value) { set(vamiga::Opt::CIA_IDLE_SLEEP, (i64)value, CiaA); }
    bool ciaBIdleSleep() const { return (bool)get(vamiga::Opt::CIA_IDLE_SLEEP, CiaB); }
    void setCiaBIdleSleep(bool value) { set(vamiga::Opt::CIA_IDLE_SLEEP, (i64)value, CiaB); }
    bool ciaAEClockSyncing() const { return (bool)get(vamiga::Opt::CIA_ECLOCK_SYNCING, CiaA); }
    void setCiaAEClockSyncing(bool value) { set(vamiga::Opt::CIA_ECLOCK_SYNCING, (i64)value, CiaA); }
    bool ciaBEClockSyncing() const { return (bool)get(vamiga::Opt::CIA_ECLOCK_SYNCING, CiaB); }
    void setCiaBEClockSyncing(bool value) { set(vamiga::Opt::CIA_ECLOCK_SYNCING, (i64)value, CiaB); }
    int dcSpeed() const { return (int)get(vamiga::Opt::DC_SPEED); }
    void setDcSpeed(int value) { set(vamiga::Opt::DC_SPEED, (i64)value); }
    bool dcLockDskSync() const { return (bool)get(vamiga::Opt::DC_LOCK_DSKSYNC); }
    void setDcLockDskSync(bool value) { set(vamiga::Opt::DC_LOCK_DSKSYNC, (i64)value); }
    bool dcAutoDskSync() const { return (bool)get(vamiga::Opt::DC_AUTO_DSKSYNC); }
    void setDcAutoDskSync(bool value) { set(vamiga::Opt::DC_AUTO_DSKSYNC, (i64)value); }

    //
    // Audio
    //

    Q_PROPERTY(int AUD_VOL0 READ vol0 WRITE setVol0 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL1 READ vol1 WRITE setVol1 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL2 READ vol2 WRITE setVol2 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOL3 READ vol3 WRITE setVol3 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN0 READ pan0 WRITE setPan0 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN1 READ pan1 WRITE setPan1 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN2 READ pan2 WRITE setPan2 NOTIFY configChanged)
    Q_PROPERTY(int AUD_PAN3 READ pan3 WRITE setPan3 NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOLL READ volL WRITE setVolL NOTIFY configChanged)
    Q_PROPERTY(int AUD_VOLR READ volR WRITE setVolR NOTIFY configChanged)
    Q_PROPERTY(int AUD_FILTER_TYPE READ audioFilterType WRITE setAudioFilterType NOTIFY configChanged)
    Q_PROPERTY(int AUD_BUFFER_SIZE READ audioBufferSize WRITE setAudioBufferSize NOTIFY configChanged)
    Q_PROPERTY(int AUD_SAMPLING_METHOD READ samplingMethod WRITE setSamplingMethod NOTIFY configChanged)
    Q_PROPERTY(bool AUD_ASR READ asr WRITE setAsr NOTIFY configChanged)
    Q_PROPERTY(bool AUD_FASTPATH READ audioFastpath WRITE setAudioFastpath NOTIFY configChanged)

    // Per-drive/per-hard-drive audio options, same rationale as the drive
    // connection options above.
    Q_INVOKABLE int drivePan(int nr) const { return (int)get(vamiga::Opt::DRIVE_PAN, nr); }
    Q_INVOKABLE void setDrivePan(int nr, int value) { set(vamiga::Opt::DRIVE_PAN, (i64)value, nr); }
    Q_INVOKABLE int driveStepVolume(int nr) const { return (int)get(vamiga::Opt::DRIVE_STEP_VOLUME, nr); }
    Q_INVOKABLE void setDriveStepVolume(int nr, int value) { set(vamiga::Opt::DRIVE_STEP_VOLUME, (i64)value, nr); }
    Q_INVOKABLE int drivePollVolume(int nr) const { return (int)get(vamiga::Opt::DRIVE_POLL_VOLUME, nr); }
    Q_INVOKABLE void setDrivePollVolume(int nr, int value) { set(vamiga::Opt::DRIVE_POLL_VOLUME, (i64)value, nr); }
    Q_INVOKABLE int driveInsertVolume(int nr) const { return (int)get(vamiga::Opt::DRIVE_INSERT_VOLUME, nr); }
    Q_INVOKABLE void setDriveInsertVolume(int nr, int value) { set(vamiga::Opt::DRIVE_INSERT_VOLUME, (i64)value, nr); }
    Q_INVOKABLE int driveEjectVolume(int nr) const { return (int)get(vamiga::Opt::DRIVE_EJECT_VOLUME, nr); }
    Q_INVOKABLE void setDriveEjectVolume(int nr, int value) { set(vamiga::Opt::DRIVE_EJECT_VOLUME, (i64)value, nr); }
    Q_INVOKABLE int hdPan(int nr) const { return (int)get(vamiga::Opt::HDR_PAN, nr); }
    Q_INVOKABLE void setHdPan(int nr, int value) { set(vamiga::Opt::HDR_PAN, (i64)value, nr); }
    Q_INVOKABLE int hdStepVolume(int nr) const { return (int)get(vamiga::Opt::HDR_STEP_VOLUME, nr); }
    Q_INVOKABLE void setHdStepVolume(int nr, int value) { set(vamiga::Opt::HDR_STEP_VOLUME, (i64)value, nr); }

    // Restores the factory settings for every option the Audio panel exposes
    // (SiAmAudioConfig.qml).
    Q_INVOKABLE void restoreAudioDefaults();

    int vol0() const { return (int)get(vamiga::Opt::AUD_VOL0); }
    void setVol0(int value) { set(vamiga::Opt::AUD_VOL0, (i64)value); }
    int vol1() const { return (int)get(vamiga::Opt::AUD_VOL1); }
    void setVol1(int value) { set(vamiga::Opt::AUD_VOL1, (i64)value); }
    int vol2() const { return (int)get(vamiga::Opt::AUD_VOL2); }
    void setVol2(int value) { set(vamiga::Opt::AUD_VOL2, (i64)value); }
    int vol3() const { return (int)get(vamiga::Opt::AUD_VOL3); }
    void setVol3(int value) { set(vamiga::Opt::AUD_VOL3, (i64)value); }
    int pan0() const { return (int)get(vamiga::Opt::AUD_PAN0); }
    void setPan0(int value) { set(vamiga::Opt::AUD_PAN0, (i64)value); }
    int pan1() const { return (int)get(vamiga::Opt::AUD_PAN1); }
    void setPan1(int value) { set(vamiga::Opt::AUD_PAN1, (i64)value); }
    int pan2() const { return (int)get(vamiga::Opt::AUD_PAN2); }
    void setPan2(int value) { set(vamiga::Opt::AUD_PAN2, (i64)value); }
    int pan3() const { return (int)get(vamiga::Opt::AUD_PAN3); }
    void setPan3(int value) { set(vamiga::Opt::AUD_PAN3, (i64)value); }
    int volL() const { return (int)get(vamiga::Opt::AUD_VOLL); }
    void setVolL(int value) { set(vamiga::Opt::AUD_VOLL, (i64)value); }
    int volR() const { return (int)get(vamiga::Opt::AUD_VOLR); }
    void setVolR(int value) { set(vamiga::Opt::AUD_VOLR, (i64)value); }
    int audioFilterType() const { return (int)get(vamiga::Opt::AUD_FILTER_TYPE); }
    void setAudioFilterType(int value) { set(vamiga::Opt::AUD_FILTER_TYPE, (i64)value); }
    int audioBufferSize() const { return (int)get(vamiga::Opt::AUD_BUFFER_SIZE); }
    void setAudioBufferSize(int value) { set(vamiga::Opt::AUD_BUFFER_SIZE, (i64)value); }
    int samplingMethod() const { return (int)get(vamiga::Opt::AUD_SAMPLING_METHOD); }
    void setSamplingMethod(int value) { set(vamiga::Opt::AUD_SAMPLING_METHOD, (i64)value); }
    bool asr() const { return (bool)get(vamiga::Opt::AUD_ASR); }
    void setAsr(bool value) { set(vamiga::Opt::AUD_ASR, (i64)value); }
    bool audioFastpath() const { return (bool)get(vamiga::Opt::AUD_FASTPATH); }
    void setAudioFastpath(bool value) { set(vamiga::Opt::AUD_FASTPATH, (i64)value); }

    //
    // Video
    //

    Q_PROPERTY(int MON_PALETTE READ palette WRITE setPalette NOTIFY configChanged)
    Q_PROPERTY(int MON_BRIGHTNESS READ brightness WRITE setBrightness NOTIFY configChanged)
    Q_PROPERTY(int MON_CONTRAST READ contrast WRITE setContrast NOTIFY configChanged)
    Q_PROPERTY(int MON_SATURATION READ saturation WRITE setSaturation NOTIFY configChanged)
    Q_PROPERTY(int MON_CENTER READ center WRITE setCenter NOTIFY configChanged)
    Q_PROPERTY(int MON_HCENTER READ hCenter WRITE setHCenter NOTIFY configChanged)
    Q_PROPERTY(int MON_VCENTER READ vCenter WRITE setVCenter NOTIFY configChanged)
    Q_PROPERTY(int MON_ZOOM READ zoom WRITE setZoom NOTIFY configChanged)
    Q_PROPERTY(int MON_HZOOM READ hZoom WRITE setHZoom NOTIFY configChanged)
    Q_PROPERTY(int MON_VZOOM READ vZoom WRITE setVZoom NOTIFY configChanged)
    Q_PROPERTY(int MON_ENHANCER READ enhancer WRITE setEnhancer NOTIFY configChanged)
    Q_PROPERTY(int MON_UPSCALER READ upscaler WRITE setUpscaler NOTIFY configChanged)
    Q_PROPERTY(bool MON_BLUR READ blur WRITE setBlur NOTIFY configChanged)
    Q_PROPERTY(int MON_BLUR_RADIUS READ blurRadius WRITE setBlurRadius NOTIFY configChanged)
    Q_PROPERTY(bool MON_BLOOM READ bloom WRITE setBloom NOTIFY configChanged)
    Q_PROPERTY(int MON_BLOOM_RADIUS READ bloomRadius WRITE setBloomRadius NOTIFY configChanged)
    Q_PROPERTY(int MON_BLOOM_BRIGHTNESS READ bloomBrightness WRITE setBloomBrightness NOTIFY configChanged)
    Q_PROPERTY(int MON_BLOOM_WEIGHT READ bloomWeight WRITE setBloomWeight NOTIFY configChanged)
    Q_PROPERTY(int MON_DOTMASK READ dotmask WRITE setDotmask NOTIFY configChanged)
    Q_PROPERTY(int MON_DOTMASK_BRIGHTNESS READ dotmaskBrightness WRITE setDotmaskBrightness NOTIFY configChanged)
    Q_PROPERTY(int MON_SCANLINES READ scanlines WRITE setScanlines NOTIFY configChanged)
    Q_PROPERTY(int MON_SCANLINE_BRIGHTNESS READ scanlineBrightness WRITE setScanlineBrightness NOTIFY configChanged)
    Q_PROPERTY(int MON_SCANLINE_WEIGHT READ scanlineWeight WRITE setScanlineWeight NOTIFY configChanged)
    Q_PROPERTY(bool MON_DISALIGNMENT READ disalignment WRITE setDisalignment NOTIFY configChanged)
    Q_PROPERTY(int MON_DISALIGNMENT_H READ disalignmentH WRITE setDisalignmentH NOTIFY configChanged)
    Q_PROPERTY(int MON_DISALIGNMENT_V READ disalignmentV WRITE setDisalignmentV NOTIFY configChanged)
    Q_PROPERTY(bool MON_FLICKER READ flicker WRITE setFlicker NOTIFY configChanged)
    Q_PROPERTY(int MON_FLICKER_WEIGHT READ flickerWeight WRITE setFlickerWeight NOTIFY configChanged)
    Q_PROPERTY(bool VID_WHITE_NOISE READ whiteNoise WRITE setWhiteNoise NOTIFY configChanged)

    // Restores the factory settings for every option the Video panel exposes
    // (SiAmVideoConfig.qml) -- the panel covers geometry and color only, so
    // the upscaler/blur/bloom/dotmask/scanline/disalignment/flicker effect
    // options are left untouched, same rationale as SiC64ConfigController's
    // restoreVideoDefaults().
    Q_INVOKABLE void restoreVideoDefaults();

    int palette() const { return (int)get(vamiga::Opt::MON_PALETTE); }
    void setPalette(int value) { set(vamiga::Opt::MON_PALETTE, (i64)value); }
    int brightness() const { return (int)get(vamiga::Opt::MON_BRIGHTNESS); }
    void setBrightness(int value) { set(vamiga::Opt::MON_BRIGHTNESS, (i64)value); }
    int contrast() const { return (int)get(vamiga::Opt::MON_CONTRAST); }
    void setContrast(int value) { set(vamiga::Opt::MON_CONTRAST, (i64)value); }
    int saturation() const { return (int)get(vamiga::Opt::MON_SATURATION); }
    void setSaturation(int value) { set(vamiga::Opt::MON_SATURATION, (i64)value); }
    int center() const { return (int)get(vamiga::Opt::MON_CENTER); }
    void setCenter(int value) { set(vamiga::Opt::MON_CENTER, (i64)value); }
    int hCenter() const { return (int)get(vamiga::Opt::MON_HCENTER); }
    void setHCenter(int value) { set(vamiga::Opt::MON_HCENTER, (i64)value); }
    int vCenter() const { return (int)get(vamiga::Opt::MON_VCENTER); }
    void setVCenter(int value) { set(vamiga::Opt::MON_VCENTER, (i64)value); }
    int zoom() const { return (int)get(vamiga::Opt::MON_ZOOM); }
    void setZoom(int value) { set(vamiga::Opt::MON_ZOOM, (i64)value); }
    int hZoom() const { return (int)get(vamiga::Opt::MON_HZOOM); }
    void setHZoom(int value) { set(vamiga::Opt::MON_HZOOM, (i64)value); }
    int vZoom() const { return (int)get(vamiga::Opt::MON_VZOOM); }
    void setVZoom(int value) { set(vamiga::Opt::MON_VZOOM, (i64)value); }
    int enhancer() const { return (int)get(vamiga::Opt::MON_ENHANCER); }
    void setEnhancer(int value) { set(vamiga::Opt::MON_ENHANCER, (i64)value); }
    int upscaler() const { return (int)get(vamiga::Opt::MON_UPSCALER); }
    void setUpscaler(int value) { set(vamiga::Opt::MON_UPSCALER, (i64)value); }
    bool blur() const { return (bool)get(vamiga::Opt::MON_BLUR); }
    void setBlur(bool value) { set(vamiga::Opt::MON_BLUR, (i64)value); }
    int blurRadius() const { return (int)get(vamiga::Opt::MON_BLUR_RADIUS); }
    void setBlurRadius(int value) { set(vamiga::Opt::MON_BLUR_RADIUS, (i64)value); }
    bool bloom() const { return (bool)get(vamiga::Opt::MON_BLOOM); }
    void setBloom(bool value) { set(vamiga::Opt::MON_BLOOM, (i64)value); }
    int bloomRadius() const { return (int)get(vamiga::Opt::MON_BLOOM_RADIUS); }
    void setBloomRadius(int value) { set(vamiga::Opt::MON_BLOOM_RADIUS, (i64)value); }
    int bloomBrightness() const { return (int)get(vamiga::Opt::MON_BLOOM_BRIGHTNESS); }
    void setBloomBrightness(int value) { set(vamiga::Opt::MON_BLOOM_BRIGHTNESS, (i64)value); }
    int bloomWeight() const { return (int)get(vamiga::Opt::MON_BLOOM_WEIGHT); }
    void setBloomWeight(int value) { set(vamiga::Opt::MON_BLOOM_WEIGHT, (i64)value); }
    int dotmask() const { return (int)get(vamiga::Opt::MON_DOTMASK); }
    void setDotmask(int value) { set(vamiga::Opt::MON_DOTMASK, (i64)value); }
    int dotmaskBrightness() const { return (int)get(vamiga::Opt::MON_DOTMASK_BRIGHTNESS); }
    void setDotmaskBrightness(int value) { set(vamiga::Opt::MON_DOTMASK_BRIGHTNESS, (i64)value); }
    int scanlines() const { return (int)get(vamiga::Opt::MON_SCANLINES); }
    void setScanlines(int value) { set(vamiga::Opt::MON_SCANLINES, (i64)value); }
    int scanlineBrightness() const { return (int)get(vamiga::Opt::MON_SCANLINE_BRIGHTNESS); }
    void setScanlineBrightness(int value) { set(vamiga::Opt::MON_SCANLINE_BRIGHTNESS, (i64)value); }
    int scanlineWeight() const { return (int)get(vamiga::Opt::MON_SCANLINE_WEIGHT); }
    void setScanlineWeight(int value) { set(vamiga::Opt::MON_SCANLINE_WEIGHT, (i64)value); }
    bool disalignment() const { return (bool)get(vamiga::Opt::MON_DISALIGNMENT); }
    void setDisalignment(bool value) { set(vamiga::Opt::MON_DISALIGNMENT, (i64)value); }
    int disalignmentH() const { return (int)get(vamiga::Opt::MON_DISALIGNMENT_H); }
    void setDisalignmentH(int value) { set(vamiga::Opt::MON_DISALIGNMENT_H, (i64)value); }
    int disalignmentV() const { return (int)get(vamiga::Opt::MON_DISALIGNMENT_V); }
    void setDisalignmentV(int value) { set(vamiga::Opt::MON_DISALIGNMENT_V, (i64)value); }
    bool flicker() const { return (bool)get(vamiga::Opt::MON_FLICKER); }
    void setFlicker(bool value) { set(vamiga::Opt::MON_FLICKER, (i64)value); }
    int flickerWeight() const { return (int)get(vamiga::Opt::MON_FLICKER_WEIGHT); }
    void setFlickerWeight(int value) { set(vamiga::Opt::MON_FLICKER_WEIGHT, (i64)value); }
    bool whiteNoise() const { return (bool)get(vamiga::Opt::VID_WHITE_NOISE); }
    void setWhiteNoise(bool value) { set(vamiga::Opt::VID_WHITE_NOISE, (i64)value); }

    //
    // Servers
    //

    Q_PROPERTY(bool SRV_RSH_ENABLE READ rshServerEnable WRITE setRshServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_RSH_TRANSPORT READ rshServerTransport WRITE setRshServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_RSH_PORT READ rshServerPort WRITE setRshServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_RSH_VERBOSE READ rshServerVerbose WRITE setRshServerVerbose NOTIFY configChanged)
    Q_PROPERTY(bool SRV_RPC_ENABLE READ rpcServerEnable WRITE setRpcServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_RPC_TRANSPORT READ rpcServerTransport WRITE setRpcServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_RPC_PORT READ rpcServerPort WRITE setRpcServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_RPC_VERBOSE READ rpcServerVerbose WRITE setRpcServerVerbose NOTIFY configChanged)
    Q_PROPERTY(bool SRV_GDB_ENABLE READ gdbServerEnable WRITE setGdbServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_GDB_TRANSPORT READ gdbServerTransport WRITE setGdbServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_GDB_PORT READ gdbServerPort WRITE setGdbServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_GDB_VERBOSE READ gdbServerVerbose WRITE setGdbServerVerbose NOTIFY configChanged)
    Q_PROPERTY(bool SRV_PROM_ENABLE READ promServerEnable WRITE setPromServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_PROM_TRANSPORT READ promServerTransport WRITE setPromServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_PROM_PORT READ promServerPort WRITE setPromServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_PROM_VERBOSE READ promServerVerbose WRITE setPromServerVerbose NOTIFY configChanged)
    Q_PROPERTY(bool SRV_SER_ENABLE READ serServerEnable WRITE setSerServerEnable NOTIFY configChanged)
    Q_PROPERTY(int SRV_SER_TRANSPORT READ serServerTransport WRITE setSerServerTransport NOTIFY configChanged)
    Q_PROPERTY(int SRV_SER_PORT READ serServerPort WRITE setSerServerPort NOTIFY configChanged)
    Q_PROPERTY(bool SRV_SER_VERBOSE READ serServerVerbose WRITE setSerServerVerbose NOTIFY configChanged)

    bool rshServerEnable() const { return (bool)get(vamiga::Opt::SRV_ENABLE, Rsh); }
    void setRshServerEnable(bool value) { set(vamiga::Opt::SRV_ENABLE, (i64)value, Rsh); }
    int rshServerTransport() const { return (int)get(vamiga::Opt::SRV_TRANSPORT, Rsh); }
    void setRshServerTransport(int value) { set(vamiga::Opt::SRV_TRANSPORT, (i64)value, Rsh); }
    int rshServerPort() const { return (int)get(vamiga::Opt::SRV_PORT, Rsh); }
    void setRshServerPort(int value) { set(vamiga::Opt::SRV_PORT, (i64)value, Rsh); }
    bool rshServerVerbose() const { return (bool)get(vamiga::Opt::SRV_VERBOSE, Rsh); }
    void setRshServerVerbose(bool value) { set(vamiga::Opt::SRV_VERBOSE, (i64)value, Rsh); }
    bool rpcServerEnable() const { return (bool)get(vamiga::Opt::SRV_ENABLE, Rpc); }
    void setRpcServerEnable(bool value) { set(vamiga::Opt::SRV_ENABLE, (i64)value, Rpc); }
    int rpcServerTransport() const { return (int)get(vamiga::Opt::SRV_TRANSPORT, Rpc); }
    void setRpcServerTransport(int value) { set(vamiga::Opt::SRV_TRANSPORT, (i64)value, Rpc); }
    int rpcServerPort() const { return (int)get(vamiga::Opt::SRV_PORT, Rpc); }
    void setRpcServerPort(int value) { set(vamiga::Opt::SRV_PORT, (i64)value, Rpc); }
    bool rpcServerVerbose() const { return (bool)get(vamiga::Opt::SRV_VERBOSE, Rpc); }
    void setRpcServerVerbose(bool value) { set(vamiga::Opt::SRV_VERBOSE, (i64)value, Rpc); }
    bool gdbServerEnable() const { return (bool)get(vamiga::Opt::SRV_ENABLE, Gdb); }
    void setGdbServerEnable(bool value) { set(vamiga::Opt::SRV_ENABLE, (i64)value, Gdb); }
    int gdbServerTransport() const { return (int)get(vamiga::Opt::SRV_TRANSPORT, Gdb); }
    void setGdbServerTransport(int value) { set(vamiga::Opt::SRV_TRANSPORT, (i64)value, Gdb); }
    int gdbServerPort() const { return (int)get(vamiga::Opt::SRV_PORT, Gdb); }
    void setGdbServerPort(int value) { set(vamiga::Opt::SRV_PORT, (i64)value, Gdb); }
    bool gdbServerVerbose() const { return (bool)get(vamiga::Opt::SRV_VERBOSE, Gdb); }
    void setGdbServerVerbose(bool value) { set(vamiga::Opt::SRV_VERBOSE, (i64)value, Gdb); }
    bool promServerEnable() const { return (bool)get(vamiga::Opt::SRV_ENABLE, Prom); }
    void setPromServerEnable(bool value) { set(vamiga::Opt::SRV_ENABLE, (i64)value, Prom); }
    int promServerTransport() const { return (int)get(vamiga::Opt::SRV_TRANSPORT, Prom); }
    void setPromServerTransport(int value) { set(vamiga::Opt::SRV_TRANSPORT, (i64)value, Prom); }
    int promServerPort() const { return (int)get(vamiga::Opt::SRV_PORT, Prom); }
    void setPromServerPort(int value) { set(vamiga::Opt::SRV_PORT, (i64)value, Prom); }
    bool promServerVerbose() const { return (bool)get(vamiga::Opt::SRV_VERBOSE, Prom); }
    void setPromServerVerbose(bool value) { set(vamiga::Opt::SRV_VERBOSE, (i64)value, Prom); }
    bool serServerEnable() const { return (bool)get(vamiga::Opt::SRV_ENABLE, Ser); }
    void setSerServerEnable(bool value) { set(vamiga::Opt::SRV_ENABLE, (i64)value, Ser); }
    int serServerTransport() const { return (int)get(vamiga::Opt::SRV_TRANSPORT, Ser); }
    void setSerServerTransport(int value) { set(vamiga::Opt::SRV_TRANSPORT, (i64)value, Ser); }
    int serServerPort() const { return (int)get(vamiga::Opt::SRV_PORT, Ser); }
    void setSerServerPort(int value) { set(vamiga::Opt::SRV_PORT, (i64)value, Ser); }
    bool serServerVerbose() const { return (bool)get(vamiga::Opt::SRV_VERBOSE, Ser); }
    void setSerServerVerbose(bool value) { set(vamiga::Opt::SRV_VERBOSE, (i64)value, Ser); }

    // Restores the factory settings for every option the Server panel
    // exposes (SiAmServerConfig.qml).
    Q_INVOKABLE void restoreServerDefaults();

    //
    // Workspaces
    //

    Q_PROPERTY(bool AMIGA_WS_COMPRESSION READ wsCompression WRITE setWsCompression NOTIFY configChanged)

    bool wsCompression() const { return (bool)get(vamiga::Opt::AMIGA_WS_COMPRESSION); }
    void setWsCompression(bool value) { set(vamiga::Opt::AMIGA_WS_COMPRESSION, (i64)value); }

    //
    // DMA Debugger
    //

  public:

    Q_PROPERTY(bool DMA_DEBUG_ENABLE READ dmaDebugEnable WRITE setDmaDebugEnable NOTIFY configChanged)
    Q_PROPERTY(int DMA_DEBUG_MODE READ dmaDebugMode WRITE setDmaDebugMode NOTIFY configChanged)
    Q_PROPERTY(int DMA_DEBUG_OPACITY READ dmaDebugOpacity WRITE setDmaDebugOpacity NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL0 READ dmaDebugChannel0 WRITE setDmaDebugChannel0 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL1 READ dmaDebugChannel1 WRITE setDmaDebugChannel1 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL2 READ dmaDebugChannel2 WRITE setDmaDebugChannel2 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL3 READ dmaDebugChannel3 WRITE setDmaDebugChannel3 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL4 READ dmaDebugChannel4 WRITE setDmaDebugChannel4 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL5 READ dmaDebugChannel5 WRITE setDmaDebugChannel5 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL6 READ dmaDebugChannel6 WRITE setDmaDebugChannel6 NOTIFY configChanged)
    Q_PROPERTY(bool DMA_DEBUG_CHANNEL7 READ dmaDebugChannel7 WRITE setDmaDebugChannel7 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR0 READ dmaDebugColor0 WRITE setDmaDebugColor0 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR1 READ dmaDebugColor1 WRITE setDmaDebugColor1 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR2 READ dmaDebugColor2 WRITE setDmaDebugColor2 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR3 READ dmaDebugColor3 WRITE setDmaDebugColor3 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR4 READ dmaDebugColor4 WRITE setDmaDebugColor4 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR5 READ dmaDebugColor5 WRITE setDmaDebugColor5 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR6 READ dmaDebugColor6 WRITE setDmaDebugColor6 NOTIFY configChanged)
    Q_PROPERTY(QColor DMA_DEBUG_COLOR7 READ dmaDebugColor7 WRITE setDmaDebugColor7 NOTIFY configChanged)

    bool dmaDebugEnable() const { return (bool)get(vamiga::Opt::DMA_DEBUG_ENABLE); }
    void setDmaDebugEnable(bool value) { set(vamiga::Opt::DMA_DEBUG_ENABLE, (i64)value); }
    int dmaDebugMode() const { return (int)get(vamiga::Opt::DMA_DEBUG_MODE); }
    void setDmaDebugMode(int value) { set(vamiga::Opt::DMA_DEBUG_MODE, (i64)value); }
    int dmaDebugOpacity() const { return (int)get(vamiga::Opt::DMA_DEBUG_OPACITY); }
    void setDmaDebugOpacity(int value) { set(vamiga::Opt::DMA_DEBUG_OPACITY, (i64)value); }
    bool dmaDebugChannel0() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL0); }
    void setDmaDebugChannel0(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL0, (i64)value); }
    bool dmaDebugChannel1() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL1); }
    void setDmaDebugChannel1(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL1, (i64)value); }
    bool dmaDebugChannel2() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL2); }
    void setDmaDebugChannel2(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL2, (i64)value); }
    bool dmaDebugChannel3() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL3); }
    void setDmaDebugChannel3(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL3, (i64)value); }
    bool dmaDebugChannel4() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL4); }
    void setDmaDebugChannel4(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL4, (i64)value); }
    bool dmaDebugChannel5() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL5); }
    void setDmaDebugChannel5(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL5, (i64)value); }
    bool dmaDebugChannel6() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL6); }
    void setDmaDebugChannel6(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL6, (i64)value); }
    bool dmaDebugChannel7() const { return (bool)get(vamiga::Opt::DMA_DEBUG_CHANNEL7); }
    void setDmaDebugChannel7(bool value) { set(vamiga::Opt::DMA_DEBUG_CHANNEL7, (i64)value); }
    QColor dmaDebugColor0() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR0); }
    void setDmaDebugColor0(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR0, c); }
    QColor dmaDebugColor1() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR1); }
    void setDmaDebugColor1(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR1, c); }
    QColor dmaDebugColor2() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR2); }
    void setDmaDebugColor2(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR2, c); }
    QColor dmaDebugColor3() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR3); }
    void setDmaDebugColor3(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR3, c); }
    QColor dmaDebugColor4() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR4); }
    void setDmaDebugColor4(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR4, c); }
    QColor dmaDebugColor5() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR5); }
    void setDmaDebugColor5(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR5, c); }
    QColor dmaDebugColor6() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR6); }
    void setDmaDebugColor6(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR6, c); }
    QColor dmaDebugColor7() const { return dmaColor(vamiga::Opt::DMA_DEBUG_COLOR7); }
    void setDmaDebugColor7(const QColor &c) { setDmaColor(vamiga::Opt::DMA_DEBUG_COLOR7, c); }

    //
    // Logic Analyzer
    //

    Q_PROPERTY(int LA_PROBE0 READ laProbe0 WRITE setLaProbe0 NOTIFY configChanged)
    Q_PROPERTY(int LA_PROBE1 READ laProbe1 WRITE setLaProbe1 NOTIFY configChanged)
    Q_PROPERTY(int LA_PROBE2 READ laProbe2 WRITE setLaProbe2 NOTIFY configChanged)
    Q_PROPERTY(int LA_PROBE3 READ laProbe3 WRITE setLaProbe3 NOTIFY configChanged)
    Q_PROPERTY(int LA_ADDR0 READ laAddr0 WRITE setLaAddr0 NOTIFY configChanged)
    Q_PROPERTY(int LA_ADDR1 READ laAddr1 WRITE setLaAddr1 NOTIFY configChanged)
    Q_PROPERTY(int LA_ADDR2 READ laAddr2 WRITE setLaAddr2 NOTIFY configChanged)
    Q_PROPERTY(int LA_ADDR3 READ laAddr3 WRITE setLaAddr3 NOTIFY configChanged)

    int laProbe0() const { return (int)get(vamiga::Opt::LA_PROBE0); }
    void setLaProbe0(int value) { set(vamiga::Opt::LA_PROBE0, (i64)value); }
    int laProbe1() const { return (int)get(vamiga::Opt::LA_PROBE1); }
    void setLaProbe1(int value) { set(vamiga::Opt::LA_PROBE1, (i64)value); }
    int laProbe2() const { return (int)get(vamiga::Opt::LA_PROBE2); }
    void setLaProbe2(int value) { set(vamiga::Opt::LA_PROBE2, (i64)value); }
    int laProbe3() const { return (int)get(vamiga::Opt::LA_PROBE3); }
    void setLaProbe3(int value) { set(vamiga::Opt::LA_PROBE3, (i64)value); }
    int laAddr0() const { return (int)get(vamiga::Opt::LA_ADDR0); }
    void setLaAddr0(int value) { set(vamiga::Opt::LA_ADDR0, (i64)value); }
    int laAddr1() const { return (int)get(vamiga::Opt::LA_ADDR1); }
    void setLaAddr1(int value) { set(vamiga::Opt::LA_ADDR1, (i64)value); }
    int laAddr2() const { return (int)get(vamiga::Opt::LA_ADDR2); }
    void setLaAddr2(int value) { set(vamiga::Opt::LA_ADDR2, (i64)value); }
    int laAddr3() const { return (int)get(vamiga::Opt::LA_ADDR3); }
    void setLaAddr3(int value) { set(vamiga::Opt::LA_ADDR3, (i64)value); }

    //
    // Helpers
    //

  private:

    // Fixed-slot ids for options that take one -- two CIAs, two mouse/
    // joystick ports, five remote servers. Floppy/hard drives go through
    // the driveXxx(nr)/hdXxx(nr) pairs above instead (see the header
    // comment), so they need no equivalent constants here.
    static constexpr long CiaA = 0;
    static constexpr long CiaB = 1;
    static constexpr long Port1 = 0;
    static constexpr long Port2 = 1;
    static constexpr long Rsh  = (long)vamiga::ServerType::RSH;
    static constexpr long Rpc  = (long)vamiga::ServerType::RPC;
    static constexpr long Gdb  = (long)vamiga::ServerType::GDB;
    static constexpr long Prom = (long)vamiga::ServerType::PROM;
    static constexpr long Ser  = (long)vamiga::ServerType::SER;

    i64 get(vamiga::Opt opt) const;
    i64 get(vamiga::Opt opt, long id) const;
    void set(vamiga::Opt opt, i64 newValue);
    void set(vamiga::Opt opt, i64 newValue, long id);
    QColor dmaColor(vamiga::Opt opt) const;
    void setDmaColor(vamiga::Opt opt, const QColor &c);

    // Drops the user's stored value for an option so the core's factory
    // fallback applies again, and pushes that value into the running
    // machine. 'objids' selects the sub-components to reset for indexed
    // options (e.g. the individual drives); leave it empty for plain,
    // unindexed ones.
    void restoreDefaults(vamiga::Opt opt, std::vector<isize> objids = { });

    //
    // Signals
    //

  signals:

    void configChanged();
    void romConfigChanged();
};
