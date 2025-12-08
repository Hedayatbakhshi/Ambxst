pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    Component.onCompleted: {
        if (BluetoothService.enabled) {
            BluetoothService.startDiscovery();
        }
    }

    Component.onDestruction: {
        BluetoothService.stopDiscovery();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Header with title and toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Text {
                text: "Bluetooth"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize + 2
                font.weight: Font.Medium
                color: Colors.overBackground
            }

            Item { Layout.fillWidth: true }

            // Scanning indicator
            Text {
                visible: BluetoothService.discovering
                text: Icons.sync
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                
                RotationAnimation on rotation {
                    running: BluetoothService.discovering
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            // Bluetooth toggle switch
            Switch {
                id: btToggle
                checked: BluetoothService.enabled
                onCheckedChanged: {
                    BluetoothService.setEnabled(checked);
                    if (checked) {
                        BluetoothService.startDiscovery();
                    }
                }

                indicator: Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    x: btToggle.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: height / 2
                    color: btToggle.checked ? Colors.primary : Colors.surfaceBright
                    border.color: btToggle.checked ? Colors.primary : Colors.outline

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration / 2 }
                    }

                    Rectangle {
                        x: btToggle.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: parent.height - 4
                        height: width
                        radius: width / 2
                        color: btToggle.checked ? Colors.background : Colors.overSurfaceVariant

                        Behavior on x {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                        }
                    }
                }
                background: null
            }
        }

        // Device list
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: BluetoothService.friendlyDeviceList

            delegate: BluetoothDeviceItem {
                required property var modelData
                width: deviceList.width
                device: modelData
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0 && !BluetoothService.discovering
                text: BluetoothService.enabled ? "No devices found" : "Bluetooth is disabled"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.overSurfaceVariant
            }
        }

        // Footer with scan button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                id: scanButton
                flat: true
                enabled: !BluetoothService.discovering && BluetoothService.enabled
                implicitWidth: 32
                implicitHeight: 32

                background: StyledRect {
                    variant: scanButton.hovered ? "focus" : "common"
                    radius: Styling.radius(4)
                }

                contentItem: Text {
                    text: Icons.sync
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: scanButton.enabled ? Colors.overBackground : Colors.outline
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: BluetoothService.startDiscovery()
            }
        }
    }
}
