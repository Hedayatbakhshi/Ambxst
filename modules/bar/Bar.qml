import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../workspaces"
import "../theme"
import "../clock"
import "../systray"
import "../launcher"
import "../notch"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
        // bottom: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: GlobalStates.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusiveZone: 40
    implicitHeight: GlobalStates.launcherOpen ? Math.min(444, notchContainer.implicitHeight + 4) : 44

    // Default view component - user@host text
    Component {
        id: defaultViewComponent
        Item {
            width: userHostText.implicitWidth + 24
            height: 28

            Text {
                id: userHostText
                anchors.centerIn: parent
                text: `${Quickshell.env("USER")}@${Quickshell.env("HOSTNAME")}`
                color: Colors.foreground
                font.family: Styling.defaultFont
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
    }

    // Launcher view component
    Component {
        id: launcherViewComponent
        Item {
            width: 480
            height: Math.min(launcherSearch.implicitHeight, 400)

            LauncherSearch {
                id: launcherSearch
                anchors.fill: parent

                onItemSelected: {
                    GlobalStates.launcherOpen = false;
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.launcherOpen = false;
                        event.accepted = true;
                    }
                }

                Component.onCompleted: {
                    clearSearch();
                    Qt.callLater(() => {
                        forceActiveFocus();
                    });
                }
            }
        }
    }

    Rectangle {
        id: bar
        anchors.fill: parent
        color: "transparent"

        // Left side of bar
        RowLayout {
            id: leftSide
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.margins: 4
            spacing: 4

            LauncherButton {
                id: launcherButton
            }

            Workspaces {
                bar: QtObject {
                    property var screen: panel.screen
                }
            }
        }

        // Right side of bar
        RowLayout {
            id: rightSide
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.margins: 4
            spacing: 4

            SysTray {
                bar: panel
            }

            Clock {
                id: clockComponent
            }
        }
    }

    // Center notch - moved outside the bar rectangle to avoid clipping
    Notch {
        id: notchContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        defaultViewComponent: defaultViewComponent
        launcherViewComponent: launcherViewComponent
    }

    // Listen for launcher state changes
    Connections {
        target: GlobalStates
        function onLauncherOpenChanged() {
            if (GlobalStates.launcherOpen) {
                notchContainer.stackView.push(launcherViewComponent);
                Qt.callLater(() => {
                    panel.requestActivate();
                    panel.forceActiveFocus();
                });
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.pop();
                }
            }
        }
    }

    // Handle global keyboard events
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && GlobalStates.launcherOpen) {
            GlobalStates.launcherOpen = false;
            event.accepted = true;
        }
    }
}
