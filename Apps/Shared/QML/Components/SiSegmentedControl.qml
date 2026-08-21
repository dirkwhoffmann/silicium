import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Silicium.Theme

// A macOS-style segmented control: a single rounded body (matching SiButton's
// gradient / border / bevel / shadow) split into clickable segments by thin
// dividers, with the selected segment highlighted in the accent color.
//
// Driven by a plain string-list model plus a currentIndex, so one instance
// covers any number of segments:
//
//   SiSegmentedControl {
//       model: [qsTr("CIA 1"), qsTr("CIA 2")]
//       currentIndex: cia.selectedCia
//       onActivated: (index) => cia.selectedCia = index
//   }
//
Item {

    id: root

    // Segment captions
    property var model: []

    // Index of the selected segment (owned by the caller)
    property int currentIndex: 0

    // Minimum width of a single segment (useful for one-character captions so
    // they don't collapse to nothing)
    property int minSegmentWidth: 28

    // Fixed width for every segment, overriding each segment's natural
    // (label-driven) width. 0 keeps the default per-segment sizing.
    property int segmentWidth: 0

    // Control-size level (see Size)
    property int size: Size.regular

    // Emitted when a segment is clicked. The caller updates currentIndex.
    signal activated(int index)

    readonly property int count: model ? model.length : 0

    implicitHeight: Size.controlHeight(size)
    implicitWidth: row.implicitWidth

    // Drop shadow for the whole control. Applied to the (unanchored) root so
    // MultiEffect's auto-padding can extend the shadow past the body -- doing
    // this on an anchors.fill child clips the shadow away.
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#40000000"
        shadowBlur: 0.1
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 1
    }

    //
    // Body (mirrors SiButton's gradient + border)
    //

    Rectangle {

        id: body
        anchors.fill: parent
        radius: Style.radius
        border.color: Palette.widgetShadow
        border.width: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: Palette.widget.lighter(1.4) }
            GradientStop { position: 1.0; color: Palette.widget.darker(1.05) }
        }
    }

    //
    // Segments
    //

    Row {

        id: row
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Repeater {

            model: root.model

            delegate: AbstractButton {

                id: seg

                required property int index
                required property var modelData

                readonly property bool selected: root.currentIndex === index
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.count - 1

                height: row.height
                leftPadding: [8, 10, 12][root.size]
                rightPadding: [8, 10, 12][root.size]
                implicitWidth: root.segmentWidth > 0
                    ? root.segmentWidth
                    : Math.max(label.implicitWidth + leftPadding + rightPadding, root.minSegmentWidth)

                onClicked: root.activated(index)

                background: Item {

                    // Selected segment: an accent fill with its own accent
                    // border (matching SiButton), covering the body's border
                    // and adjacent dividers so the selection reads with an
                    // accent-colored edge. Only the outer corners are rounded.
                    Rectangle {

                        anchors.fill: parent
                        visible: seg.selected

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: (seg.down ? Palette.accentElevated : Palette.accent).lighter(1.4)
                            }
                            GradientStop {
                                position: 1.0
                                color: (seg.down ? Palette.accentElevated : Palette.accent).darker(1.05)
                            }
                        }

                        border.width: 1
                        border.color: seg.down ? Palette.accent : Palette.accentElevated

                        topLeftRadius: seg.isFirst ? Style.radius : 0
                        bottomLeftRadius: seg.isFirst ? Style.radius : 0
                        topRightRadius: seg.isLast ? Style.radius : 0
                        bottomRightRadius: seg.isLast ? Style.radius : 0
                    }

                    // Divider on this segment's trailing edge (the seam to the
                    // next segment). Skipped whenever either side of the seam
                    // is the selected segment, which paints its own accent
                    // border over the seam instead -- so no divider ever shows
                    // directly left or right of the selection.
                    Rectangle {

                        visible: !seg.isLast && !seg.selected && root.currentIndex !== seg.index + 1
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Palette.widgetShadow
                    }
                }

                contentItem: SiText {
                    id: label
                    text: seg.modelData
                    font.pixelSize: Size.fontSize(root.size)
                    color: seg.selected ? Palette.accentText : Palette.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    //
    // Bevel -- drawn last so it sits on top of the segments (the same top-edge
    // highlight SiButton has).
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
