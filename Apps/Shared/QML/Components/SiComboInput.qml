import QtQuick
import QtQuick.Controls
import Silicium.Theme

// A macOS-style combo box: an editable text field with a pull-down button
// sharing a single pill border, as opposed to SiComboBox's read-only,
// label-only field. Built on ComboBox's own editable mode rather than a
// separate TextField + Button pair, so the usual combo box keyboard/mouse
// behavior (arrow keys, clicking the indicator to open the popup, Enter to
// accept) comes for free.
ComboBox {

    id: root

    property int size: Size.regular

    editable: true
    implicitHeight: size === Size.regular ? 22 : Size.controlHeight(size)
    leftPadding: 10
    rightPadding: indicatorWidth + Style.smallSpacing
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

    // Width of the accent-colored pull-down segment, macOS-style.
    property real indicatorWidth: 20

    // Forwarded to the inner TextField -- ComboBox itself has no
    // placeholderText property, only TextField does.
    property alias placeholderText: input.placeholderText

    // ComboBox itself has no editingFinished signal (only accepted, fired on
    // Enter); forwarded here from the inner TextField so losing focus after
    // a typed-but-not-submitted edit is still observable.
    signal editingFinished()

    // A click within this control's bounds can leave activeFocus on the
    // ComboBox itself rather than its contentItem (Control's own StrongFocus
    // click-handling can reclaim it even though the TextField still gets the
    // mouse-drag for selection, which is why selecting/copying text works
    // but typing doesn't) -- redirect it down to the actual text field
    // whenever that happens.
    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

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

        // Accent-colored pull-down segment, like a macOS combo box. Its
        // bounds line up with the 'indicator' item below, which is what
        // ComboBox itself hit-tests against to decide whether a press opens
        // the popup (editable mode) rather than starting a text edit.
        Rectangle {

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: bg.border.width
            width: root.indicatorWidth - bg.border.width
            color: root.accent
            opacity: root.enabled ? 1.0 : 0.4
            topRightRadius: bg.radius - 1
            bottomRightRadius: bg.radius - 1
        }
    }

    //
    // Indicator (pull-down arrow)
    //

    indicator: Item {

        x: root.width - width
        y: 0
        width: root.indicatorWidth
        height: root.height

        Canvas {

            id: arrow

            anchors.centerIn: parent
            width: 8
            height: 5

            property color strokeColor: root.accentText

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
    // Content (editable text field)
    //

    // One-way bound to editText, matching Qt Quick Controls' own Basic-style
    // ComboBox.qml template for editable mode: ComboBox recognizes a
    // TextInput-derived contentItem and wires user edits back into editText,
    // plus Enter/focus-out into accepted()/editingFinished(), on its own.
    contentItem: TextField {

        id: input
        text: root.editText
        font: root.font
        color: root.enabled ? root.primary : root.disabled
        verticalAlignment: Text.AlignVCenter
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        selectByMouse: true
        background: null

        onTextEdited: root.editText = text
        onEditingFinished: root.editingFinished()
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

        // A model entry of the shape {separator: true} (see e.g.
        // SiAmLogicAnalyzerController::presetModel()) renders as an inert
        // divider line instead of a selectable row, mirroring an NSMenu's
        // own separator items.
        readonly property bool isSeparator: typeof modelData === "object" && modelData !== null && modelData.separator === true

        width: root.width - 8
        height: isSeparator ? 9 : 28
        enabled: !isSeparator
        hoverEnabled: !isSeparator
        highlighted: !isSeparator && root.highlightedIndex === index

        readonly property color foreground: highlighted ? "white" : root.primary

        contentItem: Item {

            Rectangle {

                visible: item.isSeparator
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: root.controlBorder
            }

            SiText {

                visible: !item.isSeparator
                anchors.fill: parent
                text: root.textRole !== "" ? modelData[root.textRole] : modelData
                color: item.foreground
                font: root.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
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
