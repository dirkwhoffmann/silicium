// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#include "C64KeyModel.h"

namespace {

// A physical key position on the C64 keyboard matrix: nr matches the C64 key
// numbering used elsewhere in this app (0..65); row/col match the physical
// keyboard matrix, or -1/-1 for RESTORE and SHIFT LOCK, which have no matrix
// representation. Hard-coded here (rather than depending on VCCore's C64Key)
// to keep this model free of a dependency on the emulator core.
struct Key { int nr, row, col; };

constexpr Key del           {15, 0, 0};
constexpr Key ret           {47, 0, 1};
constexpr Key curLeftRight  {63, 0, 2};
constexpr Key F7F8          {64, 0, 3};
constexpr Key F1F2          {16, 0, 4};
constexpr Key F3F4          {32, 0, 5};
constexpr Key F5F6          {48, 0, 6};
constexpr Key curUpDown     {62, 0, 7};

constexpr Key digit3        {3,  1, 0};
constexpr Key W             {19, 1, 1};
constexpr Key A             {35, 1, 2};
constexpr Key digit4        {4,  1, 3};
constexpr Key Z             {51, 1, 4};
constexpr Key S             {36, 1, 5};
constexpr Key E             {20, 1, 6};
constexpr Key leftShift     {50, 1, 7};

constexpr Key digit5        {5,  2, 0};
constexpr Key R             {21, 2, 1};
constexpr Key D             {37, 2, 2};
constexpr Key digit6        {6,  2, 3};
constexpr Key C             {53, 2, 4};
constexpr Key F             {38, 2, 5};
constexpr Key T             {22, 2, 6};
constexpr Key X             {52, 2, 7};

constexpr Key digit7        {7,  3, 0};
constexpr Key Y             {23, 3, 1};
constexpr Key G             {39, 3, 2};
constexpr Key digit8        {8,  3, 3};
constexpr Key B             {55, 3, 4};
constexpr Key H             {40, 3, 5};
constexpr Key U             {24, 3, 6};
constexpr Key V             {54, 3, 7};

constexpr Key digit9        {9,  4, 0};
constexpr Key I             {25, 4, 1};
constexpr Key J             {41, 4, 2};
constexpr Key digit0        {10, 4, 3};
constexpr Key M             {57, 4, 4};
constexpr Key K             {42, 4, 5};
constexpr Key O             {26, 4, 6};
constexpr Key N             {56, 4, 7};

constexpr Key plus          {11, 5, 0};
constexpr Key P             {27, 5, 1};
constexpr Key L             {43, 5, 2};
constexpr Key minus         {12, 5, 3};
constexpr Key period        {59, 5, 4};
constexpr Key colon         {44, 5, 5};
constexpr Key at            {28, 5, 6};
constexpr Key comma         {58, 5, 7};

constexpr Key pound         {13, 6, 0};
constexpr Key asterisk      {29, 6, 1};
constexpr Key semicolon     {45, 6, 2};
constexpr Key home          {14, 6, 3};
constexpr Key rightShift    {61, 6, 4};
constexpr Key equal         {46, 6, 5};
constexpr Key upArrow       {30, 6, 6};
constexpr Key slash         {60, 6, 7};

constexpr Key digit1        {1,  7, 0};
constexpr Key leftArrow     {0,  7, 1};
constexpr Key control       {17, 7, 2};
constexpr Key digit2        {2,  7, 3};
constexpr Key space         {65, 7, 4};
constexpr Key commodore     {49, 7, 5};
constexpr Key Q             {18, 7, 6};
constexpr Key runStop       {33, 7, 7};

// Not part of the keyboard matrix
constexpr Key restore       {31, -1, -1};
constexpr Key shiftLock     {34, -1, -1};

// Appends a single key to the model. Coordinates are given in grid units;
// one unit roughly matches the width of a standard alphanumeric key.
void addKey(QVector<C64KeyInfo> &keys, const Key &key, const QHash<int, C64KeyLabel> &labels,
            qreal x, qreal y, qreal width = 1.0, qreal height = 1.0)
{
    C64KeyInfo info;

    info.nr = key.nr;
    info.row = key.row;
    info.col = key.col;
    info.labels = labels;
    info.x = x;
    info.y = y;
    info.width = width;
    info.height = height;

    keys.append(info);
}

}

