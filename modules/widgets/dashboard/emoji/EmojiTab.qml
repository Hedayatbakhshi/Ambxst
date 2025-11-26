import QtQuick
import QtQuick.Effects
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

    // Prefix support
    property string prefixIcon: ""
    signal backspaceOnEmpty

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property int selectedRecentIndex: -1
    property int lastSelectedRecentIndex: -1
    property bool isRecentFocused: false
    property bool hasNavigatedFromSearch: false
    property bool clearButtonFocused: false
    property bool clearButtonConfirmState: false
    property var emojiData: []
    property var recentEmojis: []
    property var filteredEmojis: []

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && emojiList.count > 0) {
            emojiList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredEmojis();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        selectedRecentIndex = -1;
        lastSelectedRecentIndex = -1;
        isRecentFocused = false;
        hasNavigatedFromSearch = false;
        clearButtonFocused = false;
        clearButtonConfirmState = false;
        searchInput.focusInput();
        updateFilteredEmojis();
    }

    function resetClearButton() {
        clearButtonConfirmState = false;
    }

    function clearRecentEmojis() {
        recentEmojis = [];
        saveRecentEmojis();
        clearButtonConfirmState = false;
        clearButtonFocused = false;
        searchInput.focusInput();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredEmojis() {
        var filtered = [];
        var searchLower = searchText.toLowerCase();

        for (var i = 0; i < emojiData.length; i++) {
            var emoji = emojiData[i];
            var emojiText = emoji.emoji;
            var searchTerms = emoji.search;

            // Check if search text matches emoji or any search term
            var matches = searchText.length === 0;
            if (!matches) {
                if (emojiText.includes(searchText) || searchTerms.toLowerCase().includes(searchLower)) {
                    matches = true;
                }
            }

            if (matches) {
                filtered.push(emoji);
            }
        }

        filteredEmojis = filtered;

        if (searchText.length > 0 && filteredEmojis.length > 0 && !isRecentFocused) {
            selectedIndex = 0;
            emojiList.currentIndex = 0;
        } else if (searchText.length === 0 && !hasNavigatedFromSearch) {
            selectedIndex = -1;
            selectedRecentIndex = -1;
        }
    }

    function loadEmojiData() {
        // Load emoji data from fuzzel-emoji.sh
        emojiProcess.command = ["bash", "-c", "sed '1,/^### DATA ###$/d' /home/adriano/Repos/Axenide/Ambxst/scripts/fuzzel-emoji.sh"];
        emojiProcess.running = true;
    }

    function loadRecentEmojis() {
        // Load recent emojis from JSON
        recentProcess.command = ["bash", "-c", "cat " + Quickshell.dataDir + "/emojis.json 2>/dev/null || echo '[]'"];
        recentProcess.running = true;
    }

    function saveRecentEmojis() {
        // Save recent emojis to JSON
        var jsonData = JSON.stringify(recentEmojis, null, 2);
        saveProcess.command = ["bash", "-c", "echo '" + jsonData.replace(/'/g, "'\\''") + "' > " + Quickshell.dataDir + "/emojis.json"];
        saveProcess.running = true;
    }

    function addToRecent(emoji) {
        // Remove if already exists
        recentEmojis = recentEmojis.filter(function (item) {
            return item.emoji !== emoji.emoji;
        });

        // Add to beginning with usage count
        emoji.usage = (emoji.usage || 0) + 1;
        emoji.lastUsed = Date.now();
        recentEmojis.unshift(emoji);

        // Keep only last 50
        if (recentEmojis.length > 50) {
            recentEmojis = recentEmojis.slice(0, 50);
        }

        // Sort by usage desc, then last used desc
        recentEmojis.sort(function (a, b) {
            if (a.usage !== b.usage) {
                return b.usage - a.usage;
            }
            return b.lastUsed - a.lastUsed;
        });

        saveRecentEmojis();
    }

    function copyEmoji(emoji) {
        // Cerrar el dashboard primero para que el paste vaya a la aplicación activa
        Visibilities.setActiveModule("");

        // Copiar el emoji al clipboard
        copyProcess.command = ["bash", "-c", "echo -n '" + emoji.emoji.replace(/'/g, "'\\''") + "' | wl-copy"];
        copyProcess.running = true;
        addToRecent(emoji);

        // Iniciar timers para paste automático
        pasteTimer.start();
    }

    function onDownPressed() {
        if (!hasNavigatedFromSearch) {
            // Primera vez presionando down desde search
            hasNavigatedFromSearch = true;
            if (filteredEmojis.length > 0) {
                // Ir directo a emojis (ya no priorizamos recientes)
                isRecentFocused = false;
                selectedRecentIndex = -1;
                recentList.currentIndex = -1;
                if (selectedIndex === -1) {
                    selectedIndex = 0;
                    emojiList.currentIndex = 0;
                }
            }
        } else {
            // Ya navegamos desde search, ahora navegamos dentro de la lista normal
            if (!isRecentFocused && emojiList.count > 0 && selectedIndex >= 0) {
                if (selectedIndex < emojiList.count - 1) {
                    selectedIndex++;
                    emojiList.currentIndex = selectedIndex;
                }
            } else if (isRecentFocused && recentEmojis.length > 0) {
                // Navegamos en la lista vertical de recientes
                if (selectedRecentIndex < recentEmojis.length - 1) {
                    selectedRecentIndex++;
                    recentList.currentIndex = selectedRecentIndex;
                    lastSelectedRecentIndex = selectedRecentIndex;
                }
            }
        }
    }

    function onUpPressed() {
        if (isRecentFocused) {
            // En lista de recientes
            if (selectedRecentIndex > 0) {
                selectedRecentIndex--;
                recentList.currentIndex = selectedRecentIndex;
                lastSelectedRecentIndex = selectedRecentIndex;
            } else if (selectedRecentIndex === 0) {
                // Volver al search
                isRecentFocused = false;
                selectedRecentIndex = -1;
                recentList.currentIndex = -1;
                hasNavigatedFromSearch = false;
            }
        } else if (selectedIndex > 0) {
            // Navigate within normal list
            selectedIndex--;
            emojiList.currentIndex = selectedIndex;
        } else if (selectedIndex === 0) {
            // Go back to search
            selectedIndex = -1;
            emojiList.currentIndex = -1;
            hasNavigatedFromSearch = false;
        }
    }

    function onLeftPressed() {
        // Cambiar foco a la lista normal si estamos en recientes
        if (isRecentFocused && recentEmojis.length > 0) {
            isRecentFocused = false;
            selectedRecentIndex = -1;
            recentList.currentIndex = -1;
            if (filteredEmojis.length > 0) {
                if (selectedIndex === -1) {
                    selectedIndex = 0;
                }
                emojiList.currentIndex = selectedIndex;
            }
        }
    }

    function onRightPressed() {
        // Cambiar foco a la lista de recientes si estamos en normal y hay recientes
        if (!isRecentFocused && recentEmojis.length > 0 && searchText.length === 0) {
            isRecentFocused = true;
            selectedIndex = -1;
            emojiList.currentIndex = -1;
            if (lastSelectedRecentIndex >= 0 && lastSelectedRecentIndex < recentEmojis.length) {
                selectedRecentIndex = lastSelectedRecentIndex;
            } else {
                selectedRecentIndex = 0;
                lastSelectedRecentIndex = selectedRecentIndex;
            }
            recentList.currentIndex = selectedRecentIndex;
        }
    }

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    Behavior on height {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    // Load emoji data
    Process {
        id: emojiProcess
        running: false

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var lines = text.trim().split('\n');
                var data = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length > 0) {
                        var parts = line.split(' ');
                        if (parts.length >= 2) {
                            var emoji = parts[0];
                            var search = parts.slice(1).join(' ');
                            data.push({
                                emoji: emoji,
                                search: search
                            });
                        }
                    }
                }
                emojiData = data;
                updateFilteredEmojis();
            }
        }

        onExited: function (code) {
            if (code !== 0) {}
        }
    }

    // Load recent emojis
    Process {
        id: recentProcess
        running: false

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                try {
                    recentEmojis = JSON.parse(text.trim());
                } catch (e) {
                    recentEmojis = [];
                }
            }
        }

        onExited: function (code) {
            if (code !== 0) {}
        }
    }

    // Save recent emojis
    Process {
        id: saveProcess
        running: false
    }

    // Copy emoji
    Process {
        id: copyProcess
        running: false
    }

    // Paste emoji
    Process {
        id: pasteProcess
        command: ["wtype", "-M", "ctrl", "-k", "v"]
        running: false
    }

    Timer {
        id: pasteTimer
        interval: 200 // Delay aumentado para asegurar que el emoji esté en el clipboard
        onTriggered: {
            pasteProcess.running = true;
        }
    }

    Row {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Contenedor de listas de emojis (layout horizontal)
        Row {
            width: parent.width
            height: parent.height
            spacing: 8

            // Columna izquierda: Search + Lista normal de emojis
            Column {
                width: LayoutMetrics.calculateLeftPanelWidth(parent.width, parent.height, parent.spacing)
                height: parent.height
                spacing: 8

                // Barra de búsqueda con botón de limpiar
                Row {
                    width: parent.width
                    height: 48
                    spacing: 8

                    SearchInput {
                        id: searchInput
                        width: parent.width - clearButton.width - parent.spacing
                        height: parent.height
                        text: root.searchText
                        placeholderText: "Search emojis..."
                        prefixIcon: root.prefixIcon

                        onSearchTextChanged: text => {
                            root.searchText = text;
                        }

                        onBackspaceOnEmpty: {
                            root.backspaceOnEmpty();
                        }

                        onAccepted: {
                            if (isRecentFocused && selectedRecentIndex >= 0 && selectedRecentIndex < recentEmojis.length) {
                                var selectedEmoji = recentEmojis[selectedRecentIndex];
                                if (selectedEmoji) {
                                    root.copyEmoji(selectedEmoji);
                                }
                            } else if (!isRecentFocused && selectedIndex >= 0 && selectedIndex < filteredEmojis.length) {
                                var selectedEmoji = filteredEmojis[selectedIndex];
                                if (selectedEmoji) {
                                    root.copyEmoji(selectedEmoji);
                                }
                            }
                        }

                        onEscapePressed: {
                            if (root.searchText.length === 0) {
                                Visibilities.setActiveModule("");
                            } else {
                                root.clearSearch();
                            }
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

                    // Botón de limpiar recientes
                    ClippingRectangle {
                        id: clearButton
                        width: root.clearButtonConfirmState ? clearButtonContent.implicitWidth + 32 : 48
                        height: 48
                        radius: searchInput.radius
                        color: {
                            if (root.clearButtonConfirmState) {
                                return Colors.error;
                            } else if (root.clearButtonFocused || clearButtonMouseArea.containsMouse) {
                                return Colors.surfaceBright;
                            } else {
                                return Colors.surface;
                            }
                        }
                        focus: root.clearButtonFocused
                        activeFocusOnTab: true

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        Behavior on width {
                            enabled: Config.animDuration > 0
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
                                    root.clearRecentEmojis();
                                } else {
                                    root.clearButtonConfirmState = true;
                                }
                            }
                        }

                        Row {
                            id: clearButtonContent
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                width: 32
                                height: parent.height
                                text: root.clearButtonConfirmState ? Icons.xeyes : Icons.broom
                                font.family: Icons.font
                                font.pixelSize: 20
                                color: root.clearButtonConfirmState ? Colors.overError : Colors.primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                textFormat: Text.RichText

                                Behavior on color {
                                    enabled: Config.animDuration > 0
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            Text {
                                width: parent.width - 32 - parent.spacing
                                height: parent.height
                                text: "Clear recent?"
                                font.family: Config.theme.font
                                font.weight: Font.Bold
                                font.pixelSize: Config.theme.fontSize
                                color: Colors.overError
                                opacity: root.clearButtonConfirmState ? 1.0 : 0.0
                                visible: opacity > 0
                                verticalAlignment: Text.AlignVCenter

                                Behavior on opacity {
                                    enabled: Config.animDuration > 0
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
                                    root.clearRecentEmojis();
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

                // Emoji list (7 filas)
                ListView {
                    id: emojiList
                    width: parent.width
                    height: 7 * 48
                    clip: true
                    cacheBuffer: 96
                    reuseItems: true

                    model: root.filteredEmojis
                    currentIndex: root.selectedIndex

                    onCurrentIndexChanged: {
                        if (currentIndex !== root.selectedIndex && !root.isRecentFocused) {
                            root.selectedIndex = currentIndex;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: emojiList.width
                        height: 48
                        color: "transparent"
                        radius: 16
                        
                        property color textColor: {
                            if (root.selectedIndex === index && !root.isRecentFocused) {
                                return Config.resolveColor(Config.theme.itemPrimary);
                            } else {
                                return Config.resolveColor(Config.theme.itemCommon);
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: false
                            propagateComposedEvents: true

                            onEntered: {
                                if (root.isRecentFocused) {
                                    root.isRecentFocused = false;
                                    root.selectedRecentIndex = -1;
                                    recentList.currentIndex = -1;
                                }
                                root.selectedIndex = index;
                                emojiList.currentIndex = index;
                            }

                            onClicked: {
                                root.copyEmoji(modelData);
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            StyledRect {
                                id: emojiIconBackground
                                width: emojiIcon.implicitWidth + 6 // Ancho variable basado en el emoji
                                height: 32
                                radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0
                                variant: root.selectedIndex === index && !root.isRecentFocused ? "overprimary" : "common"

                                Text {
                                    id: emojiIcon
                                    anchors.centerIn: parent
                                    color: emojiIconBackground.itemColor
                                    text: modelData.emoji
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                width: parent.width - emojiIcon.implicitWidth - 6 - parent.spacing - 16
                                text: modelData.search
                                color: textColor
                                font.family: Config.theme.font
                                font.weight: Font.Bold
                                font.pixelSize: Config.theme.fontSize
                                elide: Text.ElideRight
                            }
                        }
                    }

                    highlight: StyledRect {
                        variant: "primary"
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: root.selectedIndex >= 0 && !root.isRecentFocused
                    }

                    highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                    highlightMoveVelocity: -1
                }
            }

            // Separator
            Rectangle {
                width: 2
                height: parent.height
                radius: Config.roundness
                color: Colors.surface
            }

            // Recent emojis vertical list
            Item {
                width: LayoutMetrics.calculateRightPanelWidth(parent.height)
                height: parent.height
                visible: recentEmojis.length > 0 && searchText.length === 0

                ListView {
                    id: recentList
                    anchors.fill: parent
                    orientation: ListView.Vertical
                    spacing: 0
                    clip: true
                    cacheBuffer: 96
                    reuseItems: true

                    model: recentEmojis
                    currentIndex: root.selectedRecentIndex

                    onCurrentIndexChanged: {
                        if (currentIndex !== root.selectedRecentIndex && root.isRecentFocused) {
                            root.selectedRecentIndex = currentIndex;
                            root.lastSelectedRecentIndex = currentIndex;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: recentList.width
                        height: 48
                        color: "transparent"
                        radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0
                        
                        property color textColor: {
                            if (root.selectedRecentIndex === index && root.isRecentFocused) {
                                return Config.resolveColor(Config.theme.itemPrimary);
                            } else {
                                return Config.resolveColor(Config.theme.itemCommon);
                            }
                        }

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: false
                            propagateComposedEvents: true

                            onEntered: {
                                if (!root.isRecentFocused) {
                                    root.isRecentFocused = true;
                                    root.selectedIndex = -1;
                                    emojiList.currentIndex = -1;
                                }
                                root.selectedRecentIndex = index;
                                root.lastSelectedRecentIndex = index;
                                recentList.currentIndex = index;
                            }

                            onClicked: {
                                root.copyEmoji(modelData);
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            StyledRect {
                                id: recentEmojiIconBackground
                                width: recentEmojiIcon.implicitWidth + 6
                                height: 32
                                radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0
                                variant: root.selectedRecentIndex === index && root.isRecentFocused ? "overprimary" : "common"

                                Text {
                                    id: recentEmojiIcon
                                    anchors.centerIn: parent
                                    color: recentEmojiIconBackground.itemColor
                                    text: modelData.emoji
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                width: parent.width - recentEmojiIcon.implicitWidth - 6 - parent.spacing - 16
                                text: modelData.search
                                color: textColor
                                font.family: Config.theme.font
                                font.weight: Font.Bold
                                font.pixelSize: Config.theme.fontSize
                                elide: Text.ElideRight
                            }
                        }
                    }

                    highlight: StyledRect {
                        variant: "primary"
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: root.isRecentFocused
                    }

                    highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                    highlightMoveVelocity: -1
                }
            }

            // Placeholder cuando no hay recientes
            Item {
                width: LayoutMetrics.calculateRightPanelWidth(parent.height)
                height: parent.height
                visible: recentEmojis.length === 0 && searchText.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: Icons.countdown
                        font.family: Icons.font
                        font.pixelSize: 48
                        color: Colors.surfaceBright
                        anchors.horizontalCenter: parent.horizontalCenter
                        textFormat: Text.RichText
                    }

                    Text {
                        text: "No recent emojis"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        font.weight: Font.Bold
                        color: Colors.outline
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Visibilities.setActiveModule("");
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        loadEmojiData();
        loadRecentEmojis();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }

    // MouseArea para mantener el contexto de focus
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            focusSearchInput();
        }
    }
}
