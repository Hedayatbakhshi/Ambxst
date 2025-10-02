import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.notifications
import qs.config

Rectangle {
    color: "transparent"
    implicitWidth: 600
    implicitHeight: 300

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left panel - Widgets content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.surface
            radius: Config.roundness > 4 ? Config.roundness + 4 : 0

            Text {
                anchors.centerIn: parent
                text: "Widgets"
                color: Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: 16
                font.weight: Font.Medium
            }
        }

        // Right panel - Notification history
        ClippingRectangle {
            Layout.preferredWidth: 290
            Layout.fillHeight: true
            color: Colors.surface
            radius: Config.roundness > 4 ? Config.roundness + 4 : 0
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4

                ListView {
                    id: notificationList
                    spacing: 4
                    model: Notifications.appNameList

                    delegate: NotificationGroup {
                        required property int index
                        required property string modelData
                        width: notificationList.width
                        notificationGroup: Notifications.groupsByAppName[modelData]
                        expanded: false  // Collapsed by default for history view
                        popup: false
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: Notifications.appNameList.length === 0

                Text {
                    text: Icons.bell
                    font.family: Icons.font
                    font.pixelSize: 64
                    color: Colors.surfaceBright
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
