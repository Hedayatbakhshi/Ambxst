pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var screens: ({})
    property var panels: ({})
    property string currentActiveModule: ""
    property string lastFocusedScreen: ""

    function getForScreen(screenName) {
        if (!screens[screenName]) {
            screens[screenName] = screenPropertiesComponent.createObject(root, {
                screenName: screenName
            });
        }
        return screens[screenName];
    }

    function getForActive() {
        if (!Hyprland.focusedMonitor) {
            return null;
        }
        return getForScreen(Hyprland.focusedMonitor.name);
    }

    function registerPanel(screenName, panel) {
        panels[screenName] = panel;
    }

    function unregisterPanel(screenName) {
        delete panels[screenName];
    }

    function setActiveModule(moduleName) {
        if (!Hyprland.focusedMonitor) return;
        
        let focusedScreenName = Hyprland.focusedMonitor.name;
        
        // Check if we're closing a module (going from something to nothing)
        let wasModuleActive = currentActiveModule !== "";
        let isClosingModule = wasModuleActive && (!moduleName || moduleName === "");
        
        // Clear all modules on all screens first
        clearAll();
        
        // Set the active module on the focused screen
        if (moduleName && moduleName !== "") {
            let focusedScreen = getForScreen(focusedScreenName);
            if (moduleName === "launcher") {
                focusedScreen.launcher = true;
            } else if (moduleName === "dashboard") {
                focusedScreen.dashboard = true;
            } else if (moduleName === "overview") {
                focusedScreen.overview = true;
            }
            currentActiveModule = moduleName;
        } else {
            currentActiveModule = "";
            
            // Restore focus when closing any module
            if (isClosingModule) {
                Qt.callLater(() => {
                    Hyprland.dispatch("focuswindow", "");
                });
            }
        }
        
        lastFocusedScreen = focusedScreenName;
    }

    function moveActiveModuleToFocusedScreen() {
        if (!Hyprland.focusedMonitor || !currentActiveModule) return;
        
        let newFocusedScreen = Hyprland.focusedMonitor.name;
        
        // Don't do anything if we're already on the same screen
        if (newFocusedScreen === lastFocusedScreen) return;
        
        // Clear all screens
        clearAll();
        
        // Set the active module on the newly focused screen
        let focusedScreen = getForScreen(newFocusedScreen);
        if (currentActiveModule === "launcher") {
            focusedScreen.launcher = true;
        } else if (currentActiveModule === "dashboard") {
            focusedScreen.dashboard = true;
        } else if (currentActiveModule === "overview") {
            focusedScreen.overview = true;
        }
        
        lastFocusedScreen = newFocusedScreen;
    }

    Component {
        id: screenPropertiesComponent
        QtObject {
            property string screenName
            property bool launcher: false
            property bool dashboard: false
            property bool overview: false
        }
    }

    function clearAll() {
        for (let screenName in screens) {
            let screenProps = screens[screenName];
            screenProps.launcher = false;
            screenProps.dashboard = false;
            screenProps.overview = false;
        }
    }

    // Monitor focus changes
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            moveActiveModuleToFocusedScreen();
        }
    }
}