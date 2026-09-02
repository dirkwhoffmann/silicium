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
#include "Assets.h"
#include "Logger.h"
#include "Palette.h"
#include "Preferences.h"
#include "C64Controller.h"
#include "SiC64Renderer.h"
#include "SiC64ConfigController.h"
#include "SiC64InfoController.h"
#include "SiC64InspectorController.h"
#include "Inspector/SiC64DmaView.h"
#include "Inspector/SiC64Heatmap.h"
#include "Inspector/SiC64Waveform.h"
#include "SiC64ActivityController.h"
#include "SiC64StatusbarController.h"
#include "Keyboard/SiC64KeyboardController.h"
#include "Shortcuts.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>

void
startLogger(int argc, char *argv[])
{
    // Instantiate logger and install the message handler
    Logger::install();

    // Collect command line arguments
    QStringList quoted;
    const QStringList args = QCoreApplication::arguments();
    for (const auto &arg : args) quoted << QString("\"%1\"").arg(arg);

    // Dump startup information
    qCDebug(siLog).noquote() << quoted.join(' ');
    qCDebug(siLog).noquote() << "Running with Qt Version:" << qVersion();
}

int
main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Enable logging support
    startLogger(argc, argv);

    // Identify the application
    QCoreApplication::setOrganizationName("dirkwhoffmann");
    QCoreApplication::setApplicationName("SiC64");

    // Force the application to English/US
    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));

    // Configure app appearance
    QQuickStyle::setStyle("Fusion");
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar, true);
    app.setWindowIcon(QIcon(":/assets/images/app-icon.png"));

    // Register types
    qmlRegisterType<SiC64ConfigController>("Silicium.Controllers", 1, 0, "SiC64ConfigController");
    qmlRegisterType<SiC64InspectorController>("Silicium.Controllers", 1, 0, "SiC64InspectorController");
    qmlRegisterType<SiC64InfoController>("Silicium.Controllers", 1, 0, "SiC64InfoController");
    qmlRegisterType<SiC64ActivityController>("Silicium.Controllers", 1, 0, "SiC64ActivityController");
    qmlRegisterType<SiC64StatusbarController>("Silicium.Controllers", 1, 0, "SiC64StatusbarController");
    qmlRegisterType<SiC64KeyboardController>("Silicium.Controllers", 1, 0, "SiC64KeyboardController");
    qmlRegisterType<SiC64Renderer>("Silicium.Components", 1, 0, "SiC64Renderer");
    qmlRegisterType<SiC64DmaView>("Silicium.Components", 1, 0, "SiC64DmaView");
    qmlRegisterType<SiC64Heatmap>("Silicium.Components", 1, 0, "SiC64Heatmap");
    qmlRegisterType<SiC64Waveform>("Silicium.Components", 1, 0, "SiC64Waveform");

    // Register attachments
    qmlRegisterUncreatableType<Palette>("Silicium.Theme", 1, 0, "Palette", "Palette is an attached property");

    // Register singletons
    qmlRegisterSingletonInstance("Silicium.Assets", 1, 0, "Assets", Assets::instance());
    qmlRegisterSingletonInstance("Silicium.Components", 1, 0, "Logger", Logger::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "AppController", &AppController::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "C64Controller", &C64Controller::instance());
    qmlRegisterSingletonInstance("Silicium.Preferences", 1, 0, "Preferences", &Preferences::instance());
    qmlRegisterSingletonInstance("Silicium.Theme", 1, 0, "Shortcuts", &Shortcuts::instance());

    // Parse the command line and open the SVM file it names
    bool ok = C64Controller::instance().parseArguments(app);

    // Launch the emulator core
    C64Controller::instance().initialize();

    // Load the main window, or an alert window if the SVM file couldn't be opened
    const QUrl url(ok
        ? QStringLiteral("qrc:/qt/qml/sic64UI/SiC64/SiC64Window.qml")
        : QStringLiteral("qrc:/qt/qml/sic64UI/SiC64/Dialogs/SiC64About.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, ok](QObject *obj, const QUrl &objUrl) {

            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
                return;
            }

            if (url != objUrl) return;
            if (!ok) return;

            // Wire the main window's lifetime to the C64Controller
            if (auto *window = qobject_cast<QQuickWindow *>(obj)) {
                C64Controller::instance().attachWindow(window);
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
