import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.notifications
import qs.modules.corners
import qs.config

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Colors.surface
                topLeftRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
                topRightRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
                Text {
                    anchors.centerIn: parent
                    text: "Notifications"
                    font.family: Config.defaultFont
                    font.pixelSize: Config.theme.fontSize
                    font.weight: Font.Bold
                    color: Colors.overSurface
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                id: dndToggle
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.bottomMargin: 4
                radius: Notifications.silent ? Config.roundness + 4 : Config.roundness
                color: Notifications.silent ? Colors.primary : Colors.surface

                Text {
                    anchors.centerIn: parent
                    text: Notifications.silent ? Icons.bellZ : Icons.bell
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: Notifications.silent ? Colors.overPrimary : Colors.overSurface
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.silent = !Notifications.silent
                }
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.bottomMargin: 4
                radius: Config.roundness
                color: Colors.surface

                Text {
                    anchors.centerIn: parent
                    text: Icons.broom
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: Colors.overSurface
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.discardAllNotifications()
                }
            }
        }

        PaneRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.surface
            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            topLeftRadius: 0
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: notificationList.contentHeight
                clip: true

                ListView {
                    id: notificationList
                    width: parent.width
                    height: contentHeight
                    spacing: 4
                    model: Notifications.appNameList
                    interactive: false
                    cacheBuffer: 200
                    reuseItems: true

                    delegate: NotificationGroup {
                        required property int index
                        required property string modelData
                        width: notificationList.width
                        notificationGroup: Notifications.groupsByAppName[modelData]
                        expanded: false
                        popup: false
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: Notifications.appNameList.length === 0

                Text {
                    text: Icons.bellZ
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 64
                    color: Colors.surfaceBright
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
