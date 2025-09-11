import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Rectangle {
    id: root
    focus: true

    Keys.onEscapePressed: {
        root.itemSelected();
    }

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property int selectedImageIndex: -1
    property var imageItems: []
    property var textItems: []
    property bool isImageSectionFocused: false
    property bool hasNavigatedFromSearch: false
    property bool clearButtonFocused: false
    property bool clearButtonConfirmState: false

    // Delete mode state
    property bool deleteMode: false
    property string itemToDelete: ""
    property int originalSelectedIndex: -1
    property int deleteButtonIndex: 0 // 0 = cancel, 1 = confirm

    // Image delete mode state
    property bool imageDeleteMode: false
    property string imageToDelete: ""
    property int originalSelectedImageIndex: -1
    property int imageDeleteButtonIndex: 0 // 0 = cancel, 1 = trash

    property int imgSize: 78

    signal itemSelected

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && textResultsList.count > 0) {
            textResultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredItems();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        selectedImageIndex = -1;
        isImageSectionFocused = false;
        hasNavigatedFromSearch = false;
        clearButtonFocused = false;
        clearButtonConfirmState = false;
        searchInput.focusInput();
        updateFilteredItems();
    }

    function resetClearButton() {
        clearButtonConfirmState = false;
    }

    function cancelDeleteModeFromExternal() {
        if (deleteMode) {
            console.log("DEBUG: Canceling delete mode from external source (tab change)");
            cancelDeleteMode();
        }
        if (imageDeleteMode) {
            console.log("DEBUG: Canceling image delete mode from external source (tab change)");
            cancelImageDeleteMode();
        }
    }

    function enterDeleteMode(itemId) {
        console.log("DEBUG: Entering delete mode for item:", itemId);
        originalSelectedIndex = selectedIndex; // Store the current index
        deleteMode = true;
        itemToDelete = itemId;
        deleteButtonIndex = 0; // Start with cancel button selected
        // Quitar focus del SearchInput para que el componente root pueda capturar teclas
        root.forceActiveFocus();
    }

    function enterImageDeleteMode(imageId) {
        console.log("DEBUG: Entering image delete mode for image:", imageId);
        originalSelectedImageIndex = selectedImageIndex; // Store the current index
        imageDeleteMode = true;
        imageToDelete = imageId;
        imageDeleteButtonIndex = 0; // Start with cancel button selected
        // Quitar focus del SearchInput para que el componente root pueda capturar teclas
        root.forceActiveFocus();
    }

    function cancelDeleteMode() {
        console.log("DEBUG: Canceling delete mode");
        deleteMode = false;
        itemToDelete = "";
        deleteButtonIndex = 0;
        // Devolver focus al SearchInput
        searchInput.focusInput();
        updateFilteredItems();
        // Restore the original selectedIndex
        selectedIndex = originalSelectedIndex;
        textResultsList.currentIndex = originalSelectedIndex;
        originalSelectedIndex = -1;
    }

    function cancelImageDeleteMode() {
        console.log("DEBUG: Canceling image delete mode");
        imageDeleteMode = false;
        imageToDelete = "";
        imageDeleteButtonIndex = 0;
        // Devolver focus al SearchInput
        searchInput.focusInput();
        updateFilteredItems();
        // Restore the original selectedImageIndex
        selectedImageIndex = originalSelectedImageIndex;
        imageResultsList.currentIndex = originalSelectedImageIndex;
        originalSelectedImageIndex = -1;
    }

    function confirmDeleteItem() {
        console.log("DEBUG: Confirming delete for item:", itemToDelete);
        ClipboardService.deleteItem(itemToDelete);
        cancelDeleteMode();
        refreshClipboardHistory();
    }

    function confirmDeleteImage() {
        console.log("DEBUG: Confirming delete for image:", imageToDelete);
        ClipboardService.deleteItem(imageToDelete);
        cancelImageDeleteMode();
        refreshClipboardHistory();
    }

    function clearClipboardHistory() {
        // Aquí irá la llamada al servicio para limpiar el historial
        ClipboardService.clear();
        clearButtonConfirmState = false;
        clearButtonFocused = false;
        searchInput.focusInput();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredItems() {
        var newImageItems = [];
        var newTextItems = [];

        for (var i = 0; i < ClipboardService.items.length; i++) {
            var item = ClipboardService.items[i];
            var content = item.preview || "";

            if (searchText.length === 0 || content.toLowerCase().includes(searchText.toLowerCase())) {
                if (item.isImage) {
                    newImageItems.push(item);
                } else {
                    newTextItems.push(item);
                }
            }
        }

        imageItems = newImageItems;
        textItems = newTextItems;

        if (searchText.length > 0 && textItems.length > 0 && !isImageSectionFocused) {
            selectedIndex = 0;
            textResultsList.currentIndex = 0;
        } else if (searchText.length === 0) {
            selectedIndex = -1;
            selectedImageIndex = -1;
            textResultsList.currentIndex = -1;
        }
    }

    function onDownPressed() {
        if (!root.hasNavigatedFromSearch) {
            // Primera vez presionando down desde search
            root.hasNavigatedFromSearch = true;
            if (root.imageItems.length > 0 && root.searchText.length === 0) {
                // Ir primero a la sección de imágenes si hay imágenes y no hay búsqueda
                root.isImageSectionFocused = true;
                root.selectedIndex = -1;
                textResultsList.currentIndex = -1;
                if (root.selectedImageIndex === -1) {
                    root.selectedImageIndex = 0;
                }
                imageResultsList.currentIndex = root.selectedImageIndex;
            } else if (textResultsList.count > 0) {
                // Si no hay imágenes o hay búsqueda, ir directo a textos
                root.isImageSectionFocused = false;
                if (root.selectedIndex === -1) {
                    root.selectedIndex = 0;
                    textResultsList.currentIndex = 0;
                }
            }
        } else {
            // Ya navegamos desde search, ahora navegamos dentro de secciones
            if (root.isImageSectionFocused) {
                // Cambiar de sección de imágenes a textos
                root.isImageSectionFocused = false;
                if (root.textItems.length > 0) {
                    root.selectedIndex = 0;
                    textResultsList.currentIndex = 0;
                }
            } else if (textResultsList.count > 0 && root.selectedIndex >= 0) {
                if (root.selectedIndex < textResultsList.count - 1) {
                    root.selectedIndex++;
                    textResultsList.currentIndex = root.selectedIndex;
                }
            }
        }
    }

    function onUpPressed() {
        if (root.isImageSectionFocused) {
            // Al estar en imágenes y presionar up, regresar al search
            root.isImageSectionFocused = false;
            root.selectedImageIndex = -1;
            root.hasNavigatedFromSearch = false;
            imageResultsList.currentIndex = -1;
        } else if (root.selectedIndex > 0) {
            root.selectedIndex--;
            textResultsList.currentIndex = root.selectedIndex;
        } else if (root.selectedIndex === 0 && root.imageItems.length > 0 && root.searchText.length === 0) {
            // Cambiar de textos a imágenes solo si no hay búsqueda
            root.isImageSectionFocused = true;
            root.selectedIndex = -1;
            textResultsList.currentIndex = -1;
            if (root.selectedImageIndex === -1) {
                root.selectedImageIndex = 0;
            }
        } else if (root.selectedIndex === 0) {
            // Regresar al search
            root.selectedIndex = -1;
            root.hasNavigatedFromSearch = false;
            textResultsList.currentIndex = -1;
        }
    }

    function onLeftPressed() {
        if (root.isImageSectionFocused && root.selectedImageIndex > 0) {
            root.selectedImageIndex--;
            imageResultsList.currentIndex = root.selectedImageIndex;
        }
    }

    function onRightPressed() {
        if (root.isImageSectionFocused && root.selectedImageIndex < root.imageItems.length - 1) {
            root.selectedImageIndex++;
            imageResultsList.currentIndex = root.selectedImageIndex;
        }
    }

    function refreshClipboardHistory() {
        ClipboardService.list();
    }

    function copyToClipboard(itemId) {
        copyProcess.command = ["bash", "-c", "cliphist decode \"" + itemId + "\" | wl-copy"];
        copyProcess.running = true;
    }

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    // Conexiones al servicio
    Connections {
        target: ClipboardService
        function onListCompleted() {
            updateFilteredItems();
        }
    }

    // Proceso para copiar al portapapeles
    Process {
        id: copyProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                root.itemSelected();
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Barra de búsqueda con botón de limpiar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SearchInput {
                id: searchInput
                Layout.fillWidth: true
                text: root.searchText
                placeholderText: "Search clipboard history..."

                onSearchTextChanged: text => {
                    root.searchText = text;
                }

                onAccepted: {
                    if (root.deleteMode) {
                        // En modo eliminar, Enter equivale a cancelar
                        console.log("DEBUG: Enter in delete mode - canceling");
                        root.cancelDeleteMode();
                    } else {
                        console.log("DEBUG: Enter pressed! searchText:", root.searchText, "selectedIndex:", root.selectedIndex);

                        if (root.selectedIndex >= 0 && root.selectedIndex < root.textItems.length) {
                            let selectedItem = root.textItems[root.selectedIndex];
                            console.log("DEBUG: Selected item:", selectedItem);
                            if (selectedItem && !root.deleteMode) {
                                root.copyToClipboard(selectedItem.id);
                            }
                        } else if (root.isImageSectionFocused && root.selectedImageIndex >= 0 && root.selectedImageIndex < root.imageItems.length) {
                            let selectedImage = root.imageItems[root.selectedImageIndex];
                            console.log("DEBUG: Selected image:", selectedImage);
                            if (selectedImage && !root.deleteMode) {
                                root.copyToClipboard(selectedImage.id);
                            }
                        } else {
                            console.log("DEBUG: No action taken - selectedIndex:", root.selectedIndex, "count:", root.textItems.length);
                        }
                    }
                }

                onShiftAccepted: {
                    console.log("DEBUG: Shift+Enter pressed! selectedIndex:", root.selectedIndex, "selectedImageIndex:", root.selectedImageIndex, "deleteMode:", root.deleteMode, "imageDeleteMode:", root.imageDeleteMode);

                    if (!root.deleteMode && !root.imageDeleteMode) {
                        if (root.isImageSectionFocused && root.selectedImageIndex >= 0 && root.selectedImageIndex < root.imageItems.length) {
                            let selectedImage = root.imageItems[root.selectedImageIndex];
                            console.log("DEBUG: Selected image for deletion:", selectedImage);
                            if (selectedImage) {
                                // Activar modo delete para la imagen seleccionada
                                root.enterImageDeleteMode(selectedImage.id);
                            }
                        } else if (!root.isImageSectionFocused && root.selectedIndex >= 0 && root.selectedIndex < root.textItems.length) {
                            let selectedItem = root.textItems[root.selectedIndex];
                            console.log("DEBUG: Selected item for deletion:", selectedItem);
                            if (selectedItem) {
                                // Activar modo delete para el item seleccionado
                                root.enterDeleteMode(selectedItem.id);
                            }
                        }
                    }
                }

                onEscapePressed: {
                    if (!root.deleteMode && !root.imageDeleteMode) {
                        // Solo cerrar el notch si NO estamos en modo eliminar
                        root.itemSelected();
                    }
                    // Si estamos en modo eliminar, no hacer nada aquí
                    // El handler global del root se encargará
                }

                onDownPressed: {
                    root.onDownPressed();
                }

                onUpPressed: {
                    root.onUpPressed();
                }

                onLeftPressed: {
                    root.onLeftPressed();
                }

                onRightPressed: {
                    root.onRightPressed();
                }
            }

            // Botón de limpiar historial
            Rectangle {
                id: clearButton
                Layout.preferredWidth: root.clearButtonConfirmState ? 130 : 48
                Layout.preferredHeight: 48
                radius: searchInput.radius
                color: {
                    if (root.clearButtonConfirmState) {
                        return Colors.adapter.error;
                    } else if (root.clearButtonFocused || clearButtonMouseArea.containsMouse) {
                        return Colors.surfaceBright;
                    } else {
                        return Colors.surface;
                    }
                }
                focus: root.clearButtonFocused
                activeFocusOnTab: true

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                onActiveFocusChanged: {
                    if (activeFocus) {
                        root.clearButtonFocused = true;
                    } else {
                        root.clearButtonFocused = false;
                        root.resetClearButton();
                    }
                }

                MouseArea {
                    id: clearButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (root.clearButtonConfirmState) {
                            root.clearClipboardHistory();
                        } else {
                            root.clearButtonConfirmState = true;
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 32
                        text: root.clearButtonConfirmState ? Icons.alert : Icons.trash
                        font.family: Icons.font
                        font.pixelSize: 20
                        color: root.clearButtonConfirmState ? Colors.adapter.overError : Colors.adapter.primary
                        horizontalAlignment: Text.AlignHCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Clear all?"
                        font.family: Config.theme.font
                        font.weight: Font.Bold
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.adapter.overError
                        opacity: root.clearButtonConfirmState ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.clearButtonConfirmState) {
                            root.clearClipboardHistory();
                        } else {
                            root.clearButtonConfirmState = true;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.resetClearButton();
                        root.clearButtonFocused = false;
                        searchInput.focusInput();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                        root.resetClearButton();
                        root.clearButtonFocused = false;
                        searchInput.focusInput();
                        event.accepted = true;
                    }
                }
            }
        }

        // Contenedor de resultados del clipboard
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Sección de imágenes horizontal
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.imgSize
                visible: root.imageItems.length > 0 && root.searchText.length === 0

                ClippingRectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.isImageSectionFocused ? Colors.adapter.primary : Colors.adapter.outline
                    border.width: 0
                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutQuart
                        }
                    }

                    ListView {
                        id: imageResultsList
                        anchors.fill: parent
                        anchors.margins: 0
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true

                        model: root.imageItems
                        currentIndex: root.selectedImageIndex

                        onCurrentIndexChanged: {
                            if (currentIndex !== root.selectedImageIndex && root.isImageSectionFocused) {
                                root.selectedImageIndex = currentIndex;
                            }
                        }

                        delegate: ClippingRectangle {
                            required property var modelData
                            required property int index

                            width: root.imgSize
                            height: width
                            color: {
                                if (root.imageDeleteMode && modelData.id === root.imageToDelete) {
                                    return Colors.adapter.overError;
                                } else if (root.isImageSectionFocused && root.selectedImageIndex === index) {
                                    return Colors.adapter.primary;
                                } else {
                                    return Colors.adapter.surface;
                                }
                            }
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }

                            MouseArea {
                                id: imageMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                // Variables para gestos táctiles y long press
                                property real startX: 0
                                property real startY: 0
                                property bool isDragging: false
                                property bool longPressTriggered: false

                                property bool isInImageDeleteMode: root.imageDeleteMode && modelData.id === root.imageToDelete

                                onEntered: {
                                    // Solo cambiar la selección si no estamos en modo delete
                                    if (!root.imageDeleteMode) {
                                        if (!root.isImageSectionFocused) {
                                            root.isImageSectionFocused = true;
                                            root.selectedIndex = -1;
                                            textResultsList.currentIndex = -1;
                                        }
                                        root.selectedImageIndex = index;
                                        imageResultsList.currentIndex = index;
                                    }
                                }

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton && !imageMouseArea.isInImageDeleteMode) {
                                        // Solo copiar si NO estamos en modo delete
                                        root.copyToClipboard(modelData.id);
                                    } else if (mouse.button === Qt.RightButton) {
                                        // Click derecho - mostrar menú contextual
                                        console.log("DEBUG: Right click detected on image, showing context menu");
                                        imageContextMenu.popup(mouse.x, mouse.y);
                                    }
                                }

                                onPressed: mouse => {
                                    startX = mouse.x;
                                    startY = mouse.y;
                                    isDragging = false;
                                    longPressTriggered = false;

                                    // Solo iniciar el timer para long press si no es click derecho
                                    if (mouse.button !== Qt.RightButton) {
                                        imageLongPressTimer.start();
                                    }
                                }

                                onPositionChanged: mouse => {
                                    if (pressed && mouse.button !== Qt.RightButton) {
                                        let deltaX = mouse.x - startX;
                                        let deltaY = mouse.y - startY;
                                        let distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

                                        // Si se mueve más de 10 píxeles, considerar como arrastre
                                        if (distance > 10) {
                                            isDragging = true;
                                            imageLongPressTimer.stop();
                                        }
                                    }
                                }

                                onReleased: mouse => {
                                    imageLongPressTimer.stop();
                                    isDragging = false;
                                    longPressTriggered = false;
                                }

                                // Timer para long press
                                Timer {
                                    id: imageLongPressTimer
                                    interval: 800 // 800ms para activar long press
                                    repeat: false
                                    onTriggered: {
                                        // Long press activado - entrar en modo delete
                                        if (!imageMouseArea.isDragging) {
                                            root.enterImageDeleteMode(modelData.id);
                                            imageMouseArea.longPressTriggered = true;
                                        }
                                    }
                                }

                                // Menú contextual para imágenes
                                OptionsMenu {
                                    id: imageContextMenu

                                    items: [
                                        {
                                            text: "Copy",
                                            icon: Icons.copy,
                                            highlightColor: Colors.adapter.primary,
                                            textColor: Colors.adapter.overPrimary,
                                            onTriggered: function () {
                                                console.log("DEBUG: Copy clicked from Image ContextMenu");
                                                root.copyToClipboard(modelData.id);
                                            }
                                        },
                                        {
                                            text: "Delete",
                                            icon: Icons.trash,
                                            highlightColor: Colors.adapter.overError,
                                            textColor: Colors.adapter.error,
                                            onTriggered: function () {
                                                console.log("DEBUG: Delete clicked from Image ContextMenu");
                                                root.enterImageDeleteMode(modelData.id);
                                            }
                                        }
                                    ]
                                }
                            }

                            // Preview de imagen real o placeholder
                            Item {
                                anchors.centerIn: parent
                                width: root.imgSize // Reducir para dar espacio al menu
                                height: width

                                // Imagen real si está disponible
                                Image {
                                    id: imagePreview
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    source: {
                                        // Forzar re-evaluación cuando el cache cambia
                                        ClipboardService.revision;
                                        return ClipboardService.getImageData(modelData.id);
                                    }
                                    clip: true

                                    Component.onCompleted: {
                                        // Cargar imagen on-demand si no está en cache
                                        if (!ClipboardService.getImageData(modelData.id)) {
                                            ClipboardService.decodeToDataUrl(modelData.id, modelData.mime);
                                        }
                                    }

                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            console.log("Error loading image for ID:", modelData.id);
                                        }
                                    }
                                }

                                // Placeholder cuando la imagen no está disponible
                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.adapter.primary
                                    radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                    visible: imagePreview.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.image
                                        font.family: Icons.font
                                        font.pixelSize: 24
                                        color: Colors.adapter.overPrimary
                                    }
                                }

                                // Indicador de carga
                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.adapter.surface
                                    radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                    visible: imagePreview.status === Image.Loading
                                    opacity: 0.8

                                    Text {
                                        anchors.centerIn: parent
                                        text: "..."
                                        font.family: Config.theme.font
                                        font.pixelSize: 16
                                        color: Colors.adapter.overSurface
                                    }
                                }
                            }

                            // Botones de acción que aparecen desde abajo - MOVIDO FUERA DEL MOUSEAREA
                            Rectangle {
                                id: imageActionContainer
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 4
                                width: 68 // 32 + 4 + 32
                                height: 32
                                color: "transparent"
                                opacity: (root.imageDeleteMode && modelData.id === root.imageToDelete) ? 1.0 : 0.0
                                visible: opacity > 0
                                z: 10 // Asegurar que esté por encima

                                transform: Translate {
                                    y: (root.imageDeleteMode && modelData.id === root.imageToDelete) ? 0 : 40

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                // Fondo del menu
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    anchors.topMargin: 0
                                    // color: Colors.adapter.error
                                    color: "transparent"
                                }

                                // Highlight elástico que se estira entre botones
                                Rectangle {
                                    id: imageDeleteHighlight
                                    color: Colors.adapter.overError
                                    radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                    visible: (root.imageDeleteMode && modelData.id === root.imageToDelete)

                                    property real activeButtonMargin: 2
                                    property real idx1X: root.imageDeleteButtonIndex
                                    property real idx2X: root.imageDeleteButtonIndex

                                    // Posición y tamaño con efecto elástico
                                    x: {
                                        let minX = Math.min(idx1X, idx2X) * 36 + activeButtonMargin; // 32 + 4 spacing
                                        return minX;
                                    }

                                    y: activeButtonMargin

                                    width: {
                                        let stretchX = Math.abs(idx1X - idx2X) * 36 + 32 - activeButtonMargin * 2; // 32 + 4 spacing
                                        return stretchX;
                                    }

                                    height: 32 - activeButtonMargin * 2

                                    Behavior on idx1X {
                                        NumberAnimation {
                                            duration: Config.animDuration / 3
                                            easing.type: Easing.OutSine
                                        }
                                    }
                                    Behavior on idx2X {
                                        NumberAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutSine
                                        }
                                    }
                                }

                                Row {
                                    id: imageActionButtons
                                    anchors.fill: parent
                                    spacing: 4

                                    // Botón cancelar (cruz)
                                    Rectangle {
                                        id: imageCancelButton
                                        width: 32
                                        height: 32
                                        color: "transparent"
                                        radius: Config.roundness
                                        border.width: 0
                                        border.color: Colors.adapter.outline
                                        z: 10

                                        property bool isHighlighted: root.imageDeleteButtonIndex === 0

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.cancelImageDeleteMode()
                                            onEntered: {
                                                root.imageDeleteButtonIndex = 0;
                                            }
                                            onExited: parent.color = "transparent"
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.cancel
                                            color: imageCancelButton.isHighlighted ? Colors.adapter.error : Colors.adapter.overError
                                            font.pixelSize: 16
                                            font.family: Icons.font

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                    }

                                    // Botón confirmar (trash)
                                    Rectangle {
                                        id: imageConfirmButton
                                        width: 32
                                        height: 32
                                        color: "transparent"
                                        radius: Config.roundness
                                        z: 10

                                        property bool isHighlighted: root.imageDeleteButtonIndex === 1

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.confirmDeleteImage()
                                            onEntered: {
                                                root.imageDeleteButtonIndex = 1;
                                            }
                                            onExited: parent.color = "transparent"
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.trash
                                            color: imageConfirmButton.isHighlighted ? Colors.adapter.error : Colors.adapter.overError
                                            font.pixelSize: 16
                                            font.family: Icons.font

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Highlight cuando está seleccionado
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Colors.adapter.primary
                                border.width: 0
                                radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        highlight: ClippingRectangle {
                            color: "transparent"
                            z: 100
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                            visible: root.isImageSectionFocused

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -32
                                anchors.bottomMargin: root.imageDeleteMode ? -4 : -32
                                color: "transparent"
                                border.color: root.imageDeleteMode ? Colors.adapter.error : Colors.adapter.primary
                                border.width: 36
                                radius: Config.roundness > 0 ? Config.roundness + 36 : 0

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        highlightMoveDuration: Config.animDuration / 2
                        highlightMoveVelocity: -1
                    }
                }
            }

            // Scrollbar separador para imágenes
            ScrollBar {
                id: imageScrollBar
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                visible: root.imageItems.length > 0 && root.searchText.length === 0
                orientation: Qt.Horizontal

                size: imageResultsList.width / imageResultsList.contentWidth
                position: imageResultsList.contentX / imageResultsList.contentWidth

                background: Rectangle {
                    color: Colors.surface
                    radius: Config.roundness
                }

                contentItem: Rectangle {
                    color: Colors.adapter.primary
                    radius: Config.roundness
                }

                onPositionChanged: {
                    if (pressed) {
                        imageResultsList.contentX = position * imageResultsList.contentWidth;
                    }
                }
            }

            // Lista de textos vertical o mensaje cuando no hay elementos
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: (root.imageItems.length > 0 && root.searchText.length === 0) ? 3 * 48 : 5 * 48

                // Lista de textos
                ListView {
                    id: textResultsList
                    anchors.fill: parent
                    visible: ClipboardService.items.length > 0
                    clip: true

                    model: root.textItems
                    currentIndex: root.selectedIndex

                    onCurrentIndexChanged: {
                        if (currentIndex !== root.selectedIndex && !root.isImageSectionFocused) {
                            root.selectedIndex = currentIndex;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: textResultsList.width
                        height: 48
                        color: "transparent"
                        radius: 16

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            // Variables para gestos táctiles
                            property real startX: 0
                            property real startY: 0
                            property bool isDragging: false
                            property bool longPressTriggered: false

                            property bool isInDeleteMode: root.deleteMode && modelData.id === root.itemToDelete

                            onEntered: {
                                // Solo cambiar la selección si no estamos en modo delete
                                if (!root.deleteMode) {
                                    if (root.isImageSectionFocused) {
                                        root.isImageSectionFocused = false;
                                        root.selectedImageIndex = -1;
                                    }
                                    root.selectedIndex = index;
                                    textResultsList.currentIndex = index;
                                }
                            }

                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton && !mouseArea.isInDeleteMode) {
                                    // Solo copiar si NO estamos en modo delete
                                    root.copyToClipboard(modelData.id);
                                } else if (mouse.button === Qt.RightButton) {
                                    // Click derecho - mostrar menú contextual
                                    console.log("DEBUG: Right click detected, showing context menu");
                                    contextMenu.popup(mouse.x, mouse.y);
                                }
                            }

                            onPressed: mouse => {
                                startX = mouse.x;
                                startY = mouse.y;
                                isDragging = false;
                                longPressTriggered = false;

                                // Solo iniciar el timer para long press si no es click derecho
                                if (mouse.button !== Qt.RightButton) {
                                    longPressTimer.start();
                                }
                            }

                            onPositionChanged: mouse => {
                                if (pressed && mouse.button !== Qt.RightButton) {
                                    let deltaX = mouse.x - startX;
                                    let deltaY = mouse.y - startY;
                                    let distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

                                    // Si se mueve más de 10 píxeles, considerar como arrastre
                                    if (distance > 10) {
                                        isDragging = true;
                                        longPressTimer.stop();

                                        // Detectar swipe hacia la izquierda para delete
                                        if (deltaX < -50 && Math.abs(deltaY) < 30) {
                                            if (!longPressTriggered) {
                                                root.enterDeleteMode(modelData.id);
                                                longPressTriggered = true;
                                            }
                                        }
                                    }
                                }
                            }

                            // Botones de acción que aparecen desde la derecha
                            Rectangle {
                                id: actionContainer
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                width: 68 // 32 + 4 + 32
                                height: 32
                                color: "transparent"
                                opacity: mouseArea.isInDeleteMode ? 1.0 : 0.0
                                visible: opacity > 0

                                transform: Translate {
                                    x: mouseArea.isInDeleteMode ? 0 : 80

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                // Highlight elástico que se estira entre botones
                                Rectangle {
                                    id: deleteHighlight
                                    color: Colors.adapter.overError
                                    radius: Config.roundness > 4 ? Config.roundness - 4 : 0
                                    visible: mouseArea.isInDeleteMode
                                    z: 0

                                    property real activeButtonMargin: 2
                                    property real idx1X: root.deleteButtonIndex
                                    property real idx2X: root.deleteButtonIndex

                                    // Posición y tamaño con efecto elástico
                                    x: {
                                        let minX = Math.min(idx1X, idx2X) * 36 + activeButtonMargin; // 32 + 4 spacing
                                        return minX;
                                    }

                                    y: activeButtonMargin

                                    width: {
                                        let stretchX = Math.abs(idx1X - idx2X) * 36 + 32 - activeButtonMargin * 2; // 32 + 4 spacing
                                        return stretchX;
                                    }

                                    height: 32 - activeButtonMargin * 2

                                    Behavior on idx1X {
                                        NumberAnimation {
                                            duration: Config.animDuration / 3
                                            easing.type: Easing.OutSine
                                        }
                                    }
                                    Behavior on idx2X {
                                        NumberAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutSine
                                        }
                                    }
                                }

                                Row {
                                    id: actionButtons
                                    anchors.fill: parent
                                    spacing: 4

                                    // Botón cancelar (cruz)
                                    Rectangle {
                                        id: cancelButton
                                        width: 32
                                        height: 32
                                        color: "transparent"
                                        radius: 6
                                        border.width: 0
                                        border.color: Colors.adapter.outline
                                        z: 1

                                        property bool isHighlighted: root.deleteButtonIndex === 0

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.cancelDeleteMode()
                                            onEntered: {
                                                root.deleteButtonIndex = 0;
                                            }
                                            onExited: parent.color = "transparent"
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.cancel
                                            color: cancelButton.isHighlighted ? Colors.adapter.error : Colors.adapter.overError
                                            font.pixelSize: 14
                                            font.family: Icons.font

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                    }

                                    // Botón confirmar (check)
                                    Rectangle {
                                        id: confirmButton
                                        width: 32
                                        height: 32
                                        color: "transparent"
                                        radius: 6
                                        z: 1

                                        property bool isHighlighted: root.deleteButtonIndex === 1

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.confirmDeleteItem()
                                            onEntered: {
                                                root.deleteButtonIndex = 1;
                                            }
                                            onExited: parent.color = "transparent"
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: Icons.accept
                                            color: confirmButton.isHighlighted ? Colors.adapter.error : Colors.adapter.overError
                                            font.pixelSize: 14
                                            font.family: Icons.font

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            onReleased: mouse => {
                                longPressTimer.stop();
                                isDragging = false;
                                longPressTriggered = false;
                            }

                            // Timer para long press
                            Timer {
                                id: longPressTimer
                                interval: 800 // 800ms para activar long press
                                repeat: false
                                onTriggered: {
                                    // Long press activado - copiar item
                                    if (!mouseArea.isDragging) {
                                        root.copyToClipboard(modelData.id);
                                        mouseArea.longPressTriggered = true;
                                    }
                                }
                            }
                        }

                        // Menú contextual usando el componente reutilizable
                        OptionsMenu {
                            id: contextMenu

                            items: [
                                {
                                    text: "Copy",
                                    icon: Icons.copy,
                                    highlightColor: Colors.adapter.primary,
                                    textColor: Colors.adapter.overPrimary,
                                    onTriggered: function () {
                                        console.log("DEBUG: Copy clicked from ContextMenu");
                                        root.copyToClipboard(modelData.id);
                                    }
                                },
                                {
                                    text: "Delete",
                                    icon: Icons.trash,
                                    highlightColor: Colors.adapter.overError,
                                    textColor: Colors.adapter.error,
                                    onTriggered: function () {
                                        console.log("DEBUG: Delete clicked from ContextMenu");
                                        root.enterDeleteMode(modelData.id);
                                    }
                                }
                            ]
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.rightMargin: mouseArea.isInDeleteMode ? 84 : 8 // 68 (ancho botones) + 16 (padding extra)
                            spacing: 12

                            Behavior on anchors.rightMargin {
                                NumberAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: {
                                    if (mouseArea.isInDeleteMode) {
                                        return Colors.adapter.overError;
                                    } else if (root.selectedIndex === index && !root.isImageSectionFocused) {
                                        return Colors.adapter.overPrimary;
                                    } else {
                                        return Colors.surface;
                                    }
                                }
                                radius: Config.roundness > 0 ? Config.roundness - 4 : 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: mouseArea.isInDeleteMode ? Icons.trash : Icons.clip
                                    color: {
                                        if (mouseArea.isInDeleteMode) {
                                            return Colors.adapter.error;
                                        } else if (root.selectedIndex === index && !root.isImageSectionFocused) {
                                            return Colors.adapter.primary;
                                        } else {
                                            return Colors.adapter.overBackground;
                                        }
                                    }
                                    font.family: Icons.font
                                    font.pixelSize: 16

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Config.animDuration / 2
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: mouseArea.isInDeleteMode ? ("Delete \"" + modelData.preview.substring(0, 20) + (modelData.preview.length > 20 ? '...' : '') + "\"?") : modelData.preview
                                color: {
                                    if (mouseArea.isInDeleteMode) {
                                        return Colors.adapter.overError;
                                    } else if (root.selectedIndex === index && !root.isImageSectionFocused) {
                                        return Colors.adapter.overPrimary;
                                    } else {
                                        return Colors.adapter.overBackground;
                                    }
                                }
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: mouseArea.isInDeleteMode ? Font.Bold : Font.Bold
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }
                    }

                    highlight: Rectangle {
                        color: root.deleteMode ? Colors.adapter.error : Colors.adapter.primary
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: root.selectedIndex >= 0 && !root.isImageSectionFocused

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    highlightMoveDuration: Config.animDuration / 2
                    highlightMoveVelocity: -1
                }

                // Mensaje cuando no hay elementos
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: ClipboardService.items.length === 0

                    Text {
                        text: Icons.clipboard
                        font.family: Icons.font
                        font.pixelSize: 48
                        color: Colors.surfaceBright
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "No clipboard history"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize + 2
                        font.weight: Font.Bold
                        color: Colors.adapter.overBackground
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Copy something to get started"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.surfaceBright
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // Handler de teclas global para manejar navegación en modo eliminar
    Keys.onPressed: event => {
        if (root.deleteMode) {
            if (event.key === Qt.Key_Left) {
                root.deleteButtonIndex = 0; // Cancelar (cruz)
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.deleteButtonIndex = 1; // Confirmar (check)
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                // Ejecutar acción del botón seleccionado
                if (root.deleteButtonIndex === 0) {
                    console.log("DEBUG: Enter/Space pressed - canceling delete");
                    root.cancelDeleteMode();
                } else {
                    console.log("DEBUG: Enter/Space pressed - confirming delete");
                    root.confirmDeleteItem();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                console.log("DEBUG: Escape pressed in delete mode - canceling without closing notch");
                root.cancelDeleteMode();
                event.accepted = true;
            }
        } else if (root.imageDeleteMode) {
            if (event.key === Qt.Key_Left) {
                root.imageDeleteButtonIndex = 0; // Cancelar (cruz)
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.imageDeleteButtonIndex = 1; // Confirmar (trash)
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                // Ejecutar acción del botón seleccionado
                if (root.imageDeleteButtonIndex === 0) {
                    console.log("DEBUG: Enter/Space pressed - canceling image delete");
                    root.cancelImageDeleteMode();
                } else {
                    console.log("DEBUG: Enter/Space pressed - confirming image delete");
                    root.confirmDeleteImage();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                console.log("DEBUG: Escape pressed in image delete mode - canceling without closing notch");
                root.cancelImageDeleteMode();
                event.accepted = true;
            }
        }
    }

    // Monitor cambios en deleteMode
    onDeleteModeChanged: {
        if (!deleteMode) {
            console.log("DEBUG: Delete mode ended");
        }
    }

    // Monitor cambios en imageDeleteMode
    onImageDeleteModeChanged: {
        if (!imageDeleteMode) {
            console.log("DEBUG: Image delete mode ended");
        }
    }

    Component.onCompleted: {
        refreshClipboardHistory();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }
}
