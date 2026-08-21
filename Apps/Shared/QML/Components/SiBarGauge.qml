import QtQuick
import Silicium.Theme

// SegmentedMeter.qml

import QtQuick

Item {

    id: root

    property real value: 0.0
    property real minValue: 0.0
    property real maxValue: 1.0
    property int segments: 16
    property real alpha: 1.0

    width: segments * 4
    height: 14

    property color inactiveColor: "#60000000"

    property var stops: [
        { pos: 0.00, color: "#990000" },
        { pos: 0.25, color: "#CCCC00" },
        { pos: 0.50, color: "#009900" },
        { pos: 0.75, color: "#CCCC00" },
        { pos: 1.00, color: "#990000" }
    ]

    readonly property real normalizedValue:
        (value - minValue) / (maxValue - minValue)

    readonly property real clampedValue:
        Math.max(0.0, Math.min(1.0, normalizedValue))

    readonly property int activeSegments:
        Math.round(clampedValue * segments)

    readonly property color activeColor:
        interpolateColor(clampedValue)

    function mixColors(c1, c2, t)
    {
        c1 = Qt.color(c1)
        c2 = Qt.color(c2)

        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            alpha
        )
    }

    function interpolateColor(pos)
    {
        if (stops.length === 0)
            return "white"

        if (pos <= stops[0].pos)
            return stops[0].color

        if (pos >= stops[stops.length - 1].pos)
            return stops[stops.length - 1].color

        for (let i = 0; i < stops.length - 1; i++) {

            const a = stops[i]
            const b = stops[i + 1]

            if (pos >= a.pos && pos <= b.pos) {

                const t = (pos - a.pos) / (b.pos - a.pos)
                return mixColors(a.color, b.color, t)
            }
        }

        return stops[stops.length - 1].color
    }

    Row {

        id: row

        anchors.fill: parent
        spacing: 2

        Repeater {

            model: root.segments

            Rectangle {

                required property int index

                width: (row.width - (root.segments - 1) * row.spacing)
                    / root.segments

                height: row.height

                radius: height / 6

                color: index < root.activeSegments
                    ? root.activeColor
                    : root.inactiveColor
            }
        }
    }
}
