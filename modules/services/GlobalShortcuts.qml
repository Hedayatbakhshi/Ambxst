import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals

Item {
    id: root

    GlobalShortcut {
        id: launcherShortcut
        appid: "ambyst"
        name: "toggle-launcher"
        description: "Toggle application launcher"

        onPressed: {
            console.log("Launcher shortcut pressed");
            GlobalStates.launcherOpen = !GlobalStates.launcherOpen;
        }
    }

    GlobalShortcut {
        id: dashboardShortcut
        appid: "ambyst"
        name: "toggle-dashboard"
        description: "Toggle dashboard"

        onPressed: {
            console.log("Dashboard shortcut pressed");
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
    }
}