// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include <utl/io.h>

#include <QtQml>

/* Central hub for everything that lives in the embedded (qrc) resources.
 *
 * Most of this class is a lookup table: an enum or a name goes in, a URL or a
 * string comes out, and QML reaches those through the Q_INVOKABLE wrappers.
 * extract() is the exception -- it walks a resource tree onto the file system.
 * It is deliberately not Q_INVOKABLE: it is slow, it throws, and nothing in a
 * binding has any business calling it.
 */
class Assets : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:

    enum class Icon {

        Unknown,

        // Icons (General)
        ChickenLips,
        GitHub,
        Lock,
        Star,

        // Icons (Custom)
        Cartridge,
        Disk35,
        Disk35wp,
        Disk525,
        Disk525wp,
        DropNone,
        Drop525,
        Drop35,
        DropHd,
        DropMem,
        DropCrt,
        DropTape,
        Hourglass,
        Hourglass45,
        Hourglass90,
        MousePress,
        MousePush,
        Tape,
        WarpOn,
        WarpOff,

        // Backgrounds
        PreferencesBg,

        // Images
        AmigaBg,
        AmigaCore,
        AmigaLogo,
        AmigaMonitor,
        AppIcon,
        Biohazard,
        Bomb,
        C64Bg,
        C64Core,
        C64Logo,
        C64Monitor,
        ComingSoon,
        CommodoreLogo,
        Help,
        LedGray,
        LedGrayDark,
        LedGreen,
        LedGreenDark,
        LedRed,
        LedRedDark,
        LedRoundGray,
        LedRoundGreen,
        LedRoundYellow,
        LedRoundRed,
        Media35DDAmiga,
        Media35DDAmigaWp,
        Media35DDDos,
        Media35DDDosWp,
        Media35DDSt,
        Media35DDStWp,
        Media35DDUnknown,
        Media35DDUnknownWp,
        Media35HDAmiga,
        Media35HDAmigaWp,
        Media35HDDos,
        Media35HDDosWp,
        Media35HDUnknown,
        Media35HDUnknownWp,
        Media525DDCbm,
        Media536DDCbmWp,
        MediaCrt,
        MediaFsAmiga,
        MediaFsGeneric,
        MediaHdrAmiga,
        MediaTape,
        RomPlain,
        RomDrag,
        RomDanger,
        RomUnknown,
        RomMos,
        RomMega,
        RomCommodore,
        RomAros,
        RomHyperion,
        RomDemo,
        RomDiag,
        RomEmutos,
        Snapshot,
        State0,
        State1,
        State2,
        State3,
        State5,

        // Keyboard
        Key,
        KeyRed,
        KeyBlue,

        // Backgrounds
        Amigaball,
        Background,
        Logo,
        PoweredByVA,
        PoweredByVC
    };
    Q_ENUM(Icon)

    static Assets* instance() {
        static Assets* inst = new Assets();
        return inst;
    }

    static Assets* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        return instance();
    }

    static QUrl getIconUrl(Icon icon);
    Q_INVOKABLE QUrl iconUrl(Icon icon) const { return getIconUrl(icon); }

    static QString getMarkdown(const QString &name);
    Q_INVOKABLE QString markdown(const QString &name) const { return getMarkdown(name); }

    /* Copies a resource tree to a folder on disk, recursively.
     *
     * 'root' is a resource path such as ":/Showcases"; the tree below it is
     * recreated under 'destination', which is created if it does not exist.
     * Existing files are overwritten, so calling this twice is harmless, but
     * files that are no longer in the resource tree are left alone -- wipe the
     * destination first if you need an exact mirror.
     *
     * Copies come out writable. Resources are read-only, and a plain copy
     * would inherit that, which is useless for anything the app means to
     * modify later.
     *
     * This is the qrc counterpart of utl::syncDirectory / utl::mirrorDirectory,
     * which do the same job for two real directories. A resource root is not a
     * real path, so std::filesystem cannot walk it and those cannot be reused.
     *
     * Returns the number of files copied. Throws utl::IOError if a file cannot
     * be created, so a half-extracted tree is never silently handed back.
     */
    static utl::isize extract(const QString &root, const fs::path &destination);

private:

    static QString readTextFile(const QUrl &url);

    explicit Assets(QObject *parent = nullptr) : QObject(parent) {}
    Q_DISABLE_COPY(Assets)
};