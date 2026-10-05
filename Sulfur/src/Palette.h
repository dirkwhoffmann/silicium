// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QColor>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>

class Palette : public QQuickAttachedPropertyPropagator {

  public:

    enum class Appearance { Auto, Light, Dark };
    Q_ENUM(Appearance)

    enum class Theme { AppDefault, Solaris };
    Q_ENUM(Theme)

    enum class Color {

        // Background colors
        Accent,
        AccentElevated,
        Backdrop,
        Background,
        BackgroundElevated,
        BackgroundBorder,
        Elevation,
        Surface,
        SurfaceElevated,
        SurfaceBorder,
        Tint,
        Toolbar,
        ToolbarBorder,

        // Foreground colors
        AccentText,
        Primary,
        Secondary,
        Tertiary,
        Disabled,

        // Status colors
        StatusSuccess,
        StatusWarning,
        StatusError,

        // Widgets
        Widget,
        WidgetElevated,
        WidgetBorder,

        // Inset widgets
        Inset,
        InsetFocused,
        InsetBorder,
        InsetBorderFocused,

        // Transparent overlays
        Overlay,
        OverlayElevated,
        OverlayBorder,
        OverlayBorderElevated,

        Count
    };

    static constexpr int NumColors = static_cast<int>(Color::Count);
    using ColorTable = std::array<QColor, NumColors>;

private:

    Q_OBJECT

    QML_ELEMENT
    QML_ATTACHED(Palette)
    QML_UNCREATABLE("Palette is an attached property")
    Q_DISABLE_COPY_MOVE(Palette)

    // Setting the property to undefined calls the reset function
    Q_PROPERTY(Theme theme READ theme WRITE setTheme RESET resetTheme NOTIFY themeChanged FINAL)
    Q_PROPERTY(Appearance appearance READ appearance WRITE setAppearance RESET resetAppearance NOTIFY themeChanged FINAL)

    Q_PROPERTY(bool darkMode READ darkMode NOTIFY themeChanged FINAL)

    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor accentElevated READ accentElevated NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor backdrop READ backdrop NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor background READ background NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor backgroundElevated READ backgroundElevated NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor backgroundBorder READ backgroundBorder NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor elevation READ elevation NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor surfaceElevated READ surfaceElevated NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor surfaceBorder READ surfaceBorder NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor tint READ tint NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor toolbar READ toolbar NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor toolbarBorder READ toolbarBorder NOTIFY themeChanged FINAL)

    Q_PROPERTY(QColor accentText READ accentText NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor primary READ primary NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor secondary READ secondary NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor tertiary READ tertiary NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor disabled READ disabled NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor statusSuccess READ statusSuccess NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor statusWarning READ statusWarning NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor statusError READ statusError NOTIFY themeChanged FINAL)

    Q_PROPERTY(QColor widget READ widget NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor widgetElevated READ widgetElevated NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor widgetBorder READ widgetBorder NOTIFY themeChanged FINAL)

    Q_PROPERTY(QColor inset READ inset NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor insetFocused READ insetFocused NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor insetBorder READ insetBorder NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor insetBorderFocused READ insetBorderFocused NOTIFY themeChanged FINAL)

    Q_PROPERTY(QColor overlay READ overlay NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor overlayElevated READ overlayElevated NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor overlayBorder READ overlayBorder NOTIFY themeChanged FINAL)
    Q_PROPERTY(QColor overlayBorderElevated READ overlayBorderElevated NOTIFY themeChanged FINAL)

    Appearance m_appearance = Appearance::Auto;
    bool m_explicitAppearance = false;

    Theme m_theme = Theme::AppDefault;
    bool m_explicitTheme = false;

    static ColorTable m_colors[2][2];
    static Palette *qmlAttachedProperties(QObject *object);

    explicit Palette(QObject *parent = nullptr);

    Appearance appearance() const { return m_appearance; }
    void setAppearance(Appearance value);
    void inheritAppearance(Appearance value);
    void propagateAppearance();
    void resetAppearance();

    Theme theme() const { return m_theme; }
    void setTheme(Theme theme);
    void inheritTheme(Theme theme);
    void propagateTheme();
    void resetTheme();

    void themeChange();

    const ColorTable &activeTable() const;

    QColor accent() const { return getColor(Color::Accent); }
    QColor accentElevated() const { return getColor(Color::AccentElevated); }
    QColor backdrop() const { return getColor(Color::Backdrop); }
    QColor background() const { return getColor(Color::Background); }
    QColor backgroundElevated() const { return getColor(Color::BackgroundElevated); }
    QColor backgroundBorder() const { return getColor(Color::BackgroundBorder); }
    QColor elevation() const { return getColor(Color::Elevation); }
    QColor surface() const { return getColor(Color::Surface); }
    QColor surfaceElevated() const { return getColor(Color::SurfaceElevated); }
    QColor surfaceBorder() const { return getColor(Color::SurfaceBorder); }
    QColor tint() const { return getColor(Color::Tint); }
    QColor toolbar() const { return getColor(Color::Toolbar); }
    QColor toolbarBorder() const { return getColor(Color::ToolbarBorder); }

    QColor accentText() const { return getColor(Color::AccentText); }
    QColor primary() const { return getColor(Color::Primary); }
    QColor secondary() const { return getColor(Color::Secondary); }
    QColor tertiary() const { return getColor(Color::Tertiary); }
    QColor disabled() const { return getColor(Color::Disabled); }
    QColor statusSuccess() const { return getColor(Color::StatusSuccess); }
    QColor statusWarning() const { return getColor(Color::StatusWarning); }
    QColor statusError() const { return getColor(Color::StatusError); }

    QColor widget() const { return getColor(Color::Widget); }
    QColor widgetElevated() const { return getColor(Color::WidgetElevated); }
    QColor widgetBorder() const { return getColor(Color::WidgetBorder); }

    QColor inset() const { return getColor(Color::Inset); }
    QColor insetFocused() const { return getColor(Color::InsetFocused); }
    QColor insetBorder() const { return getColor(Color::InsetBorder); }
    QColor insetBorderFocused() const { return getColor(Color::InsetBorderFocused); }

    QColor overlay() const { return getColor(Color::Overlay); }
    QColor overlayElevated() const { return getColor(Color::OverlayElevated); }
    QColor overlayBorder() const { return getColor(Color::OverlayBorder); }
    QColor overlayBorderElevated() const { return getColor(Color::OverlayBorderElevated); }

Q_SIGNALS:

    void themeChanged();

  protected:

    void attachedParentChange(QQuickAttachedPropertyPropagator *newParent,
                              QQuickAttachedPropertyPropagator *oldParent) override;

  private:

    bool darkMode() const;
    QColor getColor(Color c) const;

    //
    // Color factory
    //

    void computeColorTables();
    QColor computeDefaultColor(Color c, bool darkMode) const;
    QColor computeSolarisColor(Color c, bool darkMode) const;
};
