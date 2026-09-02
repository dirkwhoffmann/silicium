// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "AmigaKeyModel.h"

namespace {

// Appends one key to 'keys'. Position/size in pixels, taken directly from
// vAmiga's own *.xib virtual-keyboard layouts, with the y axis flipped once
// here (Cocoa's frames are bottom-up; QML is top-down) so everything
// downstream just works in ordinary top-down coordinates. 'nr' is the exact
// keycode the XIB wires each button to (its "tag", fed straight to
// KeyboardAPI::press/release on the real app) -- these are the raw Amiga
// hardware scancodes, not something invented for this port.
void add(QVector<AmigaKeyInfo> &keys, int nr, const char *label, qreal x, qreal y, qreal w, qreal h,
          qreal notchW = 0, qreal notchH = 0)
{
    keys.append({ nr, QString::fromUtf8(label), x, y, w, h, notchW, notchH });
}

}

AmigaKeyModel::AmigaKeyModel(QObject *parent) : QAbstractListModel(parent)
{
    build();
}

int
AmigaKeyModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return keys.size();
}

QHash<int, QByteArray>
AmigaKeyModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[NrRole]          = "nr";
    roles[LabelRole]       = "label";
    roles[XRole]           = "x";
    roles[YRole]           = "y";
    roles[WidthRole]       = "width";
    roles[HeightRole]      = "height";
    roles[NotchWidthRole]  = "notchWidth";
    roles[NotchHeightRole] = "notchHeight";

    return roles;
}

QVariant
AmigaKeyModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= keys.size()) return {};

    const auto &key = keys[index.row()];

    switch (role) {

        case NrRole:          return key.nr;
        case LabelRole:       return key.label;
        case XRole:            return key.x;
        case YRole:            return key.y;
        case WidthRole:       return key.width;
        case HeightRole:      return key.height;
        case NotchWidthRole:  return key.notchWidth;
        case NotchHeightRole: return key.notchHeight;
        default:              return {};
    }
}

void
AmigaKeyModel::setA1000(bool value)
{
    if (m_a1000 != value) {

        m_a1000 = value;
        build();
        emit layoutChanged();
    }
}

void
AmigaKeyModel::setIso(bool value)
{
    if (m_iso != value) {

        m_iso = value;
        build();
        emit layoutChanged();
    }
}

void
AmigaKeyModel::build()
{
    beginResetModel();

    keys.clear();

    if (m_a1000) {
        m_iso ? buildA1000Iso() : buildA1000Ansi();
    } else {
        m_iso ? buildA500Iso() : buildA500Ansi();
    }

    endResetModel();
}

