import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.config
import "../clipboard"
import "../emoji"
import "../tmux"
import "../wallpapers"
import "calendar"

Rectangle {
    color: "transparent"
    implicitWidth: 600
    implicitHeight: 300

    property int currentTab: 0  // 0=launcher, 1=clip, 2=emoji, 3=tmux, 4=wall
    property bool prefixDisabled: false  // Flag to prevent re-activation after backspace

    // Function to focus app search when tab becomes active
    function focusAppSearch() {
        Qt.callLater(() => {
            if (currentTab === 0) {
                appLauncher.focusSearchInput();
            } else {
                let currentItem = internalStack.itemAt(currentTab);
                if (currentItem && currentItem.focusSearchInput) {
                    currentItem.focusSearchInput();
                }
            }
        });
    }

    // Expose this for Dashboard compatibility
    function focusSearchInput() {
        focusAppSearch();
    }

    // Handle prefix detection in launcher
    function detectPrefix(text) {
        // If prefix was manually disabled, don't re-enable until conditions are met
        if (prefixDisabled) {
            // Only re-enable prefix if user deletes the prefix text or adds valid content
            if (text === "clip " || text === "emoji " || text === "tmux " || text === "wall ") {
                // Still at exact prefix - keep disabled
                return 0;
            } else if (!text.startsWith("clip ") && !text.startsWith("emoji ") && !text.startsWith("tmux ") && !text.startsWith("wall ")) {
                // User deleted the prefix - re-enable detection
                prefixDisabled = false;
                return 0;
            } else {
                // User typed something after the prefix but it's still disabled
                return 0;
            }
        }

        // Normal prefix detection - only activate if exactly "prefix " (nothing after)
        if (text === "clip ") {
            return 1;
        } else if (text === "emoji ") {
            return 2;
        } else if (text === "tmux ") {
            return 3;
        } else if (text === "wall ") {
            return 4;
        }
        return 0;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // App Launcher - shown only when currentTab === 0
        Rectangle {
            id: appLauncher
            Layout.preferredWidth: {
                var remainingWidth = parent.width - parent.spacing * 2 - 2; // Total - separators - separator width
                var gridRows = 3;
                var gridColumns = 5;
                var wallpaperHeight = (parent.height + 4 * 2) / gridRows;
                var rightPanelWidth = (wallpaperHeight * gridColumns) - 8;
                return remainingWidth - rightPanelWidth;
            }
            Layout.fillHeight: true
            visible: currentTab === 0
            color: "transparent"

            property string searchText: GlobalStates.launcherSearchText
            property bool showResults: searchText.length > 0
            property int selectedIndex: GlobalStates.launcherSelectedIndex
            property bool optionsMenuOpen: false
            property int menuItemIndex: -1
            property bool menuJustClosed: false

            onSearchTextChanged: {
                // Detect prefix and switch tab if needed
                let detectedTab = detectPrefix(searchText);
                if (detectedTab !== currentTab) {
                    if (detectedTab === 0) {
                        // Return to launcher
                        currentTab = 0;
                        prefixDisabled = false;
                        Qt.callLater(() => {
                            appLauncher.focusSearchInput();
                        });
                    } else {
                        // Switch to prefix tab
                        currentTab = detectedTab;

                        // Extract the text after the prefix
                        let prefixLength = 0;
                        if (searchText.startsWith("clip "))
                            prefixLength = 5;
                        else if (searchText.startsWith("emoji "))
                            prefixLength = 6;
                        else if (searchText.startsWith("tmux "))
                            prefixLength = 5;
                        else if (searchText.startsWith("wall "))
                            prefixLength = 5;

                        let remainingText = searchText.substring(prefixLength);

                        // Focus the new tab after a brief delay to ensure it's loaded
                        Qt.callLater(() => {
                            let targetItem = null;

                            if (detectedTab === 1 && clipboardLoader.item) {
                                targetItem = clipboardLoader.item;
                            } else if (detectedTab === 2 && emojiLoader.item) {
                                targetItem = emojiLoader.item;
                            } else if (detectedTab === 3 && tmuxLoader.item) {
                                targetItem = tmuxLoader.item;
                            } else if (detectedTab === 4 && wallpapersLoader.item) {
                                targetItem = wallpapersLoader.item;
                            }

                            if (targetItem) {
                                // Set the search text in the new tab
                                if (targetItem.searchText !== undefined) {
                                    targetItem.searchText = remainingText;
                                }
                                // Focus the search input
                                if (targetItem.focusSearchInput) {
                                    targetItem.focusSearchInput();
                                }
                            }
                        });
                    }
                }
            }

            onSelectedIndexChanged: {
                if (selectedIndex === -1 && resultsList.count > 0) {
                    resultsList.positionViewAtIndex(0, ListView.Beginning);
                }
            }

            function clearSearch() {
                GlobalStates.clearLauncherState();
                searchInput.focusInput();
            }

            function focusSearchInput() {
                searchInput.focusInput();
            }

            Behavior on height {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
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
                    text: GlobalStates.launcherSearchText
                    placeholderText: "Search applications..."
                    iconText: ""

                    onSearchTextChanged: text => {
                        GlobalStates.launcherSearchText = text;
                        appLauncher.searchText = text;
                        if (text.length > 0) {
                            GlobalStates.launcherSelectedIndex = 0;
                            appLauncher.selectedIndex = 0;
                            resultsList.currentIndex = 0;
                        } else {
                            GlobalStates.launcherSelectedIndex = -1;
                            appLauncher.selectedIndex = -1;
                            resultsList.currentIndex = -1;
                        }
                    }

                    onAccepted: {
                        if (appLauncher.selectedIndex >= 0 && appLauncher.selectedIndex < resultsList.count) {
                            let selectedApp = resultsList.model[appLauncher.selectedIndex];
                            if (selectedApp) {
                                selectedApp.execute();
                                Visibilities.setActiveModule("");
                            }
                        }
                    }

                    onEscapePressed: {
                        Visibilities.setActiveModule("");
                    }

                    onDownPressed: {
                        if (resultsList.count > 0) {
                            if (appLauncher.selectedIndex === -1) {
                                GlobalStates.launcherSelectedIndex = 0;
                                appLauncher.selectedIndex = 0;
                                resultsList.currentIndex = 0;
                            } else if (appLauncher.selectedIndex < resultsList.count - 1) {
                                GlobalStates.launcherSelectedIndex++;
                                appLauncher.selectedIndex++;
                                resultsList.currentIndex = appLauncher.selectedIndex;
                            }
                        }
                    }

                    onUpPressed: {
                        if (appLauncher.selectedIndex > 0) {
                            GlobalStates.launcherSelectedIndex--;
                            appLauncher.selectedIndex--;
                            resultsList.currentIndex = appLauncher.selectedIndex;
                        } else if (appLauncher.selectedIndex === 0 && appLauncher.searchText.length === 0) {
                            GlobalStates.launcherSelectedIndex = -1;
                            appLauncher.selectedIndex = -1;
                            resultsList.currentIndex = -1;
                        }
                    }

                    onPageDownPressed: {
                        if (resultsList.count > 0) {
                            let visibleItems = Math.floor(resultsList.height / 48);
                            let newIndex = Math.min(appLauncher.selectedIndex + visibleItems, resultsList.count - 1);
                            if (appLauncher.selectedIndex === -1) {
                                newIndex = Math.min(visibleItems - 1, resultsList.count - 1);
                            }
                            GlobalStates.launcherSelectedIndex = newIndex;
                            appLauncher.selectedIndex = newIndex;
                            resultsList.currentIndex = appLauncher.selectedIndex;
                        }
                    }

                    onPageUpPressed: {
                        if (resultsList.count > 0) {
                            let visibleItems = Math.floor(resultsList.height / 48);
                            let newIndex = Math.max(appLauncher.selectedIndex - visibleItems, 0);
                            if (appLauncher.selectedIndex === -1) {
                                newIndex = Math.max(resultsList.count - visibleItems, 0);
                            }
                            GlobalStates.launcherSelectedIndex = newIndex;
                            appLauncher.selectedIndex = newIndex;
                            resultsList.currentIndex = appLauncher.selectedIndex;
                        }
                    }

                    onHomePressed: {
                        if (resultsList.count > 0) {
                            GlobalStates.launcherSelectedIndex = 0;
                            appLauncher.selectedIndex = 0;
                            resultsList.currentIndex = 0;
                        }
                    }

                    onEndPressed: {
                        if (resultsList.count > 0) {
                            GlobalStates.launcherSelectedIndex = resultsList.count - 1;
                            appLauncher.selectedIndex = resultsList.count - 1;
                            resultsList.currentIndex = appLauncher.selectedIndex;
                        }
                    }
                }

                // Results list
                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 7 * 48
                    visible: true
                    clip: true
                    interactive: !appLauncher.optionsMenuOpen
                    cacheBuffer: 96
                    reuseItems: true

                    model: appLauncher.searchText.length > 0 ? AppSearch.fuzzyQuery(appLauncher.searchText) : AppSearch.getAllApps()
                    currentIndex: appLauncher.selectedIndex

                    onCurrentIndexChanged: {
                        if (currentIndex !== appLauncher.selectedIndex) {
                            GlobalStates.launcherSelectedIndex = currentIndex;
                            appLauncher.selectedIndex = currentIndex;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: resultsList.width
                        height: 48
                        color: "transparent"
                        radius: 16

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onEntered: {
                                if (!appLauncher.optionsMenuOpen) {
                                    GlobalStates.launcherSelectedIndex = index;
                                    appLauncher.selectedIndex = index;
                                    resultsList.currentIndex = index;
                                }
                            }
                            onClicked: mouse => {
                                if (appLauncher.menuJustClosed) {
                                    return;
                                }

                                if (mouse.button === Qt.LeftButton) {
                                    modelData.execute();
                                    Visibilities.setActiveModule("");
                                } else if (mouse.button === Qt.RightButton) {
                                    appLauncher.menuItemIndex = index;
                                    appLauncher.optionsMenuOpen = true;
                                    contextMenu.popup(mouse.x, mouse.y);
                                }
                            }

                            OptionsMenu {
                                id: contextMenu

                                onClosed: {
                                    appLauncher.optionsMenuOpen = false;
                                    appLauncher.menuItemIndex = -1;
                                    appLauncher.menuJustClosed = true;
                                    menuClosedTimer.start();
                                }

                                Timer {
                                    id: menuClosedTimer
                                    interval: 100
                                    repeat: false
                                    onTriggered: {
                                        appLauncher.menuJustClosed = false;
                                    }
                                }

                                items: [
                                    {
                                        text: "Launch",
                                        icon: Icons.launch,
                                        highlightColor: Colors.primary,
                                        textColor: Colors.overPrimary,
                                        onTriggered: function () {
                                            modelData.execute();
                                            Visibilities.setActiveModule("");
                                        }
                                    },
                                    {
                                        text: "Create Shortcut",
                                        icon: Icons.shortcut,
                                        highlightColor: Colors.secondary,
                                        textColor: Colors.overSecondary,
                                        onTriggered: function () {
                                            let desktopDir = Quickshell.env("XDG_DESKTOP_DIR") || Quickshell.env("HOME") + "/Desktop";
                                            let timestamp = Date.now();
                                            let fileName = modelData.id + "-" + timestamp + ".desktop";
                                            let filePath = desktopDir + "/" + fileName;

                                            let desktopContent = "[Desktop Entry]\n" + "Version=1.0\n" + "Type=Application\n" + "Name=" + modelData.name + "\n" + "Exec=" + modelData.execString + "\n" + "Icon=" + modelData.icon + "\n" + (modelData.comment ? "Comment=" + modelData.comment + "\n" : "") + (modelData.categories.length > 0 ? "Categories=" + modelData.categories.join(";") + ";\n" : "") + (modelData.runInTerminal ? "Terminal=true\n" : "Terminal=false\n");

                                            let writeCmd = "printf '%s' '" + desktopContent.replace(/'/g, "'\\''") + "' > \"" + filePath + "\" && chmod 755 \"" + filePath + "\" && gio set \"" + filePath + "\" metadata::trusted true";
                                            copyProcess.command = ["sh", "-c", writeCmd];
                                            copyProcess.running = true;
                                        }
                                    }
                                ]
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Loader {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                sourceComponent: Config.tintIcons ? tintedIconComponent : normalIconComponent
                            }

                            Component {
                                id: normalIconComponent
                                Image {
                                    id: appIcon
                                    source: "image://icon/" + modelData.icon
                                    fillMode: Image.PreserveAspectFit

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: Colors.outline
                                        border.width: parent.status === Image.Error ? 1 : 0
                                        radius: 4

                                        Text {
                                            anchors.centerIn: parent
                                            text: "?"
                                            visible: parent.parent.status === Image.Error
                                            color: Colors.overBackground
                                            font.family: Config.theme.font
                                        }
                                    }
                                }
                            }

                            Component {
                                id: tintedIconComponent
                                Tinted {
                                    sourceItem: Image {
                                        source: "image://icon/" + modelData.icon
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    width: parent.width
                                    text: modelData.name
                                    color: appLauncher.selectedIndex === index ? Colors.overPrimary : Colors.overBackground
                                    font.family: Config.theme.font
                                    font.pixelSize: Config.theme.fontSize
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration / 2
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.comment || ""
                                    color: appLauncher.selectedIndex === index ? Colors.overPrimary : Colors.outline
                                    font.family: Config.theme.font
                                    font.pixelSize: Math.max(8, Config.theme.fontSize - 2)
                                    elide: Text.ElideRight
                                    visible: text !== ""

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
                    }

                    highlight: Rectangle {
                        color: Colors.primary
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: appLauncher.selectedIndex >= 0 && (appLauncher.optionsMenuOpen ? appLauncher.selectedIndex === appLauncher.menuItemIndex : true)
                    }

                    highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                    highlightMoveVelocity: -1
                }
            }

            Component.onCompleted: {
                focusSearchInput();
            }

            Process {
                id: copyProcess
                running: false

                onExited: function (code) {}
            }
        }

        // StackLayout for other tabs (clipboard, emoji, tmux, wallpapers)
        StackLayout {
            id: internalStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: currentTab !== 0
            currentIndex: currentTab - 1  // Subtract 1 because launcher is now separate

            // Tab 1: Clipboard (with prefix "clip ")
            Loader {
                id: clipboardLoader
                active: true
                sourceComponent: ClipboardTab {
                    prefixText: "clip "
                    onBackspaceOnEmpty: {
                        // Return to launcher with prefix text + space
                        prefixDisabled = true;
                        currentTab = 0;
                        GlobalStates.launcherSearchText = "clip ";
                        appLauncher.focusSearchInput();
                    }
                }
            }

            // Tab 2: Emoji (with prefix "emoji ")
            Loader {
                id: emojiLoader
                active: true
                sourceComponent: EmojiTab {
                    prefixText: "emoji "
                    onBackspaceOnEmpty: {
                        prefixDisabled = true;
                        currentTab = 0;
                        GlobalStates.launcherSearchText = "emoji ";
                        appLauncher.focusSearchInput();
                    }
                }
            }

            // Tab 3: Tmux (with prefix "tmux ")
            Loader {
                id: tmuxLoader
                active: true
                sourceComponent: TmuxTab {
                    prefixText: "tmux "
                    onBackspaceOnEmpty: {
                        prefixDisabled = true;
                        currentTab = 0;
                        GlobalStates.launcherSearchText = "tmux ";
                        appLauncher.focusSearchInput();
                    }
                }
            }

            // Tab 4: Wallpapers (with prefix "wall ")
            Loader {
                id: wallpapersLoader
                active: true
                sourceComponent: WallpapersTab {
                    prefixText: "wall "
                    onBackspaceOnEmpty: {
                        prefixDisabled = true;
                        currentTab = 0;
                        GlobalStates.launcherSearchText = "wall ";
                        appLauncher.focusSearchInput();
                    }
                }
            }
        }

        // Separator (only visible when in launcher tab)
        Separator {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
            vert: true
            gradient: null
            color: Colors.surface
            visible: currentTab === 0
        }

        // Widgets column (only visible when in launcher tab)
        ClippingRectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            color: "transparent"
            visible: currentTab === 0

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: columnLayout.implicitHeight
                clip: true

                ColumnLayout {
                    id: columnLayout
                    width: parent.width
                    spacing: 8

                    FullPlayer {
                        Layout.fillWidth: true
                    }

                    Calendar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                    }

                    PaneRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                    }
                }
            }
        }

        // Notification History (only visible when in launcher tab)
        NotificationHistory {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: currentTab === 0
        }
    }

    Component.onCompleted: {
        Qt.callLater(focusAppSearch);
    }
}