C64KeyModel::C64KeyModel(QObject *parent) : QAbstractListModel(parent)
{
    build();
}

int
C64KeyModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return keys.size();
}

QHash<int, QByteArray>
C64KeyModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[NrRole]          = "nr";
    roles[RowRole]         = "row";
    roles[ColRole]         = "col";
    roles[LabelRole]       = "label";
    roles[SpecialFontRole] = "specialFont";
    roles[XRole]           = "x";
    roles[YRole]           = "y";
    roles[WidthRole]       = "width";
    roles[HeightRole]      = "height";

    return roles;
}

QVariant
C64KeyModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= keys.size()) return {};

    const auto &key = keys[index.row()];

    switch (role) {

        case NrRole:          return key.nr;
        case RowRole:         return key.row;
        case ColRole:         return key.col;
        case LabelRole:       return resolveLabel(key).text;
        case SpecialFontRole: return resolveLabel(key).special;
        case XRole:           return key.x;
        case YRole:           return key.y;
        case WidthRole:       return key.width;
        case HeightRole:      return key.height;
        default:              return {};
    }
}

void
C64KeyModel::setShiftPressed(bool value) { setModifier(Shift, value); }

void
C64KeyModel::setCommodorePressed(bool value) { setModifier(Commodore, value); }

void
C64KeyModel::setControlPressed(bool value) { setModifier(Control, value); }

void
C64KeyModel::setLowercase(bool value) { setModifier(Lowercase, value); }

void
C64KeyModel::setModifier(Modifier flag, bool value)
{
    int newModifiers = value ? (m_modifiers | flag) : (m_modifiers & ~flag);

    if (newModifiers != m_modifiers) {

        m_modifiers = newModifiers;
        emit modifiersChanged();

        if (!keys.isEmpty()) {
            emit dataChanged(index(0, 0), index(keys.size() - 1, 0), { LabelRole, SpecialFontRole });
        }
    }
}

const C64KeyLabel &
C64KeyModel::resolveLabel(const C64KeyInfo &key) const
{
    // Search for a perfect match for the active modifier combination
    if (auto it = key.labels.constFind(m_modifiers); it != key.labels.constEnd()) return it.value();

    // Otherwise fall back to the most specific single modifier that applies,
    // in the same priority order used by the original VirtualC64 keycap lookup
    if (m_modifiers & Commodore) {
        if (auto it = key.labels.constFind(Commodore); it != key.labels.constEnd()) return it.value();
    }
    if (m_modifiers & Lowercase) {
        if (auto it = key.labels.constFind(Lowercase); it != key.labels.constEnd()) return it.value();
    }
    if (m_modifiers & Shift) {
        if (auto it = key.labels.constFind(Shift); it != key.labels.constEnd()) return it.value();
    }
    if (m_modifiers & Control) {
        if (auto it = key.labels.constFind(Control); it != key.labels.constEnd()) return it.value();
    }

    // Generic, unmodified label
    if (auto it = key.labels.constFind(None); it != key.labels.constEnd()) return it.value();

    // No label at all for this key
    static const C64KeyLabel empty {};
    return empty;
}

