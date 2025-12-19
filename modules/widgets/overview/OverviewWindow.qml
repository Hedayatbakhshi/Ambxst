pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.globals
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Item {
    id: root

    property var windowData
    property var toplevel
    property var monitorData: null
    property real scale
    property real availableWorkspaceWidth
    property real availableWorkspaceHeight
    property real xOffset: 0
    property real yOffset: 0

    property bool hovered: false
    property bool pressed: false
    property bool atInitPosition: (initX == x && initY == y)

    property string barPosition: "top"
    property int barReserved: 0

    // Cache calculated values
    readonly property real initX: {
        let base = (windowData?.at?.[0] || 0) - (monitorData?.x || 0);
        if (barPosition === "left") base -= barReserved;
        return Math.round(Math.max(base * scale, 0) + xOffset);
    }
    readonly property real initY: {
        let base = (windowData?.at?.[1] || 0) - (monitorData?.y || 0);
        if (barPosition === "top") base -= barReserved;
        return Math.round(Math.max(base * scale, 0) + yOffset);
    }
    readonly property real targetWindowWidth: Math.round((windowData?.size[0] || 100) * scale)
    readonly property real targetWindowHeight: Math.round((windowData?.size[1] || 100) * scale)
    readonly property bool compactMode: targetWindowHeight < 60 || targetWindowWidth < 60
    readonly property string iconPath: AppSearch.guessIcon(windowData?.class || "")
    readonly property int calculatedRadius: Styling.radius(-2)

    signal dragStarted
    signal dragFinished(int targetWorkspace)
    signal windowClicked
    signal windowClosed

    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    z: atInitPosition ? 1 : 99999

    Drag.active: false
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    // Enable layer for GPU acceleration
    layer.enabled: true
    clip: true

    Behavior on x {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }
    Behavior on y {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
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
    Behavior on height {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.calculatedRadius

        ScreencopyView {
            id: windowPreview
            anchors.fill: parent
            captureSource: Config.performance.windowPreview && GlobalStates.overviewOpen ? root.toplevel : null
            live: GlobalStates.overviewOpen
            visible: Config.performance.windowPreview
        }
    }

    // Background rectangle with rounded corners
    Rectangle {
        id: previewBackground
        anchors.fill: parent
        radius: root.calculatedRadius
        color: pressed ? Colors.surfaceBright : hovered ? Colors.surface : Colors.background
        border.color: Colors.primary
        border.width: hovered ? 2 : 0
        visible: !windowPreview.hasContent || !Config.performance.windowPreview

        Behavior on color {
            enabled: Config.animDuration > 0
            ColorAnimation { duration: Config.animDuration / 2 }
        }
    }

    // Overlay content when preview is not available
    Image {
        id: windowIcon
        readonly property real iconSize: Math.round(Math.min(root.targetWindowWidth, root.targetWindowHeight) * (root.compactMode ? 0.6 : 0.35))
        anchors.centerIn: parent
        width: iconSize
        height: iconSize
        source: Quickshell.iconPath(root.iconPath, "image-missing")
        sourceSize: Qt.size(iconSize, iconSize)
        asynchronous: true
        visible: !windowPreview.hasContent || !Config.performance.windowPreview
        z: 10
    }

    // Overlay border and effects when preview is available
    Rectangle {
        id: previewOverlay
        anchors.fill: parent
        radius: root.calculatedRadius
        color: pressed ? Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.5) 
             : hovered ? Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.2) 
             : "transparent"
        border.color: Colors.primary
        border.width: hovered ? 2 : 0
        visible: windowPreview.hasContent && Config.performance.windowPreview
        z: 5
    }

    // Overlay icon when preview is available (smaller, in corner)
    Image {
        visible: windowPreview.hasContent && !root.compactMode && Config.performance.windowPreview
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        width: 16
        height: 16
        source: Quickshell.iconPath(root.iconPath, "image-missing")
        sourceSize: Qt.size(16, 16)
        asynchronous: true
        opacity: 0.8
        z: 10
    }

    // XWayland indicator
    Rectangle {
        visible: root.windowData?.xwayland || false
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2
        width: 6
        height: 6
        radius: 3
        color: Colors.error
        z: 10
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: parent

        onEntered: {
            root.hovered = true;
            // Only focus window on hover if it's in the current workspace
            if (root.windowData) {
                // Get current active workspace from Hyprland
                let currentWorkspace = Hyprland.focusedMonitor?.activeWorkspace?.id;
                let windowWorkspace = root.windowData?.workspace?.id;

                // Only focus if the window is in the current workspace
                if (currentWorkspace && windowWorkspace && currentWorkspace === windowWorkspace) {
                    Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                }
            }
        }
        onExited: root.hovered = false

        onPressed: mouse => {
            root.pressed = true;
            root.Drag.active = true;
            root.Drag.source = root;
            root.dragStarted();
        }

        onReleased: mouse => {
            const overviewRoot = parent.parent.parent.parent;
            const targetWorkspace = overviewRoot.draggingTargetWorkspace;

            root.pressed = false;
            root.Drag.active = false;

            if (mouse.button === Qt.LeftButton) {
                root.dragFinished(targetWorkspace);
                overviewRoot.draggingTargetWorkspace = -1;

                // Reset position if no target workspace or same workspace
                if (targetWorkspace === -1 || targetWorkspace === windowData?.workspace.id) {
                    root.x = root.initX;
                    root.y = root.initY;
                }
            }
        }

        onClicked: mouse => {
            if (!root.windowData)
                return;

            if (mouse.button === Qt.LeftButton) {
                // Single click just focuses the window without closing overview
                Hyprland.dispatch(`focuswindow address:${windowData.address}`);
            } else if (mouse.button === Qt.MiddleButton) {
                root.windowClosed();
            }
        }

        onDoubleClicked: mouse => {
            if (!root.windowData)
                return;

            if (mouse.button === Qt.LeftButton) {
                // Double click closes overview and focuses window
                root.windowClicked();
            }
        }
    }

    // Tooltip
    Rectangle {
        visible: dragArea.containsMouse && !root.Drag.active && root.windowData
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 8
        color: Colors.inverseSurface
        radius: Styling.radius(0) / 2
        opacity: 0.9
        z: 1000

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: `${root.windowData?.title || ""}\n[${root.windowData?.class || ""}]${root.windowData?.xwayland ? " [XWayland]" : ""}`
            font.family: Config.theme.font
            font.pixelSize: 10
            color: Colors.inverseOnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
