import QtQuick
import qs.modules.theme
import qs.modules.services
import qs.modules.notch
import qs.config

Item {
    id: root

    implicitWidth: Math.max(mainRow.width, hasActiveNotifications ? notificationView.implicitWidth + 16 : 0)
    implicitHeight: mainRow.height + (hasActiveNotifications ? (notificationHoverHandler.hovered ? notificationView.implicitHeight + 32 : notificationView.implicitHeight + 16) : 0)

    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0

    HoverHandler {
        id: notificationHoverHandler
        enabled: hasActiveNotifications
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Row {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            UserInfo {
                id: userInfo
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: separator1
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                color: Colors.outline
                font.pixelSize: Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: true
            }

            Rectangle {
                id: placeholder
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                height: 32
                radius: Math.max(0, Config.roundness - 4)
                color: Colors.surfaceBright
            }

            Text {
                id: separator2
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                color: Colors.outline
                font.pixelSize: Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: true
            }

            NotificationIndicator {
                id: notifIndicator
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: hasActiveNotifications ? (notificationHoverHandler.hovered ? notificationView.implicitHeight + 32 : notificationView.implicitHeight + 16) : 0
            clip: false
            visible: height > 0

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            NotchNotificationView {
                id: notificationView
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: notificationHoverHandler.hovered ? 24 : 24
                anchors.rightMargin: notificationHoverHandler.hovered ? 24 : 24
                anchors.bottomMargin: 8
                opacity: hasActiveNotifications ? 1 : 0
                notchHovered: notificationHoverHandler.hovered

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on anchors.leftMargin {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on anchors.rightMargin {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }
}
