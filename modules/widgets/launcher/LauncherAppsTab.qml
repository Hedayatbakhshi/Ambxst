import QtQuick
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

    property string searchText: GlobalStates.launcherSearchText
    property bool showResults: searchText.length > 0
    property int selectedIndex: GlobalStates.launcherSelectedIndex
    property bool optionsMenuOpen: false
    property int menuItemIndex: -1
    property bool menuJustClosed: false
    signal itemSelected

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
                root.searchText = text;
                // Auto-highlight first app when text is entered
                if (text.length > 0) {
                    GlobalStates.launcherSelectedIndex = 0;
                    root.selectedIndex = 0;
                    resultsList.currentIndex = 0;
                } else {
                    GlobalStates.launcherSelectedIndex = -1;
                    root.selectedIndex = -1;
                    resultsList.currentIndex = -1;
                }
            }

            onAccepted: {
                if (root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                    let selectedApp = resultsList.model[root.selectedIndex];
                    if (selectedApp) {
                        selectedApp.execute();
                        root.itemSelected();
                    }
                }
            }

            onEscapePressed: {
                root.itemSelected();
            }

            onDownPressed: {
                if (resultsList.count > 0) {
                    if (root.selectedIndex === -1) {
                        // When nothing selected, start at first item
                        GlobalStates.launcherSelectedIndex = 0;
                        root.selectedIndex = 0;
                        resultsList.currentIndex = 0;
                    } else if (root.selectedIndex < resultsList.count - 1) {
                        GlobalStates.launcherSelectedIndex++;
                        root.selectedIndex++;
                        resultsList.currentIndex = root.selectedIndex;
                    }
                }
            }

            onUpPressed: {
                if (root.selectedIndex > 0) {
                    GlobalStates.launcherSelectedIndex--;
                    root.selectedIndex--;
                    resultsList.currentIndex = root.selectedIndex;
                } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                    // When no search text, allow going back to no selection
                    GlobalStates.launcherSelectedIndex = -1;
                    root.selectedIndex = -1;
                    resultsList.currentIndex = -1;
                }
            }

            onPageDownPressed: {
                if (resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 48);
                    let newIndex = Math.min(root.selectedIndex + visibleItems, resultsList.count - 1);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.min(visibleItems - 1, resultsList.count - 1);
                    }
                    GlobalStates.launcherSelectedIndex = newIndex;
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onPageUpPressed: {
                if (resultsList.count > 0) {
                    let visibleItems = Math.floor(resultsList.height / 48);
                    let newIndex = Math.max(root.selectedIndex - visibleItems, 0);
                    if (root.selectedIndex === -1) {
                        newIndex = Math.max(resultsList.count - visibleItems, 0);
                    }
                    GlobalStates.launcherSelectedIndex = newIndex;
                    root.selectedIndex = newIndex;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }

            onHomePressed: {
                if (resultsList.count > 0) {
                    GlobalStates.launcherSelectedIndex = 0;
                    root.selectedIndex = 0;
                    resultsList.currentIndex = 0;
                }
            }

            onEndPressed: {
                if (resultsList.count > 0) {
                    GlobalStates.launcherSelectedIndex = resultsList.count - 1;
                    root.selectedIndex = resultsList.count - 1;
                    resultsList.currentIndex = root.selectedIndex;
                }
            }
        }

        // Results list
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: 5 * 48
            visible: true
            clip: true
            interactive: !root.optionsMenuOpen
            cacheBuffer: 96
            reuseItems: true

            model: root.searchText.length > 0 ? AppSearch.fuzzyQuery(root.searchText) : AppSearch.getAllApps()
            currentIndex: root.selectedIndex

            // Sync currentIndex with selectedIndex
            onCurrentIndexChanged: {
                if (currentIndex !== root.selectedIndex) {
                    GlobalStates.launcherSelectedIndex = currentIndex;
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

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onEntered: {
                        if (!root.optionsMenuOpen) {
                            GlobalStates.launcherSelectedIndex = index;
                            root.selectedIndex = index;
                            resultsList.currentIndex = index;
                        }
                    }
                    onClicked: mouse => {
                        if (menuJustClosed) {
                            return;
                        }

                        if (mouse.button === Qt.LeftButton) {
                            modelData.execute();
                            root.itemSelected();
                        } else if (mouse.button === Qt.RightButton) {
                            root.menuItemIndex = index;
                            root.optionsMenuOpen = true;
                            contextMenu.popup(mouse.x, mouse.y);
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
                                text: "Launch",
                                icon: Icons.launch,
                                highlightColor: Colors.primary,
                                textColor: Colors.overPrimary,
                                onTriggered: function () {
                                    modelData.execute();
                                    root.itemSelected();
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
                                    
                                    let desktopContent = "[Desktop Entry]\n" +
                                        "Version=1.0\n" +
                                        "Type=Application\n" +
                                        "Name=" + modelData.name + "\n" +
                                        "Exec=" + modelData.execString + "\n" +
                                        "Icon=" + modelData.icon + "\n" +
                                        (modelData.comment ? "Comment=" + modelData.comment + "\n" : "") +
                                        (modelData.categories.length > 0 ? "Categories=" + modelData.categories.join(";") + ";\n" : "") +
                                        (modelData.runInTerminal ? "Terminal=true\n" : "Terminal=false\n");
                                    
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

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: root.selectedIndex === index ? Colors.overPrimary : Colors.overBackground
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
                }
            }

            highlight: Rectangle {
                color: Colors.primary
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                visible: root.selectedIndex >= 0 && (root.optionsMenuOpen ? root.selectedIndex === root.menuItemIndex : true)
            }

            highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
            highlightMoveVelocity: -1
        }
    }

    Component.onCompleted: {
        // Focus the input when component is ready
        focusSearchInput();
    }

    Process {
        id: copyProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                root.itemSelected();
            }
        }
    }
}
