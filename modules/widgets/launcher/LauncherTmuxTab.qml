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

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property var tmuxSessions: []
    property alias filteredSessions: listModel.sessions

    // Delete mode state
    property bool deleteMode: false
    property string sessionToDelete: ""
    property int originalSelectedIndex: -1
    property int deleteButtonIndex: 0 // 0 = cancel, 1 = confirm

    // Rename mode state
    property bool renameMode: false
    property string sessionToRename: ""
    property string newSessionName: ""
    property int renameSelectedIndex: -1
    property int renameButtonIndex: 0 // 0 = cancel, 1 = confirm
    property string pendingRenamedSession: "" // Track session to select after rename

    // Options menu state
    property bool optionsMenuOpen: false
    property int menuItemIndex: -1
    property bool menuJustClosed: false

    signal itemSelected

    QtObject {
        id: listModel
        property var sessions: []

        function updateSessions(newSessions) {
            sessions = newSessions;
        }
    }

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && resultsList.count > 0) {
            resultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredSessions();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        searchInput.focusInput();
        updateFilteredSessions();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function cancelDeleteModeFromExternal() {
        if (deleteMode) {
            console.log("DEBUG: Canceling delete mode from external source (tab change)");
            cancelDeleteMode();
        }
        if (renameMode) {
            console.log("DEBUG: Canceling rename mode from external source (tab change)");
            cancelRenameMode();
        }
    }

    function updateFilteredSessions() {
        var newFilteredSessions = [];

        if (searchText.length === 0) {
            newFilteredSessions = tmuxSessions.slice(); // Copia del array
        } else {
            newFilteredSessions = tmuxSessions.filter(function (session) {
                return session.name.toLowerCase().includes(searchText.toLowerCase());
            });

            let exactMatch = tmuxSessions.find(function (session) {
                return session.name.toLowerCase() === searchText.toLowerCase();
            });

            if (!exactMatch && searchText.length > 0) {
                newFilteredSessions.push({
                    name: `Create session "${searchText}"`,
                    isCreateSpecificButton: true,
                    sessionNameToCreate: searchText,
                    icon: "terminal"
                });
            }
        }

        if (searchText.length === 0 && !deleteMode && !renameMode) {
            newFilteredSessions.push({
                name: "Create new session",
                isCreateButton: true,
                icon: "terminal"
            });
        }

        listModel.updateSessions(newFilteredSessions);

        if (!deleteMode && !renameMode) {
            if (searchText.length > 0 && newFilteredSessions.length > 0) {
                selectedIndex = 0;
                resultsList.currentIndex = 0;
            } else if (searchText.length === 0) {
                selectedIndex = -1;
                resultsList.currentIndex = -1;
            }
        }

        if (pendingRenamedSession !== "") {
            for (let i = 0; i < newFilteredSessions.length; i++) {
                if (newFilteredSessions[i].name === pendingRenamedSession) {
                    selectedIndex = i;
                    resultsList.currentIndex = i;
                    pendingRenamedSession = "";
                    break;
                }
            }
            if (pendingRenamedSession !== "") {
                pendingRenamedSession = "";
            }
        }
    }

    function enterDeleteMode(sessionName) {
        originalSelectedIndex = selectedIndex;
        deleteMode = true;
        sessionToDelete = sessionName;
        deleteButtonIndex = 0;
        root.forceActiveFocus();
    }

    function cancelDeleteMode() {
        deleteMode = false;
        sessionToDelete = "";
        deleteButtonIndex = 0;
        searchInput.focusInput();
        updateFilteredSessions();
        selectedIndex = originalSelectedIndex;
        resultsList.currentIndex = originalSelectedIndex;
        originalSelectedIndex = -1;
    }

    function confirmDeleteSession() {
        killProcess.command = ["tmux", "kill-session", "-t", sessionToDelete];
        killProcess.running = true;
        cancelDeleteMode();
    }

    function enterRenameMode(sessionName) {
        renameSelectedIndex = selectedIndex;
        renameMode = true;
        sessionToRename = sessionName;
        newSessionName = sessionName;
        renameButtonIndex = 1;
        root.forceActiveFocus();
        Qt.callLater(() => {
        });
    }

    function cancelRenameMode() {
        renameMode = false;
        sessionToRename = "";
        newSessionName = "";
        renameButtonIndex = 1;
        if (pendingRenamedSession === "") {
            searchInput.focusInput();
            updateFilteredSessions();
            selectedIndex = renameSelectedIndex;
            resultsList.currentIndex = renameSelectedIndex;
        } else {
            searchInput.focusInput();
        }
        renameSelectedIndex = -1;
    }

    function confirmRenameSession() {
        if (newSessionName.trim() !== "" && newSessionName !== sessionToRename) {
            renameProcess.command = ["tmux", "rename-session", "-t", sessionToRename, newSessionName.trim()];
            renameProcess.running = true;
        } else {
            cancelRenameMode();
        }
    }

    function refreshTmuxSessions() {
        tmuxProcess.running = true;
    }

    function createTmuxSession(sessionName) {
        if (sessionName) {
            createProcess.command = ["bash", "-c", `cd "$HOME" && setsid kitty -e tmux new -s "${sessionName}" < /dev/null > /dev/null 2>&1 &`];
        } else {
            createProcess.command = ["bash", "-c", `cd "$HOME" && setsid kitty -e tmux < /dev/null > /dev/null 2>&1 &`];
        }
        createProcess.running = true;
        root.itemSelected(); // Cerrar el notch
    }

    function attachToSession(sessionName) {
        attachProcess.command = ["bash", "-c", `cd "$HOME" && setsid kitty -e tmux attach-session -t "${sessionName}" < /dev/null > /dev/null 2>&1 &`];
        attachProcess.running = true;
    }

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        enabled: root.deleteMode || root.renameMode
        z: -10

        onClicked: {
            if (root.deleteMode) {
                root.cancelDeleteMode();
            } else if (root.renameMode) {
                root.cancelRenameMode();
            }
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Process {
        id: tmuxProcess
        command: ["tmux", "list-sessions", "-F", "#{session_name}"]
        running: false

        stdout: StdioCollector {
            id: tmuxCollector
            waitForEnd: true

            onStreamFinished: {
                let sessions = [];
                let lines = text.trim().split('\n');
                for (let line of lines) {
                    if (line.trim().length > 0) {
                        sessions.push({
                            name: line.trim(),
                            isCreateButton: false,
                            icon: "terminal"
                        });
                    }
                }
                root.tmuxSessions = sessions;
                root.updateFilteredSessions();
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                root.tmuxSessions = [];
                root.updateFilteredSessions();
            }
        }
    }

    Process {
        id: createProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                root.refreshTmuxSessions();
            }
        }
    }

    Process {
        id: attachProcess
        running: false

        onStarted: function () {
            root.itemSelected();
        }
    }

    Process {
        id: killProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                // Sesión eliminada exitosamente, refrescar la lista
                root.refreshTmuxSessions();
            }
        }
    }

    Process {
        id: renameProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                // Sesión renombrada exitosamente, marcar para seleccionar después del refresh
                root.pendingRenamedSession = root.newSessionName;
                root.refreshTmuxSessions();
            }
            root.cancelRenameMode();
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Search input
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            text: root.searchText
            placeholderText: "Search or create tmux session..."
            iconText: ""

            onSearchTextChanged: text => {
                root.searchText = text;
            }

            onAccepted: {
                if (root.deleteMode) {
                    root.cancelDeleteMode();
                } else {
                    if (root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                        let selectedSession = root.filteredSessions[root.selectedIndex];
                        if (selectedSession) {
                            if (selectedSession.isCreateSpecificButton) {
                                root.createTmuxSession(selectedSession.sessionNameToCreate);
                            } else if (selectedSession.isCreateButton) {
                                root.createTmuxSession();
                            } else {
                                root.attachToSession(selectedSession.name);
                            }
                        }
                    } else {
                        console.log("DEBUG: No action taken - selectedIndex:", root.selectedIndex, "count:", resultsList.count);
                    }
                }
            }

            onShiftAccepted: {
                if (!root.deleteMode && root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                    let selectedSession = root.filteredSessions[root.selectedIndex];
                    if (selectedSession && !selectedSession.isCreateButton && !selectedSession.isCreateSpecificButton) {
                        root.enterDeleteMode(selectedSession.name);
                    }
                }
            }

            onCtrlRPressed: {
                if (!root.deleteMode && !root.renameMode && root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                    let selectedSession = root.filteredSessions[root.selectedIndex];
                    if (selectedSession && !selectedSession.isCreateButton && !selectedSession.isCreateSpecificButton) {
                        root.enterRenameMode(selectedSession.name);
                    }
                }
            }

            onEscapePressed: {
                if (!root.deleteMode && !root.renameMode) {
                    root.itemSelected();
                }
                // Si estamos en modo eliminar o renombrar, no hacer nada aquí
                // El handler global del root se encargará
            }

            onDownPressed: {
                if (!root.deleteMode && !root.renameMode && resultsList.count > 0) {
                    if (root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                        resultsList.currentIndex = 0;
                    } else if (root.selectedIndex < resultsList.count - 1) {
                        root.selectedIndex++;
                        resultsList.currentIndex = root.selectedIndex;
                    }
                }
            }

            onUpPressed: {
                if (!root.deleteMode && !root.renameMode) {
                    if (root.selectedIndex > 0) {
                        root.selectedIndex--;
                        resultsList.currentIndex = root.selectedIndex;
                    } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                        root.selectedIndex = -1;
                        resultsList.currentIndex = -1;
                    }
                }
            }

            onPageDownPressed: {
                if (!root.deleteMode && !root.renameMode && resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 28);
                    let newIndex = Math.min(root.selectedIndex + visibleItems, resultsList.count - 1);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.min(visibleItems - 1, resultsList.count - 1);
                    }
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onPageUpPressed: {
                if (!root.deleteMode && !root.renameMode && resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 28);
                    let newIndex = Math.max(root.selectedIndex - visibleItems, 0);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.max(resultsList.count - visibleItems, 0);
                    }
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onHomePressed: {
                if (!root.deleteMode && !root.renameMode && resultsList.count > 0) {
                    root.selectedIndex = 0;
                    resultsList.currentIndex = 0;
                }
            }

            onEndPressed: {
                if (!root.deleteMode && !root.renameMode && resultsList.count > 0) {
                    root.selectedIndex = resultsList.count - 1;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true
            interactive: !root.deleteMode && !root.renameMode && !root.optionsMenuOpen

            model: root.filteredSessions
            currentIndex: root.selectedIndex

            onCurrentIndexChanged: {
                if (currentIndex !== root.selectedIndex) {
                    root.selectedIndex = currentIndex;
                }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: resultsList.width
                height: 48
                color: "transparent"
                radius: 16
                clip: true

                property bool isInDeleteMode: root.deleteMode && modelData.name === root.sessionToDelete
                property bool isInRenameMode: root.renameMode && modelData.name === root.sessionToRename

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !isInDeleteMode && !isInRenameMode && !root.optionsMenuOpen
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property real startX: 0
                    property real startY: 0
                    property bool isDragging: false
                    property bool longPressTriggered: false

                    onEntered: {
                        if (!root.deleteMode && !root.renameMode && !root.optionsMenuOpen) {
                            root.selectedIndex = index;
                            resultsList.currentIndex = index;
                        }
                    }

                    onClicked: mouse => {
                        if (root.menuJustClosed) {
                            return;
                        }

                        if (mouse.button === Qt.LeftButton) {
                            if (root.deleteMode && modelData.name !== root.sessionToDelete) {
                                root.cancelDeleteMode();
                                return;
                            } else if (root.renameMode && modelData.name !== root.sessionToRename) {
                                root.cancelRenameMode();
                                return;
                            }

                            if (!root.deleteMode && !root.renameMode) {
                                if (modelData.isCreateSpecificButton) {
                                    root.createTmuxSession(modelData.sessionNameToCreate);
                                } else if (modelData.isCreateButton) {
                                    root.createTmuxSession();
                                } else {
                                    root.attachToSession(modelData.name);
                                }
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (root.deleteMode || root.renameMode) {
                                if (root.deleteMode) {
                                    root.cancelDeleteMode();
                                } else if (root.renameMode) {
                                    root.cancelRenameMode();
                                }
                                return;
                            }

                            if (!modelData.isCreateButton && !modelData.isCreateSpecificButton) {
                                root.menuItemIndex = index;
                                root.optionsMenuOpen = true;
                                contextMenu.popup(mouse.x, mouse.y);
                            }
                        }
                    }

                    onPressed: mouse => {
                        startX = mouse.x;
                        startY = mouse.y;
                        isDragging = false;
                        longPressTriggered = false;

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

                                if (deltaX < -50 && Math.abs(deltaY) < 30 && !modelData.isCreateButton && !modelData.isCreateSpecificButton) {
                                    if (!longPressTriggered) {
                                        root.enterDeleteMode(modelData.name);
                                        longPressTriggered = true;
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

                    Timer {
                        id: longPressTimer
                        interval: 800
                        repeat: false
                        onTriggered: {
                            if (!mouseArea.isDragging && !modelData.isCreateButton && !modelData.isCreateSpecificButton) {
                                root.enterRenameMode(modelData.name);
                                mouseArea.longPressTriggered = true;
                            }
                        }
                        }
                    }

                    OptionsMenu {
                    id: contextMenu

                    onClosed: {
                        root.optionsMenuOpen = false;
                        root.menuItemIndex = -1;
                        root.menuJustClosed = true;
                        menuClosedTimer.start();
                    }

                    Timer {
                        id: menuClosedTimer
                        interval: 100
                        repeat: false
                        onTriggered: {
                            root.menuJustClosed = false;
                        }
                    }

                    items: [
                        {
                            text: "Rename",
                            icon: Icons.edit,
                            highlightColor: Colors.secondary,
                            textColor: Colors.overSecondary,
                            onTriggered: function () {
                                root.enterRenameMode(modelData.name);
                            }
                        },
                        {
                            text: "Quit",
                            icon: Icons.alert,
                            highlightColor: Colors.errorContainer,
                            textColor: Colors.error,
                            onTriggered: function () {
                                root.enterDeleteMode(modelData.name);
                            }
                        }
                    ]
                    }

                    Rectangle {
                        id: renameActionContainer
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 8
                        width: 68
                        height: 32
                    color: "transparent"
                    opacity: isInRenameMode ? 1.0 : 0.0
                    visible: opacity > 0

                    transform: Translate {
                        x: isInRenameMode ? 0 : 80

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

                        Rectangle {
                        id: renameHighlight
                        color: Colors.overSecondary
                        radius: Config.roundness > 4 ? Config.roundness - 4 : 0
                        visible: isInRenameMode
                        z: 0

                        property real activeButtonMargin: 2
                        property real idx1X: root.renameButtonIndex
                        property real idx2X: root.renameButtonIndex

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
                        id: renameActionButtons
                        anchors.fill: parent
                        spacing: 4

                        // Botón cancelar (cruz) para rename
                        Rectangle {
                            id: renameCancelButton
                            width: 32
                            height: 32
                            color: "transparent"
                            radius: 6
                            border.width: 0
                            border.color: Colors.outline
                            z: 1

                            property bool isHighlighted: root.renameButtonIndex === 0

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.cancelRenameMode()
                                onEntered: {
                                    root.renameButtonIndex = 0;
                                }
                                onExited: parent.color = "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.cancel
                                color: renameCancelButton.isHighlighted ? Colors.secondary : Colors.overSecondary
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

                        Rectangle {
                            id: renameConfirmButton
                            width: 32
                            height: 32
                            color: "transparent"
                            radius: 6
                            z: 1

                            property bool isHighlighted: root.renameButtonIndex === 1

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.confirmRenameSession()
                                onEntered: {
                                    root.renameButtonIndex = 1;
                                }
                                onExited: parent.color = "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.accept
                                color: renameConfirmButton.isHighlighted ? Colors.secondary : Colors.overSecondary
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

                    RowLayout {
                        id: mainContent
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.rightMargin: isInRenameMode ? 84 : 8
                        spacing: 8

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
                            if (isInDeleteMode) {
                                return Colors.overError;
                            } else if (isInRenameMode) {
                                return Colors.overSecondary;
                            } else if (root.selectedIndex === index) {
                                return Colors.overPrimary;
                            } else if (modelData.isCreateButton) {
                                return Colors.primary;
                            } else {
                                return Colors.surface;
                            }
                        }
                        radius: Config.roundness > 4 ? Config.roundness - 4 : 0

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (isInDeleteMode) {
                                    return Icons.alert;
                                } else if (isInRenameMode) {
                                    return Icons.edit;
                                } else if (modelData.isCreateButton || modelData.isCreateSpecificButton) {
                                    return Icons.add;
                                } else {
                                    return Icons.terminalWindow;
                                }
                            }
                            color: {
                                if (isInDeleteMode) {
                                    return Colors.error;
                                } else if (isInRenameMode) {
                                    return Colors.secondary;
                                } else if (root.selectedIndex === index) {
                                    return Colors.primary;
                                } else if (modelData.isCreateButton) {
                                    return Colors.background;
                                } else {
                                    return Colors.overSurface;
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

                        ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: {
                                if (root.renameMode && modelData.name === root.sessionToRename) {
                                    return renameTextInput;
                                } else {
                                    return normalText;
                                }
                            }
                        }

                        Component {
                            id: normalText
                            Text {
                                text: {
                                    if (isInDeleteMode && !modelData.isCreateButton && !modelData.isCreateSpecificButton) {
                                        return `Quit "${root.sessionToDelete}"?`;
                                    } else {
                                        return modelData.name;
                                    }
                                }
                                color: isInDeleteMode ? Colors.overError : (root.selectedIndex === index ? Colors.overPrimary : Colors.overBackground)
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: isInDeleteMode ? Font.Bold : (modelData.isCreateButton ? Font.Medium : Font.Bold)
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        Component {
                            id: renameTextInput
                            TextField {
                                text: root.newSessionName
                                color: Colors.overSecondary
                                selectionColor: Colors.overSecondary
                                selectedTextColor: Colors.secondary
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Bold
                                background: Rectangle {
                                    color: "transparent"
                                    border.width: 0
                                }
                                selectByMouse: true

                                onTextChanged: {
                                    root.newSessionName = text;
                                }

                                Component.onCompleted: {
                                    Qt.callLater(() => {
                                        forceActiveFocus();
                                        selectAll();
                                    });
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.confirmRenameSession();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.cancelRenameMode();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }
                    }

                    Rectangle {
                        id: actionContainer
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 8
                        width: 68
                        height: 32
                    color: "transparent"
                    opacity: isInDeleteMode ? 1.0 : 0.0
                    visible: opacity > 0

                    transform: Translate {
                        x: isInDeleteMode ? 0 : 80

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

                        Rectangle {
                        id: deleteHighlight
                        color: Colors.overError
                        radius: Config.roundness > 4 ? Config.roundness - 4 : 0
                        visible: isInDeleteMode
                        z: 0

                        property real activeButtonMargin: 2
                        property real idx1X: root.deleteButtonIndex
                        property real idx2X: root.deleteButtonIndex

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
                            border.color: Colors.outline
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
                                color: cancelButton.isHighlighted ? Colors.error : Colors.overError
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
                                onClicked: root.confirmDeleteSession()
                                onEntered: {
                                    root.deleteButtonIndex = 1;
                                }
                                onExited: parent.color = "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.accept
                                color: confirmButton.isHighlighted ? Colors.error : Colors.overError
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
            }

            highlight: Rectangle {
                color: {
                    if (root.deleteMode) {
                        return Colors.error;
                    } else if (root.renameMode) {
                        return Colors.secondary;
                    } else {
                        return Colors.primary;
                    }
                }
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                visible: root.selectedIndex >= 0 && (root.optionsMenuOpen ? root.selectedIndex === root.menuItemIndex : true)

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutQuart
                    }
                }
            }

            highlightMoveDuration: Config.animDuration / 2
            highlightMoveVelocity: -1
        }

        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: resultsList.height
            enabled: root.deleteMode || root.renameMode
            z: 1000

            onClicked: {
                if (root.deleteMode) {
                    root.cancelDeleteMode();
                } else if (root.renameMode) {
                    root.cancelRenameMode();
                }
            }
        }
    }

    Component.onCompleted: {
        refreshTmuxSessions();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }

    Keys.onPressed: event => {
                if (root.deleteMode) {
                    if (event.key === Qt.Key_Left) {
                        root.deleteButtonIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        root.deleteButtonIndex = 1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                        if (root.deleteButtonIndex === 0) {
                            root.cancelDeleteMode();
                        } else {
                            root.confirmDeleteSession();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.cancelDeleteMode();
                        event.accepted = true;
                    }
                } else if (root.renameMode) {
                    if (event.key === Qt.Key_Left) {
                        root.renameButtonIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right) {
                        root.renameButtonIndex = 1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                        if (root.renameButtonIndex === 0) {
                            root.cancelRenameMode();
                        } else {
                            root.confirmRenameSession();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.cancelRenameMode();
                        event.accepted = true;
                    }
                }
            }

            onDeleteModeChanged: {
                if (!deleteMode) {
                }
            }

            onRenameModeChanged: {
                if (!renameMode) {
                }
            }
}
