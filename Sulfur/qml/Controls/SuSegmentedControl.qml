import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sulfur

// A macOS-style segmented control: a single rounded body (matching SuButton's
// gradient / border / bevel / shadow) split into clickable segments by thin
// dividers, with the selected segment highlighted in the accent color.
//
// Driven by a plain list model plus a currentIndex, so one instance covers any
// number of segments:
//
//   SuSegmentedControl {
//       model: [qsTr("CIA 1"), qsTr("CIA 2")]
//       currentIndex: cia.selectedCia
//       onActivated: (index) => cia.selectedCia = index
//   }
//
// An entry is either a caption string or an object with these optional keys:
//
//   text      caption (used when no icon is given)
//   symbol    icon from the Material symbols font
//   phosphor  icon from the Phosphor font
//   awesome   icon from the Awesome font
//   rotate    icon rotation in degrees
//   action    an Action: triggered on click; its enabled state is followed
//             and its text is the default tooltip
//   tooltip   tooltip text
//   enabled   false disables the segment (default true)
//
//   model: [ { symbol: "info", tooltip: qsTr("Show Info") },
//            { phosphor: "clipboard", tooltip: qsTr("Open Logger"), enabled: ok } ]
//
// currentIndex may be -1 (nothing selected). Clicks never change it; the
// caller decides how to react, e.g. deselecting on a second click.
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

    // Color aliases (declared here to make them reactive)
    property color accent: Palette.accent
    property color accentElevated: Palette.accentElevated
    property color accentText: Palette.accentText
    property color primary: Palette.primary
    property color widget: Palette.widget
    property color widgetShadow: Palette.widgetShadow

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
    // Body (mirrors SuButton's gradient + border)
    //

    Rectangle {

        id: body
        anchors.fill: parent
        radius: Style.radius
        border.color: root.widgetShadow
        border.width: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.widget.lighter(1.4) }
            GradientStop { position: 1.0; color: root.widget.darker(1.05) }
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

                // Entry normalized to an object
                readonly property var entry: typeof modelData === "string"
                    ? { text: modelData } : (modelData ?? {})
                readonly property string symbol: entry.symbol ?? ""
                readonly property string phosphor: entry.phosphor ?? ""
                readonly property string awesome: entry.awesome ?? ""
                readonly property bool hasIcon: symbol !== "" || phosphor !== "" || awesome !== ""

                readonly property bool selected: root.currentIndex === index
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.count - 1

                height: row.height
                action: entry.action ?? null
                enabled: (entry.enabled ?? true) && (entry.action ? entry.action.enabled : true)
                leftPadding: [8, 10, 12][root.size]
                rightPadding: [8, 10, 12][root.size]
                implicitWidth: root.segmentWidth > 0
                    ? root.segmentWidth
                    : Math.max(label.implicitWidth + leftPadding + rightPadding, root.minSegmentWidth)

                onClicked: root.activated(index)

                SuToolTip {
                    text: seg.entry.tooltip ?? seg.entry.action?.text ?? ""
                }

                background: Item {

                    // Selected segment: an accent fill with its own accent
                    // border (matching SuButton), covering the body's border
                    // and adjacent dividers so the selection reads with an
                    // accent-colored edge. Only the outer corners are rounded.
                    Rectangle {

                        anchors.fill: parent
                        visible: seg.selected

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: (seg.down ? root.accentElevated : root.accent).lighter(1.4)
                            }
                            GradientStop {
                                position: 1.0
                                color: (seg.down ? root.accentElevated : root.accent).darker(1.05)
                            }
                        }

                        border.width: 1
                        border.color: seg.down ? root.accent : root.accentElevated

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
                        color: root.widgetShadow
                    }
                }

                contentItem: SuText {
                    id: label
                    text: seg.hasIcon ? Fonts.iconText(seg.symbol, seg.phosphor, seg.awesome)
                                      : (seg.entry.text ?? "")
                    font.family: seg.hasIcon ? Fonts.iconFamily(seg.symbol, seg.phosphor, seg.awesome)
                                             : Fonts.main
                    font.pixelSize: seg.hasIcon ? Size.fontSize(root.size) + 6 : Size.fontSize(root.size)
                    rotation: seg.entry.rotate ?? 0
                    opacity: seg.enabled ? 1 : 0.4
                    color: seg.selected ? root.accentText : root.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    //
    // Bevel -- drawn last so it sits on top of the segments (the same top-edge
    // highlight SuButton has).
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
