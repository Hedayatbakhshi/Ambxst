pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 400

    property string hostname: ""
    property real chartZoom: 1.0

    // Adjust history points based on zoom and repaint chart
    onChartZoomChanged: {
        // Store enough history to support zoom out
        // Always store maximum (250 points) to allow smooth zooming
        SystemResources.maxHistoryPoints = 250;
        
        // Repaint chart when zoom changes
        chartCanvas.requestPaint();
    }

    // Load refresh interval from state
    Component.onCompleted: {
        // Always store maximum (250 points) to allow smooth zooming
        SystemResources.maxHistoryPoints = 250;
        
        const savedInterval = StateService.get("metricsRefreshInterval", 2000);
        SystemResources.updateInterval = Math.max(100, savedInterval);
        const savedZoom = StateService.get("metricsChartZoom", 1.0);
        // Limit zoom range: 0.2 (show all available) to 3.0 (zoom in)
        chartZoom = Math.max(0.2, Math.min(3.0, savedZoom));
        hostnameReader.running = true;
    }

    // Get hostname
    Process {
        id: hostnameReader
        running: false
        command: ["hostname"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const host = text.trim();
                if (host) {
                    root.hostname = host.charAt(0).toUpperCase() + host.slice(1);
                }
            }
        }
    }

    // Watch for history changes to repaint chart
    Connections {
        target: SystemResources
        function onCpuHistoryChanged() {
            chartCanvas.requestPaint();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left panel - Resources
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: "transparent"
            radius: Styling.radius(4)

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                // User avatar
                Rectangle {
                    id: avatarContainer
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    width: 140
                    height: 140
                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                    color: "transparent"

                    Image {
                        id: userAvatar
                        anchors.fill: parent
                        source: `file://${Quickshell.env("HOME")}/.face.icon`
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: userAvatar.width
                                    height: userAvatar.height
                                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Icons.user
                        font.family: Icons.font
                        font.pixelSize: 64
                        color: Colors.overSurfaceVariant
                        visible: userAvatar.status !== Image.Ready
                    }
                }

                // Username@Hostname
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                    text: {
                        const user = Quickshell.env("USER") || "user";
                        return root.hostname ? `${user}@${root.hostname.toLowerCase()}` : user;
                    }
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize
                    font.weight: Font.Bold
                    color: Colors.overBackground
                    visible: text !== ""
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    contentHeight: resourcesColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: resourcesColumn
                        width: parent.width
                        spacing: 12

                        // CPU
                        ResourceItem {
                            width: parent.width
                            icon: Icons.cpu
                            label: "CPU"
                            value: SystemResources.cpuUsage / 100
                            barColor: Colors.red
                        }

                        // RAM
                        ResourceItem {
                            width: parent.width
                            icon: Icons.ram
                            label: "RAM"
                            value: SystemResources.ramUsage / 100
                            barColor: Colors.cyan
                        }

                        // GPUs (if detected) - show one bar per GPU
                        Repeater {
                            id: gpuRepeater
                            model: SystemResources.gpuDetected ? SystemResources.gpuCount : 0

                            ResourceItem {
                                required property int index
                                width: parent.width
                                icon: Icons.gpu
                                label: {
                                    const name = SystemResources.gpuNames[index] || "";
                                    const vendor = SystemResources.gpuVendors[index] || "";
                                    
                                    // If we have a descriptive name, use it
                                    if (name && name !== `${vendor.toUpperCase()} GPU ${index}`) {
                                        return name;
                                    }
                                    // Otherwise show GPU index if multiple, or just "GPU" if single
                                    return SystemResources.gpuCount > 1 ? `GPU ${index}` : "GPU";
                                }
                                value: (SystemResources.gpuUsages[index] || 0) / 100
                                barColor: {
                                    // Color based on vendor
                                    const vendor = SystemResources.gpuVendors[index] || "";
                                    switch (vendor.toLowerCase()) {
                                        case "nvidia":
                                            return Colors.green;
                                        case "amd":
                                            return Colors.red;
                                        case "intel":
                                            return Colors.blue;
                                        default:
                                            return Colors.magenta;
                                    }
                                }
                            }
                        }

                        // Separator before disks
                        Separator {
                            width: parent.width
                            height: 2
                            gradient: null
                            color: Colors.surface
                        }

                        // Disks
                        Repeater {
                            id: diskRepeater
                            model: SystemResources.validDisks

                            Column {
                                required property string modelData
                                width: parent.width
                                spacing: 4

                                ResourceItem {
                                    width: parent.width
                                    icon: Icons.disk
                                    label: modelData
                                    value: SystemResources.diskUsage[modelData] ? SystemResources.diskUsage[modelData] / 100 : 0
                                    barColor: Colors.yellow
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: modelData
                                        font.family: Config.theme.font
                                        font.pixelSize: Config.theme.fontSize - 2
                                        color: Colors.surfaceBright
                                        elide: Text.ElideMiddle
                                    }

                                    Separator {
                                        Layout.preferredHeight: 2
                                        Layout.fillWidth: true
                                        gradient: null
                                        color: Colors.surface
                                    }

                                    Text {
                                        text: `${Math.round((SystemResources.diskUsage[modelData] || 0))}%`
                                        font.family: Config.theme.font
                                        font.pixelSize: Math.max(8, Config.theme.fontSize - 2)
                                        font.weight: Font.Medium
                                        color: Colors.surfaceBright
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right panel - Chart
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Styling.radius(4)
                variant: "pane"

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Styling.radius(0)
                    variant: "internalbg"

                    // Chart area
                    Canvas {
                        id: chartCanvas
                        anchors.fill: parent

                        onPaint: {
                            const ctx = getContext("2d");
                            const w = width;
                            const h = height;

                            // Clear canvas
                            ctx.clearRect(0, 0, w, h);

                            if (SystemResources.cpuHistory.length < 2)
                                return;

                            // === COORDINATE SYSTEM SETUP ===
                            // Apply zoom to visible points
                            const basePoints = 50;
                            const zoomedMaxPoints = Math.max(10, Math.floor(basePoints / root.chartZoom));

                            // Core spacing: each data point gets this many pixels
                            const pointSpacing = w / (zoomedMaxPoints - 1);
                            
                            // Calculate offset to align graph to the right
                            const actualPoints = Math.min(zoomedMaxPoints, SystemResources.cpuHistory.length);
                            const graphOffset = w - ((actualPoints - 1) * pointSpacing);

                            // === GRID RENDERING ===
                            // Grid now uses the SAME coordinate system as the data
                            ctx.strokeStyle = Colors.surface;
                            ctx.lineWidth = 1;

                            // Horizontal grid lines (percentage-based, fixed at 8 divisions)
                            for (let i = 1; i < 8; i++) {
                                const y = h * (i / 8);
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(w, y);
                                ctx.stroke();
                            }

                            // Vertical grid lines every 10 points
                            ctx.strokeStyle = Colors.surface;
                            ctx.lineWidth = 2;
                            
                            // Use the absolute data point counter for infinite scrolling
                            const totalDataPoints = SystemResources.totalDataPoints;
                            
                            // Calculate where the visible window starts in absolute terms
                            const windowStartIndex = totalDataPoints - actualPoints;
                            
                            // Find the first grid line (multiple of 10) that should appear
                            const firstGridLine = Math.floor(windowStartIndex / 10) * 10;
                            
                            // Draw vertical lines every 10 data points
                            // Continue until we pass the right edge of the canvas
                            for (let absoluteIndex = firstGridLine; absoluteIndex <= totalDataPoints + 10; absoluteIndex += 10) {
                                // Convert absolute index to position within visible window
                                const visibleIndex = absoluteIndex - windowStartIndex;
                                
                                // Only draw if within visible range
                                if (visibleIndex >= 0 && visibleIndex < actualPoints) {
                                    const x = graphOffset + (visibleIndex * pointSpacing);
                                    ctx.beginPath();
                                    ctx.moveTo(x, 0);
                                    ctx.lineTo(x, h);
                                    ctx.stroke();
                                }
                            }

                            // === DATA RENDERING ===
                            // Helper function to draw a line chart with gradient fill
                            function drawLine(history, color) {
                                if (history.length < 2)
                                    return;

                                // Get most recent data points based on zoom level
                                const visiblePoints = Math.min(zoomedMaxPoints, history.length);
                                const recentHistory = history.slice(-visiblePoints);
                                
                                // Use same offset as grid for perfect alignment
                                const dataOffset = graphOffset;

                                // Create gradient from top to bottom
                                const gradient = ctx.createLinearGradient(0, 0, 0, h);
                                gradient.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.4));
                                gradient.addColorStop(0.5, Qt.rgba(color.r, color.g, color.b, 0.2));
                                gradient.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.0));

                                // Draw filled area
                                ctx.fillStyle = gradient;
                                ctx.beginPath();

                                // Start from bottom at first point position
                                const firstX = dataOffset;
                                ctx.moveTo(firstX, h);

                                // Draw line to first data point
                                const firstY = h - (recentHistory[0] * h);
                                ctx.lineTo(firstX, firstY);

                                // Draw through all data points
                                for (let i = 1; i < recentHistory.length; i++) {
                                    const x = dataOffset + (i * pointSpacing);
                                    const y = h - (recentHistory[i] * h);
                                    ctx.lineTo(x, y);
                                }

                                // Close path along bottom
                                const lastX = dataOffset + ((recentHistory.length - 1) * pointSpacing);
                                ctx.lineTo(lastX, h);
                                ctx.closePath();
                                ctx.fill();

                                // Draw the line on top
                                ctx.strokeStyle = color;
                                ctx.lineWidth = 2;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();

                                for (let i = 0; i < recentHistory.length; i++) {
                                    const x = dataOffset + (i * pointSpacing);
                                    const y = h - (recentHistory[i] * h);

                                    if (i === 0) {
                                        ctx.moveTo(x, y);
                                    } else {
                                        ctx.lineTo(x, y);
                                    }
                                }

                                ctx.stroke();
                            }

                            // Draw CPU line (red)
                            drawLine(SystemResources.cpuHistory, Colors.red);

                            // Draw RAM line (cyan)
                            drawLine(SystemResources.ramHistory, Colors.cyan);

                            // Draw GPU lines (color based on vendor)
                            if (SystemResources.gpuDetected && SystemResources.gpuCount > 0) {
                                for (let i = 0; i < SystemResources.gpuCount; i++) {
                                    if (SystemResources.gpuHistories[i] && SystemResources.gpuHistories[i].length > 0) {
                                        // Get vendor-specific color
                                        const vendor = SystemResources.gpuVendors[i] || "";
                                        let color;
                                        switch (vendor.toLowerCase()) {
                                            case "nvidia":
                                                color = Colors.green;
                                                break;
                                            case "amd":
                                                color = Colors.red;
                                                break;
                                            case "intel":
                                                color = Colors.blue;
                                                break;
                                            default:
                                                color = Colors.magenta;
                                                break;
                                        }
                                        drawLine(SystemResources.gpuHistories[i], color);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Controls panel
            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Styling.radius(4)
                variant: "pane"

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Styling.radius(0)
                    variant: "internalbg"

                    // Controls at right
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        // Zoom label
                        Text {
                            Layout.leftMargin: 4
                            text: "Zoom"
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize - 1
                            color: Colors.surfaceBright
                        }

                        // Zoom slider
                        StyledSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: parent.height
                            vertical: false
                            value: (root.chartZoom - 0.2) / 2.8  // Map 0.2-3.0 to 0-1
                            progressColor: Colors.primary
                            backgroundColor: Colors.surface
                            tooltipText: root.chartZoom ? `${root.chartZoom.toFixed(1)}×` : "1.0×"
                            thickness: 3
                            handleSpacing: 2
                            wavy: false
                            icon: ""
                            iconPos: "start"
                            onValueChanged: {
                                const newZoom = 0.2 + (value * 2.8);  // Map 0-1 to 0.2-3.0
                                root.chartZoom = newZoom;
                                StateService.set("metricsChartZoom", newZoom);
                            }
                        }

                        // Spacer
                        Item {
                            Layout.preferredWidth: 8
                        }

                        // Decrease interval button
                        StyledRect {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: Styling.radius(-4)
                            variant: "pane"

                            Text {
                                anchors.centerIn: parent
                                text: Icons.minus
                                font.family: Icons.font
                                font.pixelSize: 18
                                color: Colors.overBackground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const newInterval = Math.max(100, SystemResources.updateInterval - 100);
                                    SystemResources.updateInterval = newInterval;
                                    StateService.set("metricsRefreshInterval", newInterval);
                                }
                            }

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Interval display
                        Text {
                            text: `${SystemResources.updateInterval}ms`
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            font.weight: Font.Bold
                            color: Colors.overBackground
                        }

                        // Increase interval button
                        StyledRect {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: Styling.radius(-4)
                            variant: "pane"

                            Text {
                                anchors.centerIn: parent
                                text: Icons.plus
                                font.family: Icons.font
                                font.pixelSize: 18
                                color: Colors.overBackground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const newInterval = SystemResources.updateInterval + 100;
                                    SystemResources.updateInterval = newInterval;
                                    StateService.set("metricsRefreshInterval", newInterval);
                                }
                            }

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
