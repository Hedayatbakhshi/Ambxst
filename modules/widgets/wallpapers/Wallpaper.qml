import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.globals

PanelWindow {
    id: wallpaper

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:wallpaper"
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    property string wallpaperDir: wallpaperConfig.adapter.wallPath || Quickshell.env("HOME") + "/Wallpapers"
    property string fallbackDir: Quickshell.env("PWD") + "/assets/wallpapers_example"
    property list<string> wallpaperPaths: []
    property int currentIndex: 0
    property string currentWallpaper: wallpaperPaths.length > 0 ? wallpaperPaths[currentIndex] : ""
    property bool initialLoadCompleted: false
    property bool usingFallback: false

    // Update directory watcher when wallpaperDir changes
    onWallpaperDirChanged: {
        console.log("Wallpaper directory changed to:", wallpaperDir);
        usingFallback = false;
        directoryWatcher.path = wallpaperDir;
        scanWallpapers.running = true;
    }

    onCurrentWallpaperChanged: {
        if (currentWallpaper && initialLoadCompleted) {
            console.log("Wallpaper changed to:", currentWallpaper);
            matugenProcess.command = ["matugen", "image", currentWallpaper, "-c", Qt.resolvedUrl("../../../assets/matugen/config.toml").toString().replace("file://", "")];
            matugenProcess.running = true;
        }
    }

    function setWallpaper(path) {
        console.log("setWallpaper called with:", path);
        initialLoadCompleted = true;
        const pathIndex = wallpaperPaths.indexOf(path);
        if (pathIndex !== -1) {
            currentIndex = pathIndex;
            wallpaperConfig.adapter.currentWall = path;
        } else {
            console.warn("Wallpaper path not found in current list:", path);
        }
    }

    function nextWallpaper() {
        if (wallpaperPaths.length === 0)
            return;
        initialLoadCompleted = true;
        currentIndex = (currentIndex + 1) % wallpaperPaths.length;
        currentWallpaper = wallpaperPaths[currentIndex];
        wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
    }

    function previousWallpaper() {
        if (wallpaperPaths.length === 0)
            return;
        initialLoadCompleted = true;
        currentIndex = currentIndex === 0 ? wallpaperPaths.length - 1 : currentIndex - 1;
        currentWallpaper = wallpaperPaths[currentIndex];
        wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
    }

    function setWallpaperByIndex(index) {
        if (index >= 0 && index < wallpaperPaths.length) {
            initialLoadCompleted = true;
            currentIndex = index;
            currentWallpaper = wallpaperPaths[currentIndex];
            wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
        }
    }

    Component.onCompleted: {
        GlobalStates.wallpaperManager = wallpaper;
        // Initial scan
        scanWallpapers.running = true;
        // Start directory monitoring
        directoryWatcher.reload();
        forceActiveFocus();
    }

    FileView {
        id: wallpaperConfig
        path: Quickshell.env("PWD") + "/modules/widgets/wallpapers/wallpaper_config.json"
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property string currentWall: ""
            property string wallPath: ""

            onCurrentWallChanged: {
                // Solo actualizar si el cambio viene del archivo JSON y es diferente al actual
                if (currentWall && currentWall !== wallpaper.currentWallpaper && wallpaper.initialLoadCompleted) {
                    console.log("Loading wallpaper from JSON:", currentWall);
                    const pathIndex = wallpaper.wallpaperPaths.indexOf(currentWall);
                    if (pathIndex !== -1) {
                        wallpaper.currentIndex = pathIndex;
                    } else {
                        console.warn("Saved wallpaper not found in current list:", currentWall);
                    }
                }
            }

            onWallPathChanged: {
                // Rescan wallpapers when wallPath changes
                if (wallPath) {
                    console.log("Wallpaper directory changed to:", wallPath);
                    scanWallpapers.running = true;
                }
            }
        }
    }

    Keys.onLeftPressed: {
        if (wallpaperPaths.length > 0) {
            previousWallpaper();
        }
    }

    Keys.onRightPressed: {
        if (wallpaperPaths.length > 0) {
            nextWallpaper();
        }
    }

    Process {
        id: matugenProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("Matugen output:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Matugen error:", text);
                }
            }
        }
    }

    // Directory watcher using FileView to monitor the wallpaper directory
    FileView {
        id: directoryWatcher
        path: wallpaperDir
        watchChanges: true
        printErrors: false
        
        onFileChanged: {
            console.log("Wallpaper directory changed, rescanning...");
            scanWallpapers.running = true;
        }
        
        onLoadFailed: {
            // Directory doesn't exist or can't be read, use fallback
            if (!usingFallback) {
                console.log("Main wallpaper directory not accessible, using fallback");
                usingFallback = true;
                scanFallback.running = true;
            }
        }
    }



    Process {
        id: scanWallpapers
        running: false
        command: ["find", wallpaperDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                let files = text.trim().split("\n").filter(f => f.length > 0);
                if (files.length === 0) {
                    if (!usingFallback) {
                        console.log("No wallpapers found in main directory, using fallback");
                        usingFallback = true;
                        scanFallback.running = true;
                    }
                } else {
                    usingFallback = false;
                    // Only update if the list has actually changed
                    const newFiles = files.sort();
                    if (JSON.stringify(newFiles) !== JSON.stringify(wallpaperPaths)) {
                        console.log("Wallpaper directory updated. Found", newFiles.length, "images");
                        wallpaperPaths = newFiles;
                        
                        // Initialize wallpaper selection
                        if (wallpaperPaths.length > 0 && !initialLoadCompleted) {
                            if (wallpaperConfig.adapter.currentWall) {
                                const savedIndex = wallpaperPaths.indexOf(wallpaperConfig.adapter.currentWall);
                                if (savedIndex !== -1) {
                                    currentIndex = savedIndex;
                                } else {
                                    currentIndex = 0;
                                    wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                                }
                            } else {
                                currentIndex = 0;
                                wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                            }
                            initialLoadCompleted = true;
                        }
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error scanning wallpaper directory:", text);
                    // Only fallback if we don't already have wallpapers loaded and not already using fallback
                    if (wallpaperPaths.length === 0 && !usingFallback) {
                        usingFallback = true;
                        scanFallback.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: scanFallback
        running: false
        command: ["find", fallbackDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split("\n").filter(f => f.length > 0);
                console.log("Using fallback wallpapers. Found", files.length, "images");
                
                // Only use fallback if we don't already have main wallpapers loaded
                if (usingFallback) {
                    wallpaperPaths = files.sort();
                    
                    // Initialize fallback wallpaper selection
                    if (wallpaperPaths.length > 0 && !initialLoadCompleted) {
                        currentIndex = 0;
                        wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                        initialLoadCompleted = true;
                    }
                }
            }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#000000"

        WallpaperImage {
            id: wallpaper1
            anchors.fill: parent
            source: wallpaper.currentWallpaper
            active: wallpaper.currentIndex % 2 === 0
        }

        WallpaperImage {
            id: wallpaper2
            anchors.fill: parent
            source: wallpaper.currentWallpaper
            active: wallpaper.currentIndex % 2 === 1
        }
    }

    component WallpaperImage: Item {
        property string source
        property bool active: false

        opacity: active ? 1.0 : 0.0
        scale: active ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Image {
            anchors.fill: parent
            source: parent.source ? parent.source : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }
    }
}
