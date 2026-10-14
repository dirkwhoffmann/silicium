// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include "Controller.h"
#include "AppServices.h"
#include "Images/SVM/SVMTypes.h"
#include <QtQml>

using retro::vault::Platform;

#if defined(Q_OS_MACOS)

static constexpr bool OS_MACOS = true;
static constexpr bool OS_WINDOWS = false;
static constexpr bool OS_LINUX = false;

#elif defined(Q_OS_WIN)

static constexpr bool OS_MACOS = false;
static constexpr bool OS_WINDOWS = true;
static constexpr bool OS_LINUX = false;

#elif defined(Q_OS_LINUX)

static constexpr bool OS_MACOS = false;
static constexpr bool OS_WINDOWS = false;
static constexpr bool OS_LINUX = true;

#endif

class AppController : public Controller {

    Q_OBJECT

  public:

    static string version();

    // Subcomponents
    Q_PROPERTY(InputManager* inputManager READ getInputManager CONSTANT)

    // App infos
    Q_PROPERTY(QString version READ getVersion CONSTANT)
    Q_PROPERTY(QString build READ getBuild CONSTANT)
    Q_PROPERTY(QString buildNr READ getBuildNr CONSTANT)
    Q_PROPERTY(bool beta READ getBeta CONSTANT)
    Q_PROPERTY(QString qtVersion READ getQtVersion CONSTANT)

    // Indicates whether the app draws its own menu bar (otherwise it is native)
    Q_PROPERTY(bool customMenu READ getCustomMenu WRITE setCustomMenu NOTIFY customMenuChanged)

    static AppController &instance();
    static AppController *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    AppController();
    ~AppController();

    // Dynamically creates a QML object
    QObject *createQmlObject(const QString &qmlName, const QVariantMap &properties = {});

    // Locates a sibling executable built as part of the same distribution
    static QString locateExecutable(const QString &name);

    // Locates the emulator built for the given platform
    static QString locateExecutable(Platform platform);

    bool getCustomMenu() const { return m_customMenu; }
    void setCustomMenu(bool value);

signals:

    void customMenuChanged();

private:

    bool m_customMenu = true;

    InputManager *getInputManager() { return &inputManager; }
    QString getVersion() const;
    QString getBuild() const;
    QString getBuildNr() const;
    bool getBeta() const;
    QString getQtVersion() const;
};
