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
        NetworkService.rescanWifi();
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
                text: "Wi-Fi"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize + 2
                font.weight: Font.Medium
                color: Colors.overBackground
            }

            Item { Layout.fillWidth: true }

            // Scanning indicator
            Text {
                visible: NetworkService.wifiScanning
                text: Icons.sync
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.primary
                
                RotationAnimation on rotation {
                    running: NetworkService.wifiScanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            // Wi-Fi toggle switch
            Switch {
                id: wifiToggle
                checked: NetworkService.wifiStatus !== "disabled"
                onCheckedChanged: {
                    NetworkService.enableWifi(checked);
                    if (checked) {
                        NetworkService.rescanWifi();
                    }
                }

                indicator: Rectangle {
                    implicitWidth: 40
                    implicitHeight: 20
                    x: wifiToggle.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: height / 2
                    color: wifiToggle.checked ? Colors.primary : Colors.surfaceBright
                    border.color: wifiToggle.checked ? Colors.primary : Colors.outline

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration / 2 }
                    }

                    Rectangle {
                        x: wifiToggle.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: parent.height - 4
                        height: width
                        radius: width / 2
                        color: wifiToggle.checked ? Colors.background : Colors.overSurfaceVariant

                        Behavior on x {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                        }
                    }
                }
                background: null
            }
        }

        // Network list
        ListView {
            id: networkList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: NetworkService.friendlyWifiNetworks

            delegate: WifiNetworkItem {
                required property var modelData
                width: networkList.width
                network: modelData
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: networkList.count === 0 && !NetworkService.wifiScanning
                text: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is disabled"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.overSurfaceVariant
            }
        }

        // Footer with rescan button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Item { Layout.fillWidth: true }

            Button {
                id: rescanButton
                flat: true
                enabled: !NetworkService.wifiScanning && NetworkService.wifiEnabled
                implicitWidth: 32
                implicitHeight: 32

                background: StyledRect {
                    variant: rescanButton.hovered ? "focus" : "common"
                    radius: Styling.radius(4)
                }

                contentItem: Text {
                    text: Icons.sync
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: rescanButton.enabled ? Colors.overBackground : Colors.outline
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: NetworkService.rescanWifi()
            }
        }
    }
}
