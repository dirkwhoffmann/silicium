// -----------------------------------------------------------------------------
// This file is part of Sulfur, the Silicium UI toolkit
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>

/* The settings Sulfur needs from the application.
 *
 * Sulfur knows nothing about the application that uses it. What it needs to
 * know -- which color scheme and fonts to use, whether to draw layout debug
 * aids -- the application tells it here, once at startup and again whenever
 * the user changes a setting. (Silicium does that in SulfurBridge, which
 * copies the values over from its preferences.)
 *
 * The values are plain numbers and flags, with the meaning the theme gives
 * them (see Palette::Appearance, Palette::Theme and Fonts.qml).
 */
class SulfurSettings : public QObject {

    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Color scheme: Palette::Appearance (Auto, Light, Dark)
    Q_PROPERTY(int appearance READ appearance WRITE setAppearance NOTIFY changed)

    // Color theme: Palette::Theme (AppDefault, Solaris)
    Q_PROPERTY(int colorTheme READ colorTheme WRITE setColorTheme NOTIFY changed)

    // Proportional and monospaced font family (see Fonts.qml)
    Q_PROPERTY(int fontTheme READ fontTheme WRITE setFontTheme NOTIFY changed)
    Q_PROPERTY(int monoFontTheme READ monoFontTheme WRITE setMonoFontTheme NOTIFY changed)

    // Draws layout debug aids (see DebugRect, HSpacer, VSpacer)
    Q_PROPERTY(bool debug READ debug WRITE setDebug NOTIFY changed)

    // The pictures a message dialog (SuUserDialog) shows: the icon of the
    // application, and the badge in its corner
    Q_PROPERTY(QUrl dialogIcon READ dialogIcon WRITE setDialogIcon NOTIFY changed)
    Q_PROPERTY(QUrl dialogBadge READ dialogBadge WRITE setDialogBadge NOTIFY changed)

    int m_appearance = 0;
    int m_colorTheme = 0;
    int m_fontTheme = 0;
    int m_monoFontTheme = 0;
    bool m_debug = false;
    QUrl m_dialogIcon;
    QUrl m_dialogBadge;

public:

    static SulfurSettings &instance();

    // The factory QML uses to get hold of the singleton
    static SulfurSettings *create(QQmlEngine *, QJSEngine *);

    SulfurSettings(const SulfurSettings &) = delete;
    SulfurSettings &operator=(const SulfurSettings &) = delete;

    int appearance() const { return m_appearance; }
    void setAppearance(int value) { update(m_appearance, value); }

    int colorTheme() const { return m_colorTheme; }
    void setColorTheme(int value) { update(m_colorTheme, value); }

    int fontTheme() const { return m_fontTheme; }
    void setFontTheme(int value) { update(m_fontTheme, value); }

    int monoFontTheme() const { return m_monoFontTheme; }
    void setMonoFontTheme(int value) { update(m_monoFontTheme, value); }

    bool debug() const { return m_debug; }
    void setDebug(bool value) { update(m_debug, value); }

    QUrl dialogIcon() const { return m_dialogIcon; }
    void setDialogIcon(const QUrl &value) { update(m_dialogIcon, value); }

    QUrl dialogBadge() const { return m_dialogBadge; }
    void setDialogBadge(const QUrl &value) { update(m_dialogBadge, value); }

signals:

    void changed();

private:

    explicit SulfurSettings(QObject *parent = nullptr) : QObject(parent) { }

    template <typename T> void update(T &member, T value) {

        if (member != value) {
            member = value;
            emit changed();
        }
    }
};
