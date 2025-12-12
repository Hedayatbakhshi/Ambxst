pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals
import qs.modules.theme
import qs.modules.services as Services
import "defaults/theme.js" as ThemeDefaults
import "defaults/bar.js" as BarDefaults
import "defaults/workspaces.js" as WorkspacesDefaults
import "defaults/overview.js" as OverviewDefaults
import "defaults/notch.js" as NotchDefaults
import "defaults/hyprland.js" as HyprlandDefaults
import "defaults/performance.js" as PerformanceDefaults
import "defaults/weather.js" as WeatherDefaults
import "defaults/desktop.js" as DesktopDefaults
import "defaults/lockscreen.js" as LockscreenDefaults
import "defaults/prefix.js" as PrefixDefaults
import "defaults/system.js" as SystemDefaults
import "ConfigValidator.js" as ConfigValidator

Singleton {
    id: root

    property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/Ambxst/config"
    property string keybindsPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/Ambxst/binds.json"

    property bool pauseAutoSave: false

    // Track initialization of all modules
    property bool themeReady: false
    property bool barReady: false
    property bool workspacesReady: false
    property bool overviewReady: false
    property bool notchReady: false
    property bool hyprlandReady: false
    property bool performanceReady: false
    property bool weatherReady: false
    property bool desktopReady: false
    property bool lockscreenReady: false
    property bool prefixReady: false
    property bool systemReady: false
    property bool keybindsInitialLoadComplete: false

    property bool initialLoadComplete: themeReady && barReady && workspacesReady &&
        overviewReady && notchReady && hyprlandReady && performanceReady &&
        weatherReady && desktopReady && lockscreenReady && prefixReady && systemReady

    // Aliases for backward compatibility
    property alias loader: themeLoader
    property alias keybindsLoader: keybindsLoader

    // ============================================
    // DIRECTORY SETUP
    // ============================================
    Process {
        id: setupConfigDir
        running: true
        command: ["mkdir", "-p", root.configDir]
    }

    // ============================================
    // THEME MODULE
    // ============================================
    FileView {
        id: themeRawLoader
        path: root.configDir + "/theme.json"
        onLoaded: {
            if (!root.themeReady) {
                validateModule("theme", themeRawLoader, ThemeDefaults.data, () => { root.themeReady = true; });
            }
        }
    }

    Process {
        id: checkThemeFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/theme.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("theme.json not found, creating with default values...");
                themeRawLoader.setText(JSON.stringify(ThemeDefaults.data, null, 4));
                root.themeReady = true;
            }
        }
    }

    FileView {
        id: themeLoader
        path: root.configDir + "/theme.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.themeReady && !root.pauseAutoSave) {
                themeLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property bool oledMode: false
            property bool lightMode: false
            property int roundness: 16
            property string font: "Roboto Condensed"
            property int fontSize: 14
            property bool tintIcons: false
            property bool enableCorners: true
            property int animDuration: 300
            property real shadowOpacity: 0.5
            property string shadowColor: "shadow"
            property int shadowXOffset: 0
            property int shadowYOffset: 0
            property real shadowBlur: 1

            property JsonObject srBg: JsonObject {
                property list<var> gradient: [["background", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "surface"
                property string halftoneBackgroundColor: "background"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 1.0
            }

            property JsonObject srInternalBg: JsonObject {
                property list<var> gradient: [["background", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "surface"
                property string halftoneBackgroundColor: "background"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 1.0
            }

            property JsonObject srBarBg: JsonObject {
                property list<var> gradient: [["surfaceDim", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "surface"
                property string halftoneBackgroundColor: "surfaceDim"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 0.0
            }

            property JsonObject srPane: JsonObject {
                property list<var> gradient: [["surface", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "surfaceBright"
                property string halftoneBackgroundColor: "surface"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 1.0
            }

            property JsonObject srCommon: JsonObject {
                property list<var> gradient: [["surface", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "background"
                property string halftoneBackgroundColor: "surface"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 1.0
            }

            property JsonObject srFocus: JsonObject {
                property list<var> gradient: [["surfaceBright", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "surfaceVariant"
                property string halftoneBackgroundColor: "surfaceBright"
                property list<var> border: ["surfaceBright", 0]
                property string itemColor: "overBackground"
                property real opacity: 1.0
            }

            property JsonObject srPrimary: JsonObject {
                property list<var> gradient: [["primary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "overPrimaryContainer"
                property string halftoneBackgroundColor: "primary"
                property list<var> border: ["primary", 0]
                property string itemColor: "overPrimary"
                property real opacity: 1.0
            }

            property JsonObject srPrimaryFocus: JsonObject {
                property list<var> gradient: [["overPrimaryContainer", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "primary"
                property string halftoneBackgroundColor: "overPrimaryContainer"
                property list<var> border: ["overBackground", 0]
                property string itemColor: "overPrimary"
                property real opacity: 1.0
            }

            property JsonObject srOverPrimary: JsonObject {
                property list<var> gradient: [["overPrimary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "primaryContainer"
                property string halftoneBackgroundColor: "overPrimary"
                property list<var> border: ["overPrimary", 0]
                property string itemColor: "primary"
                property real opacity: 1.0
            }

            property JsonObject srSecondary: JsonObject {
                property list<var> gradient: [["secondary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "overSecondaryContainer"
                property string halftoneBackgroundColor: "secondary"
                property list<var> border: ["secondary", 0]
                property string itemColor: "overSecondary"
                property real opacity: 1.0
            }

            property JsonObject srSecondaryFocus: JsonObject {
                property list<var> gradient: [["overSecondaryContainer", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "secondary"
                property string halftoneBackgroundColor: "overSecondaryContainer"
                property list<var> border: ["overBackground", 0]
                property string itemColor: "overSecondary"
                property real opacity: 1.0
            }

            property JsonObject srOverSecondary: JsonObject {
                property list<var> gradient: [["overSecondary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "secondaryContainer"
                property string halftoneBackgroundColor: "overSecondary"
                property list<var> border: ["overSecondary", 0]
                property string itemColor: "secondary"
                property real opacity: 1.0
            }

            property JsonObject srTertiary: JsonObject {
                property list<var> gradient: [["tertiary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "overTertiaryContainer"
                property string halftoneBackgroundColor: "tertiary"
                property list<var> border: ["tertiary", 0]
                property string itemColor: "overTertiary"
                property real opacity: 1.0
            }

            property JsonObject srTertiaryFocus: JsonObject {
                property list<var> gradient: [["overTertiaryContainer", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "tertiary"
                property string halftoneBackgroundColor: "overTertiaryContainer"
                property list<var> border: ["overBackground", 0]
                property string itemColor: "overTertiary"
                property real opacity: 1.0
            }

            property JsonObject srOverTertiary: JsonObject {
                property list<var> gradient: [["overTertiary", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "tertiaryContainer"
                property string halftoneBackgroundColor: "overTertiary"
                property list<var> border: ["overTertiary", 0]
                property string itemColor: "tertiary"
                property real opacity: 1.0
            }

            property JsonObject srError: JsonObject {
                property list<var> gradient: [["error", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "overErrorContainer"
                property string halftoneBackgroundColor: "error"
                property list<var> border: ["error", 0]
                property string itemColor: "overError"
                property real opacity: 1.0
            }

            property JsonObject srErrorFocus: JsonObject {
                property list<var> gradient: [["overBackground", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "error"
                property string halftoneBackgroundColor: "overErrorContainer"
                property list<var> border: ["overBackground", 0]
                property string itemColor: "overError"
                property real opacity: 1.0
            }

            property JsonObject srOverError: JsonObject {
                property list<var> gradient: [["overError", 0.0]]
                property string gradientType: "linear"
                property int gradientAngle: 0
                property real gradientCenterX: 0.5
                property real gradientCenterY: 0.5
                property real halftoneDotMin: 0.0
                property real halftoneDotMax: 2.0
                property real halftoneStart: 0.0
                property real halftoneEnd: 1.0
                property string halftoneDotColor: "errorContainer"
                property string halftoneBackgroundColor: "overError"
                property list<var> border: ["overError", 0]
                property string itemColor: "error"
                property real opacity: 1.0
            }
        }
    }

    // ============================================
    // BAR MODULE
    // ============================================
    FileView {
        id: barRawLoader
        path: root.configDir + "/bar.json"
        onLoaded: {
            if (!root.barReady) {
                validateModule("bar", barRawLoader, BarDefaults.data, () => { root.barReady = true; });
            }
        }
    }

    Process {
        id: checkBarFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/bar.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("bar.json not found, creating with default values...");
                barRawLoader.setText(JSON.stringify(BarDefaults.data, null, 4));
                root.barReady = true;
            }
        }
    }

    FileView {
        id: barLoader
        path: root.configDir + "/bar.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.barReady && !root.pauseAutoSave) {
                barLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property string position: "top"
            property string launcherIcon: ""
            property bool launcherIconTint: true
            property bool launcherIconFullTint: true
            property int launcherIconSize: 24
            property list<string> screenList: []
            property bool enableFirefoxPlayer: false
            property list<var> barColor: [["surface", 0.0]]
        }
    }

    // ============================================
    // WORKSPACES MODULE
    // ============================================
    FileView {
        id: workspacesRawLoader
        path: root.configDir + "/workspaces.json"
        onLoaded: {
            if (!root.workspacesReady) {
                validateModule("workspaces", workspacesRawLoader, WorkspacesDefaults.data, () => { root.workspacesReady = true; });
            }
        }
    }

    Process {
        id: checkWorkspacesFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/workspaces.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("workspaces.json not found, creating with default values...");
                workspacesRawLoader.setText(JSON.stringify(WorkspacesDefaults.data, null, 4));
                root.workspacesReady = true;
            }
        }
    }

    FileView {
        id: workspacesLoader
        path: root.configDir + "/workspaces.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.workspacesReady && !root.pauseAutoSave) {
                workspacesLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property int shown: 10
            property bool showAppIcons: true
            property bool alwaysShowNumbers: false
            property bool showNumbers: false
            property bool dynamic: false
        }
    }

    // ============================================
    // OVERVIEW MODULE
    // ============================================
    FileView {
        id: overviewRawLoader
        path: root.configDir + "/overview.json"
        onLoaded: {
            if (!root.overviewReady) {
                validateModule("overview", overviewRawLoader, OverviewDefaults.data, () => { root.overviewReady = true; });
            }
        }
    }

    Process {
        id: checkOverviewFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/overview.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("overview.json not found, creating with default values...");
                overviewRawLoader.setText(JSON.stringify(OverviewDefaults.data, null, 4));
                root.overviewReady = true;
            }
        }
    }

    FileView {
        id: overviewLoader
        path: root.configDir + "/overview.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.overviewReady && !root.pauseAutoSave) {
                overviewLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property int rows: 2
            property int columns: 5
            property real scale: 0.1
            property real workspaceSpacing: 4
        }
    }

    // ============================================
    // NOTCH MODULE
    // ============================================
    FileView {
        id: notchRawLoader
        path: root.configDir + "/notch.json"
        onLoaded: {
            if (!root.notchReady) {
                validateModule("notch", notchRawLoader, NotchDefaults.data, () => { root.notchReady = true; });
            }
        }
    }

    Process {
        id: checkNotchFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/notch.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("notch.json not found, creating with default values...");
                notchRawLoader.setText(JSON.stringify(NotchDefaults.data, null, 4));
                root.notchReady = true;
            }
        }
    }

    FileView {
        id: notchLoader
        path: root.configDir + "/notch.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.notchReady && !root.pauseAutoSave) {
                notchLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property string theme: "default"
        }
    }

    // ============================================
    // HYPRLAND MODULE
    // ============================================
    FileView {
        id: hyprlandRawLoader
        path: root.configDir + "/hyprland.json"
        onLoaded: {
            if (!root.hyprlandReady) {
                validateModule("hyprland", hyprlandRawLoader, HyprlandDefaults.data, () => { root.hyprlandReady = true; });
            }
        }
    }

    Process {
        id: checkHyprlandFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/hyprland.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("hyprland.json not found, creating with default values...");
                hyprlandRawLoader.setText(JSON.stringify(HyprlandDefaults.data, null, 4));
                root.hyprlandReady = true;
            }
        }
    }

    FileView {
        id: hyprlandLoader
        path: root.configDir + "/hyprland.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.hyprlandReady && !root.pauseAutoSave) {
                hyprlandLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property list<string> activeBorderColor: ["primary"]
            property int borderAngle: 45
            property list<string> inactiveBorderColor: ["surface"]
            property int inactiveBorderAngle: 45
            property int borderSize: 2
            property int rounding: 16
            property bool syncRoundness: true
            property bool syncBorderWidth: false
            property bool syncBorderColor: false
            property bool syncShadowOpacity: false
            property bool syncShadowColor: false
            property int gapsIn: 2
            property int gapsOut: 4
            property string layout: "dwindle"
            property bool shadowEnabled: true
            property int shadowRange: 8
            property int shadowRenderPower: 3
            property bool shadowSharp: false
            property bool shadowIgnoreWindow: true
            property string shadowColor: "shadow"
            property string shadowColorInactive: "shadow"
            property real shadowOpacity: 0.5
            property string shadowOffset: "0 0"
            property real shadowScale: 1.0
            property bool blurEnabled: true
            property int blurSize: 4
            property int blurPasses: 2
            property bool blurIgnoreOpacity: true
            property bool blurNewOptimizations: true
            property bool blurXray: false
            property real blurNoise: 0.0
            property real blurContrast: 1.0
            property real blurBrightness: 1.0
            property real blurVibrancy: 0.0
            property real blurVibrancyDarkness: 0.0
            property bool blurSpecial: true
            property bool blurPopups: false
            property real blurPopupsIgnorealpha: 0.2
            property bool blurInputMethods: false
            property real blurInputMethodsIgnorealpha: 0.2
        }
    }

    // ============================================
    // PERFORMANCE MODULE
    // ============================================
    FileView {
        id: performanceRawLoader
        path: root.configDir + "/performance.json"
        onLoaded: {
            if (!root.performanceReady) {
                validateModule("performance", performanceRawLoader, PerformanceDefaults.data, () => { root.performanceReady = true; });
            }
        }
    }

    Process {
        id: checkPerformanceFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/performance.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("performance.json not found, creating with default values...");
                performanceRawLoader.setText(JSON.stringify(PerformanceDefaults.data, null, 4));
                root.performanceReady = true;
            }
        }
    }

    FileView {
        id: performanceLoader
        path: root.configDir + "/performance.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.performanceReady && !root.pauseAutoSave) {
                performanceLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property bool blurTransition: true
            property bool windowPreview: true
            property bool wavyLine: true
        }
    }

    // ============================================
    // WEATHER MODULE
    // ============================================
    FileView {
        id: weatherRawLoader
        path: root.configDir + "/weather.json"
        onLoaded: {
            if (!root.weatherReady) {
                validateModule("weather", weatherRawLoader, WeatherDefaults.data, () => { root.weatherReady = true; });
            }
        }
    }

    Process {
        id: checkWeatherFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/weather.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("weather.json not found, creating with default values...");
                weatherRawLoader.setText(JSON.stringify(WeatherDefaults.data, null, 4));
                root.weatherReady = true;
            }
        }
    }

    FileView {
        id: weatherLoader
        path: root.configDir + "/weather.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.weatherReady && !root.pauseAutoSave) {
                weatherLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property string location: ""
            property string unit: "C"
        }
    }

    // ============================================
    // DESKTOP MODULE
    // ============================================
    FileView {
        id: desktopRawLoader
        path: root.configDir + "/desktop.json"
        onLoaded: {
            if (!root.desktopReady) {
                validateModule("desktop", desktopRawLoader, DesktopDefaults.data, () => { root.desktopReady = true; });
            }
        }
    }

    Process {
        id: checkDesktopFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/desktop.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("desktop.json not found, creating with default values...");
                desktopRawLoader.setText(JSON.stringify(DesktopDefaults.data, null, 4));
                root.desktopReady = true;
            }
        }
    }

    FileView {
        id: desktopLoader
        path: root.configDir + "/desktop.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.desktopReady && !root.pauseAutoSave) {
                desktopLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property bool enabled: false
            property int iconSize: 40
            property int spacingVertical: 16
            property string textColor: "overBackground"
        }
    }

    // ============================================
    // LOCKSCREEN MODULE
    // ============================================
    FileView {
        id: lockscreenRawLoader
        path: root.configDir + "/lockscreen.json"
        onLoaded: {
            if (!root.lockscreenReady) {
                validateModule("lockscreen", lockscreenRawLoader, LockscreenDefaults.data, () => { root.lockscreenReady = true; });
            }
        }
    }

    Process {
        id: checkLockscreenFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/lockscreen.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("lockscreen.json not found, creating with default values...");
                lockscreenRawLoader.setText(JSON.stringify(LockscreenDefaults.data, null, 4));
                root.lockscreenReady = true;
            }
        }
    }

    FileView {
        id: lockscreenLoader
        path: root.configDir + "/lockscreen.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.lockscreenReady && !root.pauseAutoSave) {
                lockscreenLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property string position: "bottom"
        }
    }

    // ============================================
    // PREFIX MODULE
    // ============================================
    FileView {
        id: prefixRawLoader
        path: root.configDir + "/prefix.json"
        onLoaded: {
            if (!root.prefixReady) {
                validateModule("prefix", prefixRawLoader, PrefixDefaults.data, () => { root.prefixReady = true; });
            }
        }
    }

    Process {
        id: checkPrefixFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/prefix.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("prefix.json not found, creating with default values...");
                prefixRawLoader.setText(JSON.stringify(PrefixDefaults.data, null, 4));
                root.prefixReady = true;
            }
        }
    }

    FileView {
        id: prefixLoader
        path: root.configDir + "/prefix.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.prefixReady && !root.pauseAutoSave) {
                prefixLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property string clipboard: "cc"
            property string emoji: "ee"
            property string tmux: "tt"
            property string wallpapers: "ww"
            property string notes: "nn"
        }
    }

    // ============================================
    // SYSTEM MODULE
    // ============================================
    FileView {
        id: systemRawLoader
        path: root.configDir + "/system.json"
        onLoaded: {
            if (!root.systemReady) {
                validateModule("system", systemRawLoader, SystemDefaults.data, () => { root.systemReady = true; });
            }
        }
    }

    Process {
        id: checkSystemFile
        running: true
        command: ["sh", "-c", "test -f \"" + root.configDir + "/system.json\""]
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("system.json not found, creating with default values...");
                systemRawLoader.setText(JSON.stringify(SystemDefaults.data, null, 4));
                root.systemReady = true;
            }
        }
    }

    FileView {
        id: systemLoader
        path: root.configDir + "/system.json"
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.systemReady && !root.pauseAutoSave) {
                systemLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property list<string> disks: ["/"]
        }
    }

    // ============================================
    // KEYBINDS (kept separate as binds.json)
    // ============================================
    Process {
        id: checkKeybindsFile
        running: true
        command: ["sh", "-c", "mkdir -p \"$(dirname '" + keybindsPath + "')\" && test -f \"" + keybindsPath + "\""]

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("binds.json not found, creating with default values...");
                keybindsLoader.writeAdapter();
            }
            root.keybindsInitialLoadComplete = true;
        }
    }

    FileView {
        id: keybindsLoader
        path: keybindsPath
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: reload()
        onAdapterUpdated: {
            if (root.keybindsInitialLoadComplete) {
                keybindsLoader.writeAdapter();
            }
        }

        adapter: JsonAdapter {
            property JsonObject ambxst: JsonObject {
                property JsonObject dashboard: JsonObject {
                    property JsonObject widgets: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "R"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-widgets"
                    }
                    property JsonObject clipboard: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "V"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-clipboard"
                    }
                    property JsonObject emoji: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "PERIOD"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-emoji"
                    }
                    property JsonObject tmux: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "T"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-tmux"
                    }
                    property JsonObject kanban: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "N"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-kanban"
                    }
                    property JsonObject wallpapers: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "COMMA"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-wallpapers"
                    }
                    property JsonObject assistant: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "A"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-assistant"
                    }
                    property JsonObject notes: JsonObject {
                        property list<string> modifiers: ["SUPER", "SHIFT"]
                        property string key: "N"
                        property string dispatcher: "global"
                        property string argument: "ambxst:dashboard-notes"
                    }
                }
                property JsonObject system: JsonObject {
                    property JsonObject overview: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "TAB"
                        property string dispatcher: "global"
                        property string argument: "ambxst:overview"
                    }
                    property JsonObject powermenu: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "ESCAPE"
                        property string dispatcher: "global"
                        property string argument: "ambxst:powermenu"
                    }
                    property JsonObject config: JsonObject {
                        property list<string> modifiers: ["SUPER", "SHIFT"]
                        property string key: "C"
                        property string dispatcher: "global"
                        property string argument: "ambxst:config"
                    }
                    property JsonObject lockscreen: JsonObject {
                        property list<string> modifiers: ["SUPER"]
                        property string key: "L"
                        property string dispatcher: "global"
                        property string argument: "ambxst:lockscreen"
                    }
                }
            }
            property list<var> custom: [
                // Window management
                {
                    "modifiers": ["SUPER"],
                    "key": "C",
                    "dispatcher": "killactive",
                    "argument": "",
                    "enabled": true
                },

                // Switch workspaces with SUPER + [0-9]
                {
                    "modifiers": ["SUPER"],
                    "key": "1",
                    "dispatcher": "workspace",
                    "argument": "1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "2",
                    "dispatcher": "workspace",
                    "argument": "2",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "3",
                    "dispatcher": "workspace",
                    "argument": "3",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "4",
                    "dispatcher": "workspace",
                    "argument": "4",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "5",
                    "dispatcher": "workspace",
                    "argument": "5",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "6",
                    "dispatcher": "workspace",
                    "argument": "6",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "7",
                    "dispatcher": "workspace",
                    "argument": "7",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "8",
                    "dispatcher": "workspace",
                    "argument": "8",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "9",
                    "dispatcher": "workspace",
                    "argument": "9",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "0",
                    "dispatcher": "workspace",
                    "argument": "10",
                    "enabled": true
                },

                // Move active window to workspace with SUPER + SHIFT + [0-9]
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "1",
                    "dispatcher": "movetoworkspace",
                    "argument": "1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "2",
                    "dispatcher": "movetoworkspace",
                    "argument": "2",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "3",
                    "dispatcher": "movetoworkspace",
                    "argument": "3",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "4",
                    "dispatcher": "movetoworkspace",
                    "argument": "4",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "5",
                    "dispatcher": "movetoworkspace",
                    "argument": "5",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "6",
                    "dispatcher": "movetoworkspace",
                    "argument": "6",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "7",
                    "dispatcher": "movetoworkspace",
                    "argument": "7",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "8",
                    "dispatcher": "movetoworkspace",
                    "argument": "8",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "9",
                    "dispatcher": "movetoworkspace",
                    "argument": "9",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "0",
                    "dispatcher": "movetoworkspace",
                    "argument": "10",
                    "enabled": true
                },

                // Scroll through workspaces
                {
                    "modifiers": ["SUPER"],
                    "key": "mouse_down",
                    "dispatcher": "workspace",
                    "argument": "e-1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "Z",
                    "dispatcher": "workspace",
                    "argument": "e-1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "mouse_up",
                    "dispatcher": "workspace",
                    "argument": "e+1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "X",
                    "dispatcher": "workspace",
                    "argument": "e+1",
                    "enabled": true
                },

                // Next/previous workspace with Z and X
                {
                    "modifiers": ["SUPER"],
                    "key": "Z",
                    "dispatcher": "workspace",
                    "argument": "-1",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "X",
                    "dispatcher": "workspace",
                    "argument": "+1",
                    "enabled": true
                },

                // Move/resize windows with mouse
                {
                    "modifiers": ["SUPER"],
                    "key": "mouse:272",
                    "dispatcher": "movewindow",
                    "argument": "",
                    "flags": "m",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER"],
                    "key": "mouse:273",
                    "dispatcher": "resizewindow",
                    "argument": "",
                    "flags": "m",
                    "enabled": true
                },

                // Media player controls
                {
                    "modifiers": [],
                    "key": "XF86AudioPlay",
                    "dispatcher": "exec",
                    "argument": "playerctl play-pause",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioPrev",
                    "dispatcher": "exec",
                    "argument": "playerctl previous",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioNext",
                    "dispatcher": "exec",
                    "argument": "playerctl next",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioMedia",
                    "dispatcher": "exec",
                    "argument": "playerctl play-pause",
                    "flags": "l",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioStop",
                    "dispatcher": "exec",
                    "argument": "playerctl stop",
                    "flags": "l",
                    "enabled": true
                },

                // Volume controls
                {
                    "modifiers": [],
                    "key": "XF86AudioRaiseVolume",
                    "dispatcher": "exec",
                    "argument": "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+",
                    "flags": "le",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioLowerVolume",
                    "dispatcher": "exec",
                    "argument": "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%-",
                    "flags": "le",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86AudioMute",
                    "dispatcher": "exec",
                    "argument": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
                    "flags": "le",
                    "enabled": true
                },

                // Brightness controls
                {
                    "modifiers": [],
                    "key": "XF86MonBrightnessUp",
                    "dispatcher": "exec",
                    "argument": "swayosd-client --brightness=raise 5",
                    "flags": "le",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "XF86MonBrightnessDown",
                    "dispatcher": "exec",
                    "argument": "swayosd-client --brightness=lower 5",
                    "flags": "le",
                    "enabled": true
                },

                // Calculator key
                {
                    "modifiers": [],
                    "key": "XF86Calculator",
                    "dispatcher": "exec",
                    "argument": "notify-send \"Soon\"",
                    "enabled": true
                },

                // Special workspaces
                {
                    "modifiers": ["SUPER", "SHIFT"],
                    "key": "V",
                    "dispatcher": "togglespecialworkspace",
                    "argument": "",
                    "enabled": true
                },
                {
                    "modifiers": ["SUPER", "ALT"],
                    "key": "V",
                    "dispatcher": "movetoworkspace",
                    "argument": "special",
                    "enabled": true
                },

                // Lid switch events
                {
                    "modifiers": [],
                    "key": "switch:Lid Switch",
                    "dispatcher": "exec",
                    "argument": "loginctl lock-session",
                    "flags": "l",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "switch:on:Lid Switch",
                    "dispatcher": "exec",
                    "argument": "hyprctl dispatch dpms off",
                    "flags": "l",
                    "enabled": true
                },
                {
                    "modifiers": [],
                    "key": "switch:off:Lid Switch",
                    "dispatcher": "exec",
                    "argument": "hyprctl dispatch dpms on",
                    "flags": "l",
                    "enabled": true
                }
            ]
        }
    }

    // ============================================
    // VALIDATION HELPER
    // ============================================
    function validateModule(name, rawLoader, defaults, onComplete) {
        var raw = rawLoader.text();
        if (!raw) {
            onComplete();
            return;
        }

        try {
            var current = JSON.parse(raw);
            var validated = ConfigValidator.validate(current, defaults);

            if (JSON.stringify(current) !== JSON.stringify(validated)) {
                console.log("Merging and updating " + name + ".json...");
                rawLoader.setText(JSON.stringify(validated, null, 4));
            }
            onComplete();
        } catch (e) {
            console.log("Error validating " + name + " config (invalid JSON?): " + e);
            console.log("Overwriting with defaults due to error.");
            rawLoader.setText(JSON.stringify(defaults, null, 4));
            onComplete();
        }
    }

    // ============================================
    // EXPOSED PROPERTIES (backward compatibility)
    // ============================================

    // Theme configuration
    property QtObject theme: themeLoader.adapter
    property bool oledMode: lightMode ? false : theme.oledMode
    property bool lightMode: theme.lightMode

    property int roundness: theme.roundness
    property string defaultFont: theme.font
    property int animDuration: Services.GameModeService.toggled ? 0 : theme.animDuration
    property bool tintIcons: theme.tintIcons

    // Detect lightMode changes and run Matugen
    onLightModeChanged: {
        console.log("lightMode changed to:", lightMode);
        if (GlobalStates.wallpaperManager) {
            var wallpaperManager = GlobalStates.wallpaperManager;
            if (wallpaperManager.currentWallpaper) {
                console.log("Re-running Matugen due to lightMode change");
                wallpaperManager.runMatugenForCurrentWallpaper();
            }
        }
    }

    // Bar configuration
    property QtObject bar: barLoader.adapter
    property bool showBackground: theme.srBarBg.opacity > 0

    // Workspace configuration
    property QtObject workspaces: workspacesLoader.adapter

    // Overview configuration
    property QtObject overview: overviewLoader.adapter

    // Notch configuration
    property QtObject notch: notchLoader.adapter
    property string notchTheme: notch.theme

    // Hyprland configuration
    property QtObject hyprland: hyprlandLoader.adapter
    property int hyprlandRounding: hyprland.syncRoundness ? Math.max(0, roundness - (hyprland.gapsOut - hyprlandBorderSize)) : Math.max(0, hyprland.rounding - hyprlandBorderSize)
    property int hyprlandBorderSize: hyprland.syncBorderWidth ? (theme.srBg.border[1] || 0) : hyprland.borderSize
    property string hyprlandBorderColor: hyprland.syncBorderColor ? (theme.srBg.border[0] || "primary") : (hyprland.activeBorderColor.length > 0 ? hyprland.activeBorderColor[0] : "primary")
    property real hyprlandShadowOpacity: hyprland.syncShadowOpacity ? theme.shadowOpacity : hyprland.shadowOpacity
    property string hyprlandShadowColor: hyprland.syncShadowColor ? theme.shadowColor : hyprland.shadowColor

    // Performance configuration
    property QtObject performance: performanceLoader.adapter
    property bool blurTransition: performance.blurTransition

    // Weather configuration
    property QtObject weather: weatherLoader.adapter

    // Desktop configuration
    property QtObject desktop: desktopLoader.adapter

    // Lockscreen configuration
    property QtObject lockscreen: lockscreenLoader.adapter

    // Prefix configuration
    property QtObject prefix: prefixLoader.adapter

    // System configuration
    property QtObject system: systemLoader.adapter

    // Helper functions for color handling (HEX or named colors)
    function isHexColor(colorValue) {
        if (typeof colorValue !== 'string')
            return false;
        const normalized = colorValue.toLowerCase().trim();
        return normalized.startsWith('#') || normalized.startsWith('rgb');
    }

    function resolveColor(colorValue) {
        if (isHexColor(colorValue)) {
            return colorValue;
        }
        return Colors[colorValue] || Colors.primary;
    }

    function resolveColorWithOpacity(colorValue, opacity) {
        const color = isHexColor(colorValue) ? Qt.color(colorValue) : (Colors[colorValue] || Colors.primary);
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}
