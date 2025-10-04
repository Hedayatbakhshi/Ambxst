import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.config

PanelWindow {
    id: contextWindow

    property var menuHandle: null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    exclusiveZone: 0

    mask: Region {
        item: menuContainer
    }

    MouseArea {
        anchors.fill: parent
        onClicked: contextWindow.close()
    }

    Process {
        id: cursorPos
        running: false
        command: ["hyprctl", "cursorpos"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let coords = text.trim().split(",");
                if (coords.length === 2) {
                    let x = parseInt(coords[0].trim());
                    let y = parseInt(coords[1].trim());
                    menu.x = x;
                    menu.y = y;
                    Qt.callLater(() => {
                        if (menu.visible === false) {
                            menu.popup();
                        }
                    });
                }
            }
        }
    }

    Item {
        id: menuContainer
        anchors.fill: parent

        OptionsMenu {
            id: menu

            menuWidth: 160
            itemHeight: 32

            function cleanMenuText(text) {
                if (!text || text === "") return "";
                
                text = String(text);
                
                if (text.startsWith(":/// ")) {
                    text = text.substring(5);
                }
                
                return text.trim();
            }

            function isValidIcon(icon) {
                if (!icon || icon === "") return false;
                
                if (icon.length > 4) return false;
                if (icon.includes("/") || icon.includes(".") || icon.includes(":")) return false;
                
                return true;
            }

            function isImageIcon(icon) {
                if (!icon || icon === "") return false;
                
                if (icon.includes("/") || icon.includes(".")) return true;
                if (icon.startsWith("file://") || icon.startsWith("http")) return true;
                if (icon.length > 10) return true;
                
                return false;
            }

            QsMenuOpener {
                id: menuOpener
                menu: contextWindow.menuHandle

                onChildrenChanged: {
                    console.log("Menu children changed, count:", children ? children.values.length : "null");
                }
            }

            items: {
                console.log("Building menu items...");
                console.log("menuHandle:", contextWindow.menuHandle);
                console.log("menuOpener.children:", menuOpener.children);

                if (!menuOpener.children || !menuOpener.children.values) {
                    console.log("No children values available");
                    return [];
                }

                let menuItems = [];
                console.log("Children count:", menuOpener.children.values.length);

                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    let entry = menuOpener.children.values[i];
                    console.log("Entry", i, ":", entry, "isSeparator:", entry ? entry.isSeparator : "null", "text:", entry ? entry.text : "null", "icon:", entry ? entry.icon : "null");

                    if (entry) {
                        if (entry.isSeparator) {
                            menuItems.push({
                                text: "",
                                icon: "",
                                enabled: false,
                                isSeparator: true,
                                onTriggered: function () {}
                            });
                        } else {
                            let originalText = entry.text;
                            let cleanText = menu.cleanMenuText(originalText);
                            
                            let iconToUse = "";
                            let useImageIcon = false;
                            
                            if (entry.icon) {
                                if (menu.isValidIcon(entry.icon)) {
                                    iconToUse = entry.icon;
                                    useImageIcon = false;
                                } else if (menu.isImageIcon(entry.icon)) {
                                    iconToUse = entry.icon;
                                    useImageIcon = true;
                                }
                            }

                            if (originalText !== cleanText) {
                                console.log("Text cleaned - Original:", originalText, "-> Clean:", cleanText);
                            }
                            if (entry.icon) {
                                console.log("Icon processed - Original:", entry.icon, "-> Used:", iconToUse, "isImage:", useImageIcon);
                            }

                            if (cleanText === "" && iconToUse === "") {
                                console.log("Skipping entry with no valid text or icon:", originalText);
                                continue;
                            }

                            menuItems.push({
                                text: cleanText,
                                icon: iconToUse,
                                isImageIcon: useImageIcon,
                                enabled: entry.enabled !== false,
                                isSeparator: false,
                                onTriggered: function () {
                                    console.log("Triggering menu item:", cleanText);
                                    if (entry.triggered) {
                                        entry.triggered();
                                    }
                                    contextWindow.close();
                                }
                            });
                        }
                    }
                }
                console.log("Final menu items count:", menuItems.length);
                return menuItems;
            }
        }
    }

    function openMenu(handle) {
        console.log("Opening context menu");
        menuHandle = handle;
        visible = true;
        cursorPos.running = true;
    }

    function close() {
        console.log("Closing context menu");
        visible = false;
        menuHandle = null;
    }

    onVisibleChanged: {
        if (!visible) {
            menuHandle = null;
        }
    }

    Connections {
        target: menu
        function onClosed() {
            contextWindow.close();
        }
    }
}