// Layout: A500, ANSI (US) -- vAmiga's A500ANSI.xib, content view 883x270.
// The only key in any of the four layouts with a non-zero notch: the ISO
// slot to its upper-left is empty here (no separate "#" key fills it, see
// buildA500Iso()), so Return itself has to cut that corner away.
void
AmigaKeyModel::buildA500Ansi()
{
    add(keys, 69, "Esc", 20, 20, 36, 36);
    add(keys, 80, "F1", 74, 20, 45, 36);
    add(keys, 81, "F2", 119, 20, 45, 36);
    add(keys, 82, "F3", 164, 20, 45, 36);
    add(keys, 83, "F4", 209, 20, 45, 36);
    add(keys, 84, "F5", 254, 20, 45, 36);
    add(keys, 85, "F6", 317, 20, 45, 36);
    add(keys, 86, "F7", 362, 20, 45, 36);
    add(keys, 87, "F8", 407, 20, 45, 36);
    add(keys, 88, "F9", 452, 20, 45, 36);
    add(keys, 89, "F10", 497, 20, 45, 36);
    add(keys, 0, "`", 20, 70, 54, 36);
    add(keys, 1, "1", 74, 70, 36, 36);
    add(keys, 2, "2", 110, 70, 36, 36);
    add(keys, 3, "3", 146, 70, 36, 36);
    add(keys, 4, "4", 182, 70, 36, 36);
    add(keys, 5, "5", 218, 70, 36, 36);
    add(keys, 6, "6", 254, 70, 36, 36);
    add(keys, 7, "7", 290, 70, 36, 36);
    add(keys, 8, "8", 326, 70, 36, 36);
    add(keys, 9, "9", 362, 70, 36, 36);
    add(keys, 10, "0", 398, 70, 36, 36);
    add(keys, 11, "-", 434, 70, 36, 36);
    add(keys, 12, "=", 470, 70, 36, 36);
    add(keys, 13, "\\", 506, 70, 36, 36);
    add(keys, 65, "Backspace", 542, 70, 36, 36);
    add(keys, 70, "Del", 596, 70, 54, 36);
    add(keys, 95, "Help", 650, 70, 54, 36);
    add(keys, 90, "(", 722, 70, 36, 36);
    add(keys, 91, ")", 757, 70, 36, 36);
    add(keys, 92, "/", 792, 70, 36, 36);
    add(keys, 93, "*", 827, 70, 36, 36);
    add(keys, 66, "Tab", 20, 106, 72, 36);
    add(keys, 16, "Q", 92, 106, 36, 36);
    add(keys, 17, "W", 128, 106, 36, 36);
    add(keys, 18, "E", 164, 106, 36, 36);
    add(keys, 19, "R", 200, 106, 36, 36);
    add(keys, 20, "T", 236, 106, 36, 36);
    add(keys, 21, "Y", 272, 106, 36, 36);
    add(keys, 22, "U", 308, 106, 36, 36);
    add(keys, 23, "I", 344, 106, 36, 36);
    add(keys, 24, "O", 380, 106, 36, 36);
    add(keys, 25, "P", 416, 106, 36, 36);
    add(keys, 26, "[", 452, 106, 36, 36);
    add(keys, 27, "]", 488, 106, 36, 36);
    add(keys, 61, "7", 722, 106, 36, 36);
    add(keys, 62, "8", 757, 106, 36, 36);
    add(keys, 63, "9", 792, 106, 36, 36);
    add(keys, 74, "-", 827, 106, 36, 36);
    add(keys, 99, "Ctrl", 20, 142, 45, 36);
    add(keys, 98, "Caps\nLock", 65, 142, 36, 36);
    add(keys, 32, "A", 101, 142, 36, 36);
    add(keys, 33, "S", 137, 142, 36, 36);
    add(keys, 34, "D", 173, 142, 36, 36);
    add(keys, 35, "F", 209, 142, 36, 36);
    add(keys, 36, "G", 245, 142, 36, 36);
    add(keys, 37, "H", 281, 142, 36, 36);
    add(keys, 38, "J", 317, 142, 36, 36);
    add(keys, 39, "K", 353, 142, 36, 36);
    add(keys, 40, "L", 389, 142, 36, 36);
    add(keys, 41, ";", 425, 142, 36, 36);
    add(keys, 42, "'", 461, 142, 36, 36);
    // Return: bounding box spans this row and the one above it (Q-P/[]).
    // Real hardware cuts the top-left corner away, leaving a wide bottom
    // (aligned with this row) and a narrower, right-aligned top (aligned
    // with the row above) -- see AmigaKeyModel.h and SiAmKeyboardPanel.qml
    // for how notchWidth/notchHeight turn into that shape.
    add(keys, 68, "Return", 497, 106, 81, 72, /* notchWidth */ 27, /* notchHeight */ 36);
    add(keys, 76, "Up", 632, 142, 36, 36);
    add(keys, 45, "4", 722, 142, 36, 36);
    add(keys, 46, "5", 757, 142, 36, 36);
    add(keys, 47, "6", 792, 142, 36, 36);
    add(keys, 94, "+", 827, 142, 36, 36);
    add(keys, 96, "Shift", 20, 178, 99, 36);
    add(keys, 49, "Z", 119, 178, 36, 36);
    add(keys, 50, "X", 155, 178, 36, 36);
    add(keys, 51, "C", 191, 178, 36, 36);
    add(keys, 52, "V", 227, 178, 36, 36);
    add(keys, 53, "B", 263, 178, 36, 36);
    add(keys, 54, "N", 299, 178, 36, 36);
    add(keys, 55, "M", 335, 178, 36, 36);
    add(keys, 56, ",", 371, 178, 36, 36);
    add(keys, 57, ".", 407, 178, 36, 36);
    add(keys, 58, "/", 443, 178, 36, 36);
    add(keys, 97, "Shift", 479, 178, 99, 36);
    add(keys, 79, "Left", 596, 178, 36, 36);
    add(keys, 77, "Down", 632, 178, 36, 36);
    add(keys, 78, "Right", 668, 178, 36, 36);
    add(keys, 29, "1", 722, 178, 36, 36);
    add(keys, 30, "2", 757, 178, 36, 36);
    add(keys, 31, "3", 792, 178, 36, 36);
    // Keypad Enter: tall, spans this row and the one below (bottom row).
    add(keys, 67, "Enter", 827, 178, 36, 72);
    add(keys, 100, "Alt", 48, 214, 45, 36);
    add(keys, 102, "Amiga", 93, 214, 45, 36);
    add(keys, 64, "", 137, 214, 324, 36);
    add(keys, 103, "Amiga", 460, 214, 45, 36);
    add(keys, 101, "Alt", 505, 214, 45, 36);
    add(keys, 15, "0", 722, 214, 72, 36);
    add(keys, 60, ".", 792, 214, 36, 36);
}

