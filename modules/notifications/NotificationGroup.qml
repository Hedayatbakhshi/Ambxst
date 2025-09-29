import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.config
import "./NotificationAnimation.qml"
import "./NotificationSummaryGroup.qml"
import "./notification_utils.js" as NotificationUtils

Item {
    id: root
    property var notificationGroup
    property var notifications: notificationGroup?.notifications ?? []
    property int notificationCount: notifications.length
    property bool multipleNotifications: notificationCount > 1
    property var validNotifications: notifications.filter(n => n != null && n.summary != null)

    property var groupedNotifications: {
        const groups = {};
        root.validNotifications.forEach(notif => {
            const summary = notif.summary || "";
            if (!groups[summary]) {
                groups[summary] = [];
            }
            groups[summary].push(notif);
        });
        return Object.values(groups).map(notifications => ({
                    summary: notifications[0].summary,
                    notifications: notifications
                }));
    }

    onNotificationGroupChanged: {}

    onValidNotificationsChanged: {}
    property bool expanded: false
    property bool popup: false
    property real padding: 8
    implicitHeight: background.implicitHeight

    property real dragConfirmThreshold: 70
    property real dismissOvershoot: 20
    property var qmlParent: root.parent.parent
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - (index ?? 0))
    property real xOffset: dragIndexDiff == 0 ? Math.max(0, parentDragDistance) : parentDragDistance > dragConfirmThreshold ? 0 : dragIndexDiff == 1 ? Math.max(0, parentDragDistance * 0.3) : dragIndexDiff == 2 ? Math.max(0, parentDragDistance * 0.1) : 0

    function destroyWithAnimation() {
        if (root.qmlParent && root.qmlParent.resetDrag)
            root.qmlParent.resetDrag();
        background.anchors.leftMargin = background.anchors.leftMargin;
        notificationAnimation.startDestroy();
    }

    NotificationAnimation {
        id: notificationAnimation
        targetItem: background
        dismissOvershoot: root.dismissOvershoot
        parentWidth: root.width

        onDestroyFinished: {
            root.notifications.forEach(notif => {
                Qt.callLater(() => {
                    Notifications.discardNotification(notif.id);
                });
            });
        }
    }

    function toggleExpanded() {
        root.expanded = !root.expanded;
    }

    // Escuchar cuando las notificaciones van a hacer timeout
    Connections {
        target: Notifications
        function onTimeoutWithAnimation(id) {
            // Verificar si la notificación que va a hacer timeout pertenece a este grupo
            const notifExists = root.notifications.some(notif => notif.id === id);
            if (notifExists && root.popup) {
                root.destroyWithAnimation();
            }
        }
    }

    // HoverHandler dedicado para pausar/reanudar timers
    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hovered) {
                if (notificationGroup?.appName) {
                    Notifications.pauseGroupTimers(notificationGroup.appName);
                }
            } else {
                if (notificationGroup?.appName) {
                    Notifications.resumeGroupTimers(notificationGroup.appName);
                }
            }
        }
    }

    MouseArea {
        id: dragManager
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.toggleExpanded();
            else if (mouse.button === Qt.MiddleButton)
                root.destroyWithAnimation();
        }

        property bool dragging: false
        property real dragDiffX: 0

        function resetDrag() {
            dragging = false;
            dragDiffX = 0;
        }
    }

    ClippingRectangle {
        id: background
        anchors.left: parent.left
        width: parent.width
        color: Colors.background
        radius: Config.roundness > 0 ? Config.roundness : 0
        border.color: Colors.surfaceContainerHigh
        border.width: 0
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        clip: true
        implicitHeight: expanded ? row.implicitHeight + padding * 2 : Math.max(56 + padding * 2, row.implicitHeight + padding * 2)

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutBack
            }
        }

        RowLayout {
            id: row
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding
            spacing: root.padding / 2

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.notificationCount === 1 ? 0 : (root.expanded ? 8 : 4)

                Behavior on spacing {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: topRow
                    Layout.fillWidth: true
                    property real fontSize: Config.theme.fontSize
                    property bool showAppName: root.multipleNotifications
                    implicitHeight: root.multipleNotifications ? Math.max(topTextRow.implicitHeight, expandButton.implicitHeight) : 0
                    visible: root.multipleNotifications

                    RowLayout {
                        id: topTextRow
                        anchors.left: parent.left
                        anchors.right: expandButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        visible: root.multipleNotifications

                        // Small app icon similar to NotificationAppIcon's overlay
                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: (notificationGroup && notificationGroup.appIcon !== "") ? "image://icon/" + notificationGroup.appIcon : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: notificationGroup && notificationGroup.appIcon !== ""
                        }
                        Text {
                            text: Icons.info
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: topRow.showAppName ? Colors.adapter.outline : Colors.adapter.primary
                            visible: !(notificationGroup && notificationGroup.appIcon !== "")
                        }

                        Text {
                            id: appName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: (topRow.showAppName ? notificationGroup?.appName : (root.validNotifications.length > 0 ? root.validNotifications[0]?.summary ?? "" : "")) || ""
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            font.weight: Font.Bold
                            color: topRow.showAppName ? Colors.adapter.outline : Colors.adapter.primary
                        }
                        Text {
                            id: timeText
                            Layout.rightMargin: 10
                            horizontalAlignment: Text.AlignLeft
                            text: NotificationUtils.getFriendlyNotifTimeString(notificationGroup?.time)
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            color: Colors.adapter.overBackground
                        }
                    }
                    NotificationGroupExpandButton {
                        id: expandButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        count: root.notificationCount
                        expanded: root.expanded
                        fontSize: topRow.fontSize
                        visible: root.multipleNotifications
                        onClicked: {
                            root.toggleExpanded();
                        }
                    }
                }

                ListView {
                    id: notificationsColumn
                    implicitHeight: contentHeight
                    Layout.fillWidth: true
                    spacing: root.expanded ? 4 : 0
                    interactive: false

                    Behavior on spacing {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    model: expanded ? root.groupedNotifications : root.groupedNotifications.slice(0, 2)

                    delegate: NotificationSummaryGroup {
                        required property int index
                        required property var modelData
                        notifications: modelData.notifications
                        expanded: root.expanded
                        onlyNotification: (modelData.notifications.length === 1)
                        opacity: (!root.expanded && index == 1 && root.groupedNotifications.length > 2) ? 0.5 : 1
                        visible: root.expanded || (index < 2)
                        anchors.left: parent?.left
                        anchors.right: parent?.right

                        Component.onCompleted: {}

                        onDestroyRequested: {
                            // Destruir todo el grupo si es el único o si hay múltiples
                            root.destroyWithAnimation();
                        }
                    }
                }
            }
        }
    }
}
