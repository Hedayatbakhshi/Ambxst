pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300

    property int currentSection: 0  // 0: Wi-Fi, 1: Bluetooth, 2: Audio

    Row {
        anchors.fill: parent
        spacing: 8

        // Sidebar navigation
        Column {
            id: sidebar
            width: 48
            height: parent.height
            spacing: 8

            Repeater {
                model: [
                    { icon: Icons.wifiHigh, section: 0 },
                    { icon: Icons.bluetooth, section: 1 },
                    { icon: Icons.speakerHigh, section: 2 }
                ]

                delegate: Button {
                    id: sidebarButton
                    required property var modelData
                    required property int index

                    width: sidebar.width
                    height: width
                    flat: true

                    background: StyledRect {
                        variant: root.currentSection === sidebarButton.modelData.section ? "primary" : "common"
                        radius: Styling.radius(4)

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    contentItem: Text {
                        text: sidebarButton.modelData.icon
                        font.family: Icons.font
                        font.pixelSize: 20
                        color: root.currentSection === sidebarButton.modelData.section 
                            ? Config.resolveColor(Config.theme.srPrimary.itemColor) 
                            : Colors.overBackground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    onClicked: root.currentSection = sidebarButton.modelData.section
                }
            }
        }

        // Separator
        Separator {
            width: 2
            height: parent.height
            vert: true
        }

        // Content area
        StackLayout {
            id: contentStack
            width: parent.width - sidebar.width - 10  // 8 spacing + 2 separator
            height: parent.height
            currentIndex: root.currentSection

            WifiPanel {}
            BluetoothPanel {}
            AudioMixerPanel {}
        }
    }
}
