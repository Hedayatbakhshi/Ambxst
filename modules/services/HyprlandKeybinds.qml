import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

QtObject {
    id: root

    property Process hyprctlProcess: Process {}

    property Timer applyTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: applyKeybindsInternal()
    }

    function applyKeybinds() {
        applyTimer.restart();
    }

    function applyKeybindsInternal() {
        // Verificar que el adapter esté cargado
        if (!Config.keybindsLoader.loaded) {
            console.log("HyprlandKeybinds: Esperando que se cargue el adapter...");
            return;
        }

        console.log("HyprlandKeybinds: Aplicando keybindings...");

        // Construir lista de unbinds
        let unbindCommands = [];
        
        // Helper function para formatear modifiers
        function formatModifiers(modifiers) {
            if (!modifiers || modifiers.length === 0) return "";
            return modifiers.join(" ");
        }

        // Helper function para crear un bind command
        function createBindCommand(keybind, flags) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            const dispatcher = keybind.dispatcher;
            const argument = keybind.argument || "";
            const bindKeyword = flags ? `bind${flags}` : "bind";
            // Para bindm no se incluye argumento si está vacío
            if (flags === "m" && !argument) {
                return `keyword ${bindKeyword} ${mods},${key},${dispatcher}`;
            }
            return `keyword ${bindKeyword} ${mods},${key},${dispatcher},${argument}`;
        }

        // Helper function para crear un unbind command
        function createUnbindCommand(keybind) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            return `keyword unbind ${mods},${key}`;
        }

        // Construir batch command con todos los binds
        let batchCommands = [];

        // Procesar Ambxst keybinds
        const ambxst = Config.keybindsLoader.adapter.ambxst;
        
        // Dashboard keybinds
        const dashboard = ambxst.dashboard;
        unbindCommands.push(createUnbindCommand(dashboard.widgets));
        unbindCommands.push(createUnbindCommand(dashboard.clipboard));
        unbindCommands.push(createUnbindCommand(dashboard.emoji));
        unbindCommands.push(createUnbindCommand(dashboard.tmux));
        unbindCommands.push(createUnbindCommand(dashboard.kanban));
        unbindCommands.push(createUnbindCommand(dashboard.wallpapers));
        unbindCommands.push(createUnbindCommand(dashboard.assistant));
        
        batchCommands.push(createBindCommand(dashboard.widgets));
        batchCommands.push(createBindCommand(dashboard.clipboard));
        batchCommands.push(createBindCommand(dashboard.emoji));
        batchCommands.push(createBindCommand(dashboard.tmux));
        batchCommands.push(createBindCommand(dashboard.kanban));
        batchCommands.push(createBindCommand(dashboard.wallpapers));
        batchCommands.push(createBindCommand(dashboard.assistant));

        // System keybinds
        const system = ambxst.system;
        unbindCommands.push(createUnbindCommand(system.overview));
        unbindCommands.push(createUnbindCommand(system.powermenu));
        unbindCommands.push(createUnbindCommand(system.config));
        unbindCommands.push(createUnbindCommand(system.lockscreen));
        
        batchCommands.push(createBindCommand(system.overview));
        batchCommands.push(createBindCommand(system.powermenu));
        batchCommands.push(createBindCommand(system.config));
        batchCommands.push(createBindCommand(system.lockscreen));

        // Procesar custom keybinds
        const customBinds = Config.keybindsLoader.adapter.custom;
        if (customBinds && customBinds.length > 0) {
            for (let i = 0; i < customBinds.length; i++) {
                const bind = customBinds[i];
                if (bind.enabled !== false) {  // Por defecto enabled=true
                    unbindCommands.push(createUnbindCommand(bind));
                    const flags = bind.flags || "";
                    batchCommands.push(createBindCommand(bind, flags));
                }
            }
        }

        // Combinar unbind y bind en un solo batch
        const fullBatchCommand = unbindCommands.join("; ") + "; " + batchCommands.join("; ");

        console.log("HyprlandKeybinds: Ejecutando batch command");
        hyprctlProcess.command = ["sh", "-c", `hyprctl --batch "${fullBatchCommand}"`];
        hyprctlProcess.running = true;
    }

    property Connections configConnections: Connections {
        target: Config.keybindsLoader
        function onFileChanged() {
            applyKeybinds();
        }
        function onLoaded() {
            applyKeybinds();
        }
    }

    property Connections hyprlandConnections: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                console.log("HyprlandKeybinds: Detectado configreloaded, reaplicando keybindings...");
                applyKeybinds();
            }
        }
    }

    Component.onCompleted: {
        // Si el loader ya está cargado, aplicar inmediatamente
        if (Config.keybindsLoader.loaded) {
            applyKeybinds();
        }
    }
}
