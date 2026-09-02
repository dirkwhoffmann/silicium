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

/* Describes a single key on the virtual Amiga keyboard.
 *
 * Coordinates and sizes are given in pixels, taken directly from vAmiga's
 * own A500ANSI.xib/A500ISO.xib/A1000ANSI.xib/A1000ISO.xib (the Mac app's
 * four virtual-keyboard layouts) -- x/y there are Cocoa's bottom-up window
 * coordinates; build() flips them to QML's top-down ones once per layout, so
 * this struct and the QML side both work in the same top-down space.
 *
 * Most keys are plain rectangles. Return isn't, on three of the four
 * layouts: on real hardware it's an upside-down L (wide at the bottom,
 * narrower and right-aligned at the top) -- the same shape a PC calls "ISO
 * Enter". vAmiga's own XIBs don't model that notch as a shaped button --
 * every Return/Enter button's *frame* is a plain rectangle, and the notched
 * look comes only from the "]" key's button being drawn on top of Return's
 * bounding box, overlapping its top-left corner (vAmiga's key-cap images
 * carry no alpha-shaped cutout either -- it's pure z-order layering). There
 * is no such layering here, so build() computes each layout's overlap
 * directly from the two XIBs' raw frames and bakes it into notchWidth/
 * notchHeight instead: 27x36 for the A500 ANSI and both A1000 layouts
 * (their "]" key overlaps Return's top-left corner by exactly that much),
 * and zero for A500 ISO, where Return's own frame is already narrower and
 * a separate "#" key -- not an overlap -- fills the corner. This model
 * keeps the same one-row-per-key shape as SiC64's C64KeyModel, but adds
 * those two fields, zero for every ordinary key, describing how much of a
 * key's bounding box's top-left corner to cut away. The QML side
 * (SiAmKeyboardPanel) turns a non-zero pair into an actual polygon via
 * QtQuick.Shapes, and a plain rectangle for everything else -- see the
 * comment there for the shape itself.
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

    // Non-zero only for Return, and only on the layouts where it's
    // notched -- see the struct comment above.
    qreal notchWidth = 0;
    qreal notchHeight = 0;
};

// List model exposing all keys of the virtual Amiga keyboard to QML. The
// keyboard comes in four physical layouts -- two keyboard styles (A500,
// A1000) crossed with two international standards (ANSI, ISO) -- selected
// via the a1000/iso properties; changing either rebuilds the whole model
// with a different key table.
class AmigaKeyModel : public QAbstractListModel {

    Q_OBJECT

    Q_PROPERTY(bool a1000 READ a1000 WRITE setA1000 NOTIFY layoutChanged)
    Q_PROPERTY(bool iso READ iso WRITE setIso NOTIFY layoutChanged)

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

    // false = A500 (wide) style, true = A1000 (narrow) style
    bool m_a1000 = false;

    // false = ANSI (US), true = ISO (international)
    bool m_iso = false;

public:

    explicit AmigaKeyModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool a1000() const { return m_a1000; }
    void setA1000(bool value);

    bool iso() const { return m_iso; }
    void setIso(bool value);

signals:

    void layoutChanged();

private:

    // Clears the model and repopulates it with the key table matching the
    // current a1000/iso combination.
    void build();

    // One populator per physical layout, each filling 'keys' with positions/
    // sizes/keycodes extracted from the matching vAmiga *.xib.
    void buildA500Ansi();
    void buildA500Iso();
    void buildA1000Ansi();
    void buildA1000Iso();
};
