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
#include "AudioController.h"
#include "Shared/Theme/Palette.h"
#include "Shared/Theme/Shortcuts.h"
#include "Shared/Preferences/Preferences.h"
#include "HubController.h"
#include "HubSidebarController.h"
#include "Logger.h"
#include "OnboardingController.h"
#include "PrefController.h"
#include "Silicium.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QFileOpenEvent>
#include <QIcon>

/* Opens virtual machines that Finder hands to the app.
 *
 * A document opened from Finder does not arrive on the command line: macOS
 * sends a QFileOpenEvent instead, both for a machine double-clicked while the
 * Hub is already up and for the one that launched it. The launch case is the
 * awkward one -- the event is delivered while the QML engine is still loading,
 * so before HubWindow.qml's Component.onCompleted has called
 * HubController::start() and before there is a library to add anything to.
 *
 * Anything that lands that early is held here and replayed from flush(), which
 * the engine's objectCreated handler calls. That handler is a queued
 * connection, so it runs after engine.load() has returned and start() with it.
 */
class FileOpenFilter : public QObject {

    // Documents that arrived before the hub was ready for them
    QList<QUrl> pending;

    // Whether the QML engine has produced its root object
    bool ready = false;

  public:

    void flush()
    {
        ready = true;

        const auto queued = pending;
        pending.clear();

        for (const auto &url : queued) openVM(url);
    }

  protected:

    bool eventFilter(QObject *object, QEvent *event) override
    {
        if (event->type() != QEvent::FileOpen) {
            return QObject::eventFilter(object, event);
        }

        const auto url = static_cast<QFileOpenEvent *>(event)->url();

        qCDebug(siLog) << "FileOpen:" << url.toString() << (ready ? "" : "(queued)");

        ready ? openVM(url) : pending.append(url);
        return true;
    }

  private:

    static void openVM(const QUrl &url)
    {
        // The Hub owns the library, so the add-or-look-up lives there
        HubController::instance().openVM(url);
    }
};

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
    FileOpenFilter fileOpenFilter;

    // Installed before anything else: on a launch-by-document, the event is
    // already on its way while the rest of this function is still running.
    app.installEventFilter(&fileOpenFilter);

    // Enable logging support
    startLogger(argc, argv);

    // Identify the application
    QCoreApplication::setOrganizationName("dirkwhoffmann");
    QCoreApplication::setApplicationName("Silicium");

    // Force the application to English/US
    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));

    // Configure app appearance
    QQuickStyle::setStyle("Fusion");
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar, true);
    app.setWindowIcon(QIcon(":/assets/images/app-icon.png"));

    // Register types (Controllers)
    qmlRegisterType<AudioController>("Silicium.Controllers", 1, 0, "AudioController");
    qmlRegisterType<HubController>("Silicium.Controllers", 1, 0, "HubController");
    qmlRegisterType<PrefController>("Silicium.Controllers", 1, 0, "PrefController");
    qmlRegisterType<HubSidebarController>("Silicium.Controllers", 1, 0, "HubSidebarController");
    qmlRegisterType<OnboardingController>("Silicium.Controllers", 1, 0, "OnboardingController");

    // Register meta types
    qRegisterMetaType<EmulationKey>("EmulationKey");

    // Register attachments
    qmlRegisterUncreatableType<Palette>("Silicium.Theme", 1, 0, "Palette", "Palette is an attached property");

    // Register singletons
    qmlRegisterSingletonInstance("Silicium.Assets", 1, 0, "Assets", Assets::instance());
    qmlRegisterSingletonInstance("Silicium.Components", 1, 0, "Logger", Logger::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "Silicium", &Silicium::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "AppController", &AppController::instance());
    qmlRegisterSingletonInstance("Silicium.Controllers", 1, 0, "HubController", &HubController::instance());
    qmlRegisterSingletonInstance("Silicium.Preferences", 1, 0, "Preferences", &Preferences::instance());
    qmlRegisterSingletonInstance("Silicium.Theme", 1, 0, "Shortcuts", &Shortcuts::instance());

    // Load the QML file
    const QUrl url(QStringLiteral("qrc:/qt/qml/siliciumUI/Silicium/Hub/HubWindow.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, &fileOpenFilter](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);

            // The hub is up: hand it whatever Finder asked for at launch
            if (obj && url == objUrl) fileOpenFilter.flush();
        },
        Qt::QueuedConnection);
    engine.load(url);

    // Run the app
    try {
        return app.exec();
    } catch (std::exception &e) {
        fprintf(stderr, "FATAL ERROR: \n%s\n", e.what());
    }
}