// Layout: A500, ISO (international) -- vAmiga's A500ISO.xib, content view
// 883x270. The two ISO-only keys ("#" next to Return, "<" next to left
// Shift) each occupy a slot that the ANSI layout leaves for a neighboring
// key's notch or a wider neighbor -- so unlike the ANSI Return, this one is
// a plain rectangle.
void
AmigaKeyModel::buildA500Iso()
{
    add(keys, 69, "Esc", 20, 20, 36, 36);
    add(keys, 80, "F1", 74, 20, 45, 36);
    add(keys, 81, "F2", 119, 20, 45, 36);
    add(keys, 82, "F3", 164, 20, 45, 36);
    add(keys, 83, "F4", 209, 20, 45, 36);
    add(keys, 84, "F5", 254, 20, 45, 36);
    add(keys, 85, "F6", 317, 20, 45, 36);
    add(keys, 86, "F7", 362, 20, 45, 36);
    add(keys, 87, "F8", 407, 20, 45, 36);
    add(keys, 88, "F9", 452, 20, 45, 36);
    add(keys, 89, "F10", 497, 20, 45, 36);
    add(keys, 0, "`", 20, 70, 54, 36);
    add(keys, 1, "1", 74, 70, 36, 36);
    add(keys, 2, "2", 110, 70, 36, 36);
    add(keys, 3, "3", 146, 70, 36, 36);
    add(keys, 4, "4", 182, 70, 36, 36);
    add(keys, 5, "5", 218, 70, 36, 36);
    add(keys, 6, "6", 254, 70, 36, 36);
    add(keys, 7, "7", 290, 70, 36, 36);
    add(keys, 8, "8", 326, 70, 36, 36);
    add(keys, 9, "9", 362, 70, 36, 36);
    add(keys, 10, "0", 398, 70, 36, 36);
    add(keys, 11, "-", 434, 70, 36, 36);
    add(keys, 12, "=", 470, 70, 36, 36);
    add(keys, 13, "\\", 506, 70, 36, 36);
    add(keys, 65, "Backspace", 542, 70, 36, 36);
    add(keys, 70, "Del", 596, 70, 54, 36);
    add(keys, 95, "Help", 650, 70, 54, 36);
    add(keys, 90, "(", 722, 70, 36, 36);
    add(keys, 91, ")", 757, 70, 36, 36);
    add(keys, 92, "/", 792, 70, 36, 36);
    add(keys, 93, "*", 827, 70, 36, 36);
    add(keys, 66, "Tab", 20, 106, 72, 36);
    add(keys, 16, "Q", 92, 106, 36, 36);
    add(keys, 17, "W", 128, 106, 36, 36);
    add(keys, 18, "E", 164, 106, 36, 36);
    add(keys, 19, "R", 200, 106, 36, 36);
    add(keys, 20, "T", 236, 106, 36, 36);
    add(keys, 21, "Y", 272, 106, 36, 36);
    add(keys, 22, "U", 308, 106, 36, 36);
    add(keys, 23, "I", 344, 106, 36, 36);
    add(keys, 24, "O", 380, 106, 36, 36);
    add(keys, 25, "P", 416, 106, 36, 36);
    add(keys, 26, "[", 452, 106, 36, 36);
    add(keys, 27, "]", 488, 106, 36, 36);
    add(keys, 61, "7", 722, 106, 36, 36);
    add(keys, 62, "8", 757, 106, 36, 36);
    add(keys, 63, "9", 792, 106, 36, 36);
    add(keys, 74, "-", 827, 106, 36, 36);
    add(keys, 99, "Ctrl", 20, 142, 45, 36);
    add(keys, 98, "Caps\nLock", 65, 142, 36, 36);
    add(keys, 32, "A", 101, 142, 36, 36);
    add(keys, 33, "S", 137, 142, 36, 36);
    add(keys, 34, "D", 173, 142, 36, 36);
    add(keys, 35, "F", 209, 142, 36, 36);
    add(keys, 36, "G", 245, 142, 36, 36);
    add(keys, 37, "H", 281, 142, 36, 36);
    add(keys, 38, "J", 317, 142, 36, 36);
    add(keys, 39, "K", 353, 142, 36, 36);
    add(keys, 40, "L", 389, 142, 36, 36);
    add(keys, 41, ";", 425, 142, 36, 36);
    add(keys, 42, "'", 461, 142, 36, 36);
    add(keys, 43, "#", 497, 142, 36, 36);
    add(keys, 68, "Return", 524, 106, 54, 72);
    add(keys, 76, "Up", 632, 142, 36, 36);
    add(keys, 45, "4", 722, 142, 36, 36);
    add(keys, 46, "5", 757, 142, 36, 36);
    add(keys, 47, "6", 792, 142, 36, 36);
    add(keys, 94, "+", 827, 142, 36, 36);
    add(keys, 96, "Shift", 20, 178, 63, 36);
    add(keys, 48, "<", 83, 178, 36, 36);
    add(keys, 49, "Z", 119, 178, 36, 36);
    add(keys, 50, "X", 155, 178, 36, 36);
    add(keys, 51, "C", 191, 178, 36, 36);
    add(keys, 52, "V", 227, 178, 36, 36);
    add(keys, 53, "B", 263, 178, 36, 36);
    add(keys, 54, "N", 299, 178, 36, 36);
    add(keys, 55, "M", 335, 178, 36, 36);
    add(keys, 56, ",", 371, 178, 36, 36);
    add(keys, 57, ".", 407, 178, 36, 36);
    add(keys, 58, "/", 443, 178, 36, 36);
    add(keys, 97, "Shift", 479, 178, 99, 36);
    add(keys, 79, "Left", 596, 178, 36, 36);
    add(keys, 77, "Down", 632, 178, 36, 36);
    add(keys, 78, "Right", 668, 178, 36, 36);
    add(keys, 29, "1", 722, 178, 36, 36);
    add(keys, 30, "2", 757, 178, 36, 36);
    add(keys, 31, "3", 792, 178, 36, 36);
    add(keys, 100, "Alt", 48, 214, 45, 36);
    add(keys, 102, "Amiga", 93, 214, 45, 36);
    add(keys, 64, "", 137, 214, 324, 36);
    add(keys, 103, "Amiga", 460, 214, 45, 36);
    add(keys, 101, "Alt", 505, 214, 45, 36);
    add(keys, 15, "0", 722, 214, 72, 36);
    add(keys, 60, ".", 792, 214, 36, 36);
    add(keys, 67, "Enter", 827, 178, 36, 72);
}

