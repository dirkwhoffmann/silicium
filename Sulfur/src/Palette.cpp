// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "Palette.h"
#include "SulfurSettings.h"
#include <QGuiApplication>
#include <QStyleHints>
#include <QRgb>

Palette::ColorTable Palette::m_colors[2][2];

Palette::Palette(QObject *parent) : QQuickAttachedPropertyPropagator(parent)
{
    m_appearance = Appearance(SulfurSettings::instance().appearance());
    m_theme  = Theme(SulfurSettings::instance().colorTheme());

    computeColorTables();
    initialize();

    // Follow the host system's dark mode setting while in Auto mode
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this](Qt::ColorScheme) {
        if (m_appearance == Appearance::Auto) themeChange();
    });
}

const Palette::ColorTable &
Palette::activeTable() const
{
    return m_colors[m_theme == Theme::Solaris ? 1 : 0][darkMode() ? 1 : 0];
}

Palette *
Palette::qmlAttachedProperties(QObject *object)
{
    return new Palette(object);
}

void
Palette::setAppearance(Appearance value)
{
    m_explicitAppearance = true;

    // QGuiApplication::styleHints() is process-global, so it must only be
    // touched by the root Palette (the one attached directly to a Window,
    // which is what drives the OS-native title bar). A Palette attached
    // further down the item tree -- e.g. to recolor a single page -- has an
    // attached parent Palette; letting it through here would flip every
    // window's title bar and every other Palette in Auto mode along with it.
    if (!qobject_cast<Palette *>(attachedParent())) {

        switch (value) {
            case Appearance::Light:
                QGuiApplication::styleHints()->setColorScheme(Qt::ColorScheme::Light);
                break;
            case Appearance::Dark:
                QGuiApplication::styleHints()->setColorScheme(Qt::ColorScheme::Dark);
                break;
            default:
                QGuiApplication::styleHints()->setColorScheme(Qt::ColorScheme::Unknown);
                break;
        }
    }

    if (m_appearance != value) {

        m_appearance = value;
        propagateAppearance();
        themeChange();
    }
}

void
Palette::inheritAppearance(Appearance value)
{
    if (!m_explicitAppearance) {

        m_appearance = value;
        propagateAppearance();
        themeChange();
    }
}
void
Palette::propagateAppearance()
{
    const auto styles = attachedChildren();

    for (QQuickAttachedPropertyPropagator *child : styles) {

        if (auto *palette = qobject_cast<Palette *>(child)) {
            palette->inheritAppearance(m_appearance);
        }
    }
}

void
Palette::resetAppearance()
{
    if (m_explicitAppearance) {

        m_explicitAppearance = false;
        Palette *palette = qobject_cast<Palette *>(attachedParent());
        inheritAppearance(palette ? palette->appearance() : Appearance::Auto);
    }
}


void
Palette::setTheme(Theme theme)
{
    m_explicitTheme = true;

    if (m_theme != theme) {

        m_theme = theme;
        propagateTheme();
        themeChange();
    }
}

void
Palette::inheritTheme(Theme theme)
{
    if (!m_explicitTheme) {

        m_theme = theme;
        propagateTheme();
        themeChange();
    }
}

void
Palette::propagateTheme()
{
    const auto styles = attachedChildren();

    for (QQuickAttachedPropertyPropagator *child : styles) {

        if (auto *palette = qobject_cast<Palette *>(child)) {
            palette->inheritTheme(m_theme);
        }
    }
}

void
Palette::resetTheme()
{
    if (m_explicitTheme) {

        m_explicitTheme  = false;
        Palette *palette = qobject_cast<Palette *>(attachedParent());
        inheritTheme(palette ? palette->theme() : Theme::AppDefault);
    }
}

void
Palette::themeChange()
{
    emit themeChanged();

    // Emit other change signals for theme-dependent properties
    // ...
}

void
Palette::attachedParentChange(QQuickAttachedPropertyPropagator *newParent,
                              QQuickAttachedPropertyPropagator *oldParent)
{
    Q_UNUSED(oldParent);
    Palette *attachedParentStyle = qobject_cast<Palette *>(newParent);

    if (attachedParentStyle) {

        inheritAppearance(attachedParentStyle->appearance());
        inheritTheme(attachedParentStyle->theme());
    }
}

bool
Palette::darkMode() const
{
    switch (m_appearance) {

        case Appearance::Light: return false;
        case Appearance::Dark:  return true;

        default:
            return QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
    }
}


QColor
Palette::getColor(Color c) const
{
    return m_colors[size_t(m_theme)][darkMode()][size_t(c)];
}

