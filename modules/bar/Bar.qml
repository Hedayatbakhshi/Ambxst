import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../workspaces"
import "../theme"
import "../clock"
import "../systray"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 40
    margins.top: 0
    margins.left: 0
    margins.right: 0

    Rectangle {
        id: bar
        anchors.fill: parent
        anchors.margins: 0
        color: Colors.background
        radius: 0
        border.color: Colors.outline
        border.width: 0

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 4
            spacing: 16

            Workspaces {
                bar: QtObject {
                    property var screen: panel.screen
                }
            }

            Text {
                visible: Hyprland.workspaces.length === 0
                text: "No workspaces"
                color: Colors.foreground
                font.pixelSize: 12
            }

            Item {
                Layout.fillWidth: true
            }

            SysTray {
                bar: panel
            }

            Clock {
                id: clockComponent
            }
        }
    }
}