void
C64KeyModel::build()
{
    beginResetModel();

    keys.clear();

    // Label variants are ported from the keycap table in the Swift-based
    // VirtualC64 GUI (C64Key.swift). A label's 'special' flag is set if and
    // only if the corresponding Swift Keycap() call passed font: "C64";
    // those glyphs (PETSCII / box / block / card-suit characters) only exist
    // in the bundled C64 Pro Mono font, while everything else uses the
    // regular UI font. Non-ASCII code points are written as \uXXXX escapes
    // rather than pasted literally, mirroring the \u{XXXX} style used in the
    // Swift source.

    //
    // Row 0
    //

    addKey(keys, leftArrow, {{None, {"\u2190"}}}, 0.5, 0);
    addKey(keys, digit1,    {{None, {"1"}}, {Shift, {"!"}}, {Commodore, {"ORG"}}, {Control, {"BLK"}}},          1.5, 0);
    addKey(keys, digit2,    {{None, {"2"}}, {Shift, {"\""}}, {Commodore, {"BRN"}}, {Control, {"WHT"}}},         2.5, 0);
    addKey(keys, digit3,    {{None, {"3"}}, {Shift, {"#"}}, {Commodore, {"PNK"}}, {Control, {"RED"}}},          3.5, 0);
    addKey(keys, digit4,    {{None, {"4"}}, {Shift, {"$"}}, {Commodore, {"DARK\nGRY"}}, {Control, {"CYN"}}},    4.5, 0);
    addKey(keys, digit5,    {{None, {"5"}}, {Shift, {"%%"}}, {Commodore, {"GRY"}}, {Control, {"PUR"}}},         5.5, 0);
    addKey(keys, digit6,    {{None, {"6"}}, {Shift, {"&"}}, {Commodore, {"LIGHT\nGRN"}}, {Control, {"GRN"}}},  6.5, 0);
    addKey(keys, digit7,    {{None, {"7"}}, {Shift, {"'"}}, {Commodore, {"LIGHT\nBLU"}}, {Control, {"BLU"}}},  7.5, 0);
    addKey(keys, digit8,    {{None, {"8"}}, {Shift, {"("}}, {Commodore, {"LIGHT\nGRY"}}, {Control, {"YEL"}}},  8.5, 0);
    addKey(keys, digit9,    {{None, {"9"}}, {Shift, {")"}}, {Commodore, {")"}}, {Control, {"RVS\nON"}}},       9.5, 0);
    addKey(keys, digit0,    {{None, {"0"}}, {Control, {"RVS\nOFF"}}},                                        10.5, 0);
    addKey(keys, plus,      {{None, {"+"}}, {Shift, {"\u253C", true}}, {Commodore, {"\u2592", true}}},        11.5, 0);
    addKey(keys, minus,     {{None, {"-"}}, {Shift, {"\u2502", true}}, {Commodore, {"\uE0DC", true}}},        12.5, 0);
    addKey(keys, pound,     {{None, {"\u00A3"}}, {Shift, {"\u25E4", true}}, {Shift | Lowercase, {"\uE1E9", true}}, {Commodore, {"\uE0A8", true}}}, 13.5, 0);
    addKey(keys, home,      {{None, {"HOME"}}, {Shift, {"CLR"}}},                                             14.5, 0);
    addKey(keys, del,       {{None, {"DEL"}}, {Shift, {"INST"}}},                                             15.5, 0);

    addKey(keys, F1F2, {{None, {"F1"}}, {Shift, {"F2"}}}, 17.5, 0, 2.0);

    //
    // Row 1
    //

    addKey(keys, control,  {{None, {"CTRL"}}}, 0.5,  1, 1.5);
    addKey(keys, Q,        {{None, {"Q"}}, {Shift, {"\u2022", true}}, {Lowercase, {"q"}}, {Shift | Lowercase, {"Q"}}, {Commodore, {"\u251C", true}}}, 2.0,  1);
    addKey(keys, W,        {{None, {"W"}}, {Shift, {"\u25CB", true}}, {Lowercase, {"w"}}, {Shift | Lowercase, {"W"}}, {Commodore, {"\u2524", true}}}, 3.0,  1);
    addKey(keys, E,        {{None, {"E"}}, {Shift, {"\uE0C5", true}}, {Lowercase, {"e"}}, {Shift | Lowercase, {"E"}}, {Commodore, {"\u2534", true}}}, 4.0,  1);
    addKey(keys, R,        {{None, {"R"}}, {Shift, {"\uE072", true}}, {Lowercase, {"r"}}, {Shift | Lowercase, {"R"}}, {Commodore, {"\u252C", true}}}, 5.0,  1);
    addKey(keys, T,        {{None, {"T"}}, {Shift, {"\uE0D4", true}}, {Lowercase, {"t"}}, {Shift | Lowercase, {"T"}}, {Commodore, {"\u2594", true}}}, 6.0,  1);
    addKey(keys, Y,        {{None, {"Y"}}, {Shift, {"\uE0D9", true}}, {Lowercase, {"y"}}, {Shift | Lowercase, {"Y"}}, {Commodore, {"\uE0B7", true}}}, 7.0,  1);
    addKey(keys, U,        {{None, {"U"}}, {Shift, {"\u256D", true}}, {Lowercase, {"u"}}, {Shift | Lowercase, {"U"}}, {Commodore, {"\uE0B8", true}}}, 8.0,  1);
    addKey(keys, I,        {{None, {"I"}}, {Shift, {"\u256E", true}}, {Lowercase, {"i"}}, {Shift | Lowercase, {"I"}}, {Commodore, {"\u2584", true}}}, 9.0,  1);
    addKey(keys, O,        {{None, {"O"}}, {Shift, {"\uE0CF", true}}, {Lowercase, {"o"}}, {Shift | Lowercase, {"O"}}, {Commodore, {"\u2583", true}}}, 10.0, 1);
    addKey(keys, P,        {{None, {"P"}}, {Shift, {"\uE0D0", true}}, {Lowercase, {"p"}}, {Shift | Lowercase, {"P"}}, {Commodore, {"\u2582", true}}}, 11.0, 1);
    addKey(keys, at,       {{None, {"@"}}, {Shift, {"\uE0BA", true}}, {Shift | Lowercase, {"\uE1FA", true}}, {Commodore, {"\u2581", true}}}, 12.0, 1);
    addKey(keys, asterisk, {{None, {"*"}}, {Shift, {"\u2500", true}}, {Commodore, {"\u25E5", true}}, {Commodore | Lowercase, {"\uE17F", true}}}, 13.0, 1);
    addKey(keys, upArrow,  {{None, {"\u2191"}}, {Shift, {"\u03C0"}}, {Commodore, {"\u03C0"}}, {Lowercase, {"\uE1DE", true}}}, 14.0, 1);
    addKey(keys, restore,  {{None, {"RESTORE"}}}, 15.0, 1, 1.5);

    addKey(keys, F3F4, {{None, {"F3"}}, {Shift, {"F4"}}}, 17.5, 1, 2.0);

    //
    // Row 2
    //

    addKey(keys, runStop,   {{None, {"RUN\nSTOP"}}},     0,  2);
    addKey(keys, shiftLock, {{None, {"SHIFT\nLOCK"}}},   1,  2);
    addKey(keys, A,         {{None, {"A"}}, {Shift, {"\u2660", true}}, {Lowercase, {"a"}}, {Shift | Lowercase, {"A"}}, {Commodore, {"\u250C", true}}}, 2,  2);
    addKey(keys, S,         {{None, {"S"}}, {Shift, {"\u2665", true}}, {Lowercase, {"s"}}, {Shift | Lowercase, {"S"}}, {Commodore, {"\u2510", true}}}, 3,  2);
    addKey(keys, D,         {{None, {"D"}}, {Shift, {"\uE064", true}}, {Lowercase, {"d"}}, {Shift | Lowercase, {"D"}}, {Commodore, {"\u2597", true}}}, 4,  2);
    addKey(keys, F,         {{None, {"F"}}, {Shift, {"\uE0C6", true}}, {Lowercase, {"f"}}, {Shift | Lowercase, {"F"}}, {Commodore, {"\u2596", true}}}, 5,  2);
    addKey(keys, G,         {{None, {"G"}}, {Shift, {"\uE0C7", true}}, {Lowercase, {"g"}}, {Shift | Lowercase, {"G"}}, {Commodore, {"\u258E", true}}}, 6,  2);
    addKey(keys, H,         {{None, {"H"}}, {Shift, {"\uE0C8", true}}, {Lowercase, {"h"}}, {Shift | Lowercase, {"H"}}, {Commodore, {"\u258E", true}}}, 7,  2);
    addKey(keys, J,         {{None, {"J"}}, {Shift, {"\u2570", true}}, {Lowercase, {"j"}}, {Shift | Lowercase, {"J"}}, {Commodore, {"\u258D", true}}}, 8,  2);
    addKey(keys, K,         {{None, {"K"}}, {Shift, {"\u256F", true}}, {Lowercase, {"k"}}, {Shift | Lowercase, {"K"}}, {Commodore, {"\u258C", true}}}, 9,  2);
    addKey(keys, L,         {{None, {"L"}}, {Shift, {"\uE0CC", true}}, {Lowercase, {"l"}}, {Shift | Lowercase, {"L"}}, {Commodore, {"\uE0B6", true}}}, 10, 2);
    addKey(keys, colon,     {{None, {":"}}, {Shift, {"["}}, {Commodore, {"["}}},                                                                       11, 2);
    addKey(keys, semicolon, {{None, {";"}}, {Shift, {"]"}}, {Commodore, {"]"}}},                                                                       12, 2);
    addKey(keys, equal,     {{None, {"="}}},                                                                                                           13, 2);
    addKey(keys, ret,       {{None, {"RETURN"}}},                                                                                                      14, 2, 2.0);

    addKey(keys, F5F6, {{None, {"F5"}}, {Shift, {"F6"}}}, 17.5, 2, 2.0);

    //
    // Row 3
    //

    addKey(keys, commodore,    {{None, {"C="}}},    0,    3);
    addKey(keys, leftShift,    {{None, {"SHIFT"}}}, 1,    3, 1.5);
    addKey(keys, Z,            {{None, {"Z"}}, {Shift, {"\u2666", true}}, {Lowercase, {"z"}}, {Shift | Lowercase, {"Z"}}, {Commodore, {"\u2514", true}}}, 2.5,  3);
    addKey(keys, X,            {{None, {"X"}}, {Shift, {"\u2663", true}}, {Lowercase, {"x"}}, {Shift | Lowercase, {"X"}}, {Commodore, {"\u2518", true}}}, 3.5,  3);
    addKey(keys, C,            {{None, {"C"}}, {Shift, {"\u2500", true}}, {Lowercase, {"c"}}, {Shift | Lowercase, {"C"}}, {Commodore, {"\u259D", true}}}, 4.5,  3);
    addKey(keys, V,            {{None, {"V"}}, {Shift, {"\u2573", true}}, {Lowercase, {"v"}}, {Shift | Lowercase, {"V"}}, {Commodore, {"\u2598", true}}}, 5.5,  3);
    addKey(keys, B,            {{None, {"B"}}, {Shift, {"\u2502", true}}, {Lowercase, {"b"}}, {Shift | Lowercase, {"B"}}, {Commodore, {"\u259A", true}}}, 6.5,  3);
    addKey(keys, N,            {{None, {"N"}}, {Shift, {"\u2571", true}}, {Lowercase, {"n"}}, {Shift | Lowercase, {"N"}}, {Commodore, {"\uE0AA", true}}}, 7.5,  3);
    addKey(keys, M,            {{None, {"M"}}, {Shift, {"\u2572", true}}, {Lowercase, {"m"}}, {Shift | Lowercase, {"M"}}, {Commodore, {"\uE0A7", true}}}, 8.5,  3);
    addKey(keys, comma,        {{None, {","}}, {Shift, {"<"}}, {Commodore, {"<"}}},                                                                       9.5,  3);
    addKey(keys, period,       {{None, {"."}}, {Shift, {">"}}, {Commodore, {">"}}},                                                                      10.5,  3);
    addKey(keys, slash,        {{None, {"/"}}, {Shift, {"?"}}, {Commodore, {"?"}}},                                                                      11.5,  3);
    addKey(keys, rightShift,   {{None, {"SHIFT"}}},                                                                                                      12.5,  3, 1.5);
    addKey(keys, curUpDown,    {{None, {"\u21E9"}}, {Shift, {"\u21E7"}}},                                                                                 14,   3);
    addKey(keys, curLeftRight, {{None, {"\u21E8"}}, {Shift, {"\u21E6"}}},                                                                                 15,   3);

    addKey(keys, F7F8, {{None, {"F7"}}, {Shift, {"F8"}}}, 17.5, 3, 2.0);

    //
    // Row 4
    //

    addKey(keys, space, {{None, {"SPACE"}}}, 3, 4, 8.5);

    endResetModel();
}