// Layout: A1000, ANSI (US) -- vAmiga's A1000ANSI.xib, content view 758x256.
// The A1000's narrower keyboard has no separate numeric-keypad operator
// keys (no (, ), /, *, +) and arranges its cursor keys as a compact
// up/down/left/right diamond instead of A500's inline row -- both real
// differences from the A500, not omissions in this port. Return gets the
// same notch as the A500 ANSI layout (see buildA500Ansi()): its "]" key
// overlaps Return's top-left corner by exactly 27x36, the same way it does
// on the A500.
void
AmigaKeyModel::buildA1000Ansi()
{
    add(keys, 69, "Esc", 20, 20, 36, 36);
    add(keys, 80, "F1", 74, 20, 45, 36);
    add(keys, 81, "F2", 119, 20, 45, 36);
    add(keys, 82, "F3", 164, 20, 45, 36);
    add(keys, 83, "F4", 209, 20, 45, 36);
    add(keys, 84, "F5", 254, 20, 45, 36);
    add(keys, 85, "F6", 317, 20, 45, 36);
    add(keys, 86, "F7", 362, 20, 45, 36);
    add(keys, 87, "F8", 407, 20, 45, 36);
    add(keys, 88, "F9", 452, 20, 45, 36);
    add(keys, 89, "F10", 497, 20, 45, 36);
    add(keys, 70, "Del", 560, 20, 36, 36);
    add(keys, 0, "`", 20, 56, 45, 36);
    add(keys, 1, "1", 65, 56, 36, 36);
    add(keys, 2, "2", 101, 56, 36, 36);
    add(keys, 3, "3", 137, 56, 36, 36);
    add(keys, 4, "4", 173, 56, 36, 36);
    add(keys, 5, "5", 209, 56, 36, 36);
    add(keys, 6, "6", 245, 56, 36, 36);
    add(keys, 7, "7", 281, 56, 36, 36);
    add(keys, 8, "8", 317, 56, 36, 36);
    add(keys, 9, "9", 353, 56, 36, 36);
    add(keys, 10, "0", 389, 56, 36, 36);
    add(keys, 11, "-", 425, 56, 36, 36);
    add(keys, 12, "=", 461, 56, 36, 36);
    add(keys, 13, "\\", 497, 56, 36, 36);
    add(keys, 65, "Backspace", 533, 56, 63, 36);
    add(keys, 61, "7", 632, 56, 36, 36);
    add(keys, 62, "8", 667, 56, 36, 36);
    add(keys, 63, "9", 702, 56, 36, 36);
    add(keys, 66, "Tab", 20, 92, 63, 36);
    add(keys, 16, "Q", 83, 92, 36, 36);
    add(keys, 17, "W", 119, 92, 36, 36);
    add(keys, 18, "E", 155, 92, 36, 36);
    add(keys, 19, "R", 191, 92, 36, 36);
    add(keys, 20, "T", 227, 92, 36, 36);
    add(keys, 21, "Y", 263, 92, 36, 36);
    add(keys, 22, "U", 299, 92, 36, 36);
    add(keys, 23, "I", 335, 92, 36, 36);
    add(keys, 24, "O", 371, 92, 36, 36);
    add(keys, 25, "P", 407, 92, 36, 36);
    add(keys, 26, "[", 443, 92, 36, 36);
    add(keys, 27, "]", 479, 92, 36, 36);
    add(keys, 95, "Help", 560, 92, 36, 36);
    add(keys, 45, "4", 632, 92, 36, 36);
    add(keys, 46, "5", 667, 92, 36, 36);
    add(keys, 47, "6", 702, 92, 36, 36);
    add(keys, 99, "Ctrl", 20, 128, 36, 36);
    add(keys, 98, "Caps\nLock", 56, 128, 36, 36);
    add(keys, 32, "A", 92, 128, 36, 36);
    add(keys, 33, "S", 128, 128, 36, 36);
    add(keys, 34, "D", 164, 128, 36, 36);
    add(keys, 35, "F", 200, 128, 36, 36);
    add(keys, 36, "G", 236, 128, 36, 36);
    add(keys, 37, "H", 272, 128, 36, 36);
    add(keys, 38, "J", 308, 128, 36, 36);
    add(keys, 39, "K", 344, 128, 36, 36);
    add(keys, 40, "L", 380, 128, 36, 36);
    add(keys, 41, ";", 416, 128, 36, 36);
    add(keys, 42, "'", 452, 128, 36, 36);
    add(keys, 68, "Return", 488, 92, 72, 72, /* notchWidth */ 27, /* notchHeight */ 36);
    add(keys, 76, "Up", 560, 128, 36, 36);
    add(keys, 29, "1", 632, 128, 36, 36);
    add(keys, 30, "2", 667, 128, 36, 36);
    add(keys, 31, "3", 702, 128, 36, 36);
    add(keys, 96, "Shift", 20, 164, 90, 36);
    add(keys, 49, "Z", 110, 164, 36, 36);
    add(keys, 50, "X", 146, 164, 36, 36);
    add(keys, 51, "C", 182, 164, 36, 36);
    add(keys, 52, "V", 218, 164, 36, 36);
    add(keys, 53, "B", 254, 164, 36, 36);
    add(keys, 54, "N", 290, 164, 36, 36);
    add(keys, 55, "M", 326, 164, 36, 36);
    add(keys, 56, ",", 362, 164, 36, 36);
    add(keys, 57, ".", 398, 164, 36, 36);
    add(keys, 58, "/", 434, 164, 36, 36);
    add(keys, 97, "Shift", 470, 164, 72, 36);
    add(keys, 79, "Left", 542, 164, 36, 36);
    add(keys, 78, "Right", 578, 164, 36, 36);
    add(keys, 15, "0", 632, 164, 72, 36);
    add(keys, 60, ".", 702, 164, 36, 36);
    add(keys, 100, "Alt", 65, 200, 45, 36);
    add(keys, 102, "Amiga", 110, 200, 45, 36);
    add(keys, 64, "", 155, 200, 270, 36);
    add(keys, 103, "Amiga", 425, 200, 45, 36);
    add(keys, 101, "Alt", 470, 200, 45, 36);
    add(keys, 77, "Down", 560, 200, 36, 36);
    add(keys, 74, "-", 632, 200, 36, 36);
    add(keys, 67, "Enter", 666, 200, 72, 36);
}

