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
#include <QHash>

/* A single label variant for a key.
 *
 *  'special' mirrors the `font: "C64"` annotation found on the corresponding
 *  Keycap() call in the original Swift keycap table: it is true only for
 *  glyphs that require the bundled C64 Pro Mono font (PETSCII / graphics
 *  characters), and false for plain text shown in the regular UI font.
 */
struct C64KeyLabel {

    QString text;
    bool special = false;
};

/* Describes a single key on the virtual C64 keyboard
 *
 *  Coordinates and sizes are given in abstract grid units. The QML side
 *  multiplies them by a common key size to compute pixel positions, so the
 *  whole keyboard scales uniformly.
 *
 *  A key can show different labels depending on which modifier keys are
 *  currently held down (SHIFT, Commodore, CTRL) and whether lower case
 *  letters are requested. 'labels' maps a modifier bitmask (see
 *  C64KeyModel::Modifier) to the label that should be shown for that
 *  combination. Ported from the modifier-aware keycap lookup originally
 *  implemented in the Swift-based VirtualC64 GUI.
 */
struct C64KeyInfo {

    // Unique key identifier (matches vc64::C64Key::nr, 0 .. 65)
    int nr = -1;

    // Row / column in the physical keyboard matrix (-1 for RESTORE and SHIFT LOCK)
    int row = -1;
    int col = -1;

    // Label variants, keyed by a C64KeyModel::Modifier bitmask
    QHash<int, C64KeyLabel> labels;

    // Position and size in grid units
    qreal x = 0;
    qreal y = 0;
    qreal width = 1;
    qreal height = 1;
};

// List model exposing all keys of the virtual C64 keyboard to QML
class C64KeyModel : public QAbstractListModel {

    Q_OBJECT

    Q_PROPERTY(bool shiftPressed READ shiftPressed WRITE setShiftPressed NOTIFY modifiersChanged)
    Q_PROPERTY(bool commodorePressed READ commodorePressed WRITE setCommodorePressed NOTIFY modifiersChanged)
    Q_PROPERTY(bool controlPressed READ controlPressed WRITE setControlPressed NOTIFY modifiersChanged)
    Q_PROPERTY(bool lowercase READ lowercase WRITE setLowercase NOTIFY modifiersChanged)

public:

    enum KeyRoles {

        NrRole = Qt::UserRole + 1,
        RowRole,
        ColRole,
        LabelRole,
        SpecialFontRole,
        XRole,
        YRole,
        WidthRole,
        HeightRole
    };

    // Modifier flags that select which label variant is displayed
    enum Modifier {

        None      = 0,
        Shift     = 1 << 0,
        Commodore = 1 << 1,
        Control   = 1 << 2,
        Lowercase = 1 << 3
    };

private:

    QVector<C64KeyInfo> keys;

    // Currently active combination of Modifier flags
    int m_modifiers = None;

public:

    explicit C64KeyModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool shiftPressed() const { return m_modifiers & Shift; }
    void setShiftPressed(bool value);

    bool commodorePressed() const { return m_modifiers & Commodore; }
    void setCommodorePressed(bool value);

    bool controlPressed() const { return m_modifiers & Control; }
    void setControlPressed(bool value);

    bool lowercase() const { return m_modifiers & Lowercase; }
    void setLowercase(bool value);

signals:

    void modifiersChanged();

private:

    // Populates the model with all 66 C64 keys
    void build();

    // Adds or removes a single modifier flag from the active combination
    void setModifier(Modifier flag, bool value);

    // Picks the label variant that best matches the active modifiers
    const C64KeyLabel &resolveLabel(const C64KeyInfo &key) const;
};
