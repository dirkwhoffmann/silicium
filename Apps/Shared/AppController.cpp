// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "AppController.h"
#include "Logger.h"
#include "utl/chrono.h"
#include "utl/io.h"
#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>

string
AppController::version()
{
    string result;

    result = std::to_string(VER_MAJOR) + "." + std::to_string(VER_MINOR);
    if constexpr (VER_SUBMINOR > 0) result += "." + std::to_string(VER_SUBMINOR);
    if constexpr (VER_BETA > 0) result += 'b' + std::to_string(VER_BETA);

    return result;
}

AppController::AppController() : Controller()
{
    LogTask task("Creating AppController...");

    inputManager.start();
}

AppController::~AppController()
{
    inputManager.stop();
}

QObject *
AppController::createQmlObject(const QString &qmlName, const QVariantMap &properties)
{
    QQmlEngine *engine = qmlEngine(this);

    if (!engine) {
        qCCritical(siLog) << "Can't access QQmlEngine";
        return nullptr;
    }

    QQmlComponent component(engine);
    component.loadFromModule("siliciumUI", qmlName);

    if (!component.isReady()) {
        qCCritical(siLog) << "QML Error:" << component.errorString();
        return nullptr;
    }

    QObject *obj = component.createWithInitialProperties(properties);

    if (!obj) {
        qCCritical(siLog) << "Failed to create QML object";
        return nullptr;
    }

    QQmlEngine::setObjectOwnership(obj, QQmlEngine::CppOwnership);

    return obj;
}

QString
AppController::locateExecutable(const QString &name)
{
    QStringList searchDirs { QCoreApplication::applicationDirPath() };

#if defined(Q_OS_MACOS)

    QDir bundleParent(QCoreApplication::applicationDirPath());
    bundleParent.cdUp(); // Contents/MacOS -> Contents
    bundleParent.cdUp(); // Contents -> <this>.app
    bundleParent.cdUp(); // <this>.app -> bin
    searchDirs << bundleParent.filePath(name + ".app/Contents/MacOS");

#endif

    return QStandardPaths::findExecutable(name, searchDirs);
}

QString
AppController::locateExecutable(Platform platform)
{
    string name;

    switch (platform) {

        case Platform::C64:   name = "SiC64"; break;
        case Platform::AMIGA: name = "SiAmiga"; break;

        default:
            break;
    }

    if (QString path = locateExecutable(QString::fromStdString(name)); !path.isEmpty()) {
        return path;
    }

    throw ImageError(ImageError::EXECUTABLE_NOT_FOUND, name);
}

QString
AppController::getVersion() const
{
    return QString::fromStdString(version());
}

QString
AppController::getBuild() const
{
    auto result = QString::fromStdString(utl::Time::buildTime());
    if constexpr (debugBuild) result += " [DEBUG]";
    return result;
}

QString
AppController::getBuildNr() const
{
    auto result = QString::fromStdString(utl::Time::buildTime("%y%m%d"));
    if constexpr (debugBuild) result += " [DEBUG]";
    return result;
}

bool
AppController::getBeta() const
{
    return VER_BETA > 0;
}

QString
AppController::getQtVersion() const
{
    return qVersion();
}

AppController &
AppController::instance()
{
    static AppController *inst = new AppController();
    return *inst;
}

AppController *
AppController::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    return &instance();
}
