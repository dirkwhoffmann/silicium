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
import Silicium.Controllers
import Silicium.Preferences
import Silicium.Theme

Rectangle {

    id: root
    required property HubSidebarController sidebarController
    required property OnboardingController onboardingController

    SplitView.fillWidth: true
    SplitView.fillHeight: true

    Connections {

        target: HubController

        function onPanelChanged() {
            updateStack()
        }

        function onOverlayChanged() {
            updateStack()
        }

        function onSelectionChanged() {

            if (HubController.selected) {
                HubController.panel = "preview"
            } else {
                HubController.panel = "splash"
                HubController.overlay = ""
            }
        }
    }

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        StackView {

            id: viewStack
            Layout.fillWidth: true
            Layout.fillHeight: true

            background: Image {
                source: Assets.iconUrl(Assets.Background)
                // anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                clip: true
                opacity: 1.0
            }

            initialItem: splashComponent

            // Define smooth cross-fade transitions
            replaceEnter: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 0;
                    to: 1; duration: 400; easing.type: Easing.OutCubic
                }
            }
            replaceExit: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 1;
                    to: 0; duration: 0
                }
            }
        }
    }

    Component {
        id: splashComponent
        HubSplashScreen {
        }
    }

    Component {
        id: onboardingComponent
        OnboardingView {
            onboardingController: root.onboardingController
        }
    }

    Component {
        id: previewComponent
        HubPreview {
            sidebarController: root.sidebarController
        }
    }

    Component {
        id: infoComponent
        HubInfo {
        }
    }

    Component {
        id: loggerComponent
        HubLogger {
        }
    }

    function updateStack() {

        let targetComponent;

        if (HubController.overlay === "info") {
            targetComponent = infoComponent;
        } else if (HubController.overlay === "logger") {
            targetComponent = loggerComponent;
        } else if (HubController.panel === "preview") {
            targetComponent = previewComponent;
        } else if (HubController.panel === "assistant") {
            targetComponent = onboardingComponent;
        } else {
            targetComponent = splashComponent;
        }

        if (!viewStack.currentItem || viewStack.currentItem.component !== targetComponent) {
            viewStack.replace(targetComponent);
        }
    }
}