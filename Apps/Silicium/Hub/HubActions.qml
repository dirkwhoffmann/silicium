import QtQuick
import QtQuick.Controls
import Silicium.Controllers
import Silicium.Preferences

Item {

    id: root

    required property HubController hc
    required property HubSidebarController sc
    required property OnboardingController oc
    required property var preferencesWindow
    required property var openSvmFileDialog
    required property var cloneDialog

    property alias preferences: preferencesAction
    property alias open: openAction
    property alias onboarding: onboardingAction
    property alias onboardingC64: onboardingC64Action
    property alias onboardingAmiga: onboardingAmigaAction
    property alias onboardingToggle: onboardingToggleAction
    property alias info: infoAction
    property alias logger: loggerAction
    property alias clone: cloneAction
    property alias rename: renameAction

    Action {

        id: preferencesAction
        text: "Open Preferences"
        shortcut: StandardKey.Preferences
        onTriggered: {
            console.log("HubWindow: preferencesAction")
            preferencesWindow.show()
            preferencesWindow.raise()
            preferencesWindow.requestActivate()
        }
    }

    Action {

        id: openAction
        text: "Open Virtual Machine"
        shortcut: StandardKey.Open
        onTriggered: openSvmFileDialog.open()
    }

    /* Reveals the assistant on a given page.
     *
     * The platform must be assigned before the page: setting it rebuilds the
     * flow the assistant walks through (see OnboardingController::
     * buildPageList), so a page assigned first would momentarily not be part
     * of its own flow.
     */
    function startOnboarding(platform, page) {

        hc.panel = "assistant"
        oc.platform = platform
        oc.page = page
    }

    Action {

        id: onboardingAction
        text: "New Virtual Machine"
        onTriggered: root.startOnboarding("c64", "welcome")
    }

    Action {

        id: onboardingC64Action
        text: "New Virtual C64"
        onTriggered: root.startOnboarding("c64", "c64Model")
    }

    Action {

        id: onboardingAmigaAction
        text: "New Virtual Amiga"
        onTriggered: root.startOnboarding("amiga", "amigaModel")
    }

    Action {

        /* The icon bar's button, which closes the assistant when it is
         * already open. The per-platform actions above deliberately do not
         * toggle: hitting '+' on the Amiga row while the C64 assistant is
         * showing should switch to the Amiga flow, not dismiss the panel.
         */
        id: onboardingToggleAction
        text: "New Virtual Machine"
        onTriggered: {
            if (hc.panel === "assistant") {
                hc.selectionChanged()
            } else {
                root.startOnboarding("c64", "welcome")
            }
        }
    }

    Action {

        id: infoAction
        text: "Inspect Virtual Machine"
        onTriggered: {
            hc.overlay = hc.overlay === "info" ? "" : "info"
        }
    }

    Action {

        id: loggerAction
        text: "Show Application Log"
        onTriggered: {
            hc.overlay = hc.overlay === "logger" ? "" : "logger"
        }
    }

    Action {

        id: cloneAction
        text: "Clone Virtual Machine"

        property string uuid: ""

        onTriggered: {
            console.log("HubWindow: cloneAction")
            cloneDialog.uuid = uuid
            cloneDialog.open()
        }
    }

    Action {

        id: renameAction
        text: "Rename Virtual Machine"

        property string uuid: ""
        property string newName: ""

        onTriggered: {
            console.log("HubWindow: renameAction")
            hc.rename(uuid, newName)
        }
    }
}