import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.modules.components
import qs.modules.notifications
import qs.config
import "../notifications/notification_utils.js" as NotificationUtils

Item {
    id: root

    implicitWidth: hovered ? 420 : 290
    implicitHeight: mainColumn.implicitHeight

    property var currentNotification: {
        const currentIndex = notificationListView ? notificationListView.currentIndex : 0;
        return (Notifications.popupList.length > currentIndex && currentIndex >= 0) ? 
               Notifications.popupList[currentIndex] : 
               (Notifications.popupList.length > 0 ? Notifications.popupList[0] : null);
    }
    property bool notchHovered: false
    property bool hovered: notchHovered || mouseArea.containsMouse || anyButtonHovered
    property bool anyButtonHovered: false

    // Timer para actualizar el timestamp cada minuto
    Timer {
        id: timestampUpdateTimer
        interval: 60000 // 1 minuto
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            // Forzar actualización del timestamp
            if (timestampText && currentNotification) {
                timestampText.text = NotificationUtils.getFriendlyNotifTimeString(currentNotification.time);
            }
        }
    }

    // MouseArea para detectar hover en toda el área y navegación con scroll
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1
        
        // Navegación con rueda del ratón cuando hay múltiples notificaciones
        onWheel: {
            if (Notifications.popupList.length > 1 && notificationListView) {
                if (wheel.angleDelta.y > 0) {
                    // Scroll hacia arriba - ir a la notificación anterior
                    notificationListView.decrementCurrentIndex();
                } else {
                    // Scroll hacia abajo - ir a la siguiente notificación
                    notificationListView.incrementCurrentIndex();
                }
            }
        }
    }

    // Manejo del hover - pausa/reanuda timers de timeout de notificación
    onHoveredChanged: {
        if (hovered) {
            if (currentNotification) {
                Notifications.pauseGroupTimers(currentNotification.appName);
            }
        } else {
            if (currentNotification) {
                Notifications.resumeGroupTimers(currentNotification.appName);
            }
        }
    }

    // Nueva estructura de 3 filas
    Column {
        id: mainColumn
        anchors.fill: parent
        spacing: hovered ? 8 : 0

        // FILA 1: Controles superiores (solo visible con hover)
        Item {
            id: topControlsRow
            width: parent.width
            height: hovered ? 24 : 0
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 8

                // Botón del dashboard (solo)
                Rectangle {
                    id: dashboardAccess
                    Layout.preferredWidth: 250
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    color: dashboardAccessMouse.containsMouse ? Colors.surfaceBright : Colors.surface
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: Config.roundness
                    bottomRightRadius: Config.roundness

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                        }
                    }

                    MouseArea {
                        id: dashboardAccessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onHoveredChanged: {
                            root.anyButtonHovered = containsMouse;
                        }

                        onClicked: {
                            GlobalStates.dashboardCurrentTab = 0;
                            Visibilities.setActiveModule("dashboard");
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Icons.caretDoubleDown
                        font.family: Icons.font
                        font.pixelSize: 16
                        color: dashboardAccessMouse.containsMouse ? Colors.adapter.overBackground : Colors.adapter.surfaceBright

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }
                }
            }
        }

        // ÁREA DE CONTENIDO CON SCROLL: Combina fila 2 (contenido) y fila 3 (botones de acción)
        RowLayout {
            id: contentWithScrollArea
            width: parent.width
            height: {
                // Altura base para el contenido principal
                let baseHeight = Math.max(hovered ? 48 : 32, 48); // mínimo para iconos y texto
                
                // Si estamos en hover y la notificación actual tiene acciones, añadir espacio para botones
                if (hovered && currentNotification && currentNotification.actions.length > 0) {
                    baseHeight += 32 + 8; // altura de botones + spacing
                }
                
                return baseHeight;
            }
            spacing: 4

            // ScrollBar (solo visible con múltiples notificaciones)
            Rectangle {
                id: scrollBarContainer
                Layout.preferredWidth: (Notifications.popupList.length > 1) ? 4 : 0
                Layout.fillHeight: true
                color: "transparent"
                visible: Notifications.popupList.length > 1

                Rectangle {
                    id: scrollBar
                    width: 4
                    height: parent.height / Math.max(1, Notifications.popupList.length) // altura proporcional al número de notificaciones
                    color: Colors.adapter.outline
                    radius: 2
                    opacity: 0.6
                    
                    // Posición del scroll basada en la notificación actual
                    y: {
                        if (Notifications.popupList.length <= 1) return 0;
                        const currentIndex = currentNotification ? Notifications.popupList.findIndex(n => n.id === currentNotification.id) : 0;
                        const maxY = parent.height - height;
                        return (currentIndex / Math.max(1, Notifications.popupList.length - 1)) * maxY;
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Config.animDuration / 2
                        }
                    }
                }
            }

            // Área principal de notificaciones (ListView)
            Item {
                id: notificationArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ListView {
                    id: notificationListView
                    anchors.fill: parent
                    model: Notifications.popupList
                    orientation: ListView.Horizontal
                    snapMode: ListView.SnapOneItem
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    interactive: Notifications.popupList.length > 1
                    clip: true
                    
                    // Ir a la notificación actual cuando cambie
                    currentIndex: {
                        if (!currentNotification || Notifications.popupList.length === 0) return 0;
                        return Notifications.popupList.findIndex(n => n.id === currentNotification.id);
                    }
                    
                    // Actualizar la notificación actual cuando cambie el índice
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < Notifications.popupList.length) {
                            const newNotification = Notifications.popupList[currentIndex];
                            if (newNotification && newNotification.id !== (currentNotification?.id)) {
                                // Pausar timers de la notificación anterior
                                if (currentNotification) {
                                    Notifications.resumeGroupTimers(currentNotification.appName);
                                }
                                // Pausar timers de la nueva notificación si estamos en hover
                                if (hovered) {
                                    Notifications.pauseGroupTimers(newNotification.appName);
                                }
                            }
                        }
                    }

                    delegate: Item {
                        width: notificationListView.width
                        height: notificationListView.height
                        
                        property var notification: modelData
                        
                        Column {
                            anchors.fill: parent
                            spacing: hovered ? 8 : 0
                            
                            // Contenido principal de la notificación
                            RowLayout {
                                id: mainContentRow
                                width: parent.width
                                height: Math.max(hovered ? 48 : 32, textColumn.implicitHeight)
                                spacing: 8
                                
                                // App icon
                                NotificationAppIcon {
                                    id: appIcon
                                    Layout.preferredWidth: hovered ? 48 : 32
                                    Layout.preferredHeight: hovered ? 48 : 32
                                    Layout.alignment: Qt.AlignTop
                                    size: hovered ? 48 : 32
                                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                                    visible: notification && (notification.appIcon !== "" || notification.image !== "")
                                    appIcon: notification ? notification.appIcon : ""
                                    image: notification ? notification.image : ""
                                    summary: notification ? notification.summary : ""
                                    urgency: notification ? notification.urgency : NotificationUrgency.Normal
                                }

                                // Textos de la notificación
                                Column {
                                    id: textColumn
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: hovered ? 4 : 0

                                    // Fila del summary, app name y timestamp
                                    Row {
                                        width: parent.width
                                        spacing: 4

                                        // Contenedor izquierdo para summary y app name
                                        Row {
                                            width: parent.width - timestampText.width - parent.spacing
                                            spacing: 4

                                            Text {
                                                id: summaryText
                                                width: Math.min(implicitWidth, parent.width - (appNameText.visible ? appNameText.width + parent.spacing : 0))
                                                text: notification ? notification.summary : ""
                                                font.family: Config.theme.font
                                                font.pixelSize: Config.theme.fontSize
                                                font.weight: Font.Bold
                                                color: Colors.adapter.primary
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                wrapMode: Text.NoWrap
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            Text {
                                                id: appNameText
                                                width: Math.min(implicitWidth, Math.max(60, parent.width * 0.3))
                                                text: notification ? "• " + notification.appName : ""
                                                font.family: Config.theme.font
                                                font.pixelSize: Config.theme.fontSize - 1
                                                font.weight: Font.Bold
                                                color: Colors.adapter.outline
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                wrapMode: Text.NoWrap
                                                verticalAlignment: Text.AlignVCenter
                                                visible: text !== ""
                                            }
                                        }

                                        // Timestamp a la derecha
                                        Text {
                                            id: timestampText
                                            text: notification ? NotificationUtils.getFriendlyNotifTimeString(notification.time) : ""
                                            font.family: Config.theme.font
                                            font.pixelSize: Config.theme.fontSize
                                            font.weight: Font.Bold
                                            color: Colors.adapter.outline
                                            verticalAlignment: Text.AlignVCenter
                                            visible: text !== ""
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: notification ? processNotificationBody(notification.body, notification.appName) : ""
                                        font.family: Config.theme.font
                                        font.pixelSize: Config.theme.fontSize
                                        font.weight: Font.Bold
                                        color: Colors.adapter.overBackground
                                        wrapMode: hovered ? Text.Wrap : Text.NoWrap
                                        maximumLineCount: hovered ? 3 : 1
                                        elide: Text.ElideRight
                                        visible: hovered || text !== ""
                                    }
                                }

                                // Columna de botones (solo visible con hover)
                                Column {
                                    Layout.preferredWidth: hovered ? 32 : 0
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 4
                                    visible: hovered
                                    clip: true

                                    // Botón de descartar
                                    Button {
                                        width: 32
                                        height: 32
                                        hoverEnabled: true

                                        onHoveredChanged: {
                                            root.anyButtonHovered = hovered;
                                        }

                                        background: Rectangle {
                                            color: parent.pressed ? Colors.adapter.error : (parent.hovered ? Colors.surfaceBright : Colors.surface)
                                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                }
                                            }
                                        }

                                        contentItem: Text {
                                            text: Icons.cancel
                                            font.family: Icons.font
                                            font.pixelSize: 16
                                            color: parent.pressed ? Colors.adapter.overError : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.error)
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                }
                                            }
                                        }

                                        onClicked: {
                                            if (notification) {
                                                Notifications.discardNotification(notification.id);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Botones de acción (solo visible con hover)
                            Item {
                                id: actionButtonsRow
                                width: parent.width
                                height: (hovered && notification && notification.actions.length > 0) ? 32 : 0
                                clip: true

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    Repeater {
                                        model: notification ? notification.actions : []

                                        Button {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32

                                            text: modelData.text
                                            font.family: Config.theme.font
                                            font.pixelSize: Config.theme.fontSize
                                            font.weight: Font.Bold
                                            hoverEnabled: true

                                            onHoveredChanged: {
                                                root.anyButtonHovered = hovered;
                                            }

                                            background: Rectangle {
                                                color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : Colors.surface)
                                                radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Config.animDuration / 2
                                                    }
                                                }
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font: parent.font
                                                color: parent.pressed ? Colors.adapter.overPrimary : (parent.hovered ? Colors.adapter.primary : Colors.adapter.overBackground)
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Config.animDuration / 2
                                                    }
                                                }
                                            }

                                            onClicked: {
                                                Notifications.attemptInvokeAction(notification.id, modelData.identifier);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Función auxiliar para procesar el cuerpo de la notificación
    function processNotificationBody(body, appName) {
        if (!body)
            return "";

        let processedBody = body;

        // Limpiar notificaciones de navegadores basados en Chromium
        if (appName) {
            const lowerApp = appName.toLowerCase();
            const chromiumBrowsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"];

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n');

                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n');
                }
            }
        }

        // No reemplazar saltos de línea con espacios
        return processedBody;
    }
}
