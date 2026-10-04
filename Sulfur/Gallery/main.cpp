// -----------------------------------------------------------------------------
// This file is part of Sulfur, the Silicium UI toolkit
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "SulfurSettings.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>

int
main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Sulfur Gallery");

    QQuickStyle::setStyle("Fusion");

    // What the application tells Sulfur. A real application copies these from
    // its preferences (see SulfurBridge in Silicium); the gallery just picks.
    auto &settings = SulfurSettings::instance();

    QString screenshot;
    const auto args = app.arguments();

    for (int i = 1; i < args.size(); i++) {

        if (args[i] == "--dark") settings.setAppearance(2);
        if (args[i] == "--light") settings.setAppearance(1);
        if (args[i] == "--screenshot" && i + 1 < args.size()) screenshot = args[++i];
    }

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("SulfurGalleryUI", "Gallery");

    if (engine.rootObjects().isEmpty()) return 1;

    // Write a picture of the window, then go away
    if (!screenshot.isEmpty()) {

        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());

        // Tall enough to show the whole page
        window->setHeight(1450);

        QTimer::singleShot(1500, &app, [&app, window, screenshot] {

            const bool ok = window && window->grabWindow().save(screenshot);
            app.exit(ok ? 0 : 2);
        });
    }

    return app.exec();
}
