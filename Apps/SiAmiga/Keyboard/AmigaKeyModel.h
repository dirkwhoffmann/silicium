// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#include <QAbstractListModel>

/* Describes a single key on the virtual Amiga 500 keyboard.
 *
 * Coordinates and sizes are given in pixels, taken directly from vAmiga's
 * own A500ANSI.xib (the Mac app's virtual keyboard layout) -- x/y there are
 * Cocoa's bottom-up window coordinates; build() flips them to QML's
 * top-down ones once, so this struct and the QML side both work in the
 * same top-down space.
 *
 * Most keys are plain rectangles. The Return key isn't: on a real Amiga
 * keyboard it's an upside-down L (wide at the bottom, narrower and
 * right-aligned at the top) -- the same shape a PC calls "ISO Enter". The
 * XIB models this with a single button whose *frame* is the full bounding
 * box (the notch is cut out of the button's *image* instead, which isn't
 * an option here since there's no such key-cap art to draw from). This
 * model keeps the same one-row-per-key shape as SiC64's C64KeyModel, but
 * adds two fields -- notchWidth/notchHeight -- that are zero for every
 * ordinary rectangular key and non-zero only for Return, describing how
 * much of the top-left corner of its bounding box to cut away. The QML
 * side (SiAmKeyboardPanel) turns that into an actual six-point polygon via
 * QtQuick.Shapes for the one key that needs it, and a plain rectangle for
 * everything else -- see the comment there for the shape itself.
 */
struct AmigaKeyInfo {

    // Raw Amiga keycode (matches vamiga::KeyCode / the core's KeyboardAPI)
    int nr = -1;

    QString label;

    // Position and size, in pixels
    qreal x = 0;
    qreal y = 0;
    qreal width = 1;
    qreal height = 1;

    // Non-zero only for Return -- see the struct comment above.
    qreal notchWidth = 0;
    qreal notchHeight = 0;
};

// List model exposing all keys of the virtual Amiga keyboard to QML
class AmigaKeyModel : public QAbstractListModel {

    Q_OBJECT

public:

    enum KeyRoles {

        NrRole = Qt::UserRole + 1,
        LabelRole,
        XRole,
        YRole,
        WidthRole,
        HeightRole,
        NotchWidthRole,
        NotchHeightRole
    };

private:

    QVector<AmigaKeyInfo> keys;

public:

    explicit AmigaKeyModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

private:

    // Populates the model with all 93 keys of the A500 ANSI layout
    // (positions/sizes/keycodes extracted from vAmiga's A500ANSI.xib).
    void build();
};
