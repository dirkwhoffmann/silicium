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
import Silicium.Theme

Button {

    id: root

    property bool accented: false
    property bool accentedUp: accented
    property bool accentedDown: accented

    property int size: Size.regular

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
    implicitWidth: Math.max(80, contentItem.implicitWidth + leftPadding + rightPadding)

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

    contentItem: SiText {

        text: root.text
        font: root.font
        color: root.fgColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
