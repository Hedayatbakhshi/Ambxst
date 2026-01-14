import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

PanelWindow {
    id: screenshotPopup
    required property var screen


    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Visible only when explicitly opened
    visible: state !== "idle"
    exclusionMode: ExclusionMode.Ignore

    property string state: "idle" // idle, loading, active, processing
    property string currentMode: "region" // region, window, screen
    property var activeWindows: []

    property var modes: [
        {
            name: "region",
            icon: Icons.regionScreenshot,
            tooltip: "Region"
        },
        {
            name: "window",
            icon: Icons.windowScreenshot,
            tooltip: "Window"
        },
        {
            name: "screen",
            icon: Icons.fullScreenshot,
            tooltip: "Screen"
        }
    ]

    function open() {
        // Reset to default state
        if (modeGrid)
            modeGrid.currentIndex = 0;
        screenshotPopup.currentMode = "region";

        screenshotPopup.state = "loading";
        // Screenshot.freezeScreen() is now called centrally in shell.qml
    }

    function close() {
        screenshotPopup.state = "idle";
    }

    function executeCapture() {
        if (screenshotPopup.currentMode === "screen") {
            Screenshot.processFullscreen();
            screenshotPopup.close();
        } else if (screenshotPopup.currentMode === "region") {
            // Check if rect exists
            if (Screenshot.selectionW > 0) {
                Screenshot.processRegion(Screenshot.selectionX, Screenshot.selectionY, Screenshot.selectionW, Screenshot.selectionH);
                screenshotPopup.close();
            }
        } else if (screenshotPopup.currentMode === "window") {
            // If enter pressed in window mode, maybe capture the one under cursor?
        }
    }

    // Connect to global Screenshot singleton signals
    Connections {
        target: Screenshot
        function onScreenshotCaptured(path) {
            previewImage.source = "";
            previewImage.source = "file://" + path;
            screenshotPopup.state = "active";
            // Reset selection
            Screenshot.selectionW = 0;
            Screenshot.selectionH = 0;
            // Fetch windows if we are in window mode, or pre-fetch
            Screenshot.fetchWindows();

            // Force focus on the overlay window content
            modeGrid.forceActiveFocus();
        }
        function onWindowListReady(windows) {
            screenshotPopup.activeWindows = windows;
        }
        function onErrorOccurred(msg) {
            console.warn("Screenshot Error:", msg);
            screenshotPopup.close();
        }
    }

    // Mask to capture input on the entire window when open
    mask: Region {
        item: screenshotPopup.visible ? fullMask : emptyMask
    }

    Item {
        id: fullMask
        anchors.fill: parent
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    // Focus grabber
    HyprlandFocusGrab {
        id: focusGrab
        windows: [screenshotPopup]
        active: screenshotPopup.visible
    }

    // Main Content
    FocusScope {
        id: mainFocusScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: screenshotPopup.close()

        // 1. The "Frozen" Image
        // Wrapper to clip the image to this screen's bounds
        Item {
            anchors.fill: parent
            clip: true
            
            Image {
                id: previewImage
                // No anchors.fill: parent
                fillMode: Image.Pad
                
                // Scale the image so 1 image pixel = 1 physical screen pixel
                // On a scale 2 monitor, this means image logical width = sourceWidth / 2
                width: sourceSize.width / screenshotPopup.screen.scale
                height: sourceSize.height / screenshotPopup.screen.scale
                
                // Position to show the part of the image corresponding to this screen
                x: -screenshotPopup.screen.x
                y: -screenshotPopup.screen.y
                
                visible: screenshotPopup.state === "active"
            }
        }

        // 2. Dimmer (Dark overlay)
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: screenshotPopup.state === "active" ? 0.4 : 0
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode !== "screen"
        }

        // 3. Window Selection Highlights
        Item {
            anchors.fill: parent
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode === "window"

            Repeater {
                model: screenshotPopup.activeWindows
                // Only show windows relevant to this screen (roughly)
                // Actually, window coordinates are global, so we shift them by screen offset
                delegate: Rectangle {
                    x: modelData.at[0] - screenshotPopup.screen.x
                    y: modelData.at[1] - screenshotPopup.screen.y
                    width: modelData.size[0]
                    height: modelData.size[1]
                    color: "transparent"
                    border.color: hoverHandler.hovered ? Styling.srItem("overprimary") : "transparent"
                    border.width: 2

                    Rectangle {
                        anchors.fill: parent
                        color: Styling.srItem("overprimary")
                        opacity: hoverHandler.hovered ? 0.2 : 0
                    }

                    HoverHandler {
                        id: hoverHandler
                    }

                    TapHandler {
                        onTapped: {
                            Screenshot.processRegion(modelData.at[0], modelData.at[1], modelData.size[0], modelData.size[1]);
                            screenshotPopup.close();
                        }
                    }
                }
            }
        }

        // 4. Region Selection (Drag) and Screen Capture (Click)
        MouseArea {
            id: regionArea
            anchors.fill: parent
            enabled: screenshotPopup.state === "active" && (screenshotPopup.currentMode === "region" || screenshotPopup.currentMode === "screen")
            hoverEnabled: true
            cursorShape: screenshotPopup.currentMode === "region" ? Qt.CrossCursor : Qt.ArrowCursor

            property point startPointGlobal: Qt.point(0, 0)
            property bool selecting: false

            onPressed: mouse => {
                if (screenshotPopup.currentMode === "screen") {
                    // Immediate capture for screen mode
                    return;
                }

                // Convert local mouse to global coordinates
                var globalX = mouse.x + screenshotPopup.screen.x;
                var globalY = mouse.y + screenshotPopup.screen.y;

                startPointGlobal = Qt.point(globalX, globalY);
                Screenshot.selectionX = globalX;
                Screenshot.selectionY = globalY;
                Screenshot.selectionW = 0;
                Screenshot.selectionH = 0;
                selecting = true;
            }

            onClicked: {
                if (screenshotPopup.currentMode === "screen") {
                    Screenshot.processFullscreen();
                    screenshotPopup.close();
                }
            }

            onPositionChanged: mouse => {
                if (!selecting)
                    return;
                
                var currentGlobalX = mouse.x + screenshotPopup.screen.x;
                var currentGlobalY = mouse.y + screenshotPopup.screen.y;

                var x = Math.min(startPointGlobal.x, currentGlobalX);
                var y = Math.min(startPointGlobal.y, currentGlobalY);
                var w = Math.abs(startPointGlobal.x - currentGlobalX);
                var h = Math.abs(startPointGlobal.y - currentGlobalY);

                Screenshot.selectionX = x;
                Screenshot.selectionY = y;
                Screenshot.selectionW = w;
                Screenshot.selectionH = h;
            }

            onReleased: {
                if (!selecting)
                    // for screen mode click
                    return;
                selecting = false;
                
                if (Screenshot.selectionW > 5 && Screenshot.selectionH > 5) {
                    Screenshot.processRegion(Screenshot.selectionX, Screenshot.selectionY, Screenshot.selectionW, Screenshot.selectionH);
                    screenshotPopup.close();
                }
            }
        }

        // Visual Selection Rect
        Rectangle {
            id: selectionRect
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode === "region"
            
            // Map global selection back to local coordinates
            x: Screenshot.selectionX - screenshotPopup.screen.x
            y: Screenshot.selectionY - screenshotPopup.screen.y
            width: Screenshot.selectionW
            height: Screenshot.selectionH
            
            color: "transparent"
            border.color: Styling.srItem("overprimary")
            border.width: 2

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: 0.2
            }
        }

        // 5. Controls UI (Bottom Bar)
        Rectangle {
            id: controlsBar
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 50

            // Padding of 16px around the content
            width: modeGrid.width + 32
            height: modeGrid.height + 32

            radius: Styling.radius(20)
            color: Colors.background
            border.color: Colors.surface
            border.width: 1
            visible: screenshotPopup.state === "active"

            // Catch-all MouseArea
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
            }

            ActionGrid {
                id: modeGrid
                anchors.centerIn: parent
                actions: screenshotPopup.modes
                buttonSize: 48
                iconSize: 24
                spacing: 10

                onCurrentIndexChanged: {
                    screenshotPopup.currentMode = screenshotPopup.modes[currentIndex].name;
                }

                onActionTriggered: {
                    screenshotPopup.executeCapture();
                }
            }
        }
    }
}
