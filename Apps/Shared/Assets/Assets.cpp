// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Assets.h"

#include <QDirIterator>
#include <QFile>
#include <QFileInfo>

QUrl
Assets::getIconUrl(Icon icon)
{
    switch (icon) {

        case Icon::ChickenLips:         return QUrl("qrc:/icons/chicken-lips.svg");
        case Icon::GitHub:              return QUrl("qrc:/icons/github.svg");
        case Icon::Lock:                return QUrl("qrc:/images/lock.png");
        case Icon::Star:                return QUrl("qrc:/icons/star.svg");

        case Icon::Cartridge:           return QUrl("qrc:/icons/cartridge.png");
        case Icon::Disk35:              return QUrl("qrc:/icons/disk-35.png");
        case Icon::Disk35wp:            return QUrl("qrc:/icons/disk-35-wp.png");
        case Icon::Disk525:             return QUrl("qrc:/icons/disk-525.png");
        case Icon::Disk525wp:           return QUrl("qrc:/icons/disk-525-wp.png");
        case Icon::DropNone:            return QUrl("qrc:/icons/drop-none.png");
        case Icon::Drop525:             return QUrl("qrc:/icons/drop-525.png");
        case Icon::Drop35:              return QUrl("qrc:/icons/drop-35.png");
        case Icon::DropHd:              return QUrl("qrc:/icons/drop-hd.png");
        case Icon::DropMem:             return QUrl("qrc:/icons/drop-mem.png");
        case Icon::DropCrt:             return QUrl("qrc:/icons/drop-crt.png");
        case Icon::DropTape:            return QUrl("qrc:/icons/drop-tape.png");
        case Icon::Hourglass:           return QUrl("qrc:/icons/hourglass.png");
        case Icon::Hourglass45:         return QUrl("qrc:/icons/hourglass-45.png");
        case Icon::Hourglass90:         return QUrl("qrc:/icons/hourglass-90.png");
        case Icon::MousePress:          return QUrl("qrc:/icons/mouse-press.png");
        case Icon::MousePush:           return QUrl("qrc:/icons/mouse-push.png");
        case Icon::Tape:                return QUrl("qrc:/icons/tape.png");
        case Icon::WarpOn:              return QUrl("qrc:/icons/warp-on.png");
        case Icon::WarpOff:             return QUrl("qrc:/icons/warp-off.png");

        case Icon::PreferencesBg:       return QUrl("qrc:/backgrounds/preferences-bg.png");

        case Icon::AmigaBg:             return QUrl("qrc:/images/amiga-bg.png");
        case Icon::AmigaCore:           return QUrl("qrc:/images/amiga-core.png");
        case Icon::AmigaLogo:           return QUrl("qrc:/images/amiga-logo.png");
        case Icon::AmigaMonitor:        return QUrl("qrc:/images/amiga-monitor.png");
        case Icon::AppIcon:             return QUrl("qrc:/images/app-icon.png");
        case Icon::Biohazard:           return QUrl("qrc:/images/biohazard.png");
        case Icon::Bomb:                return QUrl("qrc:/images/bomb.png");
        case Icon::C64Bg:               return QUrl("qrc:/images/c64-bg.png");
        case Icon::C64Core:             return QUrl("qrc:/images/c64-core.png");
        case Icon::C64Logo:             return QUrl("qrc:/images/c64-logo.png");
        case Icon::C64Monitor:          return QUrl("qrc:/images/c64-monitor.png");
        case Icon::CommodoreLogo:       return QUrl("qrc:/images/commodore-logo.png");
        case Icon::ComingSoon:          return QUrl("qrc:/images/coming-soon.png");
        case Icon::Help:                return QUrl("qrc:/images/help.png");
        case Icon::LedGray:             return QUrl("qrc:/images/led-gray.png");
        case Icon::LedGrayDark:         return QUrl("qrc:/images/led-gray-dark.png");
        case Icon::LedGreen:            return QUrl("qrc:/images/led-green.png");
        case Icon::LedGreenDark:        return QUrl("qrc:/images/led-green-dark.png");
        case Icon::LedRed:              return QUrl("qrc:/images/led-red.png");
        case Icon::LedRedDark:          return QUrl("qrc:/images/led-red-dark.png");
        case Icon::LedRoundGray:        return QUrl("qrc:/images/led-round-gray.png");
        case Icon::LedRoundGreen:       return QUrl("qrc:/images/led-round-green.png");
        case Icon::LedRoundYellow:      return QUrl("qrc:/images/led-round-yellow.png");
        case Icon::LedRoundRed:         return QUrl("qrc:/images/led-round-red.png");

        case Icon::Media35DDAmiga:      return QUrl("qrc:/images/media-35-dd-amiga.png");
        case Icon::Media35DDAmigaWp:    return QUrl("qrc:/images/media-35-dd-amiga-wp.png");
        case Icon::Media35DDDos:        return QUrl("qrc:/images/media-35-dd-dos.png");
        case Icon::Media35DDDosWp:      return QUrl("qrc:/images/media-35-dd-dos-wp.png");
        case Icon::Media35DDSt:         return QUrl("qrc:/images/media-35-dd-st.png");
        case Icon::Media35DDStWp:       return QUrl("qrc:/images/media-35-dd-st-wp.png");
        case Icon::Media35DDUnknown:    return QUrl("qrc:/images/media-35-dd-unknown.png");
        case Icon::Media35DDUnknownWp:  return QUrl("qrc:/images/media-35-dd-unknown.png");
        case Icon::Media35HDAmiga:      return QUrl("qrc:/images/media-35-hd-amiga.png");
        case Icon::Media35HDAmigaWp:    return QUrl("qrc:/images/media-35-hd-amiga-wp.png");
        case Icon::Media35HDDos:        return QUrl("qrc:/images/media-35-hd-dos.png");
        case Icon::Media35HDDosWp:      return QUrl("qrc:/images/media-35-hd-dos-wp.png");
        case Icon::Media35HDUnknown:    return QUrl("qrc:/images/media-35-hd-unknown.png");
        case Icon::Media35HDUnknownWp:  return QUrl("qrc:/images/media-35-hd-unknwon-wp.png");
        case Icon::Media525DDCbm:       return QUrl("qrc:/images/media-525-dd-cbm.png");
        case Icon::Media536DDCbmWp:     return QUrl("qrc:/images/media-525-dd-cbm-wp.png");
        case Icon::MediaCrt:            return QUrl("qrc:/images/media-crt.png");
        case Icon::MediaFsAmiga:        return QUrl("qrc:/images/media-fs-amiga.png");
        case Icon::MediaFsGeneric:      return QUrl("qrc:/images/media-fs-generic.png");
        case Icon::MediaHdrAmiga:       return QUrl("qrc:/images/media-hdr-amiga.png");
        case Icon::MediaTape:           return QUrl("qrc:/images/media-tape.png");

        case Icon::RomPlain:            return QUrl("qrc:/images/rom-plain.png");
        case Icon::RomDrag:             return QUrl("qrc:/images/rom-drag.png");
        case Icon::RomDanger:           return QUrl("qrc:/images/rom-danger.png");
        case Icon::RomUnknown:          return QUrl("qrc:/images/rom-unknown.png");
        case Icon::RomMos:              return QUrl("qrc:/images/rom-mos.png");
        case Icon::RomMega:             return QUrl("qrc:/images/rom-mega.png");
        case Icon::RomCommodore:        return QUrl("qrc:/images/rom-commodore.png");
        case Icon::RomAros:             return QUrl("qrc:/images/rom-aros.png");
        case Icon::RomHyperion:         return QUrl("qrc:/images/rom-hyperion.png");
        case Icon::RomDemo:             return QUrl("qrc:/images/rom-demo.png");
        case Icon::RomDiag:             return QUrl("qrc:/images/rom-diag.png");
        case Icon::RomEmutos:           return QUrl("qrc:/images/rom-emutos.png");
        case Icon::Snapshot:            return QUrl("qrc:/images/snapshot.png");
        case Icon::State0:              return QUrl("qrc:/images/state0.png");
        case Icon::State1:              return QUrl("qrc:/images/state1.png");
        case Icon::State2:              return QUrl("qrc:/images/state2.png");
        case Icon::State3:              return QUrl("qrc:/images/state3.png");
        case Icon::State5:              return QUrl("qrc:/images/state5.png");

        case Icon::Key:                 return QUrl("qrc:/images/key.png");
        case Icon::KeyRed:              return QUrl("qrc:/images/key-red.png");
        case Icon::KeyBlue:             return QUrl("qrc:/images/key-blue.png");

        case Icon::Amigaball:           return QUrl("qrc:/images/amiga-ball.png");
        case Icon::Background:          return QUrl("qrc:/backgrounds/background.jpg");
        case Icon::Logo:                return QUrl("qrc:/images/logo.png");
        case Icon::PoweredByVA:         return QUrl("qrc:/images/amiga-engine.png");
        case Icon::PoweredByVC:         return QUrl("qrc:/images/c64-engine.png");

        default:
            return QUrl("qrc:/icons/questionmark.svg");
    }
}

