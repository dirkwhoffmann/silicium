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
#include "Preferences.h"
#include "C64Controller.h"
#include "SiC64Renderer.h"
#include "SiC64ConfigController.h"
#include "SiC64InfoController.h"
#include "Inspector/SiC64InspectorController.h"
#include "Inspector/XRay/SiC64DmaView.h"
#include "Inspector/Memory/SiC64Heatmap.h"
#include "Inspector/SID/SiC64Waveform.h"
#include "SiC64ActivityController.h"
#include "Keyboard/SiC64KeyboardController.h"
#include "SulfurBridge.h"
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
    app.setWindowIcon(QIcon(":/assets/images/c64-icon.png"));

    // Register types
    qmlRegisterType<SiC64ConfigController>("Silicium.Controllers", 1, 0, "SiC64ConfigController");
    qmlRegisterType<SiC64InspectorController>("Silicium.Controllers", 1, 0, "SiC64InspectorController");
    qmlRegisterType<SiC64InfoController>("Silicium.Controllers", 1, 0, "SiC64InfoController");
    qmlRegisterType<SiC64ActivityController>("Silicium.Controllers", 1, 0, "SiC64ActivityController");
    qmlRegisterType<SiC64KeyboardController>("Silicium.Controllers", 1, 0, "SiC64KeyboardController");
    qmlRegisterType<SiC64Renderer>("Silicium.Components", 1, 0, "SiC64Renderer");
    qmlRegisterType<SiC64DmaView>("Silicium.Components", 1, 0, "SiC64DmaView");
    qmlRegisterType<SiC64Heatmap>("Silicium.Components", 1, 0, "SiC64Heatmap");
    qmlRegisterType<SiC64Waveform>("Silicium.Components", 1, 0, "SiC64Waveform");

    // Tell the UI toolkit what the user has set up
    SulfurBridge::install(Assets::Icon::C64Icon);

    // Register singletons
    qmlRegisterSingletonInstance("Silicium.Assets", 1, 0, "Assets", Assets::instance());
    qmlRegisterSingletonInstance("Silicium.Components", 1, 0, "Logger", Logger::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "AppController", &AppController::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "C64Controller", &C64Controller::instance());
    qmlRegisterSingletonInstance("Silicium.Preferences", 1, 0, "Preferences", &Preferences::instance());

    // Parse the command line and open the SVM file it names
    bool ok = C64Controller::instance().parseArguments(app);

    // Choose between the native and the custom menu bar (see parseArguments)
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar, AppController::instance().getCustomMenu());

    // Launch the emulator core
    C64Controller::instance().initialize();

    /* Detach the core before Qt goes away.
     *
     * 'app' is a stack object in this function, so QGuiApplication is
     * destroyed as soon as main() returns -- while the emulator, reached
     * through two function-local statics (C64Controller::instance() and
     * C64Controller::core()), is not destroyed until afterwards. The core
     * keeps posting messages throughout its own shutdown, and every one of
     * them lands in process(), which marshals onto a Qt event loop that no
     * longer exists.
     *
     * Order matters: detach first, then halt. halt() sends a command to the
     * emulator thread and waits until the thread has terminated. The thread
     * answers the command by posting Msg::SHUTDOWN -- so halting first would
     * emit exactly the message this is meant to avoid. Detaching is
     * synchronised against delivery inside MsgQueue, so it is safe to do
     * while that thread is running.
     *
     * Without this the app segfaults on quit whenever nothing else halted
     * the core first, which is the case when it opens the About dialog
     * instead of a machine window (no SVM, or one that failed to load) --
     * that path never calls attachWindow(), so windowDidClose() never runs.
     */
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, [] {

        C64Controller::core().removeListener();
        C64Controller::core().halt();
    });

    // Load the main window, or an alert window if the SVM file couldn't be opened
    const QUrl url(ok
        ? QStringLiteral("qrc:/qt/qml/sic64UI/SiC64/SiC64Window.qml")
        : QStringLiteral("qrc:/qt/qml/sic64UI/Shared/QML/Dialogs/SiAbout.qml"));
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

    // The About window doubles as the error window: tell it what went wrong
    if (!ok) {
        engine.setInitialProperties({
            { "appName", "SiC64" },
            { "iconSource", Assets::instance()->iconUrl(Assets::Icon::C64Icon) },
            { "tagline", QObject::tr("C64 Virtual Machine") },
            { "errorMessage", C64Controller::instance().getErrorMessage() }
        });
    }
    engine.load(url);

    // Run the app
    try {
        return app.exec();
    } catch (std::exception &e) {
        fprintf(stderr, "FATAL ERROR: \n%s\n", e.what());
    }
}