template <> QColor
Palette::computeColor<Palette::Theme::AppDefault>(Color c, bool darkMode) const
{
    auto lighter = [&](Color col, int factor = 115) {
        return computeColor<Theme::AppDefault>(col, darkMode).lighter(factor);
    };
    auto darker = [&](Color col, int factor = 115) {
        return computeColor<Theme::AppDefault>(col, darkMode).darker(factor);
    };

    if (darkMode) {

        //
        // Dark mode
        //

        switch (c) {

            case Color::Accent:                 return QColor("#0080FF");
            case Color::Backdrop:               return QColor("#161414");
            case Color::Background:             return QColor("#262424");
            case Color::Surface:                return QColor("#3c3c3e"); // QColor("#2c2c2e");
            case Color::Tint:                   return QColor("#99ccff");
            case Color::Toolbar:                return darker(Color::Surface, 100); // lighter(Color::Background, 110);

            case Color::AccentText:             return QColor("#FFFFFF");
            case Color::Primary:                return QColor("#ffffff");
            case Color::Secondary:              return QColor("#c0ffffff"); // alpha(Color::Primary, 192);
            case Color::Tertiary:               return QColor("#80ffffff"); // alpha(Color::Primary, 128);
            case Color::Disabled:               return QColor("#40ffffff"); // alpha(Color::Primary, 64);

            case Color::StatusSuccess:          return QColor("#66ff66");
            case Color::StatusWarning:          return QColor("#ffff66");
            case Color::StatusError:            return QColor("#ff6666");

            case Color::Widget:                 return QColor("#363434");
            case Color::Inset:                  return lighter(Color::Surface,120); // QColor("#555555"); //  ""#656565");
            case Color::InsetFocused:           return lighter(Color::Inset,130);
            case Color::InsetBorderFocused:     return lighter(Color::InsetFocused,150);

            case Color::Overlay:                return QColor("#A0000000");

            default:
                return deriveColor<Theme::AppDefault>(c, darkMode);
        }

    } else {

        //
        // Light mode
        //

        switch (c) {

            case Color::Accent:                 return QColor("#00309F");
            case Color::Backdrop:               return QColor("#cccccc");
            case Color::Background:             return QColor("#ececec");
            case Color::Surface:                return QColor("#e2e2e2");
            case Color::Tint:                   return QColor("#CFDDFF");
            case Color::Toolbar:                return darker(Color::Surface, 100); // darker(Color::Background, 104);

            case Color::AccentText:             return QColor("#FFFFFF");
            case Color::Primary:                return QColor("#000000");
            case Color::Secondary:              return QColor("#c0000000");
            case Color::Tertiary:               return QColor("#80000000");
            case Color::Disabled:               return QColor("#40000000");

            case Color::StatusSuccess:          return QColor("#00aa00");
            case Color::StatusWarning:          return QColor("#cccc00");
            case Color::StatusError:            return QColor("#ff0000");

            case Color::Widget:                 return QColor("#dcdcdc");
            case Color::Inset:                  return QColor("#FFFFFF");
            case Color::InsetFocused:           return QColor("#FFFFFF");
            case Color::InsetBorder:            return darker(Color::Inset);
            case Color::InsetBorderFocused:     return darker(Color::InsetBorder);

            case Color::Overlay:                return QColor("#A0000000");

            default:
                return deriveColor<Theme::AppDefault>(c, darkMode);
        }
    }
}