// Layout: A1000, ISO (international) -- vAmiga's A1000ISO.xib, content view
// 758x256. Same physical differences from A500 as buildA1000Ansi(); the
// single ISO-only key here ("<" next to left Shift) doesn't touch Return at
// all, so it keeps the same notch as buildA1000Ansi() (the "]" key still
// overlaps its top-left corner the same way).
void
AmigaKeyModel::buildA1000Iso()
{
    add(keys, 69, "Esc", 20, 20, 36, 36);
    add(keys, 80, "F1", 74, 20, 45, 36);
    add(keys, 81, "F2", 119, 20, 45, 36);
    add(keys, 82, "F3", 164, 20, 45, 36);
    add(keys, 83, "F4", 209, 20, 45, 36);
    add(keys, 84, "F5", 254, 20, 45, 36);
    add(keys, 85, "F6", 317, 20, 45, 36);
    add(keys, 86, "F7", 362, 20, 45, 36);
    add(keys, 87, "F8", 407, 20, 45, 36);
    add(keys, 88, "F9", 452, 20, 45, 36);
    add(keys, 89, "F10", 497, 20, 45, 36);
    add(keys, 70, "Del", 560, 20, 36, 36);
    add(keys, 0, "`", 20, 56, 45, 36);
    add(keys, 1, "1", 65, 56, 36, 36);
    add(keys, 2, "2", 101, 56, 36, 36);
    add(keys, 3, "3", 137, 56, 36, 36);
    add(keys, 4, "4", 173, 56, 36, 36);
    add(keys, 5, "5", 209, 56, 36, 36);
    add(keys, 6, "6", 245, 56, 36, 36);
    add(keys, 7, "7", 281, 56, 36, 36);
    add(keys, 8, "8", 317, 56, 36, 36);
    add(keys, 9, "9", 353, 56, 36, 36);
    add(keys, 10, "0", 389, 56, 36, 36);
    add(keys, 11, "-", 425, 56, 36, 36);
    add(keys, 12, "=", 461, 56, 36, 36);
    add(keys, 13, "\\", 497, 56, 36, 36);
    add(keys, 65, "Backspace", 533, 56, 63, 36);
    add(keys, 61, "7", 632, 56, 36, 36);
    add(keys, 62, "8", 667, 56, 36, 36);
    add(keys, 63, "9", 702, 56, 36, 36);
    add(keys, 66, "Tab", 20, 92, 63, 36);
    add(keys, 16, "Q", 83, 92, 36, 36);
    add(keys, 17, "W", 119, 92, 36, 36);
    add(keys, 18, "E", 155, 92, 36, 36);
    add(keys, 19, "R", 191, 92, 36, 36);
    add(keys, 20, "T", 227, 92, 36, 36);
    add(keys, 21, "Y", 263, 92, 36, 36);
    add(keys, 22, "U", 299, 92, 36, 36);
    add(keys, 23, "I", 335, 92, 36, 36);
    add(keys, 24, "O", 371, 92, 36, 36);
    add(keys, 25, "P", 407, 92, 36, 36);
    add(keys, 26, "[", 443, 92, 36, 36);
    add(keys, 27, "]", 479, 92, 36, 36);
    add(keys, 95, "Help", 560, 92, 36, 36);
    add(keys, 45, "4", 632, 92, 36, 36);
    add(keys, 46, "5", 667, 92, 36, 36);
    add(keys, 47, "6", 702, 92, 36, 36);
    add(keys, 99, "Ctrl", 20, 128, 36, 36);
    add(keys, 98, "Caps\nLock", 56, 128, 36, 36);
    add(keys, 32, "A", 92, 128, 36, 36);
    add(keys, 33, "S", 128, 128, 36, 36);
    add(keys, 34, "D", 164, 128, 36, 36);
    add(keys, 35, "F", 200, 128, 36, 36);
    add(keys, 36, "G", 236, 128, 36, 36);
    add(keys, 37, "H", 272, 128, 36, 36);
    add(keys, 38, "J", 308, 128, 36, 36);
    add(keys, 39, "K", 344, 128, 36, 36);
    add(keys, 40, "L", 380, 128, 36, 36);
    add(keys, 41, ";", 416, 128, 36, 36);
    add(keys, 42, "'", 452, 128, 36, 36);
    add(keys, 68, "Return", 488, 92, 72, 72, /* notchWidth */ 27, /* notchHeight */ 36);
    add(keys, 76, "Up", 560, 128, 36, 36);
    add(keys, 29, "1", 632, 128, 36, 36);
    add(keys, 30, "2", 667, 128, 36, 36);
    add(keys, 31, "3", 702, 128, 36, 36);
    add(keys, 96, "Shift", 20, 164, 54, 36);
    add(keys, 48, "<", 74, 164, 36, 36);
    add(keys, 49, "Z", 110, 164, 36, 36);
    add(keys, 50, "X", 146, 164, 36, 36);
    add(keys, 51, "C", 182, 164, 36, 36);
    add(keys, 52, "V", 218, 164, 36, 36);
    add(keys, 53, "B", 254, 164, 36, 36);
    add(keys, 54, "N", 290, 164, 36, 36);
    add(keys, 55, "M", 326, 164, 36, 36);
    add(keys, 56, ",", 362, 164, 36, 36);
    add(keys, 57, ".", 398, 164, 36, 36);
    add(keys, 58, "/", 434, 164, 36, 36);
    add(keys, 97, "Shift", 470, 164, 72, 36);
    add(keys, 79, "Left", 542, 164, 36, 36);
    add(keys, 78, "Right", 578, 164, 36, 36);
    add(keys, 15, "0", 632, 164, 72, 36);
    add(keys, 60, ".", 702, 164, 36, 36);
    add(keys, 100, "Alt", 65, 200, 45, 36);
    add(keys, 102, "Amiga", 110, 200, 45, 36);
    add(keys, 64, "", 155, 200, 270, 36);
    add(keys, 103, "Amiga", 425, 200, 45, 36);
    add(keys, 101, "Alt", 470, 200, 45, 36);
    add(keys, 77, "Down", 560, 200, 36, 36);
    add(keys, 74, "-", 632, 200, 36, 36);
    add(keys, 67, "Enter", 666, 200, 72, 36);
}
