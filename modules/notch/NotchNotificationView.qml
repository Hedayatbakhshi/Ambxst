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
    implicitHeight: hovered ? mainColumn.implicitHeight - 16 : mainColumn.implicitHeight

    property var currentNotification: {
        return (Notifications.popupList.length > currentIndex && currentIndex >= 0) ? Notifications.popupList[currentIndex] : (Notifications.popupList.length > 0 ? Notifications.popupList[0] : null);
    }
    property bool notchHovered: false
    property bool hovered: notchHovered || mouseArea.containsMouse

    // Índice actual para navegación
    property int currentIndex: 0
    // Contador para detectar cuando se añaden nuevas notificaciones
    property int lastNotificationCount: 0

    // Timer para forzar actualización del timestamp cada minuto
    Timer {
        id: timestampUpdateTimer
        interval: 60000 // 1 minuto
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            // Forzar actualización recreando el componente
            if (currentNotification && notificationStack.currentItem) {
                notificationStack.navigateToNotification(currentIndex, StackView.ReplaceTransition);
            }
        }
    }

    // MouseArea para detectar hover en toda el área y navegación con scroll
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 1000  // Poner encima de todos los elementos

        // Navegación con rueda del ratón cuando hay múltiples notificaciones
        onWheel: {
            if (Notifications.popupList.length > 1) {
                if (wheel.angleDelta.y > 0) {
                    // Scroll hacia arriba - ir a la notificación anterior
                    navigateToPrevious();
                } else {
                    // Scroll hacia abajo - ir a la siguiente notificación
                    navigateToNext();
                }
            }
        }
    }

    // Funciones de navegación
    function navigateToNext() {
        if (Notifications.popupList.length > 1) {
            const nextIndex = (currentIndex + 1) % Notifications.popupList.length;
            notificationStack.navigateToNotification(nextIndex);
        }
    }

    function navigateToPrevious() {
        if (Notifications.popupList.length > 1) {
            const prevIndex = currentIndex > 0 ? currentIndex - 1 : Notifications.popupList.length - 1;
            notificationStack.navigateToNotification(prevIndex);
        }
    }

    function updateNotificationStack() {
        if (Notifications.popupList.length > 0 && notificationStack) {
            notificationStack.navigateToNotification(currentIndex);
        }
    }

    // Manejo del hover - pausa/reanuda timers de timeout de todas las notificaciones
    onHoveredChanged: {
        if (hovered) {
            // Pausar todos los timers de notificaciones activas
            Notifications.pauseAllTimers();
        } else {
            // Reanudar todos los timers de notificaciones activas
            Notifications.resumeAllTimers();
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
                            duration: Config.animDuration
                        }
                    }

                    MouseArea {
                        id: dashboardAccessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        // Ya no necesita gestionar anyButtonHovered porque mouseArea principal maneja el hover

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
                                duration: Config.animDuration
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
            implicitHeight: notificationStack.implicitHeight
            height: implicitHeight
            spacing: 8

            // Área principal de notificaciones (StackView)
            Item {
                id: notificationArea
                Layout.fillWidth: true
                Layout.preferredHeight: notificationStack.implicitHeight

                StackView {
                    id: notificationStack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    implicitHeight: currentItem ? currentItem.implicitHeight : 0
                    height: implicitHeight
                    clip: true

                    // Crear componente inicial
                    Component.onCompleted: {
                        if (Notifications.popupList.length > 0) {
                            push(notificationComponent, {
                                "notification": Notifications.popupList[0]
                            });
                        }
                    }

                    // Función para navegar a una notificación específica
                    function navigateToNotification(index, forceDirection = null) {
                        if (index >= 0 && index < Notifications.popupList.length) {
                            const newNotification = Notifications.popupList[index];
                            const currentItem = notificationStack.currentItem;

                            if (!currentItem || !currentItem.notification || currentItem.notification.id !== newNotification.id) {

                                // Determinar dirección de la transición
                                let direction;
                                if (forceDirection !== null) {
                                    direction = forceDirection;
                                } else {
                                    direction = index > root.currentIndex ? StackView.PushTransition : StackView.PopTransition;
                                }

                                // Usar replace para evitar acumulación en el stack
                                replace(notificationComponent, {
                                    "notification": newNotification
                                }, direction);

                                root.currentIndex = index;
                            }
                        }
                    }

                    // Actualizar cuando cambie la lista de notificaciones
                    Connections {
                        target: Notifications
                        function onPopupListChanged() {
                            if (Notifications.popupList.length === 0) {
                                notificationStack.clear();
                                root.currentIndex = 0;
                                root.lastNotificationCount = 0;
                                return;
                            }

                            // Si no hay items en el stack, añadir la primera notificación
                            if (notificationStack.depth === 0) {
                                notificationStack.push(notificationComponent, {
                                    "notification": Notifications.popupList[0]
                                });
                                root.currentIndex = 0;
                                root.lastNotificationCount = Notifications.popupList.length;
                                return;
                            }

                            // Detectar nueva notificación: si la lista creció, ir a la más reciente (última)
                            // Solo si no hay hover para no interrumpir la interacción del usuario
                            if (Notifications.popupList.length > root.lastNotificationCount && !root.hovered) {
                                const newIndex = Notifications.popupList.length - 1;
                                root.currentIndex = newIndex;
                                notificationStack.navigateToNotification(newIndex, StackView.PushTransition);
                                root.lastNotificationCount = Notifications.popupList.length;
                                return;
                            }

                            // Actualizar el contador
                            root.lastNotificationCount = Notifications.popupList.length;

                            // Manejar eliminación de notificaciones
                            // Obtener la notificación actual antes del ajuste
                            const currentNotificationId = notificationStack.currentItem?.notification?.id;
                            const oldIndex = root.currentIndex;

                            // Ajustar el índice si es necesario
                            if (root.currentIndex >= Notifications.popupList.length) {
                                root.currentIndex = Math.max(0, Notifications.popupList.length - 1);
                            }

                            // Determinar si una notificación fue eliminada y calcular la dirección apropiada
                            const newNotification = Notifications.popupList[root.currentIndex];
                            let forceDirection = null;

                            // Si la notificación actual cambió, significa que se eliminó una
                            if (currentNotificationId && newNotification && currentNotificationId !== newNotification.id) {
                                // Si estábamos viendo una notificación posterior y ahora vemos una anterior,
                                // significa que se eliminó una notificación antes de la actual -> transición hacia abajo
                                if (oldIndex > 0 && root.currentIndex < oldIndex) {
                                    forceDirection = StackView.PopTransition; // Aparece desde arriba (hacia abajo)
                                } else
                                // Si se eliminó la notificación actual y vamos a la siguiente
                                if (root.currentIndex === oldIndex) {
                                    forceDirection = StackView.PushTransition; // Aparece desde abajo (hacia arriba)
                                }
                            }

                            // Navegar a la notificación actual con la dirección calculada
                            notificationStack.navigateToNotification(root.currentIndex, forceDirection);
                        }
                    }

                    // Transiciones verticales - igual que el launcher
                    pushEnter: Transition {
                        PropertyAnimation {
                            property: "y"
                            from: notificationStack.height
                            to: 0
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                        PropertyAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    pushExit: Transition {
                        PropertyAnimation {
                            property: "y"
                            from: 0
                            to: -notificationStack.height
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                        PropertyAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    popEnter: Transition {
                        PropertyAnimation {
                            property: "y"
                            from: -notificationStack.height
                            to: 0
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                        PropertyAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    popExit: Transition {
                        PropertyAnimation {
                            property: "y"
                            from: 0
                            to: notificationStack.height
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                        PropertyAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                // Componente de notificación reutilizable
                Component {
                    id: notificationComponent

                    Item {
                        width: notificationStack.width
                        implicitHeight: notificationContent.implicitHeight

                        property var notification

                        Column {
                            id: notificationContent
                            width: parent.width
                            spacing: hovered ? 8 : 0

                            // Contenido principal de la notificación
                            RowLayout {
                                id: mainContentRow
                                width: parent.width
                                implicitHeight: Math.max(hovered ? 48 : 32, textColumn.implicitHeight)
                                height: implicitHeight
                                spacing: 8

                                // Contenido principal
                                RowLayout {
                                    Layout.fillWidth: true
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
                                        appIcon: notification ? (notification.cachedAppIcon || notification.appIcon) : ""
                                        image: notification ? (notification.cachedImage || notification.image) : ""
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
                                                width: parent.width - (timestampText.visible ? timestampText.implicitWidth + parent.spacing : 0)
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
                                                    font.pixelSize: Config.theme.fontSize
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
                                            font.weight: Font.Normal
                                            color: Colors.adapter.overBackground
                                            wrapMode: hovered ? Text.Wrap : Text.NoWrap
                                            maximumLineCount: hovered ? 3 : 1
                                            elide: Text.ElideRight
                                            visible: hovered || text !== ""
                                        }
                                    }
                                }

                                // Botón de descartar
                                Item {
                                    Layout.preferredWidth: hovered ? 32 : 0
                                    Layout.preferredHeight: hovered ? 32 : 0
                                    Layout.alignment: Qt.AlignTop

                                    Loader {
                                        anchors.fill: parent
                                        active: hovered

                                        sourceComponent: Button {
                                            id: dismissButton
                                            anchors.fill: parent
                                            hoverEnabled: true

                                            background: Rectangle {
                                                color: parent.pressed ? Colors.adapter.error : (parent.hovered ? Colors.surfaceBright : Colors.surface)
                                                radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Config.animDuration
                                                    }
                                                }
                                            }

                                            contentItem: Text {
                                                text: Icons.cancel
                                                font.family: Icons.font
                                                font.pixelSize: 20
                                                color: parent.pressed ? Colors.adapter.overError : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.error)
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Config.animDuration
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
                            }

                            // Botones de acción (solo visible con hover)
                            Item {
                                id: actionButtonsRow
                                width: parent.width
                                implicitHeight: (hovered && notification && notification.actions.length > 0 && !notification.isCached) ? 32 : 0
                                height: implicitHeight
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

                                            // Ya no necesita gestionar anyButtonHovered porque mouseArea principal maneja el hover

                                            background: Rectangle {
                                                color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : Colors.surface)
                                                radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Config.animDuration
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
                                                        duration: Config.animDuration
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

            // Indicadores de navegación (solo visible con múltiples notificaciones)
            Item {
                id: pageIndicators
                Layout.preferredWidth: (Notifications.popupList.length > 1) ? 8 : 0
                Layout.preferredHeight: 32 // Altura fija para 3 puntos + spacing
                Layout.alignment: Qt.AlignVCenter
                visible: Notifications.popupList.length > 1
                clip: true

                Column {
                    id: dotsColumn
                    width: parent.width
                    spacing: 4

                    // Posición Y animada para el efecto de scroll
                    y: {
                        if (Notifications.popupList.length <= 3)
                            return 0;

                        const totalNotifications = Notifications.popupList.length;
                        const dotHeight = 8 + 4; // altura del punto + spacing
                        const maxY = -(totalNotifications - 3) * dotHeight;
                        const currentIndex = root.currentIndex;

                        // Calcular posición basada en el índice actual
                        let targetY = 0;
                        if (currentIndex >= 1 && currentIndex < totalNotifications - 1) {
                            // Centrar en el punto actual (mantener en posición media)
                            targetY = -(currentIndex - 1) * dotHeight;
                        } else if (currentIndex >= totalNotifications - 1) {
                            // Al final, mostrar los últimos 3
                            targetY = maxY;
                        }

                        return Math.max(maxY, Math.min(0, targetY));
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: Notifications.popupList.length

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: index === root.currentIndex ? Colors.adapter.primary : Colors.surfaceBright

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            // Animación de escala para el punto activo
                            scale: index === root.currentIndex ? 1.0 : 0.5

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
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
