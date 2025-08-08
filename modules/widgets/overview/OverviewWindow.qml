pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.globals
import qs.modules.theme
import qs.modules.services
import qs.config

Item {
    id: root

    property var windowData
    property var toplevel
    property var monitorData: null  // Monitor data passed from Overview
    property real scale
    property real availableWorkspaceWidth
    property real availableWorkspaceHeight
    property real xOffset: 0
    property real yOffset: 0

    property bool hovered: false
    property bool pressed: false
    property bool atInitPosition: (initX == x && initY == y)

    // Propiedades de la barra pasadas desde Overview
    property string barPosition: "top"
    property int barReserved: 0

    property real initX: {
        let base = (windowData?.at?.[0] || 0) - (monitorData?.x || 0);
        if (barPosition === "left") {
            base -= barReserved;
        }
        return Math.max(base * scale, 0) + xOffset;
    }
    property real initY: {
        let base = (windowData?.at?.[1] || 0) - (monitorData?.y || 0);
        if (barPosition === "top") {
            base -= barReserved;
        }
        return Math.max(base * scale, 0) + yOffset;
    }
    property real targetWindowWidth: (windowData?.size[0] || 100) * scale
    property real targetWindowHeight: (windowData?.size[1] || 100) * scale

    property real iconToWindowRatio: 0.35
    property real iconToWindowRatioCompact: 0.6
    property string iconPath: AppSearch.guessIcon(windowData?.class || "")
    property bool compactMode: targetWindowHeight < 60 || targetWindowWidth < 60

    signal dragStarted
    signal dragFinished(int targetWorkspace)
    signal windowClicked
    signal windowClosed

    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    anchors.margins: 4
    z: atInitPosition ? 1 : 99999

    Drag.active: false
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    // Apply rounded corners using MultiEffect with clipping
    layer.enabled: true
    layer.effect: MultiEffect {
        source: root
    }
    clip: true

    Behavior on x {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: GlobalStates.overviewOpen ? root.toplevel : null
        live: true

        // Background rectangle with rounded corners
        Rectangle {
            id: previewBackground
            anchors.fill: parent
            radius: Math.max(0, Config.roundness - workspaceSpacing - 2)
            color: pressed ? Colors.surfaceContainerHighest : hovered ? Colors.surfaceContainer : Colors.surface
            border.color: Colors.surfaceContainerHighest
            border.width: 2
            visible: !windowPreview.hasContent
            clip: true

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        // Overlay content when preview is not available
        Column {
            anchors.centerIn: parent
            spacing: 4
            visible: !windowPreview.hasContent
            z: 10

            Image {
                id: windowIcon
                property real iconSize: Math.min(root.targetWindowWidth, root.targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)

                anchors.horizontalCenter: parent.horizontalCenter
                source: Quickshell.iconPath(root.iconPath, "image-missing")
                width: iconSize
                height: iconSize
                sourceSize: Qt.size(iconSize, iconSize)

                Behavior on width {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Text {
                id: windowTitle
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.windowData?.title || ""
                font.family: Styling.defaultFont
                font.pixelSize: Math.max(8, Math.min(12, root.targetWindowHeight * 0.1))
                font.weight: Font.Medium
                color: Colors.adapter.overSurface
                opacity: root.compactMode ? 0 : 0.8
                width: Math.min(implicitWidth, root.targetWindowWidth - 8)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }
            }
        }

        // Overlay border and effects when preview is available
        Rectangle {
            id: previewOverlay
            anchors.fill: parent
            radius: Math.max(0, Config.roundness - workspaceSpacing - 2)
            color: pressed ? Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.5) : hovered ? Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.2) : "transparent"
            border.color: Colors.surfaceContainerHighest
            border.width: 2
            visible: windowPreview.hasContent
            z: 5

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        // Overlay icon when preview is available (smaller, in corner)
        Image {
            id: overlayIcon
            visible: windowPreview.hasContent && !root.compactMode
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 4
            source: Quickshell.iconPath(root.iconPath, "image-missing")
            width: 16
            height: 16
            sourceSize: Qt.size(16, 16)
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
            color: Colors.adapter.error
            z: 10
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: parent

        onEntered: root.hovered = true
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
                root.windowClicked();
            } else if (mouse.button === Qt.MiddleButton) {
                root.windowClosed();
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
        color: Colors.adapter.inverseSurface
        radius: Config.roundness / 2
        opacity: 0.9
        z: 1000

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: `${root.windowData?.title || ""}\n[${root.windowData?.class || ""}]${root.windowData?.xwayland ? " [XWayland]" : ""}`
            font.family: Styling.defaultFont
            font.pixelSize: 10
            color: Colors.adapter.inverseOnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
