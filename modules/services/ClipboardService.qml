pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool active: true
    property var items: []
    property var imageDataById: ({})
    property int revision: 0
    property bool _operationInProgress: false
    
    readonly property string dbPath: Quickshell.dataPath("clipboard.db")
    readonly property string binaryDataDir: Quickshell.dataPath("clipboard-data")
    readonly property string schemaPath: Qt.resolvedUrl("clipboard_init.sql").toString().replace("file://", "")
    readonly property string insertScriptPath: Qt.resolvedUrl("../../scripts/clipboard_insert.sh").toString().replace("file://", "")
    readonly property string checkScriptPath: Qt.resolvedUrl("../../scripts/clipboard_check.sh").toString().replace("file://", "")
    readonly property string watchScriptPath: Qt.resolvedUrl("../../scripts/clipboard_watch.sh").toString().replace("file://", "")

    property bool _initialized: false

    signal listCompleted()

    // Clipboard watcher using custom script that monitors changes
    property Process clipboardWatcher: Process {
        running: root._initialized
        command: [watchScriptPath, checkScriptPath, dbPath, insertScriptPath, binaryDataDir]
        
        stdout: StdioCollector {
            onStreamFinished: {
                // When watcher outputs something, refresh the list
                var lines = text.trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i] === "REFRESH_LIST") {
                        Qt.callLater(root.list);
                    }
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0 && !text.includes("No selection")) {
                    console.warn("ClipboardService: watcher stderr:", text);
                }
            }
        }
        
        onExited: function(code) {
            // Watcher should keep running, restart if it exits
            if (root._initialized) {
                console.warn("ClipboardService: watcher exited with code:", code, "- restarting...");
                Qt.callLater(function() {
                    if (root._initialized) {
                        clipboardWatcher.running = true;
                    }
                });
            }
        }
    }

    // Initialize database
    property Process initDbProcess: Process {
        running: false
        
        onExited: function(code) {
            if (code === 0) {
                console.log("ClipboardService: Database initialized");
                root._initialized = true;
                ensureBinaryDataDir();
                Qt.callLater(root.list);
            } else {
                console.warn("ClipboardService: Failed to initialize database");
            }
        }
    }

    property Process ensureDirProcess: Process {
        running: false
    }

    // Single process to check and insert clipboard content (used for manual checks)
    property Process checkAndInsertProcess: Process {
        running: false
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0 && !text.includes("No selection")) {
                    console.warn("ClipboardService: checkAndInsertProcess stderr:", text);
                }
            }
        }
        
        onExited: function(code) {
            _operationInProgress = false;
            if (code === 0) {
                Qt.callLater(root.list);
            }
        }
    }

    // List all items from database
    property Process listProcess: Process {
        running: false
        
        stdout: StdioCollector {
            waitForEnd: true
            
            onStreamFinished: {
                var clipboardItems = [];
                
                var trimmedText = text.trim();
                if (trimmedText.length === 0) {
                    root.items = clipboardItems;
                    root.listCompleted();
                    root._operationInProgress = false;
                    return;
                }
                
                try {
                    var jsonArray = JSON.parse(trimmedText);
                    
                    for (var i = 0; i < jsonArray.length; i++) {
                        var item = jsonArray[i];
                        var isFile = item.mime_type === "text/uri-list";
                        
                        // For files, extract the filename from the URI for preview
                        var preview = item.preview;
                        if (isFile && item.full_content) {
                            var uriContent = item.full_content.trim();
                            if (uriContent.startsWith("file://")) {
                                var filePath = uriContent.substring(7); // Remove "file://"
                                var fileName = filePath.split('/').pop();
                                preview = "[File] " + fileName;
                            }
                        } else if (item.is_image === 1) {
                            preview = "[Image]";
                        }
                        
                        clipboardItems.push({
                            id: item.id.toString(),
                            preview: preview,
                            fullContent: item.preview,
                            mime: item.mime_type,
                            isImage: item.is_image === 1,
                            isFile: isFile,
                            binaryPath: item.binary_path || "",
                            hash: item.content_hash || "",
                            createdAt: item.created_at || 0
                        });
                    }
                } catch (e) {
                    console.warn("ClipboardService: Failed to parse clipboard items:", e);
                }
                
                root.items = clipboardItems;
                root.listCompleted();
                root._operationInProgress = false;
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("ClipboardService: listProcess stderr:", text);
                }
            }
        }
        
        onExited: function(code) {
            if (code !== 0) {
                root.items = [];
                root.listCompleted();
                root._operationInProgress = false;
            }
        }
    }

    // Insert item into database - kept for backwards compatibility but deprecated
    property Process insertProcess: Process {
        property string itemHash: ""
        property string itemContent: ""
        property string tmpFile: ""
        running: false
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("ClipboardService: insertProcess stderr:", text);
                }
            }
        }
        
        onExited: function(code) {
            if (code === 0) {
                Qt.callLater(root.list);
            } else {
                console.warn("ClipboardService: insertProcess failed with code:", code);
                root._operationInProgress = false;
            }
            
            itemHash = "";
            itemContent = "";
            tmpFile = "";
        }
    }

    // Get full content of an item
    property Process getContentProcess: Process {
        property string itemId: ""
        running: false
        
        stdout: StdioCollector {
            waitForEnd: true
            
            onStreamFinished: {
                root.fullContentRetrieved(getContentProcess.itemId, text);
            }
        }
        
        onExited: function(code) {
            if (code !== 0) {
                root.fullContentRetrieved(getContentProcess.itemId, "");
            }
        }
    }

    // Delete item
    property Process deleteProcess: Process {
        property string itemId: ""
        running: false
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("ClipboardService: deleteProcess stderr:", text);
                }
            }
        }
        
        onExited: function(code) {
            if (code === 0) {
                Qt.callLater(root.list);
            } else {
                root._operationInProgress = false;
            }
        }
    }

    // Clear all items
    property Process clearProcess: Process {
        running: false
        
        onExited: function(code) {
            if (code === 0) {
                root.items = [];
                root.imageDataById = {};
                root.revision++;
                root.listCompleted();
                cleanBinaryDataDirProcess.running = true;
            }
        }
    }
    
    // Clean binary data directory
    property Process cleanBinaryDataDirProcess: Process {
        running: false
        command: ["sh", "-c", "rm -f " + binaryDataDir + "/*"]
    }

    // Load image data
    property Process loadImageProcess: Process {
        property string itemId: ""
        property string mimeType: ""
        running: false
        
        stdout: StdioCollector {
            waitForEnd: true
            
            onStreamFinished: {
                if (text.length > 0) {
                    var cleanBase64 = text.replace(/\s/g, '');
                    var dataUrl = "data:" + loadImageProcess.mimeType + ";base64," + cleanBase64;
                    root.imageDataById[loadImageProcess.itemId] = dataUrl;
                    root.revision++;
                }
            }
        }
    }

    signal fullContentRetrieved(string itemId, string content)

    function initialize() {
        initDbProcess.command = ["sh", "-c", "sqlite3 " + dbPath + " < " + schemaPath];
        initDbProcess.running = true;
    }

    function ensureBinaryDataDir() {
        ensureDirProcess.command = ["mkdir", "-p", binaryDataDir];
        ensureDirProcess.running = true;
    }

    function checkClipboard() {
        if (!_initialized || _operationInProgress) return;
        _operationInProgress = true;
        checkAndInsertProcess.command = [checkScriptPath, dbPath, insertScriptPath, binaryDataDir];
        checkAndInsertProcess.running = true;
    }

    function getImageHash(mimeType) {
        // Deprecated - now handled by clipboard_check.sh
    }

    function insertTextItemFromFile(hash, tmpFile) {
        // Deprecated - now handled by clipboard_check.sh
    }
    
    function insertFileItemFromFile(hash, tmpFile) {
        // Deprecated - now handled by clipboard_check.sh
    }
    
    property Process writeTmpProcess: Process {
        property string itemHash: ""
        property string itemContent: ""
        running: false
        
        stdout: StdioCollector {
            waitForEnd: true
            
            onStreamFinished: {
                // Deprecated
            }
        }
    }

    function insertImageItem(hash, mimeType) {
        // Deprecated - now handled by clipboard_check.sh
    }

    function list() {
        if (!_initialized) return;
        _operationInProgress = true;
        // Use JSON mode for reliable parsing, with timeout to avoid locks
        // ORDER BY updated_at to show most recently used items first
        listProcess.command = ["sh", "-c", 
            "sqlite3 '" + dbPath + "' <<'EOSQL'\n.timeout 5000\n.mode json\nSELECT id, mime_type, preview, is_image, binary_path, content_hash, created_at FROM clipboard_items ORDER BY updated_at DESC LIMIT 100;\nEOSQL"
        ];
        listProcess.running = true;
    }

    function getFullContent(id) {
        if (!_initialized) return;
        getContentProcess.itemId = id;
        getContentProcess.command = ["sh", "-c", "sqlite3 '" + dbPath + "' '.timeout 5000' 'SELECT full_content FROM clipboard_items WHERE id = " + id + ";'"];
        getContentProcess.running = true;
    }

    function deleteItem(id) {
        if (!_initialized) return;
        _operationInProgress = true;
        deleteProcess.itemId = id;
        deleteProcess.command = ["sh", "-c", "sqlite3 '" + dbPath + "' '.timeout 5000' 'DELETE FROM clipboard_items WHERE id = " + id + ";'"];
        deleteProcess.running = true;
    }

    function clear() {
        if (!_initialized) return;
        clearProcess.command = ["sh", "-c", "sqlite3 '" + dbPath + "' '.timeout 5000' 'DELETE FROM clipboard_items;'"];
        clearProcess.running = true;
    }

    function decodeToDataUrl(id, mime) {
        if (imageDataById[id]) {
            return;
        }
        
        for (var i = 0; i < items.length; i++) {
            if (items[i].id === id) {
                var binaryPath = items[i].binaryPath;
                if (binaryPath && binaryPath.length > 0) {
                    loadImageProcess.itemId = id;
                    loadImageProcess.mimeType = mime;
                    loadImageProcess.command = ["base64", "-w", "0", binaryPath];
                    loadImageProcess.running = true;
                }
                break;
            }
        }
    }

    function getImageData(id) {
        return imageDataById[id] || "";
    }

    Component.onCompleted: {
        initialize();
    }
}
