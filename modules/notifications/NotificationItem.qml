import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.config
import "./NotificationAnimation.qml"

Item {
    id: root
    property var notificationObject
    property bool expanded: false
    property real fontSize: 12
    property real padding: 8

    property real dragConfirmThreshold: 70
    property real dismissOvershoot: 20
    property var qmlParent: root?.parent?.parent
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - (index ?? 0))
    property real xOffset: dragIndexDiff == 0 ? Math.max(0, parentDragDistance) : parentDragDistance > dragConfirmThreshold ? 0 : dragIndexDiff == 1 ? Math.max(0, parentDragDistance * 0.3) : dragIndexDiff == 2 ? Math.max(0, parentDragDistance * 0.1) : 0

    signal destroyRequested

    implicitHeight: background.implicitHeight

    function processNotificationBody(body) {
        // Limpiar HTML básico y saltos de línea para vista simple
        return body.replace(/<[^>]*>/g, "").replace(/\n/g, " ");
    }

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
            Notifications.discardNotification(notificationObject.id);
        }
    }

    MouseArea {
        id: dragManager
        anchors.fill: root
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool dragging: false
        property real dragDiffX: 0

        onPressed: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
        }

        function resetDrag() {
            dragging = false;
            dragDiffX = 0;
        }
    }

    Rectangle {
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: 8
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        color: (notificationObject.urgency == NotificationUrgency.Critical) ? Colors.adapter.error : Colors.surfaceContainerLow

        implicitHeight: contentColumn.implicitHeight + padding * 2

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 8

            // Título de la notificación
            Text {
                id: summaryText
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Colors.adapter.primary
                elide: Text.ElideRight
                text: root.notificationObject.summary || ""
                visible: text.length > 0
            }

            // Contenido de la notificación
            Text {
                id: bodyText
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: root.fontSize
                color: Colors.adapter.overBackground
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: processNotificationBody(notificationObject.body || "")
                visible: text.length > 0
            }

            // Botones de acción si existen
            RowLayout {
                Layout.fillWidth: true
                visible: notificationObject.actions.length > 0

                Repeater {
                    model: notificationObject.actions
                    Button {
                        Layout.fillWidth: true
                        text: modelData.text
                        onClicked: {
                            Notifications.attemptInvokeAction(notificationObject.id, modelData.identifier);
                        }
                    }
                }
            }
        }
    }
}
