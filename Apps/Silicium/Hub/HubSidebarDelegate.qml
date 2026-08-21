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
import Silicium.Assets
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

ItemDelegate {

    id: myDelegate

    required property int index
    required property string uuid
    required property string svm
    required property bool isHidden
    required property string iconSrc
    required property string stateSrc
    required property string title
    required property int type
    required property int level
    required property bool readOnly
    required property bool isCompatible
    required property bool isExpandable
    required property bool isExpanded

    readonly property var sc: sidebarController
    readonly property var vInfo: HubController.vInfo
    readonly property var sInfo: HubController.sInfo
    readonly property var next: sidebarController.nextSnap(uuid)
    readonly property var prev: sidebarController.prevSnap(uuid)
    readonly property var nextVM: sidebarController.nextVM(uuid)
    readonly property var prevVM: sidebarController.prevVM(uuid)

    property bool isPlatform: type === 0
    property bool isVM: type === 1
    property bool isSnapshot: type === 2
    property bool isSelected: uuid === HubController.selected
    property bool editing: false

    // Cancel editing when the user clicks on another item
    onIsSelectedChanged: if (!isSelected) { editing = false }

    readonly property var auxAction: isSnapshot ? deleteAction : isPlatform ? onboardingAction : null

    visible: !isHidden
    width: ListView.view.width
    height: isHidden ? 0 : 26
    rightPadding: 0

    HoverHandler {
        id: delegateHover
    }

    Action {

        id: renameAction
        icon.name: "edit_square"
        text: "Rename"
        enabled: !readOnly

        onTriggered: {

            myDelegate.editing = true
            editor.forceActiveFocus()
            editor.selectAll()
        }
    }

    Action {

        id: removeAction
        icon.name: "ink_eraser"
        text: "Remove from library"
        enabled: !readOnly

        onTriggered: {

            HubController.remove(uuid)
        }
    }

    Action {

        id: deleteAction
        icon.name: "delete"
        text: "Delete"
        enabled: !readOnly

        onTriggered: HubController.remove(uuid)
    }

    Action {

        id: cloneAction
        icon.name: "content_copy"
        text: "Clone"

        onTriggered: {

            root.actions.clone.uuid = uuid
            root.actions.clone.trigger()
        }
    }

    Action {

        id: onboardingAction
        text: "Create Virtual Machine"
        icon.name: "add_circle"

        onTriggered: {

            // Keyed on the row's uuid, not its title -- see the CATEGORY_*
            // constants in HubSidebarController.
            if (uuid === myDelegate.sc.CATEGORY_C64) {
                root.actions.onboardingC64.trigger()
            } else if (uuid === myDelegate.sc.CATEGORY_AMIGA) {
                root.actions.onboardingAmiga.trigger()
            } else {
                root.actions.onboarding.trigger()
            }
        }
    }

    SiMenu {

        id: itemMenu

        SiMenuItem {
            visible: (isVM || isSnapshot) && !readOnly
            action: renameAction
        }

        SiMenuItem {
            visible: isVM
            action: cloneAction
        }

        SiMenuItem {
            visible: isVM && !readOnly
            action: removeAction
        }

        SiMenuItem {
            visible: isSnapshot
            action: deleteAction
        }
    }

    background: Rectangle {

        color: isPlatform ? "transparent"
            : isSelected ? Palette.accent
                : hovered ? Palette.surfaceElevated : "transparent"

        radius: isSelected || hovered ? 4 : 0
    }

    contentItem: RowLayout {

        anchors.fill: parent
        spacing: Style.smallSpacing

        HSpacer {
            size: level * (18 + Style.smallSpacing)
        }

        //
        // Chevron or Lock
        //

        Item {

            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            SiText {

                visible: isExpandable && !readOnly
                anchors.centerIn: parent
                text: "chevron_right"
                font.family: Fonts.symbols
                font.pixelSize: 16
                font.bold: true
                color: isSelected ? "white" : Palette.secondary
                rotation: isExpanded ? 90 : 0
            }

            SiSymbol {

                visible: readOnly
                anchors.centerIn: parent
                awesome: "lock"
                color: isSelected ? Palette.accentText : Palette.tertiary
                scale: 0.75
                Layout.alignment: Qt.AlignVCenter
            }

            TapHandler {

                onTapped: {

                    sidebarController.sidebarModel.expandOrCollapse(uuid)
                }
            }
        }

        //
        // VM Icon
        //

        Image {

            visible: isVM

            Layout.preferredWidth: 18
            Layout.preferredHeight: 18

            source: iconSrc
            sourceSize.width: Style.iconSmall
            sourceSize.height: Style.iconSmall

            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
        }

        SiSymbol {

            visible: isSnapshot

            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            awesome: "camera"
            color: isSelected ? Palette.accentText : Palette.tertiary
            scale: 0.75
            Layout.alignment: Qt.AlignVCenter
        }

        //
        // Text
        //

        SiText {

            visible: !editing
            text: title
            font.strikeout: !isCompatible

            DebugRect {}

            font.bold: isPlatform
            font.pixelSize: isPlatform ? Style.regular * 0.9 : Style.regular
            color:
                isPlatform
                    ? Palette.secondary
                    : isSelected
                        ? Palette.accentText
                        : isCompatible
                            ? Palette.primary
                            : Palette.warning

            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight

            /* Without Layout.fillWidth, this item's layout width is always
             * its implicitWidth (the full, un-elided text) -- RowLayout only
             * shrinks items that opt in via fillWidth, so elide never
             * actually had anything to elide; text just ran past the row's
             * width and was hard-clipped by the ListView's clip: true
             * instead, with no ellipsis.
             *
             * That also broke the icon column below: with no fillWidth item
             * of its own, the trailing HSpacer that used to sit here was the
             * *only* thing standing between "some space left" and "no space
             * left" -- once it bottomed out at zero, there was nothing left
             * to absorb the difference between rows, so each row's icon
             * ended up positioned by that row's own (differently-sized) text
             * instead of a shared margin, and the icons drifted out of their
             * column. Giving the text itself fillWidth makes it the thing
             * that shrinks -- via real elision, not clipping -- so the icon
             * stays pinned at a constant distance from the edge on every
             * row, which is what actually keeps the column aligned. See the
             * (now removed) HSpacer that used to follow this item.
             */
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            TapHandler {

                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onTapped: (eventPoint, button) => {

                    if (button === Qt.RightButton) {

                        //
                        // Right Click
                        //

                        itemMenu.popup()
                        return
                    }

                    if (isSelected) {

                        if (doubleClickTimer.running) {

                            //
                            // Fast double-click
                            //

                            doubleClickTimer.stop()
                            slowClickTimer.stop()
                            HubController.open()
                            return

                        } else if (slowClickTimer.running && slowClickTimer.armedFor === uuid) {

                            //
                            // Slow double-click
                            //

                            doubleClickTimer.stop()
                            slowClickTimer.stop()
                            renameAction.trigger()
                            return
                        }

                        //
                        // Click on an already-selected item
                        //

                        /* Only the double-click window reopens here, so
                         * double-clicking a selected item still opens it.
                         * The rename window deliberately does not: were it
                         * re-armed, a selected item would sit permanently
                         * one click away from renaming, and two casual
                         * clicks a second apart -- long after it was
                         * selected -- would start an edit nobody asked
                         * for. Renaming stays available from the context
                         * menu, and from the select-then-click gesture
                         * below.
                         */
                        doubleClickTimer.restart()
                        return
                    }

                    //
                    // Single click (on an item that was not selected)
                    //

                    doubleClickTimer.restart()
                    slowClickTimer.restart()
                    slowClickTimer.armedFor = uuid
                    HubController.selected = uuid
                }
            }

            HoverHandler {

                id: labelHover

                // Moving off the item abandons the rename gesture: coming
                // back later and clicking should select, not start an
                // edit. Guarded by armedFor so leaving one item cannot
                // cancel a window opened on another.
                onHoveredChanged: {

                    if (!hovered && slowClickTimer.armedFor === uuid) {
                        slowClickTimer.stop()
                    }
                }
            }
        }

        //
        // Renaming field
        //

        SiTextField {

            id: editor
            visible: myDelegate.editing
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            text: title
            selectByMouse: true

            onAccepted: {

                root.actions.rename.uuid = uuid
                root.actions.rename.newName = text
                root.actions.rename.trigger()
                myDelegate.editing = false
            }

            onEditingFinished: {

                myDelegate.editing = false
            }

            Keys.onEscapePressed: {

                myDelegate.editing = false
            }
        }

        //
        // Aux button
        //

        SiSymbolButton {

            visible: opacity > 0
            opacity: ((auxAction && delegateHover.hovered) || isSnapshot) ? 1.0 : 0.0

            Behavior on opacity {

                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Style.smallSpacing
            symbol: auxAction?.icon.name ?? ""
            font.pixelSize: Style.large
            color: isSelected ? Palette.accentText : Palette.secondary
            action: auxAction
        }

        //
        // Aux image
        //

        Image {

            visible: isVM && stateSrc !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Style.smallSpacing
            source: stateSrc
            sourceSize.width: Style.iconSmall
            sourceSize.height: Style.iconSmall
            fillMode: Image.PreserveAspectFit

        }
    }
}