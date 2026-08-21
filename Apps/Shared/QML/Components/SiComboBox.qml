import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Silicium.Theme

ComboBox {

    id: root

    property int size: Size.regular

    implicitHeight: size === Size.regular ? 22 : Size.controlHeight(size)
    leftPadding: 10
    rightPadding: 0
    font.family: Fonts.main
    font.pixelSize: Size.fontSize(size)

    property color accent: Palette.accent
    property color accentText: Palette.accentText
    property color primary: Palette.primary
    property color disabled: Palette.disabled
    property color control: Palette.control
    property color controlSelected: Palette.controlSelected
    property color controlBorder: Palette.controlBorder
    property color controlBorderSelected: Palette.controlBorderSelected

    // Width of the accent-colored arrow segment, macOS-style
    property real indicatorWidth: 20

    property var isItemEnabled: function(itemText, index) { return true; }

    // When true, the dropdown arrow isn't drawn -- for read-only, single-
    // option combo boxes that are shown rather than interacted with.
    property bool readOnly: false

    //
    // Icons (optional)
    //

    /* Point 'iconRole' at a model role holding a symbol name (see SiSymbol) and
     * every dropdown row, plus the field showing the current selection, gets
     * that symbol left of its text. Leave it empty for a text-only combo box,
     * which is what most callers want.
     */
    property string iconRole: ""

    // Symbol of the current selection, or "" for a text-only combo box. Icons
    // need a model QML can index (a JS array or a QVariantList), which is what
    // every caller passing objects uses.
    readonly property string currentSymbol:
        root.iconRole !== "" && root.currentIndex >= 0 && root.model
            ? root.itemSymbol(root.model[root.currentIndex]) : ""

    // Text of a model item: its textRole when one is set, the item itself
    // otherwise (a plain list of strings). Never returns undefined, so callers
    // can bind to it without guarding.
    function itemText(item) {

        const value = root.textRole !== "" && item && typeof item === "object" ? item[root.textRole] : item
        return value === undefined || value === null ? "" : value
    }

    // Symbol of a model item, or "" when this combo box carries no icons.
    function itemSymbol(item) {

        const value = root.iconRole !== "" && item && typeof item === "object" ? item[root.iconRole] : ""
        return value === undefined || value === null ? "" : value
    }

    //
    // Background (Pill)
    //

    background: Rectangle {

        id: bg

        implicitWidth: 100
        implicitHeight: root.implicitHeight
        radius: Style.radius
        border.color: root.activeFocus ? root.controlBorderSelected : root.controlBorder
        border.width: 1
        color: root.activeFocus ? root.controlSelected : root.control

        // Accent-colored segment behind the arrow, like a macOS combo box
        Rectangle {

            visible: true // !root.readOnly
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: bg.border.width
            width: root.indicatorWidth - bg.border.width
            color: root.readOnly ? root.controlBorder : root.accent
            opacity: root.enabled ? 1.0 : 0.4
            topRightRadius: bg.radius - 1
            bottomRightRadius: bg.radius - 1
        }
    }

    // Indicator (drop-down arrow)
    indicator: Item {

        x: root.width - width
        y: 0
        width: root.indicatorWidth
        height: root.height
        visible: !root.readOnly

        Canvas {

            id: arrow

            anchors.centerIn: parent
            width: 8
            height: 5

            property color strokeColor: root.accentText // root.enabled ? root.accentText : root.disabled

            onStrokeColorChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {

                const ctx = getContext("2d");
                ctx.reset();
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width / 2, height);
                ctx.closePath();
                ctx.fillStyle = strokeColor;
                ctx.fill();
            }
        }
    }

    //
    // Content
    //

    contentItem: RowLayout {

        spacing: Style.smallSpacing

        SiSymbol {

            symbol: root.currentSymbol
            visible: symbol !== ""
            size: root.size
            color: root.enabled ? root.primary : root.disabled
            Layout.alignment: Qt.AlignVCenter

            DebugRect {}
        }

        SiText {

            text: root.displayText
            font: root.font
            color: root.enabled ? root.primary : root.disabled
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.fillWidth: true
            // Keep clear of the arrow segment, which overlays the right edge.
            Layout.rightMargin: root.indicator.width + Style.smallSpacing // root.spacing
        }
    }

    //
    // Popup (dropdown list)
    //

    popup: Popup {

        y: root.height + 2
        width: root.width
        implicitHeight: contentItem.implicitHeight + 10
        padding: 4

        contentItem: ListView {

            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {

            color: root.controlSelected
            border.color: root.controlBorderSelected
            radius: Style.radius
        }
    }

    //
    // Delegate (List items)
    //

    delegate: ItemDelegate {

        id: item

        width: root.width - 8
        height: 28
        highlighted: root.highlightedIndex === index

        // Colour of this row's text and symbol
        readonly property color foreground: highlighted ? "white" : enabled ? root.primary : root.disabled

        enabled: root.isItemEnabled(root.itemText(modelData), index)

        contentItem: RowLayout {

            spacing: Style.smallSpacing

            SiSymbol {

                // This row's own symbol, not the selected one's.
                symbol: root.itemSymbol(modelData)
                visible: symbol !== ""
                size: root.size
                color: item.foreground
                Layout.alignment: Qt.AlignVCenter
            }

            SiText {

                text: root.itemText(modelData)
                color: item.foreground
                font: root.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        background: Rectangle {

            radius: Style.radius
            visible: highlighted
            color: root.accent
            anchors.margins: 2
        }
    }
}