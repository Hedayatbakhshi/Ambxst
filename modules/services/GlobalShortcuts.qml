import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals
import qs.modules.services

Item {
    id: root

    GlobalShortcut {
        id: overviewShortcut
        appid: "ambxst"
        name: "overview"
        description: "Toggle window overview"

        onPressed: {
            if (Visibilities.currentActiveModule === "overview") {
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("overview");
            }
        }
    }

    GlobalShortcut {
        id: powermenuShortcut
        appid: "ambxst"
        name: "powermenu"
        description: "Toggle power menu"

        onPressed: {
            if (Visibilities.currentActiveModule === "powermenu") {
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("powermenu");
            }
        }
    }

    // Launcher tab shortcuts
    GlobalShortcut {
        id: launcherAppsShortcut
        appid: "ambxst"
        name: "launcher-apps"
        description: "Open launcher apps tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "launcher" && GlobalStates.launcherCurrentTab === 0) {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "launcher") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.launcherCurrentTab = 0;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.launcherCurrentTab = 0;
                Visibilities.setActiveModule("launcher");
            }
        }
    }

    GlobalShortcut {
        id: launcherTmuxShortcut
        appid: "ambxst"
        name: "launcher-tmux"
        description: "Open launcher tmux tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "launcher" && GlobalStates.launcherCurrentTab === 1) {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "launcher") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.launcherCurrentTab = 1;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.launcherCurrentTab = 1;
                Visibilities.setActiveModule("launcher");
            }
        }
    }

    GlobalShortcut {
        id: launcherClipboardShortcut
        appid: "ambxst"
        name: "launcher-clipboard"
        description: "Open launcher clipboard tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "launcher" && GlobalStates.launcherCurrentTab === 2) {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "launcher") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.launcherCurrentTab = 2;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.launcherCurrentTab = 2;
                Visibilities.setActiveModule("launcher");
            }
        }
    }

    // Dashboard tab shortcuts
    GlobalShortcut {
        id: dashboardWidgetsShortcut
        appid: "ambxst"
        name: "dashboard-widgets"
        description: "Open dashboard widgets tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 0) {
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "dashboard") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.dashboardCurrentTab = 0;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.dashboardCurrentTab = 0;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    GlobalShortcut {
        id: dashboardPinsShortcut
        appid: "ambxst"
        name: "dashboard-pins"
        description: "Open dashboard pins tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 1) {
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "dashboard") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.dashboardCurrentTab = 1;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.dashboardCurrentTab = 1;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    GlobalShortcut {
        id: dashboardKanbanShortcut
        appid: "ambxst"
        name: "dashboard-kanban"
        description: "Open dashboard kanban tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 2) {
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "dashboard") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.dashboardCurrentTab = 2;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.dashboardCurrentTab = 2;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    GlobalShortcut {
        id: dashboardWallpapersShortcut
        appid: "ambxst"
        name: "dashboard-wallpapers"
        description: "Open dashboard wallpapers tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 3) {
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "dashboard") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.dashboardCurrentTab = 3;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.dashboardCurrentTab = 3;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    GlobalShortcut {
        id: dashboardAssistantShortcut
        appid: "ambxst"
        name: "dashboard-assistant"
        description: "Open dashboard assistant tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "dashboard" && GlobalStates.dashboardCurrentTab === 4) {
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "dashboard") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.dashboardCurrentTab = 4;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.dashboardCurrentTab = 4;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }

    GlobalShortcut {
        id: launcherEmojiShortcut
        appid: "ambxst"
        name: "launcher-emoji"
        description: "Open launcher emoji tab"

        onPressed: {
            if (Visibilities.currentActiveModule === "launcher" && GlobalStates.launcherCurrentTab === 3) {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            } else if (Visibilities.currentActiveModule === "launcher") {
                // Solo navegar a la pestaña sin cerrar/abrir
                GlobalStates.launcherCurrentTab = 3;
            } else {
                // Actualizar la pestaña ANTES de abrir el módulo
                GlobalStates.launcherCurrentTab = 3;
                Visibilities.setActiveModule("launcher");
            }
        }
    }

    // Media player shortcuts
    GlobalShortcut {
        id: mediaSeekBackwardShortcut
        appid: "ambxst"
        name: "media-seek-backward"
        description: "Seek backward in media player"

        onPressed: {
            if (MprisController.activePlayer && MprisController.activePlayer.canSeek) {
                const seekAmount = 5000; // Seek 5 seconds backward
                MprisController.activePlayer.position = Math.max(0, MprisController.activePlayer.position - seekAmount);
            }
        }
    }

    GlobalShortcut {
        id: mediaSeekForwardShortcut
        appid: "ambxst"
        name: "media-seek-forward"
        description: "Seek forward in media player"

        onPressed: {
            if (MprisController.activePlayer && MprisController.activePlayer.canSeek) {
                const seekAmount = 5000; // Seek 5 seconds forward
                MprisController.activePlayer.position = Math.min(MprisController.activePlayer.length, MprisController.activePlayer.position + seekAmount);
            }
        }
    }

    GlobalShortcut {
        id: mediaPlayPauseShortcut
        appid: "ambxst"
        name: "media-play-pause"
        description: "Toggle play/pause in media player"

        onPressed: {
            if (MprisController.canTogglePlaying) {
                MprisController.togglePlaying();
            }
        }
    }

    // Volume control shortcuts
    GlobalShortcut {
        id: volumeUpShortcut
        appid: "ambxst"
        name: "vol-up"
        description: "Increase volume by 5%"

        onPressed: {
            if (Audio.sink?.audio) {
                Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + 0.05);
            }
        }
    }

    GlobalShortcut {
        id: volumeDownShortcut
        appid: "ambxst"
        name: "vol-down"
        description: "Decrease volume by 5%"

        onPressed: {
            if (Audio.sink?.audio) {
                Audio.sink.audio.volume = Math.max(0, Audio.sink.audio.volume - 0.05);
            }
        }
    }

    GlobalShortcut {
        id: volumeMuteShortcut
        appid: "ambxst"
        name: "vol-mute"
        description: "Toggle mute"

        onPressed: {
            if (Audio.sink?.audio) {
                Audio.sink.audio.muted = !Audio.sink.audio.muted;
            }
        }
    }
}
