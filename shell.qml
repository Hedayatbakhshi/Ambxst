//@ pragma UseQApplication
//@ pragma ShellId Ambyst
import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.workspaces
import qs.modules.notifications
import qs.modules.wallpaper
import qs.modules.notch
import qs.modules.services
import qs.modules.corners
import qs.config

ShellRoot {
    id: root

    // Wallpaper for all screens
    Variants {
        model: Quickshell.screens

        Loader {
            id: wallpaperLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Wallpaper {
                screen: wallpaperLoader.modelData
            }
        }
    }

    // Multi-monitor support - create bar for each screen
    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Configuration.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: barLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Bar {
                screen: barLoader.modelData
            }
        }
    }

    // Multi-monitor support - create notch for each screen
    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Configuration.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        Loader {
            id: notchLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: NotchWindow {
                screen: notchLoader.modelData
            }
        }
    }

    // Multi-monitor support - create corners for each screen
    Variants {
        model: Quickshell.screens

        Loader {
            id: cornersLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: ScreenCorners {
                screen: cornersLoader.modelData
            }
        }
    }

    Loader {
        active: true
        sourceComponent: NotificationPopup {}
    }

    // Global shortcuts service
    GlobalShortcuts {
        id: globalShortcuts
    }
}
