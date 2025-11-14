import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Rectangle {
    id: root
    focus: true

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

    signal itemSelected

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
        copyProcess.command = ["bash", "-c", "echo -n '" + emoji.emoji.replace(/'/g, "'\\''") + "' | wl-copy"];
        copyProcess.running = true;
        addToRecent(emoji);
        typeTimer.start();
        pasteTimer.start();
        root.itemSelected();
    }

    function onDownPressed() {
        if (!hasNavigatedFromSearch) {
            // Primera vez presionando down desde search
            hasNavigatedFromSearch = true;
            if (recentEmojis.length > 0 && searchText.length === 0) {
                // Ir primero a la sección de recientes si hay recientes y no hay búsqueda
                isRecentFocused = true;
                selectedIndex = -1;
                emojiList.currentIndex = -1;
                if (lastSelectedRecentIndex >= 0 && lastSelectedRecentIndex < recentEmojis.length) {
                    selectedRecentIndex = lastSelectedRecentIndex;
                } else {
                    selectedRecentIndex = 0; // Start from first recent
                    lastSelectedRecentIndex = selectedRecentIndex; // Remember it
                }
                recentList.currentIndex = selectedRecentIndex;
            } else if (filteredEmojis.length > 0) {
                // Si no hay recientes o hay búsqueda, ir directo a emojis
                isRecentFocused = false;
                selectedRecentIndex = -1;
                recentList.currentIndex = -1;
                if (selectedIndex === -1) {
                    selectedIndex = 0;
                    emojiList.currentIndex = 0;
                }
            }
        } else {
            // Ya navegamos desde search, ahora navegamos dentro de secciones
            if (isRecentFocused) {
                // Cambiar de sección de recientes a emojis
                lastSelectedRecentIndex = selectedRecentIndex; // Remember last position
                isRecentFocused = false;
                selectedRecentIndex = -1;
                recentList.currentIndex = -1;
                if (filteredEmojis.length > 0) {
                    selectedIndex = 0;
                    emojiList.currentIndex = 0;
                }
            } else if (emojiList.count > 0 && selectedIndex >= 0) {
                if (selectedIndex < emojiList.count - 1) {
                    selectedIndex++;
                    emojiList.currentIndex = selectedIndex;
                } else if (selectedIndex === emojiList.count - 1 && recentEmojis.length > 0 && searchText.length === 0) {
                    // At end of normal list, go back to recent section
                    isRecentFocused = true;
                    selectedIndex = -1;
                    emojiList.currentIndex = -1;
                    if (lastSelectedRecentIndex >= 0 && lastSelectedRecentIndex < recentEmojis.length) {
                        selectedRecentIndex = lastSelectedRecentIndex;
                    } else {
                        selectedRecentIndex = 0;
                        lastSelectedRecentIndex = selectedRecentIndex; // Remember it
                    }
                    recentList.currentIndex = selectedRecentIndex;
                }
            }
        }
    }

    function onUpPressed() {
        if (isRecentFocused) {
            // If in recent section, go back to search
            lastSelectedRecentIndex = selectedRecentIndex; // Remember last position
            isRecentFocused = false;
            selectedRecentIndex = -1;
            recentList.currentIndex = -1;
            hasNavigatedFromSearch = false; // Allow going down again to recent
        } else if (selectedIndex > 0) {
            // Navigate within normal list
            selectedIndex--;
            emojiList.currentIndex = selectedIndex;
        } else if (selectedIndex === 0 && recentEmojis.length > 0 && searchText.length === 0) {
            // Go to recent section (last highlighted item)
            isRecentFocused = true;
            selectedIndex = -1;
            emojiList.currentIndex = -1;
            if (lastSelectedRecentIndex >= 0 && lastSelectedRecentIndex < recentEmojis.length) {
                selectedRecentIndex = lastSelectedRecentIndex;
            } else {
                selectedRecentIndex = 0;
                lastSelectedRecentIndex = selectedRecentIndex; // Remember it
            }
            recentList.currentIndex = selectedRecentIndex;
        } else if (selectedIndex === 0) {
            // Go back to search
            selectedIndex = -1;
            emojiList.currentIndex = -1;
            hasNavigatedFromSearch = false; // Allow going down again
        }
    }

    function onLeftPressed() {
        if (isRecentFocused && selectedRecentIndex > 0) {
            selectedRecentIndex--;
            recentList.currentIndex = selectedRecentIndex;
            lastSelectedRecentIndex = selectedRecentIndex; // Remember position
        }
    }

    function onRightPressed() {
        if (isRecentFocused && selectedRecentIndex < recentEmojis.length - 1) {
            selectedRecentIndex++;
            recentList.currentIndex = selectedRecentIndex;
            lastSelectedRecentIndex = selectedRecentIndex; // Remember position
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

    // Type emoji
    Process {
        id: typeProcess
        command: ["bash", "-c", "wl-paste | wtype"]
        running: false
    }

    // Paste emoji
    Process {
        id: pasteProcess
        command: ["wtype", "-M", "ctrl", "-k", "v"]
        running: false
    }

    Timer {
        id: typeTimer
        interval: 100
        onTriggered: {
            typeProcess.running = true;
        }
    }

    Timer {
        id: pasteTimer
        interval: 150
        onTriggered: {
            pasteProcess.running = true;
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
                placeholderText: "Search emojis..."

                onSearchTextChanged: text => {
                    root.searchText = text;
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
                        root.itemSelected();
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
            Rectangle {
                id: clearButton
                Layout.preferredWidth: root.clearButtonConfirmState ? clearButtonContent.implicitWidth + 32 : 48
                Layout.preferredHeight: 48
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

                Behavior on Layout.preferredWidth {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
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

                RowLayout {
                    id: clearButtonContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        Layout.preferredWidth: 32
                        text: root.clearButtonConfirmState ? Icons.xeyes : Icons.broom
                        font.family: Icons.font
                        font.pixelSize: 20
                        color: root.clearButtonConfirmState ? Colors.overError : Colors.primary
                        horizontalAlignment: Text.AlignHCenter
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
                        Layout.fillWidth: true
                        text: "Clear recent?"
                        font.family: Config.theme.font
                        font.weight: Font.Bold
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overError
                        opacity: root.clearButtonConfirmState ? 1.0 : 0.0
                        visible: opacity > 0

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

        // Contenedor de listas de emojis
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            // Recent emojis horizontal list
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                visible: recentEmojis.length > 0 && searchText.length === 0

                ListView {
                    id: recentList
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 8
                    clip: true
                    cacheBuffer: 96
                    reuseItems: true

                    model: recentEmojis
                    currentIndex: root.selectedRecentIndex

                    onCurrentIndexChanged: {
                        if (currentIndex !== root.selectedRecentIndex && root.isRecentFocused) {
                            root.selectedRecentIndex = currentIndex;
                            root.lastSelectedRecentIndex = currentIndex; // Remember position
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: emojiText.implicitWidth + 24 // Ancho basado en el contenido del emoji + padding
                        height: 48
                        color: "transparent"
                        radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0

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

                            onEntered: {
                                if (!root.isRecentFocused) {
                                    root.isRecentFocused = true;
                                    root.selectedIndex = -1;
                                    emojiList.currentIndex = -1;
                                }
                                root.selectedRecentIndex = index;
                                root.lastSelectedRecentIndex = index; // Remember position
                                recentList.currentIndex = index;
                            }

                            onClicked: {
                                root.copyEmoji(modelData);
                            }
                        }

                        Text {
                            id: emojiText
                            anchors.centerIn: parent
                            text: modelData.emoji
                            color: Colors.overBackground
                            font.pixelSize: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    highlight: Rectangle {
                        color: Colors.primary
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: root.isRecentFocused
                    }

                    highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                    highlightMoveVelocity: -1
                }
            }

            // Emoji list
            ListView {
                id: emojiList
                Layout.fillWidth: true
                Layout.preferredHeight: (recentEmojis.length > 0 && searchText.length === 0 ? 4 : 5) * 48
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

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

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

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: emojiIcon.implicitWidth + 6 // Ancho variable basado en el emoji
                            Layout.preferredHeight: 32
                            radius: Config.roundness > 0 ? Math.max(Config.roundness - 4, 0) : 0
                            color: root.selectedIndex === index && !root.isRecentFocused ? Colors.overPrimary : Colors.surface

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Text {
                                id: emojiIcon
                                anchors.centerIn: parent
                                color: root.selectedIndex === index && !root.isRecentFocused ? Colors.overPrimary : Colors.overBackground
                                // Layout.preferredWidth: implicitWidth + 8 // Ancho variable basado en el emoji
                                // Layout.preferredHeight: 32
                                text: modelData.emoji
                                font.pixelSize: 24
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.search
                            color: root.selectedIndex === index && !root.isRecentFocused ? Colors.overPrimary : Colors.overBackground
                            font.family: Config.theme.font
                            font.weight: Font.Bold
                            font.pixelSize: Config.theme.fontSize
                            elide: Text.ElideRight

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                highlight: Rectangle {
                    color: Colors.primary
                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                    visible: root.selectedIndex >= 0 && !root.isRecentFocused
                }

                highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                highlightMoveVelocity: -1
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.itemSelected();
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        loadEmojiData();
        loadRecentEmojis();
        focusSearchInput();
    }
}
