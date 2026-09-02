// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "AmigaKeyModel.h"

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
        case XRole:           return key.x;
        case YRole:           return key.y;
        case WidthRole:       return key.width;
        case HeightRole:      return key.height;
        case NotchWidthRole:  return key.notchWidth;
        case NotchHeightRole: return key.notchHeight;
        default:              return {};
    }
}

void
AmigaKeyModel::build()
{
    // Position/size in pixels, taken directly from vAmiga's own
    // A500ANSI.xib (its Mac virtual-keyboard layout), with the y axis
    // flipped once here (Cocoa's frames are bottom-up; QML is top-down) so
    // everything downstream just works in ordinary top-down coordinates.
    // 'nr' is the exact keycode the XIB wires each button to (its "tag",
    // fed straight to KeyboardAPI::press/release on the real app) -- these
    // are the raw Amiga hardware scancodes, not something invented for
    // this port.
    auto add = [&](int nr, const char *label, qreal x, qreal y, qreal w, qreal h,
                   qreal notchW = 0, qreal notchH = 0) {

        keys.append({ nr, QString::fromUtf8(label), x, y, w, h, notchW, notchH });
    };

    // Row: Esc, F1-F10
    add(69, "Esc", 20, 20, 36, 36);
    add(80, "F1", 74, 20, 45, 36);
    add(81, "F2", 119, 20, 45, 36);
    add(82, "F3", 164, 20, 45, 36);
    add(83, "F4", 209, 20, 45, 36);
    add(84, "F5", 254, 20, 45, 36);
    add(85, "F6", 317, 20, 45, 36);
    add(86, "F7", 362, 20, 45, 36);
    add(87, "F8", 407, 20, 45, 36);
    add(88, "F9", 452, 20, 45, 36);
    add(89, "F10", 497, 20, 45, 36);

    // Row: ` 1-0 - = Backspace, plus Help and the keypad's own top row
    add(1, "`", 74, 70, 36, 36);
    add(2, "1", 110, 70, 36, 36);
    add(3, "2", 146, 70, 36, 36);
    add(4, "3", 182, 70, 36, 36);
    add(5, "4", 218, 70, 36, 36);
    add(6, "5", 254, 70, 36, 36);
    add(7, "6", 290, 70, 36, 36);
    add(8, "7", 326, 70, 36, 36);
    add(9, "8", 362, 70, 36, 36);
    add(10, "9", 398, 70, 36, 36);
    add(11, "0", 434, 70, 36, 36);
    add(12, "-", 470, 70, 36, 36);
    add(13, "=", 506, 70, 36, 36);
    add(65, "Backspace", 542, 70, 36, 36);
    add(70, "Help", 596, 70, 54, 36);
    add(95, "", 650, 70, 54, 36);
    add(90, "(", 722, 70, 36, 36);
    add(91, ")", 757, 70, 36, 36);
    add(92, "/", 792, 70, 36, 36);
    add(93, "*", 827, 70, 36, 36);

    // Row: Tab, Q-P, [ ], keypad 7-9 -
    add(66, "Tab", 20, 106, 72, 36);
    add(16, "Q", 92, 106, 36, 36);
    add(17, "W", 128, 106, 36, 36);
    add(18, "E", 164, 106, 36, 36);
    add(19, "R", 200, 106, 36, 36);
    add(20, "T", 236, 106, 36, 36);
    add(21, "Y", 272, 106, 36, 36);
    add(22, "U", 308, 106, 36, 36);
    add(23, "I", 344, 106, 36, 36);
    add(24, "O", 380, 106, 36, 36);
    add(25, "P", 416, 106, 36, 36);
    add(26, "[", 452, 106, 36, 36);
    add(27, "]", 488, 106, 36, 36);
    add(61, "7", 722, 106, 36, 36);
    add(62, "8", 757, 106, 36, 36);
    add(63, "9", 792, 106, 36, 36);
    add(74, "-", 827, 106, 36, 36);

    // Row: Ctrl, Caps Lock, A-L, ; ', Return (bottom of the L), Up, keypad 4-6 +
    add(99, "Ctrl", 20, 142, 45, 36);
    add(98, "Caps\nLock", 65, 142, 36, 36);
    add(32, "A", 101, 142, 36, 36);
    add(33, "S", 137, 142, 36, 36);
    add(34, "D", 173, 142, 36, 36);
    add(35, "F", 209, 142, 36, 36);
    add(36, "G", 245, 142, 36, 36);
    add(37, "H", 281, 142, 36, 36);
    add(38, "J", 317, 142, 36, 36);
    add(39, "K", 353, 142, 36, 36);
    add(40, "L", 389, 142, 36, 36);
    add(41, ";", 425, 142, 36, 36);
    add(42, "'", 461, 142, 36, 36);
    // Return: bounding box spans this row and the one above it (Q-P/[]).
    // Real hardware cuts the top-left corner away, leaving a wide bottom
    // (aligned with this row) and a narrower, right-aligned top (aligned
    // with the row above) -- see AmigaKeyModel.h and SiAmKeyboardPanel.qml
    // for how notchWidth/notchHeight turn into that shape.
    add(68, "Return", 497, 106, 81, 72, /* notchWidth */ 27, /* notchHeight */ 36);
    add(76, "Up", 632, 142, 36, 36);
    add(45, "4", 722, 142, 36, 36);
    add(46, "5", 757, 142, 36, 36);
    add(47, "6", 792, 142, 36, 36);
    add(94, "+", 827, 142, 36, 36);

    // Row: Shift, Z-M, , . /, Shift, Left/Down/Right, keypad 1-3
    add(96, "Shift", 20, 178, 99, 36);
    add(49, "Z", 119, 178, 36, 36);
    add(50, "X", 155, 178, 36, 36);
    add(51, "C", 191, 178, 36, 36);
    add(52, "V", 227, 178, 36, 36);
    add(53, "B", 263, 178, 36, 36);
    add(54, "N", 299, 178, 36, 36);
    add(55, "M", 335, 178, 36, 36);
    add(56, ",", 371, 178, 36, 36);
    add(57, ".", 407, 178, 36, 36);
    add(58, "/", 443, 178, 36, 36);
    add(97, "Shift", 479, 178, 99, 36);
    add(79, "Left", 596, 178, 36, 36);
    add(77, "Down", 632, 178, 36, 36);
    add(78, "Right", 668, 178, 36, 36);
    add(29, "1", 722, 178, 36, 36);
    add(30, "2", 757, 178, 36, 36);
    add(31, "3", 792, 178, 36, 36);
    // Keypad Enter: tall, spans this row and the one below (bottom row).
    add(67, "Enter", 827, 178, 36, 72);

    // Bottom row: Alt, Amiga, Space, Amiga, Alt, Del, keypad 0
    add(100, "Alt", 48, 214, 45, 36);
    add(102, "Amiga", 93, 214, 45, 36);
    add(64, "", 137, 214, 324, 36);
    add(103, "Amiga", 460, 214, 45, 36);
    add(101, "Alt", 505, 214, 45, 36);
    add(15, "Del", 722, 214, 72, 36);
    add(60, "0", 792, 214, 36, 36);
}
