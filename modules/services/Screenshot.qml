pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals

QtObject {
    id: root

    signal screenshotCaptured(string path)
    signal errorOccurred(string message)
    signal windowListReady(var windows)
    signal lensImageReady(string path)

    property string tempPath: "/tmp/ambxst_freeze.png"
    property string cropPath: "/tmp/ambxst_crop.png"
    property string lensPath: "/tmp/image.png"
    
    // Mode: "normal" saves to Screenshots folder, "lens" saves to /tmp/image.png
    property string captureMode: "normal"
    
    // We'll store the resolved XDG_PICTURES_DIR/Screenshots here
    property string screenshotsDir: ""
    property string finalPath: ""
    
    // Global selection state for multi-monitor synchronization
    property int selectionX: 0
    property int selectionY: 0
    property int selectionW: 0
    property int selectionH: 0
    
    // Internal storage for active workspace IDs
    property var _activeWorkspaceIds: []
    
    // Store monitor scale factor for coordinate scaling
    property real monitorScale: 1.0

    // Process to resolve XDG_PICTURES_DIR
    property Process xdgProcess: Process {
        id: xdgProcess
        command: ["bash", "-c", "xdg-user-dir PICTURES"]
        stdout: StdioCollector {
             onTextChanged: {
                // Not running immediately, handled in onExited
             }
        }
        running: true // Run on load
        onExited: exitCode => {
            if (exitCode === 0) {
                var dir = xdgProcess.stdout.text.trim()
                if (dir === "") {
                    // Fallback to home/Pictures if xdg-user-dir fails or returns empty
                    dir = Quickshell.env("HOME") + "/Pictures"
                }
                root.screenshotsDir = dir + "/Screenshots"
                // Ensure directory exists
                ensureDirProcess.running = true
            }
        }
    }

    property Process ensureDirProcess: Process {
        id: ensureDirProcess
        command: ["mkdir", "-p", root.screenshotsDir]
    }

    // Process for initial freeze
    property Process freezeProcess: Process {
        id: freezeProcess
        command: ["grim", root.tempPath]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.screenshotCaptured(root.tempPath)
            } else {
                root.errorOccurred("Failed to capture screen (grim)")
            }
        }
    }
    
    // Process to get scale factor before freeze
    property Process scaleProcess: Process {
        id: scaleProcess
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    var monitors = JSON.parse(scaleProcess.stdout.text)
                    for (var i = 0; i < monitors.length; i++) {
                        if (monitors[i].focused && monitors[i].scale) {
                            root.monitorScale = monitors[i].scale
                            console.log("Screenshot: Monitor scale factor detected: " + root.monitorScale)
                            break
                        }
                    }
                } catch (e) {
                    console.warn("Screenshot: Failed to parse scale: " + e.message)
                    root.monitorScale = 1.0
                }
            } else {
                root.monitorScale = 1.0
            }
        }
    }
    
    // Process for fetching monitors (to get active workspaces reliably)
    property Process monitorsProcess: Process {
        id: monitorsProcess
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    var monitors = JSON.parse(monitorsProcess.stdout.text)
                    var ids = []
                    for (var i = 0; i < monitors.length; i++) {
                        if (monitors[i].activeWorkspace) {
                            ids.push(monitors[i].activeWorkspace.id)
                        }
                        // Get scale factor from focused monitor
                        if (monitors[i].focused && monitors[i].scale) {
                            root.monitorScale = monitors[i].scale
                            console.log("Screenshot: Monitor scale factor detected: " + root.monitorScale)
                        }
                    }
                    root._activeWorkspaceIds = ids
                    console.log("Screenshot: Active workspaces found via hyprctl: " + JSON.stringify(ids))
                    
                    // Now fetch clients
                    clientsProcess.running = true
                } catch (e) {
                    console.warn("Screenshot: Failed to parse monitors: " + e.message)
                    // Fallback: try fetching clients anyway, filtering might fail or be permissive
                    root._activeWorkspaceIds = []
                    root.monitorScale = 1.0
                    clientsProcess.running = true
                }
            } else {
                console.warn("Screenshot: Failed to fetch monitors")
                root._activeWorkspaceIds = []
                root.monitorScale = 1.0
                clientsProcess.running = true
            }
        }
    }

    // Process for fetching windows
    property Process clientsProcess: Process {
        id: clientsProcess
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    var allClients = JSON.parse(clientsProcess.stdout.text)
                    
                    // Filter using the IDs we got from monitorsProcess
                    var activeIds = root._activeWorkspaceIds
                    
                    var filteredClients = allClients.filter(c => {
                        // Keep pinned windows OR windows on active workspaces
                        return c.pinned || (activeIds.length > 0 && activeIds.includes(c.workspace.id))
                    })
                    
                    console.log("Screenshot: Total clients: " + allClients.length + ", Filtered: " + filteredClients.length)
                    
                    root.windowListReady(filteredClients)
                    
                } catch (e) {
                    console.warn("Screenshot: Error processing windows: " + e.message)
                    root.errorOccurred("Failed to parse window list: " + e.message)
                }
            } else {
                console.warn("Screenshot: hyprctl clients failed with code " + exitCode)
            }
        }
    }

    // Process for cropping/saving
    property Process cropProcess: Process {
        id: cropProcess
        // command set dynamically
        onExited: exitCode => {
            if (exitCode === 0) {
                if (root.captureMode === "lens") {
                    // Run Google Lens script
                    root.runLensScript()
                    root.captureMode = "normal" // Reset mode
                } else {
                    // After successful save/crop, copy to clipboard
                    copyProcess.running = true
                }
            } else {
                root.errorOccurred("Failed to save image")
            }
        }
    }

    property Process copyProcess: Process {
        id: copyProcess
        command: ["bash", "-c", `wl-copy < "${root.finalPath}"`]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Failed to copy to clipboard")
            }
        }
    }

    // Process for Google Lens upload
    property Process lensProcess: Process {
        id: lensProcess
        // command set dynamically
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("Screenshot: Google Lens script executed successfully")
            } else {
                console.warn("Screenshot: Google Lens script failed with exit code " + exitCode)
                console.warn("Screenshot: stderr: " + lensProcess.stderr.text)
                root.errorOccurred("Failed to open Google Lens: " + lensProcess.stderr.text)
            }
        }
    }

    function freezeScreen() {
        // Run both in parallel. The freeze is urgent for UI feedback.
        // Scale is needed later for cropping.
        scaleProcess.running = true;
        freezeProcess.running = true;
    }

    function fetchWindows() {
        // Start the chain: Monitors -> Clients
        monitorsProcess.running = true
    }

    function getTimestamp() {
        // Simple timestamp format YYYY-MM-DD-HH-mm-ss
        var d = new Date()
        // Manually format to avoid weird ISO chars
        var pad = (n) => n < 10 ? '0' + n : n;
        return d.getFullYear() + '-' + 
               pad(d.getMonth() + 1) + '-' + 
               pad(d.getDate()) + '-' + 
               pad(d.getHours()) + '-' + 
               pad(d.getMinutes()) + '-' + 
               pad(d.getSeconds());
    }

    function processRegion(x, y, w, h) {
        // Determine output path based on mode
        if (root.captureMode === "lens") {
            root.finalPath = root.lensPath;
        } else {
            if (root.screenshotsDir === "") {
                root.screenshotsDir = Quickshell.env("HOME") + "/Pictures/Screenshots"
            }
            var filename = "Screenshot_" + getTimestamp() + ".png"
            root.finalPath = root.screenshotsDir + "/" + filename
        }
        
        // Scale coordinates by monitor scale factor for accurate cropping
        var scaledX = Math.round(x * root.monitorScale)
        var scaledY = Math.round(y * root.monitorScale)
        var scaledW = Math.round(w * root.monitorScale)
        var scaledH = Math.round(h * root.monitorScale)
        
        console.log(`Screenshot: Region - logical: ${w}x${h}+${x}+${y}, physical: ${scaledW}x${scaledH}+${scaledX}+${scaledY}, scale: ${root.monitorScale}`)
        
        // convert /tmp/ambxst_freeze.png -crop WxH+X+Y /path/to/save.png
        var geom = `${scaledW}x${scaledH}+${scaledX}+${scaledY}`
        cropProcess.command = ["convert", root.tempPath, "-crop", geom, root.finalPath]
        cropProcess.running = true
    }

    function processFullscreen() {
        // Determine output path based on mode
        if (root.captureMode === "lens") {
            root.finalPath = root.lensPath;
        } else {
            if (root.screenshotsDir === "") {
                root.screenshotsDir = Quickshell.env("HOME") + "/Pictures/Screenshots"
            }
            var filename = "Screenshot_" + getTimestamp() + ".png"
            root.finalPath = root.screenshotsDir + "/" + filename
        }

        // Just copy the freeze file to final path
        cropProcess.command = ["cp", root.tempPath, root.finalPath]
        cropProcess.running = true
    }

    property Process openScreenshotsProcess: Process {
        id: openScreenshotsProcess
        command: ["xdg-open", root.screenshotsDir]
    }

    function openScreenshotsFolder() {
        if (root.screenshotsDir === "") {
             // Fallback attempt if not ready
             openScreenshotsProcess.command = ["xdg-open", Quickshell.env("HOME") + "/Pictures/Screenshots"];
        } else {
             openScreenshotsProcess.command = ["xdg-open", root.screenshotsDir];
        }
        openScreenshotsProcess.running = true;
    }

    function runLensScript() {
        var scriptPath = Qt.resolvedUrl("../../scripts/google_lens.sh").toString().replace("file://", "");
        
        // Verify image exists before running script
        verifyImageProcess.command = ["test", "-f", root.lensPath];
        verifyImageProcess.running = true;
    }
    
    property Process verifyImageProcess: Process {
        id: verifyImageProcess
        // command set dynamically
        onExited: exitCode => {
            if (exitCode === 0) {
                // Image exists, proceed with lens script
                var scriptPath = Qt.resolvedUrl("../../scripts/google_lens.sh").toString().replace("file://", "");
                lensProcess.command = ["bash", scriptPath];
                lensProcess.running = true;
            } else {
                console.warn("Screenshot: Image file not found at " + root.lensPath)
                root.errorOccurred("Image file not ready for Google Lens")
            }
        }
    }
}