template <> QColor
Palette::computeColor<Palette::Theme::Solaris>(Color c, bool darkMode) const
{
    auto lighter = [&](Color col, int factor = 115) {
        return computeColor<Theme::Solaris>(col, darkMode).lighter(factor);
    };
    auto darker = [&](Color col, int factor = 115) {
        return computeColor<Theme::Solaris>(col, darkMode).darker(factor);
    };

    if (darkMode) {

        //
        // Dark mode
        //

        switch (c) {

            case Color::Accent:                 return QColor("#A75376");
            case Color::Backdrop:               return QColor("#5C636A");
            case Color::Background:             return QColor("#494971"); // #586C80"); // #718BA4"); // #AFB2C1").darker(115);
            case Color::Surface:                return QColor("#9496A4");
            case Color::Tint:                   return QColor("#636398");
            case Color::Toolbar:                return lighter(Color::Background);

            case Color::AccentText:             return QColor("#FFFFFF");
            case Color::Primary:                return QColor("#FFFFFF");
            case Color::Secondary:              return QColor("#98FFFFFF");
            case Color::Tertiary:               return QColor("#80FFFFFF");
            case Color::Disabled:               return QColor("#40FFFFFF");

            case Color::StatusSuccess:          return QColor("#66ff66");
            case Color::StatusWarning:          return QColor("#A75376");
            case Color::StatusError:            return QColor("#ff6666");

            case Color::Widget:                 return QColor("#55556E"); // darker(Color::Tint, 100); // #6B6C76"); // #767882");
            case Color::Inset:                  return darker(Color::Tint, 100); // "#767882");
            case Color::InsetFocused:           return lighter(Color::Inset); //, 130);
            case Color::InsetBorder:            return darker(Color::Inset, 150); //, 140);
            case Color::InsetBorderFocused:     return darker(Color::InsetBorder);

            case Color::Overlay:                return QColor("#A0000000");

            default:
                return deriveColor<Theme::Solaris>(c, darkMode);
        }

    } else {

        //
        // Light mode
        //

        switch (c) {

            case Color::Accent:                 return QColor("#A75376");
            case Color::Backdrop:               return QColor("#5C636A");
            case Color::Background:             return QColor("#AFB2C1");
            case Color::Surface:                return QColor("#9496A4");
            case Color::Tint:                   return QColor("#636398");
            case Color::Toolbar:                return lighter(Color::Background);

            case Color::AccentText:             return QColor("#FFFFFF");
            case Color::Primary:                return QColor("#000000");
            case Color::Secondary:              return QColor("#98000000");
            case Color::Tertiary:               return QColor("#80000000");
            case Color::Disabled:               return QColor("#40000000");

            case Color::StatusSuccess:          return QColor("#66ff66");
            case Color::StatusWarning:          return QColor("#A75376");
            case Color::StatusError:            return QColor("#ff6666");

            case Color::Widget:                 return QColor("#D4D5DF");
            case Color::Inset:                  return QColor("#D4D5DF");
            case Color::InsetFocused:           return lighter(Color::Inset); //, 130);
            case Color::InsetBorder:            return darker(Color::Inset, 150); //, 140);
            case Color::InsetBorderFocused:     return darker(Color::InsetBorder);

            case Color::Overlay:                return QColor("#A0000000");

            default:
                return deriveColor<Theme::Solaris>(c, darkMode);
        }
    }
}

template <Palette::Theme T> QColor
Palette::deriveColor(Color c, bool darkMode) const
{
    auto lighter = [&](Color col, int factor = 115) {
        return computeColor<T>(col, darkMode).lighter(factor);
    };
    auto darker = [&](Color col, int factor = 115) {
        return computeColor<T>(col, darkMode).darker(factor);
    };

    if (darkMode) {

        switch (c) {

            case Color::AccentElevated:         return lighter(Color::Accent);
            case Color::BackgroundElevated:     return lighter(Color::Background);
            case Color::BackgroundBorder:       return darker(Color::Background);
            case Color::SurfaceElevated:        return lighter(Color::Surface);
            case Color::SurfaceBorder:          return darker(Color::Surface);
            case Color::WidgetElevated:         return lighter(Color::Widget);
            case Color::WidgetBorder:           return darker(Color::Widget);
            case Color::InsetBorder:            return darker(Color::Inset);
            case Color::OverlayElevated:        return lighter(Color::Overlay);
            case Color::OverlayBorder:          return darker(Color::Overlay);
            case Color::OverlayBorderElevated:  return lighter(Color::OverlayBorder);
            case Color::ToolbarBorder:          return darker(Color::Toolbar);
            case Color::Elevation:              return QColor("#10FFFFFF");

            default:
                return QColor("red");
        }

    } else {

        switch (c) {

            case Color::AccentElevated:         return darker(Color::Accent);
            case Color::BackgroundElevated:     return darker(Color::Background);
            case Color::BackgroundBorder:       return lighter(Color::Background);
            case Color::SurfaceElevated:        return darker(Color::Surface);
            case Color::SurfaceBorder:          return lighter(Color::Surface);
            case Color::WidgetElevated:         return darker(Color::Widget);
            case Color::WidgetBorder:           return darker(Color::Widget);
            case Color::InsetBorder:            return darker(Color::Inset);
            case Color::OverlayElevated:        return darker(Color::Overlay);
            case Color::OverlayBorder:          return lighter(Color::Overlay);
            case Color::OverlayBorderElevated:  return darker(Color::OverlayBorder);
            case Color::ToolbarBorder:          return lighter(Color::Toolbar);
            case Color::Elevation:              return QColor("#10000000");

            default:
                return QColor("red");
        }
    }
}

void
Palette::computeColorTables()
{
    for (std::size_t i = 0; i < m_colors[0][0].size(); ++i) {

        for (std::size_t j = 0; j < 2; ++j) {

            m_colors[size_t(Theme::AppDefault)][j][i] = computeColor<Theme::AppDefault>(Color(i), j);
            m_colors[size_t(Theme::Solaris)][j][i] = computeColor<Theme::Solaris>(Color(i), j);
        }
    }
}
