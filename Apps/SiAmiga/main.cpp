// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "SiAmController.h"
#include "SiAmRenderer.h"
#include "SiAmActivityController.h"
#include "Logger.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>

void
startLogger(int argc, char *argv[])
{
    Logger::install();

    QStringList quoted;
    const QStringList args = QCoreApplication::arguments();
    for (const auto &arg : args) quoted << QString("\"%1\"").arg(arg);

    qCDebug(siLog).noquote() << quoted.join(' ');
    qCDebug(siLog).noquote() << "Running with Qt Version:" << qVersion();
}

int
main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    startLogger(argc, argv);

    // Identify the application
    QCoreApplication::setOrganizationName("dirkwhoffmann");
    QCoreApplication::setApplicationName("SiAmiga");

    // Force the application to English/US
    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));

    // Configure app appearance
    QQuickStyle::setStyle("Fusion");
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar, true);
    app.setWindowIcon(QIcon(":/assets/images/app-icon.png"));

    // Register types
    qmlRegisterType<SiAmRenderer>("Silicium.Controllers", 1, 0, "SiAmRenderer");
    qmlRegisterType<SiAmActivityController>("Silicium.Controllers", 1, 0, "SiAmActivityController");

    // Register singletons
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "SiAmController", &SiAmController::instance());

    // Launch the emulator core
    SiAmController::instance().initialize();

    const QUrl url(QStringLiteral("qrc:/qt/qml/siamigaUI/SiAmiga/SiAmWindow.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {

            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
                return;
            }

            if (url != objUrl) return;

            // Wire the main window's lifetime to the SiAmController
            if (auto *window = qobject_cast<QQuickWindow *>(obj)) {
                SiAmController::instance().attachWindow(window);
            }
        });
    engine.load(url);

    // Run the app
    try {
        return app.exec();
    } catch (std::exception &e) {
        fprintf(stderr, "FATAL ERROR: \n%s\n", e.what());
    }
}
