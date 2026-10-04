// -----------------------------------------------------------------------------
// This file is part of Silicium UI
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Sulfur

Button {

    id: root

    property bool accented: false
    property bool accentedUp: accented || checked
    property bool accentedDown: accented

    property int size: Size.regular

    // Optional icon (first non-empty wins). An icon replaces the text and
    // makes the button square-ish instead of at least 80 points wide.
    property string symbol: ""
    property string phosphor: ""
    property string awesome: ""
    property real iconRotation: 0
    // Tooltip text. Icon-only buttons default to the button's text (e.g. the action's).
    property string tooltip: hasIcon ? text : ""
    readonly property bool hasIcon: symbol !== "" || phosphor !== "" || awesome !== ""

    property color bgUpColor: accentedUp ? Palette.accent : Palette.widget
    property color bgDownColor: accentedDown ? Palette.accentElevated : Palette.widgetElevated
    property color fgUpColor: accentedUp ? Palette.accentText : Palette.primary
    property color fgDownColor: accentedDown ? Palette.accentText : Palette.primary
    property color borderUpColor: accentedUp ? Palette.accentElevated : Palette.widgetShadow
    property color borderDownColor: accentedDown ? Palette.accent : Palette.widgetShadow
    readonly property color bgColor: down ? bgDownColor : bgUpColor
    readonly property color fgColor: down ? fgDownColor : fgUpColor
    readonly property color borderColor: down ? borderDownColor : borderUpColor


    font.family: Fonts.main
    font.pixelSize: Size.fontSize(size)

    implicitHeight: Size.controlHeight(size)
    implicitWidth: hasIcon
        ? implicitHeight + 8
        : Math.max(80, contentItem.implicitWidth + leftPadding + rightPadding)

    background: Rectangle {

        implicitHeight: root.implicitHeight
        radius: Style.radius

        //
        // Border
        //

        border.color: root.borderColor
        border.width: 1

        //
        // Main Gradient
        //

        gradient: Gradient {

            GradientStop {
                position: 0.0
                color: root.bgColor.lighter(1.4)
            }
            GradientStop {
                position: 1.0
                color: root.bgColor.darker(1.05)
            }
        }

        //
        // Drop Shadow
        //

        layer.enabled: true
        layer.effect: MultiEffect {

            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.1
            shadowVerticalOffset: 1
            shadowHorizontalOffset: 1
        }

        //
        // Bevel
        //

        Rectangle {

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            height: 1
            color: "#80ffffff"
        }
    }

    SiToolTip {
        text: root.tooltip
    }

    contentItem: SiText {

        rotation: root.iconRotation

        text: root.hasIcon ? Fonts.iconText(root.symbol, root.phosphor, root.awesome) : root.text
        font.family: root.hasIcon ? Fonts.iconFamily(root.symbol, root.phosphor, root.awesome)
                                  : root.font.family
        font.pixelSize: root.hasIcon ? root.font.pixelSize + 6 : root.font.pixelSize
        font.bold: root.font.bold
        color: (root.enabled || !root.hasIcon) ? root.fgColor : Palette.disabled
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
