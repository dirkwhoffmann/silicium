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
import Silicium.Theme

/* Shows what a SiTask is doing.
 *
 * Bind 'task' to one and the dialog follows it: it opens when the job starts
 * and closes when it ends, so a caller only has to start the job.
 *
 * 'task' is untyped on purpose. SiTask is a plain QObject rather than a
 * registered QML type, so this file works in every app without each of them
 * having to register it first.
 */
SiDialog {

    id: root

    property var task: null

    // Whether the user may call the job off. Off by default: a job that is
    // half-done has to be safe to abandon before it is offered.
    property bool cancellable: false

    /* How long a job has to run before it is worth interrupting the user
     * with a dialog. Most copies finish in a fraction of a second, and a
     * window that flashes up and vanishes is worse than no window at all.
     */
    property int showDelay: 400

    readonly property bool active: task !== null && task.running

    title: ""
    closePolicy: Popup.NoAutoClose
    buttons: cancellable ? Dialog.Cancel : Dialog.NoButton

    onRejected: if (task) task.cancel()

    onActiveChanged: {

        if (active) {
            delay.restart()
        } else {
            delay.stop()
            close()
        }
    }

    Timer {

        id: delay
        interval: root.showDelay
        onTriggered: if (root.active) root.open()
    }

    ColumnLayout {

        Layout.fillWidth: true
        spacing: Style.mediumSpacing

        SiText {

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: Style.regular
            text: root.task ? root.task.text : ""
        }

        SiProgressBar {

            Layout.fillWidth: true
            value: root.task ? root.task.progress : 0.0
        }

        SiText {

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Style.small
            opacity: 0.7
            text: root.task ? Math.round(root.task.progress * 100) + "%" : ""
        }
    }
}