QString
Assets::getMarkdown(const QString &name)
{
    QUrl url("qrc:/markdown/" + name);
    QString markdown = readTextFile(url);

    return markdown;
}

utl::isize
Assets::extract(const QString &root, const fs::path &destination)
{
    utl::isize count = 0;

    fs::create_directories(destination);

    QDirIterator it(root, QDirIterator::Subdirectories);

    while (it.hasNext()) {

        auto resource = it.next();
        auto relative = resource.mid(root.length() + 1);
        auto target = destination / relative.toStdString();

        if (QFileInfo(resource).isDir()) {

            fs::create_directories(target);
            continue;
        }

        fs::create_directories(target.parent_path());

        /* QFile::copy refuses to overwrite, so clear the way first. This is
         * what makes a second call a no-op rather than a failure.
         */
        auto path = QString::fromStdString(target.string());
        if (QFile::exists(path)) QFile::remove(path);

        if (!QFile::copy(resource, path)) {
            throw utl::IOError(utl::IOError::FILE_CANT_CREATE, target);
        }

        // Resources are read-only and the copy inherits that. Undo it.
        QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
        count++;
    }

    return count;
}

QString
Assets::readTextFile(const QUrl &url)
{
    QFile file;

    if (url.scheme() == "qrc") {
        file.setFileName(":" + url.path());
    } else {
        file.setFileName(url.toLocalFile());
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    return QString::fromUtf8(file.readAll());
}