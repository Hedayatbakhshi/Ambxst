import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.bar
import qs.modules.bar.workspaces
import qs.modules.notch
import qs.modules.dock
import qs.modules.frame
import qs.modules.corners
import qs.modules.services
import qs.modules.globals
import qs.modules.components
import qs.config

PanelWindow {
    id: unifiedPanel

    required property ShellScreen targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    
    // Compatibility properties for Visibilities and other components
    readonly property alias barPosition: barContent.barPosition
    readonly property alias barPinned: barContent.pinned
    readonly property alias barHoverActive: barContent.hoverActive
    readonly property alias barFullscreen: barContent.activeWindowFullscreen
    readonly property alias barReveal: barContent.reveal

    readonly property alias dockPosition: dockContent.position
    readonly property alias dockPinned: dockContent.pinned
    readonly property alias dockReveal: dockContent.reveal
    readonly property alias dockFullscreen: dockContent.activeWindowFullscreen

    readonly property alias notchHoverActive: notchContent.hoverActive
    readonly property alias notchOpen: notchContent.screenNotchOpen
    readonly property alias notchReveal: notchContent.reveal

    // Generic names for external compatibility (Visibilities expects these on the panel object)
    readonly property alias pinned: barContent.pinned
    readonly property alias reveal: barContent.reveal
    readonly property alias hoverActive: barContent.hoverActive // Default hoverActive points to bar
    readonly property alias notch_hoverActive: notchContent.hoverActive // Used by bar to check notch

    readonly property var hyprlandMonitor: Hyprland.monitorFor(targetScreen)
    readonly property bool hasFullscreenWindow: {
        if (!hyprlandMonitor) return false;
        
        const activeWorkspaceId = hyprlandMonitor.activeWorkspace.id;
        const monId = hyprlandMonitor.id;
        
        // Check active toplevel first (fast path)
        const toplevel = ToplevelManager.activeToplevel;
        if (toplevel && toplevel.fullscreen && Hyprland.focusedMonitor.id === monId) {
             return true;
        }

        // Check all windows on this monitor (robust path)
        const wins = HyprlandData.windowList;
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].monitor === monId && wins[i].fullscreen && wins[i].workspace.id === activeWorkspaceId) {
                return true;
            }
        }
        return false;
    }

    // Proxy properties for Bar/Notch synchronization
    // Note: BarContent and NotchContent already handle their internal sync using Visibilities.
    
    Component.onCompleted: {
        Visibilities.registerBarPanel(screen.name, unifiedPanel);
        Visibilities.registerNotchPanel(screen.name, unifiedPanel);
        Visibilities.registerBar(screen.name, barContent);
        Visibilities.registerNotch(screen.name, notchContent.notchContainerRef);
    }

    Component.onDestruction: {
        Visibilities.unregisterBarPanel(screen.name);
        Visibilities.unregisterNotchPanel(screen.name);
        Visibilities.unregisterBar(screen.name);
        Visibilities.unregisterNotch(screen.name);
    }

    // Mask Region Logic
    // We use nested regions to define non-contiguous hit areas for each component.
    // This allows clicking through the empty space between the Bar, Notch, and Dock.
    mask: Region {
        regions: [
            Region {
                item: barContent.barHitbox
            },
            Region {
                item: notchContent.notchHitbox
            },
            Region {
                // Only include the dock hitbox if the dock is actually enabled and visible on this screen.
                item: dockContent.visible ? dockContent.dockHitbox : null
            }
        ]
    }

    // Focus Grab for Notch
    HyprlandFocusGrab {
        id: focusGrab
        windows: {
            let windowList = [unifiedPanel];
            // Optionally add other windows if needed, but since we are one window, this might be enough.
            return windowList;
        }
        active: notchContent.screenNotchOpen

        onCleared: {
            Visibilities.setActiveModule("");
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // VISUAL CONTENT (Unified Shadow Wrapper)
    // ═══════════════════════════════════════════════════════════════

    Item {
        id: visualContainer
        anchors.fill: parent
        
        // Apply a single unified shadow to the composite of all components
        layer.enabled: true
        layer.effect: Shadow {}

        ScreenFrameContent {
            id: frameContent
            anchors.fill: parent
            targetScreen: unifiedPanel.targetScreen
            hasFullscreenWindow: unifiedPanel.hasFullscreenWindow
            z: 1
        }

        BarContent {
            id: barContent
            anchors.fill: parent
            screen: unifiedPanel.targetScreen
            z: 2

            // Keep the masking logic to cut out the notch area from the bar
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskInverted: true
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.5
                maskSource: ShaderEffectSource {
                    sourceItem: notchContent
                    hideSource: false
                }
            }
        }

        DockContent {
            id: dockContent
            anchors.fill: parent
            screen: unifiedPanel.targetScreen
            z: 3
            visible: {
                if (!(Config.dock?.enabled ?? false) || (Config.dock?.theme ?? "default") === "integrated")
                    return false;
                
                const list = Config.dock?.screenList ?? [];
                if (!list || list.length === 0)
                    return true;
                return list.includes(screen.name);
            }
        }

        NotchContent {
            id: notchContent
            anchors.fill: parent
            screen: unifiedPanel.targetScreen
            z: 4
        }

        ScreenCornersContent {
            id: cornersContent
            anchors.fill: parent
            hasFullscreenWindow: unifiedPanel.hasFullscreenWindow
            z: 5
            visible: Config.theme.enableCorners && Config.roundness > 0
        }
    }
}
