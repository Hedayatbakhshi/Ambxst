pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property bool showOutput: true  // true = output, false = input

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Header with title and output/input toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Text {
                text: root.showOutput ? "Sound Output" : "Sound Input"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize + 2
                font.weight: Font.Medium
                color: Colors.overBackground
            }

            Item { Layout.fillWidth: true }

            // Toggle between output and input
            Button {
                id: toggleButton
                flat: true
                implicitWidth: 32
                implicitHeight: 32

                background: StyledRect {
                    variant: toggleButton.hovered ? "focus" : "common"
                    radius: Styling.radius(4)
                }

                contentItem: Text {
                    text: root.showOutput ? Icons.mic : Icons.speakerHigh
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: Colors.overBackground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.showOutput = !root.showOutput
            }
        }

        // Scrollable content
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: contentColumn
                width: flickable.width
                spacing: 8

                // Section: Devices
                Text {
                    text: root.showOutput ? "Output Device" : "Input Device"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1
                    font.weight: Font.Medium
                    color: Colors.overSurfaceVariant
                }

                // Device list
                Repeater {
                    model: root.showOutput ? Audio.outputDevices : Audio.inputDevices

                    delegate: AudioDeviceItem {
                        required property var modelData
                        Layout.fillWidth: true
                        node: modelData
                        isOutput: root.showOutput
                        isSelected: (root.showOutput ? Audio.sink : Audio.source) === modelData
                    }
                }

                // Separator
                Separator {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                // Section: Volume Mixer
                Text {
                    text: "Volume Mixer"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1
                    font.weight: Font.Medium
                    color: Colors.overSurfaceVariant
                }

                // Main volume control
                AudioVolumeEntry {
                    Layout.fillWidth: true
                    node: root.showOutput ? Audio.sink : Audio.source
                    icon: root.showOutput ? Icons.speakerHigh : Icons.mic
                    isMainDevice: true
                }

                // App volume controls
                Repeater {
                    model: root.showOutput ? Audio.outputAppNodes : Audio.inputAppNodes

                    delegate: AudioVolumeEntry {
                        required property var modelData
                        Layout.fillWidth: true
                        node: modelData
                        isMainDevice: false
                    }
                }

                // Empty state for apps
                Text {
                    visible: (root.showOutput ? Audio.outputAppNodes : Audio.inputAppNodes).length === 0
                    text: "No applications using audio"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize - 1
                    color: Colors.outline
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                }
            }
        }
    }
}
