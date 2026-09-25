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
#include "Config/SiAmConfigController.h"
#include "SiAmInfoController.h"
#include "Inspector/SiAmLogicView.h"
#include "Inspector/SiAmSpriteView.h"
#include "Inspector/SiAmDmaView.h"
#include "AppController.h"
#include "Assets.h"
#include "Logger.h"
#include "Palette.h"
#include "Preferences.h"
#include "Shortcuts.h"
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
    qmlRegisterType<SiAmConfigController>("Silicium.Controllers", 1, 0, "SiAmConfigController");
    qmlRegisterType<SiAmInfoController>("Silicium.Controllers", 1, 0, "SiAmInfoController");
    qmlRegisterType<SiAmLogicView>("Silicium.Components", 1, 0, "SiAmLogicView");
    qmlRegisterType<SiAmSpriteView>("Silicium.Components", 1, 0, "SiAmSpriteView");
    qmlRegisterType<SiAmDmaView>("Silicium.Components", 1, 0, "SiAmDmaView");

    // Register attachments
    qmlRegisterUncreatableType<Palette>("Silicium.Theme", 1, 0, "Palette", "Palette is an attached property");

    // Register singletons
    qmlRegisterSingletonInstance("Silicium.Assets", 1, 0, "Assets", Assets::instance());
    qmlRegisterSingletonInstance("Silicium.Components", 1, 0, "Logger", Logger::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "AppController", &AppController::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "SiAmController", &SiAmController::instance());
    qmlRegisterSingletonInstance("Silicium.Preferences", 1, 0, "Preferences", &Preferences::instance());
    qmlRegisterSingletonInstance("Silicium.Theme", 1, 0, "Shortcuts", &Shortcuts::instance());

    // Parse the command line and open the SVM file it names
    bool ok = SiAmController::instance().parseArguments(app);

    // Launch the emulator core
    SiAmController::instance().initialize();

    /* Detach the core before Qt goes away.
     *
     * 'app' is a stack object in this function, so QGuiApplication is
     * destroyed as soon as main() returns -- while the emulator, reached
     * through two function-local statics (SiAmController::instance() and
     * SiAmController::core()), is not destroyed until afterwards. The core
     * keeps posting messages throughout its own shutdown, and every one of
     * them lands in process(), which marshals onto a Qt event loop that no
     * longer exists.
     *
     * Order matters: detach first, then halt. halt() only queues a command
     * for the emulator thread, which answers it by posting Msg::SHUTDOWN --
     * so halting first would emit exactly the message this is meant to
     * avoid. Detaching is synchronised against delivery inside MsgQueue, so
     * it is safe to do while that thread is running.
     *
     * Without this the app segfaults on quit whenever nothing else halted
     * the core first, which is the case when it opens the About dialog
     * instead of a machine window (no SVM, or one that failed to load) --
     * that path never calls attachWindow(), so windowDidClose() never runs.
     */
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, [] {

        SiAmController::core().removeListener();
        SiAmController::core().halt();
    });

    // Load the main window, or an alert window if the SVM file couldn't be opened
    const QUrl url(ok
        ? QStringLiteral("qrc:/qt/qml/siamigaUI/SiAmiga/SiAmWindow.qml")
        : QStringLiteral("qrc:/qt/qml/siamigaUI/SiAmiga/Dialogs/SiAmAbout.qml"));
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
